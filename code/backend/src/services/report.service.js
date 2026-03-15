const prisma = require('../utils/prisma');
const ApiError = require('../utils/ApiError');
const { uploadToCloudinary } = require('../utils/cloudinary');
const { passengerCategories, driverCategories } = require('../validations/report.validation');

const MAX_MEDIA = 3;

const baseSelect = {
  id: true,
  bookingId: true,
  reporterId: true,
  reportedUserId: true,
  reporterRole: true,
  category: true,
  types: true,
  description: true,
  mediaUrls: true,
  status: true,
  createdAt: true,
  updatedAt: true,
};

const userBrief = { id: true, firstName: true, lastName: true, username: true, selfiePhotoUrl: true };
const userFull = { ...userBrief, email: true, phoneNumber: true };

const buildWhere = (opts = {}) => {
  const { q, status, bookingId, reporterId, reportedUserId, reporterRole, category, createdFrom, createdTo } = opts;

  return {
    ...(status && { status }),
    ...(bookingId && { bookingId }),
    ...(reporterId && { reporterId }),
    ...(reportedUserId && { reportedUserId }),
    ...(reporterRole && { reporterRole }),
    ...(category && { category }),
    ...((createdFrom || createdTo)
      ? {
        createdAt: {
          ...(createdFrom ? { gte: new Date(createdFrom) } : {}),
          ...(createdTo ? { lte: new Date(createdTo) } : {}),
        },
      }
      : {}),
    ...(q
      ? {
        OR: [
          { description: { contains: q, mode: 'insensitive' } },
        ],
      }
      : {}),
  };
};

/**
 * Upload media files (photo/video/mp3) to Cloudinary — max 3
 */
const uploadMedia = async (files) => {
  const urls = [];
  if (!files || files.length === 0) return urls;
  if (files.length > MAX_MEDIA) {
    throw new ApiError(400, `You can upload at most ${MAX_MEDIA} files`);
  }
  for (const file of files) {
    const result = await uploadToCloudinary(file.buffer, 'reports');
    urls.push(result.url);
  }
  return urls;
};

/**
 * Validate category matches reporter role
 */
const validateCategory = (reporterRole, category) => {
  const allowed = reporterRole === 'PASSENGER' ? passengerCategories : driverCategories;
  if (!allowed.includes(category)) {
    throw new ApiError(400, `Invalid category "${category}" for ${reporterRole.toLowerCase()}. Allowed: ${allowed.join(', ')}`);
  }
};

/**
 * Create a report (passenger reports driver OR driver reports passenger)
 */
const createReport = async (data, reporterId, reporterRole, files) => {
  // Validate category matches role
  validateCategory(reporterRole, data.category);

  // Verify booking exists and enforce strict participant matching
  const booking = await prisma.booking.findUnique({
    where: { id: data.bookingId },
    select: {
      id: true,
      passengerId: true,
      route: { select: { driverId: true } },
    },
  });
  if (!booking) {
    throw new ApiError(404, 'Booking not found');
  }

  if (reporterRole === 'PASSENGER') {
    if (booking.passengerId !== reporterId) {
      throw new ApiError(400, 'Booking does not belong to this passenger');
    }
    if (booking.route.driverId !== data.reportedUserId) {
      throw new ApiError(400, 'Reported user must be the booking driver');
    }
  }

  if (reporterRole === 'DRIVER') {
    if (booking.route.driverId !== reporterId) {
      throw new ApiError(400, 'Booking route does not belong to this driver');
    }
    if (booking.passengerId !== data.reportedUserId) {
      throw new ApiError(400, 'Reported user must be the booking passenger');
    }
  }

  // Verify reported user exists
  const reportedUser = await prisma.user.findUnique({
    where: { id: data.reportedUserId },
    select: { id: true, role: true },
  });
  if (!reportedUser) throw new ApiError(404, 'Reported user not found');

  // Validate direction: passenger cannot report passenger
  if (reporterRole === 'PASSENGER' && reportedUser.role === 'PASSENGER') {
    throw new ApiError(400, 'Passengers cannot report other passengers');
  }

  // Cannot report yourself
  if (data.reportedUserId === reporterId) {
    throw new ApiError(400, 'You cannot report yourself');
  }

  // Upload media to Cloudinary (max 3)
  const mediaUrls = await uploadMedia(files);

  const report = await prisma.$transaction(async (tx) => {
    const created = await tx.report.create({
      data: {
        bookingId: data.bookingId,
        reporterId,
        reportedUserId: data.reportedUserId,
        reporterRole,
        category: data.category,
        types: data.types || [],
        description: data.description || null,
        mediaUrls,
      },
      select: {
        ...baseSelect,
        reporter: { select: userFull },
        reportedUser: { select: userFull },
      },
    });

    // Send notification to reporter that report has been sent
    await tx.notification.create({
      data: {
        userId: reporterId,
        type: 'REPORT',
        title: 'รายงานของคุณถูกส่งแล้ว',
        body: 'รายงานของคุณถูกส่งเรียบร้อยแล้ว เราจะตรวจสอบและแจ้งผลให้ทราบ',
        metadata: {
          kind: 'REPORT_CREATED',
          reportId: created.id,
          bookingId: data.bookingId,
          reportedUserId: data.reportedUserId,
        },
      },
    });

    return created;
  });

  return report;
};

