/**
 * @swagger
 * components:
 *   schemas:
 *     ReportCategory:
 *       type: string
 *       description: |
 *         Passenger categories: safety, driverBehavior, vehicle, lostItem, other
 *         Driver categories: safety, passengerBehavior, damaged, lostItem, other
 *       enum:
 *         - safety
 *         - driverBehavior
 *         - vehicle
 *         - lostItem
 *         - passengerBehavior
 *         - damaged
 *         - other
 *     ReportStatus:
 *       type: string
 *       enum: [PENDING, ON_PROGRESS, COMPLETED, REJECTED]
 *     Report:
 *       type: object
 *       properties:
 *         id:
 *           type: string
 *         bookingId:
 *           type: string
 *         reporterId:
 *           type: string
 *         reportedUserId:
 *           type: string
 *         reporterRole:
 *           type: string
 *           enum: [PASSENGER, DRIVER]
 *         category:
 *           $ref: '#/components/schemas/ReportCategory'
 *         types:
 *           type: array
 *           items:
 *             type: string
 *           description: Free-form type strings provided by frontend
 *         description:
 *           type: string
 *           nullable: true
 *         mediaUrls:
 *           type: array
 *           items:
 *             type: string
 *             format: uri
 *           maxItems: 3
 *           description: Up to 3 Cloudinary URLs (photo/video/mp3)
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
 *         bookingId:
 *           type: string
 *         reporterId:
 *           type: string
 *         reportedUserId:
 *           type: string
 *         reporterRole:
 *           type: string
 *           enum: [PASSENGER, DRIVER]
 *         category:
 *           $ref: '#/components/schemas/ReportCategory'
 *         types:
 *           type: array
 *           items:
 *             type: string
 *         description:
 *           type: string
 *           nullable: true
 *         mediaUrls:
 *           type: array
 *           items:
 *             type: string
 *             format: uri
 *           maxItems: 3
 *         status:
 *           $ref: '#/components/schemas/ReportStatus'
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *         reporter:
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
 *         reportedUser:
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
 *     summary: Create a new report (passenger reports driver OR driver reports passenger)
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
 *               - bookingId
 *               - reportedUserId
 *               - category
 *             properties:
 *               bookingId:
 *                 type: string
 *                 description: Booking ID for the trip context being reported
 *               reportedUserId:
 *                 type: string
 *                 description: ID of the user being reported
 *               category:
 *                 $ref: '#/components/schemas/ReportCategory'
 *               types:
 *                 type: string
 *                 description: 'JSON array of free-form type strings, e.g. ["speeding","rude"]'
 *               description:
 *                 type: string
 *                 description: Additional details about the report
 *               media:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *                 description: Up to 3 files (photo/video/mp3) as evidence
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
 *         description: Validation error or invalid category for role
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Only passengers and drivers can create reports
 *       404:
 *         description: Reported user not found
 */

/**
 * @swagger
 * /api/reports/me:
 *   get:
 *     summary: Get my reports (reports I created)
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
 *     summary: Get a specific report by ID (must be the reporter)
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
 *         name: bookingId
 *         schema:
 *           type: string
 *       - in: query
 *         name: reporterId
 *         schema:
 *           type: string
 *       - in: query
 *         name: reportedUserId
 *         schema:
 *           type: string
 *       - in: query
 *         name: reporterRole
 *         schema:
 *           type: string
 *           enum: [PASSENGER, DRIVER]
 *       - in: query
 *         name: category
 *         schema:
 *           $ref: '#/components/schemas/ReportCategory'
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
 *     summary: Update report status (admin only)
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
 *                 enum: [PENDING, ON_PROGRESS, COMPLETED, REJECTED]
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
