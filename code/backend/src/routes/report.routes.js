const express = require('express');
const validate = require('../middlewares/validate');
const { protect, requireAdmin } = require('../middlewares/auth');
const upload = require('../middlewares/upload.middleware');
const reportController = require('../controllers/report.controller');
const { adminGetReportsByGroup } = require('../controllers/report.controller')


const reportService = require('../services/report.service')
const prisma = require('../utils/prisma')

const {
  createReportSchema,
  idParamSchema,
  updateReportStatusSchema,
  listReportsQuerySchema,
} = require('../validations/report.validation');

const router = express.Router();

router.get(
  "/admin/group/:bookingId/:category",
  protect,
  requireAdmin,
  adminGetReportsByGroup
);


router.patch(
  '/admin/group/:bookingId/:category/status',
  protect,
  requireAdmin,
  async (req, res) => {

    const { bookingId, category } = req.params
    const { status, notificationBody } = req.body

    try {

      const reports = await prisma.report.findMany({
        where: {
          bookingId,
          category
        }
      })

      const results = []

      for (const report of reports) {
        const updated = await reportService.adminUpdateReportStatus(
          report.id,
          status,
          notificationBody
        )
        results.push(updated)
      }

      res.json({
        success: true,
        message: 'Reports updated successfully',
        data: results
      })

    } catch (err) {
      console.error(err)
      res.status(500).json({
        success: false,
        message: 'Failed to update reports'
      })
    }
  }
)

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

// --- User Routes (Passenger or Driver) ---
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

// POST /reports  (passenger or driver can create — max 3 media files)
router.post(
  '/',
  protect,
  upload.array('media', 3),
  validate({ body: createReportSchema }),
  reportController.createReport
);



module.exports = router;
