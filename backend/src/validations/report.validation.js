const { z } = require('zod');
const { ReportStatus } = require('@prisma/client');

const reportTypes = [
  'DANGEROUS_DRIVING',
  'INAPPROPRIATE_COMMENTS',
  'USING_PHONE_WHILE_DRIVING',
  'HARASSMENT',
  'LATE',
  'OVERCHARGING',
  'DECLINE_PASSENGER',
  'TAKING_WRONG_ROUTE_INTENTIONALLY',
  'OTHER'
];

const createReportSchema = z.object({
  driverId: z.string().cuid({ message: 'Invalid driver ID format' }),
  types: z
    .array(z.enum(reportTypes, { message: 'Invalid report type' }))
    .min(1, 'At least one report type is required'),
  description: z.string().max(2000, 'Description must not exceed 2000 characters').optional(),
});

const idParamSchema = z.object({
  id: z.string().cuid({ message: 'Invalid report ID format' }),
});

const updateReportStatusSchema = z.object({
  status: z.enum(['APPROVED', 'REJECTED'], {
    required_error: 'Status is required',
    invalid_type_error: 'Status must be APPROVED or REJECTED',
  }),
});

const listReportsQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),

  q: z.string().trim().min(1).optional(),
  status: z.nativeEnum(ReportStatus).optional(),
  passengerId: z.string().cuid().optional(),
  driverId: z.string().cuid().optional(),

  createdFrom: z.string().refine(v => !isNaN(Date.parse(v)), { message: 'Invalid createdFrom' }).optional(),
  createdTo: z.string().refine(v => !isNaN(Date.parse(v)), { message: 'Invalid createdTo' }).optional(),

  sortBy: z.enum(['createdAt', 'status']).default('createdAt'),
  sortOrder: z.enum(['asc', 'desc']).default('desc'),
});

module.exports = {
  createReportSchema,
  idParamSchema,
  updateReportStatusSchema,
  listReportsQuerySchema,
};