/**
 * Get my reports (reports I made)
 */
const getMyReports = async (userId) => {
  return prisma.report.findMany({
    where: { reporterId: userId },
    select: {
      ...baseSelect,
      reportedUser: { select: userFull },
    },
    orderBy: { createdAt: 'desc' },
  });
};

/**
 * Get report by ID (must be the reporter)
 */
const getMyReportById = async (id, userId) => {
  const report = await prisma.report.findUnique({
    where: { id },
    select: {
      ...baseSelect,
      reporter: { select: userFull },
      reportedUser: { select: userFull },
    },
  });
  if (!report || report.reporterId !== userId) {
    throw new ApiError(404, 'Report not found');
  }
  return report;
};

/**
 * Admin: list all reports with pagination & filters
 */
const listReportsAdmin = async (opts = {}) => {
  const { page = 1, limit = 20 } = opts
  const skip = (page - 1) * limit

  const groups = await prisma.$queryRaw`
    SELECT 
      b."routeId",
      r."category",
      COUNT(r.id) as "reportCount",
      MAX(r."createdAt") as "latestReport"
    FROM "Report" r
    JOIN "Booking" b ON r."bookingId" = b.id
    GROUP BY b."routeId", r."category"
    ORDER BY "latestReport" DESC
    LIMIT ${limit}
    OFFSET ${skip}
  `

  const data = (await Promise.all(
    groups.map(async (g) => {
      const report = await prisma.report.findFirst({
        where: {
          category: g.category,
          booking: { routeId: g.routeId }
        },
        orderBy: { createdAt: 'desc' },
        select: {
          ...baseSelect,
          reporter: { select: userFull },
          reportedUser: { select: userFull },
          booking: { select: { routeId: true } }
        }
      })

      if (!report) return null

      const { booking, ...rest } = report

      return {
        ...rest,
        routeId: booking?.routeId,
        reportCount: Number(g.reportCount)
      }
    })
  )).filter(Boolean)

  return {
    data,
    pagination: {
      page,
      limit,
      total: data.length,
      totalPages: Math.ceil(data.length / limit)
    }
  }
}
/**
 * Admin: get report by ID
 */
const adminGetReportById = async (id) => {
  const report = await prisma.report.findUnique({
    where: { id },
    select: {
      ...baseSelect,
      reporter: { select: userFull },
      reportedUser: { select: userFull },
    },
  });
  if (!report) throw new ApiError(404, 'Report not found');
  return report;
};


