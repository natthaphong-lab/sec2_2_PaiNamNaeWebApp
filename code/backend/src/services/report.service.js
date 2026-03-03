const prisma = require('../utils/prisma');
const ApiError = require('../utils/ApiError');
const { uploadToCloudinary } = require('../utils/cloudinary');
const { passengerCategories, driverCategories } = require('../validations/report.validation');

const MAX_MEDIA = 3;

const baseSelect = {
  id: true,
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
  const { q, status, reporterId, reportedUserId, reporterRole, category, createdFrom, createdTo } = opts;

  return {
    ...(status && { status }),
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
  const {
    page = 1,
    limit = 20,
    sortBy = 'createdAt',
    sortOrder = 'desc',
    ...filters
  } = opts;

  const where = buildWhere(filters);
  const skip = (page - 1) * limit;
  const take = limit;

  const [total, data] = await prisma.$transaction([
    prisma.report.count({ where }),
    prisma.report.findMany({
      where,
      orderBy: { [sortBy]: sortOrder },
      skip,
      take,
      select: {
        ...baseSelect,
        reporter: { select: userFull },
        reportedUser: { select: userFull },
      },
    }),
  ]);

  return {
    data,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  };
};

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

/**
 * Admin: update report status (pending / onProgress / completed / rejected)
 */
const adminUpdateReportStatus = async (id, status) => {
  const report = await prisma.report.findUnique({ where: { id } });
  if (!report) throw new ApiError(404, 'Report not found');

  const updated = await prisma.$transaction(async (tx) => {
    const updatedReport = await tx.report.update({
      where: { id },
      data: { status },
      select: {
        ...baseSelect,
        reporter: { select: userFull },
        reportedUser: { select: userFull },
      },
    });

    // Send notification to reporter about status change
    const statusTextMap = {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'กำลังดำเนินการ',
      COMPLETED: 'ดำเนินการเรียบร้อย',
      REJECTED: 'ปฏิเสธ',
    };
    const statusText = statusTextMap[status] || status;

    const bodyTextMap = {
      PENDING: 'รายงานของคุณถูกตั้งสถานะเป็นรอดำเนินการ',
      ON_PROGRESS: 'ทีมงานกำลังตรวจสอบรายงานของคุณ จะแจ้งผลให้ทราบเร็วๆ นี้',
      COMPLETED: 'ทางทีมงานได้ตรวจสอบและดำเนินการตามแนวทางของระบบแล้ว ขอบคุณที่แจ้งข้อมูลให้เราทราบ',
      REJECTED: 'ขอขอบคุณสำหรับการรายงาน หลังจากตรวจสอบแล้ว ทีมงานไม่พบการกระทำที่เข้าข่ายการละเมิดหรือผิดกฎของระบบ จึงขอปฏิเสธการรายงานในครั้งนี้',
    };
    const bodyText = bodyTextMap[status] || '';

    await tx.notification.create({
      data: {
        userId: report.reporterId,
        type: 'REPORT',
        title: `สถานะรายงานของคุณ: ${statusText}`,
        body: bodyText,
        metadata: {
          kind: 'REPORT_STATUS_UPDATED',
          reportId: id,
          status,
        },
      },
    });

    return updatedReport;
  });

  return updated;
};

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
