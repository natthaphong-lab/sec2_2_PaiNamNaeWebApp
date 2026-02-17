const express = require('express');
const validate = require('../middlewares/validate');
const { protect, requireAdmin } = require('../middlewares/auth');
const upload = require('../middlewares/upload.middleware');
const reportController = require('../controllers/report.controller');
const {
  createReportSchema,
  idParamSchema,
  updateReportStatusSchema,
  listReportsQuerySchema,
} = require('../validations/report.validation');

const router = express.Router();

// --- Admin Routes ---
// GET /reports/admin
router.get(
  '/admin',
  protect,
  requireAdmin,
  validate({ query: listReportsQuerySchema }),
  reportController.adminListReports
);

// GET /reports/admin/:id
router.get(
  '/admin/:id',
  protect,
  requireAdmin,
  validate({ params: idParamSchema }),
  reportController.adminGetReportById
);

// PATCH /reports/admin/:id/status
router.patch(
  '/admin/:id/status',
  protect,
  requireAdmin,
  validate({ params: idParamSchema, body: updateReportStatusSchema }),
  reportController.adminUpdateReportStatus
);

// DELETE /reports/admin/:id
router.delete(
  '/admin/:id',
  protect,
  requireAdmin,
  validate({ params: idParamSchema }),
  reportController.adminDeleteReport
);

// --- Passenger Routes ---
// GET /reports/me
router.get(
  '/me',
  protect,
  reportController.getMyReports
);

// GET /reports/:id
router.get(
  '/:id',
  protect,
  validate({ params: idParamSchema }),
  reportController.getMyReportById
);

// POST /reports
router.post(
  '/',
  protect,
  upload.array('photos', 5),
  validate({ body: createReportSchema }),
  reportController.createReport
);

module.exports = router;