const statusTextByCategory = {
  safety: {
    PENDING: 'รอดำเนินการ',
    ON_PROGRESS: 'กำลังดำเนินการ',
    COMPLETED: 'ตักเตือนและลงโทษแล้ว',
    REJECTED: 'ไม่พบความผิด',
  },

  driverBehavior: {
    PENDING: 'รอดำเนินการ',
    ON_PROGRESS: 'กำลังดำเนินการ',
    COMPLETED: 'ตักเตือนและลงโทษแล้ว',
    REJECTED: 'ไม่พบความผิด',
  },

  passengerBehavior: {
    PENDING: 'รอดำเนินการ',
    ON_PROGRESS: 'กำลังดำเนินการ',
    COMPLETED: 'ตักเตือนและลงโทษแล้ว',
    REJECTED: 'ไม่พบความผิด',
  },

  lostItem: {
    PENDING: 'รอดำเนินการ',
    ON_PROGRESS: 'อยู่ระหว่างการติดต่อ',
    COMPLETED: 'แจ้งไปที่ผู้โดยสารเรียบร้อย',
    REJECTED: 'ไม่พบของ',
  },

  vehicle: {
    PENDING: 'รอการดำเนินการ',
    ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
    COMPLETED: 'แจ้งให้แก้ไขแล้ว',
    REJECTED: 'ไม่พบความผิด',
  },

  damaged: {
    PENDING: 'รอการดำเนินการ',
    ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
    COMPLETED: 'แจ้งให้แก้ไขแล้ว',
    REJECTED: 'ไม่พบความผิด',
  },

  other: {
    PENDING: 'รอดำเนินการ',
    ON_PROGRESS: 'กำลังดำเนินการ',
    COMPLETED: 'ดำเนินการเสร็จสิ้น',
    REJECTED: 'ไม่พบความผิด',
  }
};
/**
 * Admin: update report status (pending / onProgress / completed / rejected)
 */
const adminUpdateReportStatus = async (routeId, category, status, notificationBody) => {

  const reports = await prisma.report.findMany({
    where: {
      category,
      booking: {
        route: { id: routeId }
      }
    },
    select: {
      id: true,
      reporterId: true
    }
  })

  if (!reports.length) {
    throw new ApiError(404, "Report group not found")
  }

  const updated = await prisma.$transaction(async (tx) => {

    await tx.report.updateMany({
      where: {
        category,
        booking: {
          route: {
            id: routeId
          }
        }
      },
      data: {
        status
      }
    })

    const statusTextMap = {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'กำลังดำเนินการ',
      COMPLETED: 'ดำเนินการเรียบร้อย',
      REJECTED: 'ปฏิเสธ'
    }

    const defaultBodyTextMap = {
      PENDING: 'รายงานของคุณถูกตั้งสถานะเป็นรอดำเนินการ',
      ON_PROGRESS: 'ทีมงานกำลังตรวจสอบรายงานของคุณ',
      COMPLETED: 'ทีมงานได้ดำเนินการเรียบร้อยแล้ว',
      REJECTED: 'หลังจากตรวจสอบแล้วไม่พบการกระทำที่ผิดกฎ'
    }

    const statusText = statusTextMap[status] || status
    const bodyText = notificationBody || defaultBodyTextMap[status] || ''

    for (const report of reports) {
      await tx.notification.create({
        data: {
          userId: report.reporterId,
          type: 'REPORT',
          title: `สถานะรายงานของคุณ: ${statusText}`,
          body: bodyText,
          metadata: {
            kind: 'REPORT_STATUS_UPDATED',
            reportId: report.id,
            routeId,
            status
          }
        }
      })
    }

    return { updated: reports.length }
  })

  return updated
}

/**
 * Admin: delete a report
 */
const adminDeleteReport = async (id) => {
  const report = await prisma.report.findUnique({ where: { id } });
  if (!report) throw new ApiError(404, 'Report not found');

  await prisma.report.delete({ where: { id } });
  return { id };
};

module.exports = {
  createReport,
  getMyReports,
  getMyReportById,
  listReportsAdmin,
  adminGetReportById,
  adminUpdateReportStatus,
  adminDeleteReport,
};
