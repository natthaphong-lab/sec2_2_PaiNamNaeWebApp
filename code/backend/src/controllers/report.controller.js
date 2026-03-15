const asyncHandler = require('express-async-handler');
const reportService = require('../services/report.service');
const ApiError = require('../utils/ApiError');
const prisma = require('../utils/prisma');

const createReport = asyncHandler(async (req, res) => {
  const reporterId = req.user.sub;
  const reporterRole = req.user.role; // PASSENGER or DRIVER

  if (reporterRole !== 'PASSENGER' && reporterRole !== 'DRIVER') {
    throw new ApiError(403, 'Only passengers and drivers can create reports');
  }

  // Parse types from body (could be JSON string if sent via multipart)
  let types = req.body.types;
  if (typeof types === 'string') {
    try {
      types = JSON.parse(types);
    } catch {
      throw new ApiError(400, 'Invalid types format');
    }
  }

  const payload = {
    bookingId: req.body.bookingId,
    reportedUserId: req.body.reportedUserId,
    category: req.body.category,
    types: types || [],
    description: req.body.description,
  };

  const report = await reportService.createReport(payload, reporterId, reporterRole, req.files);
  res.status(201).json({ success: true, message: 'Report created successfully', data: report });
});

const getMyReports = asyncHandler(async (req, res) => {
  const userId = req.user.sub;
  const data = await reportService.getMyReports(userId);
  res.status(200).json({ success: true, message: 'Reports retrieved successfully', data });
});

const getMyReportById = asyncHandler(async (req, res) => {
  const userId = req.user.sub;
  const data = await reportService.getMyReportById(req.params.id, userId);
  res.status(200).json({ success: true, message: 'Report retrieved successfully', data });
});

// --- Admin ---

const adminListReports = asyncHandler(async (req, res) => {
  const result = await reportService.listReportsAdmin(req.query);
  res.status(200).json({ success: true, message: 'Reports (admin) retrieved successfully', ...result });
});

const adminGetReportById = asyncHandler(async (req, res) => {
  const data = await reportService.adminGetReportById(req.params.id);
  res.status(200).json({ success: true, message: 'Report retrieved successfully', data });
});

const adminUpdateReportStatus = asyncHandler(async (req, res) => {

  console.log("PARAMS:", req.params)
  console.log("BODY:", req.body)

  const { id } = req.params;
  const { status, notificationBody } = req.body;

  console.log("ID:", id)
  console.log("STATUS:", status)
  console.log("NOTI:", notificationBody)

  const data = await reportService.adminUpdateReportStatus(id, status, notificationBody);

  res.status(200).json({
    success: true,
    message: `Report status updated to ${status}`,
    data
  });
});

const adminDeleteReport = asyncHandler(async (req, res) => {
  const data = await reportService.adminDeleteReport(req.params.id);
  res.status(200).json({ success: true, message: 'Report deleted successfully', data });
});


const adminGetReportsByGroup = asyncHandler(async (req, res) => {

  const { bookingId, category } = req.params;

  const reports = await prisma.report.findMany({
    where: {
      bookingId,
      category
    },
    include: {
      reporter: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          email: true,
          username: true,
          phoneNumber: true,
          profilePicture: true
        }
      },
      reportedUser: {
        select: {
          id: true,
          firstName: true,
          lastName: true,
          email: true,
          username: true,
          phoneNumber: true,
          profilePicture: true
        }
      }
    },
    orderBy: {
      createdAt: 'desc'
    }
  });

  res.status(200).json({
    success: true,
    message: 'Reports retrieved successfully',
    data: reports
  });

});



module.exports = {
  createReport,
  getMyReports,
  getMyReportById,
  adminListReports,
  adminGetReportById,
  adminUpdateReportStatus,
  adminDeleteReport,
  adminGetReportsByGroup   
};