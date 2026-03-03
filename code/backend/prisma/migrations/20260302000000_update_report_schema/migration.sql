-- Drop existing Report table (automatically drops its indexes and FK constraints)
DROP TABLE "Report";

-- Drop old enums
DROP TYPE "ReportType";
DROP TYPE "ReportStatus";

-- CreateEnum: new ReportCategory
CREATE TYPE "ReportCategory" AS ENUM ('safety', 'driverBehavior', 'vehicle', 'lostItem', 'passengerBehavior', 'damaged', 'other');

-- CreateEnum: new ReportStatus with ON_PROGRESS and COMPLETED
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'ON_PROGRESS', 'COMPLETED', 'REJECTED');

-- CreateTable: new Report structure
CREATE TABLE "Report" (
    "id" TEXT NOT NULL,
    "reporterId" TEXT NOT NULL,
    "reportedUserId" TEXT NOT NULL,
    "reporterRole" TEXT NOT NULL,
    "category" "ReportCategory" NOT NULL,
    "types" TEXT[],
    "description" TEXT,
    "mediaUrls" TEXT[],
    "status" "ReportStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Report_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Report_reporterId_idx" ON "Report"("reporterId");

-- CreateIndex
CREATE INDEX "Report_reportedUserId_idx" ON "Report"("reportedUserId");

-- CreateIndex
CREATE INDEX "Report_status_idx" ON "Report"("status");

-- CreateIndex
CREATE INDEX "Report_createdAt_idx" ON "Report"("createdAt");

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reportedUserId_fkey" FOREIGN KEY ("reportedUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
