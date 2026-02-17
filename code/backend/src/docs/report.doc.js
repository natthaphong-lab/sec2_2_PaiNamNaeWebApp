/**
 * @swagger
 * components:
 *   schemas:
 *     ReportType:
 *       type: string
 *       enum:
 *         - DANGEROUS_DRIVING
 *         - INAPPROPRIATE_COMMENTS
 *         - USING_PHONE_WHILE_DRIVING
 *         - HARASSMENT
 *         - LATE
 *         - OVERCHARGING
 *         - DECLINE_PASSENGER
 *         - TAKING_WRONG_ROUTE_INTENTIONALLY
 *     ReportStatus:
 *       type: string
 *       enum: [PENDING, APPROVED, REJECTED]
 *     Report:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         passengerId:
 *           type: string
 *         driverId:
 *           type: string
 *         types:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/ReportType'
 *         description:
 *           type: string
 *           nullable: true
 *         photos:
 *           type: array
 *           items:
 *             type: string
 *             format: uri
 *         status:
 *           $ref: '#/components/schemas/ReportStatus'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *     ReportWithUsers:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         passengerId:
 *           type: string
 *         driverId:
 *           type: string
 *         types:
 *           type: array
 *           items:
 *             $ref: '#/components/schemas/ReportType'
 *         description:
 *           type: string
 *           nullable: true
 *         photos:
 *           type: array
 *           items:
 *             type: string
 *             format: uri
 *         status:
 *           $ref: '#/components/schemas/ReportStatus'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *         passenger:
 *           type: object
 *           properties:
 *             id:
 *               type: string
 *             firstName:
 *               type: string
 *             lastName:
 *               type: string
 *             username:
 *               type: string
 *             email:
 *               type: string
 *             phoneNumber:
 *               type: string
 *             profilePicture:
 *               type: string
 *         driver:
 *           type: object
 *           properties:
 *             id:
 *               type: string
 *             firstName:
 *               type: string
 *             lastName:
 *               type: string
 *             username:
 *               type: string
 *             email:
 *               type: string
 *             phoneNumber:
 *               type: string
 *             profilePicture:
 *               type: string
 */

/**
 * @swagger
 * /api/reports:
 *   post:
 *     summary: Create a new report (passenger reports a driver)
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - driverId
 *               - types
 *             properties:
 *               driverId:
 *                 type: string
 *                 description: ID of the driver being reported
 *               types:
 *                 type: string
 *                 description: 'JSON array of report types, e.g. ["DANGEROUS_DRIVING","LATE"]'
 *               description:
 *                 type: string
 *                 description: Additional details about the report
 *               photos:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *                 description: Up to 5 image files as evidence
 *     responses:
 *       201:
 *         description: Report created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/Report'
 *       400:
 *         description: Validation error
 *       401:
 *         description: Not authorized
 *       404:
 *         description: Driver not found
 */

/**
 * @swagger
 * /api/reports/me:
 *   get:
 *     summary: Get my reports (as passenger)
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Reports retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Report'
 *       401:
 *         description: Not authorized
 */

/**
 * @swagger
 * /api/reports/{id}:
 *   get:
 *     summary: Get a specific report by ID (passenger must own the report)
 *     tags: [Reports]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Report retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/Report'
 *       401:
 *         description: Not authorized
 *       404:
 *         description: Report not found
 */

/**
 * @swagger
 * /api/reports/admin:
 *   get:
 *     summary: List all reports (admin)
 *     tags: [Reports (Admin)]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *       - in: query
 *         name: status
 *         schema:
 *           $ref: '#/components/schemas/ReportStatus'
 *       - in: query
 *         name: passengerId
 *         schema:
 *           type: string
 *       - in: query
 *         name: driverId
 *         schema:
 *           type: string
 *       - in: query
 *         name: q
 *         schema:
 *           type: string
 *         description: Search in description
 *       - in: query
 *         name: createdFrom
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: createdTo
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: sortBy
 *         schema:
 *           type: string
 *           enum: [createdAt, status]
 *           default: createdAt
 *       - in: query
 *         name: sortOrder
 *         schema:
 *           type: string
 *           enum: [asc, desc]
 *           default: desc
 *     responses:
 *       200:
 *         description: Reports retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/ReportWithUsers'
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 *                     total:
 *                       type: integer
 *                     totalPages:
 *                       type: integer
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Admin access required
 */

/**
 * @swagger
 * /api/reports/admin/{id}:
 *   get:
 *     summary: Get a report by ID (admin)
 *     tags: [Reports (Admin)]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Report retrieved
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/ReportWithUsers'
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Admin access required
 *       404:
 *         description: Report not found
 */

/**
 * @swagger
 * /api/reports/admin/{id}/status:
 *   patch:
 *     summary: Update report status (admin only — approve or reject)
 *     tags: [Reports (Admin)]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - status
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [APPROVED, REJECTED]
 *     responses:
 *       200:
 *         description: Report status updated
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   $ref: '#/components/schemas/Report'
 *       400:
 *         description: Validation error
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Admin access required
 *       404:
 *         description: Report not found
 */

/**
 * @swagger
 * /api/reports/admin/{id}:
 *   delete:
 *     summary: Delete a report (admin)
 *     tags: [Reports (Admin)]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Report deleted
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 message:
 *                   type: string
 *                 data:
 *                   type: object
 *                   properties:
 *                     id:
 *                       type: string
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Admin access required
 *       404:
 *         description: Report not found
 */
