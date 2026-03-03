const { z } = require('zod');
const { ReportStatus } = require('@prisma/client');

// Categories allowed per reporter role
const passengerCategories = ['safety', 'driverBehavior', 'vehicle', 'lostItem', 'other'];
const driverCategories = ['safety', 'driverBehavior','passengerBehavior', 'vehicle','damaged', 'lostItem', 'other'];
const allCategories = [...new Set([...passengerCategories, ...driverCategories])];

const createReportSchema = z.object({
  reportedUserId: z.string().cuid({ message: 'Invalid reported user ID format' }),
  category: z.enum(allCategories, {
    required_error: 'Category is required',
    invalid_type_error: `Category must be one of: ${allCategories.join(', ')}`,
  }),
  types: z
    .preprocess(
      (val) => {
        if (typeof val === 'string') {
          try { return JSON.parse(val); } catch { return val; }
        }
        return val;
      },
      z.array(z.string().min(1).max(200))
       .max(20, 'Too many types (max 20)')
       .optional()
       .default([]),
    ),
  description: z.string().max(2000, 'Description must not exceed 2000 characters').optional(),
});

const idParamSchema = z.object({
  id: z.string().cuid({ message: 'Invalid report ID format' }),
});

const updateReportStatusSchema = z.object({
  status: z.enum(['PENDING', 'ON_PROGRESS', 'COMPLETED', 'REJECTED'], {
    required_error: 'Status is required',
    invalid_type_error: 'Status must be PENDING, ON_PROGRESS, COMPLETED, or REJECTED',
  }),
  notificationBody: z.string().trim().min(1).max(500).optional(),
});

const listReportsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),

  q: z.string().trim().min(1).optional(),
  status: z.nativeEnum(ReportStatus).optional(),
  reporterId: z.string().cuid().optional(),
  reportedUserId: z.string().cuid().optional(),
  reporterRole: z.enum(['PASSENGER', 'DRIVER']).optional(),
  category: z.enum(allCategories).optional(),

  createdFrom: z.string().refine(v => !isNaN(Date.parse(v)), { message: 'Invalid createdFrom' }).optional(),
  createdTo: z.string().refine(v => !isNaN(Date.parse(v)), { message: 'Invalid createdTo' }).optional(),

  sortBy: z.enum(['createdAt', 'status']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

module.exports = {
  passengerCategories,
  driverCategories,
  createReportSchema,
  idParamSchema,
  updateReportStatusSchema,
  listReportsQuerySchema,
};
