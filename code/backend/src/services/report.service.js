const prisma = require('../utils/prisma');
const ApiError = require('../utils/ApiError');
const { uploadToCloudinary } = require('../utils/cloudinary');

const baseSelect = {
  id: true,
  passengerId: true,
  driverId: true,
  types: true,
  description: true,
  photos: true,
  status: true,
  createdAt: true,
  updatedAt: true,
};

const buildWhere = (opts = {}) => {
  const { q, status, passengerId, driverId, createdFrom, createdTo } = opts;

  return {
    ...(status && { status }),
    ...(passengerId && { passengerId }),
    ...(driverId && { driverId }),
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
 * Passenger creates a report against a driver
 */
const createReport = async (data, passengerId, files) => {
  // Verify the driver exists and is actually a driver
  const driver = await prisma.user.findUnique({
    where: { id: data.driverId },
    select: { id: true, role: true },
  });
  if (!driver) throw new ApiError(404, 'Driver not found');
  if (driver.role !== 'DRIVER') throw new ApiError(400, 'The reported user is not a driver');

  // Cannot report yourself
  if (data.driverId === passengerId) {
    throw new ApiError(400, 'You cannot report yourself');
  }

  // Upload photos to Cloudinary
  const photoUrls = [];
  if (files && files.length > 0) {
    for (const file of files) {
      const result = await uploadToCloudinary(file.buffer, 'reports');
      photoUrls.push(result.url);
    }
  }

  const report = await prisma.$transaction(async (tx) => {
    const created = await tx.report.create({
      data: {
        passengerId,
        driverId: data.driverId,
        types: data.types,
        description: data.description || null,
        photos: photoUrls,
      },
      select: {
        ...baseSelect,
        passenger: { select: { id: true, firstName: true, lastName: true, username: true } },
        driver: { select: { id: true, firstName: true, lastName: true, username: true } },
      },
    });

    // Send notification to passenger that report has been sent
    await tx.notification.create({
      data: {
        userId: passengerId,
        type: 'REPORT',
        title: 'รายงานของคุณถูกส่งแล้ว',
        body: 'รายงานของคุณถูกส่งเรียบร้อยแล้ว เราจะตรวจสอบและแจ้งผลให้ทราบ',
        metadata: {
          kind: 'REPORT_CREATED',
          reportId: created.id,
          driverId: data.driverId,
        },
      },
    });

    return created;
  });

  return report;
};

/**
 * Passenger gets their own reports
 */
const getMyReports = async (passengerId) => {
  return prisma.report.findMany({
    where: { passengerId },
    select: {
      ...baseSelect,
      driver: {
        select: { id: true, firstName: true, lastName: true, username: true, profilePicture: true },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
};

/**
 * Get report by ID (for passenger — must own the report)
 */
const getMyReportById = async (id, passengerId) => {
  const report = await prisma.report.findUnique({
    where: { id },
    select: {
      ...baseSelect,
      passenger: { select: { id: true, firstName: true, lastName: true, username: true } },
      driver: { select: { id: true, firstName: true, lastName: true, username: true, profilePicture: true } },
    },
  });
  if (!report || report.passengerId !== passengerId) {
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
        passenger: { select: { id: true, firstName: true, lastName: true, email: true, username: true, phoneNumber: true, profilePicture: true } },
        driver: { select: { id: true, firstName: true, lastName: true, email: true, username: true, phoneNumber: true, profilePicture: true } },
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
      passenger: { select: { id: true, firstName: true, lastName: true, email: true, username: true, phoneNumber: true, profilePicture: true } },
      driver: { select: { id: true, firstName: true, lastName: true, email: true, username: true, phoneNumber: true, profilePicture: true } },
    },
  });
  if (!report) throw new ApiError(404, 'Report not found');
  return report;
};

/**
 * Admin: update report status (approve / reject)
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
        passenger: { select: { id: true, firstName: true, lastName: true, username: true, email: true, phoneNumber: true, profilePicture: true } },
        driver: { select: { id: true, firstName: true, lastName: true, username: true, email: true, phoneNumber: true, profilePicture: true } },
      },
    });

    // Send notification to passenger about status change
    const statusText = status === 'APPROVED' ? 'ดำเนินการเรียบร้อย' : 'ปฏิเสธ';
    const bodyText = status === 'APPROVED'
      ? 'ทางทีมงานได้ตรวจสอบและดำเนินการตามแนวทางของระบบแล้ว ขอบคุณที่แจ้งข้อมูลให้เราทราบ'
      : 'ขอขอบคุณสำหรับการรายงานหลังจากตรวจสอบแล้ว ทีมงานไม่พบการกระทำที่เข้าข่ายการละเมิดหรือผิดกฎของระบบ จึงขอปฏิเสธการรายงานในครั้งนี้ หากมีข้อมูลเพิ่มเติมสามารถแจ้งเข้ามาได้อีกครั้ง';

    await tx.notification.create({
      data: {
        userId: report.passengerId,
        type: 'REPORT',
        title: `รายงานคนขับของคุณถูก${statusText}`,
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
