-- CreateEnum
CREATE TYPE "ReportType" AS ENUM ('DANGEROUS_DRIVING', 'INAPPROPRIATE_COMMENTS', 'USING_PHONE_WHILE_DRIVING', 'HARASSMENT', 'LATE', 'OVERCHARGING', 'DECLINE_PASSENGER', 'TAKING_WRONG_ROUTE_INTENTIONALLY');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- AlterEnum
ALTER TYPE "NotificationType" ADD VALUE 'REPORT';

-- CreateTable
CREATE TABLE "Report" (
    "id" TEXT NOT NULL,
    "passengerId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "types" "ReportType"[],
    "description" TEXT,
    "photos" TEXT[],
    "status" "ReportStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Report_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Report_passengerId_idx" ON "Report"("passengerId");

-- CreateIndex
CREATE INDEX "Report_driverId_idx" ON "Report"("driverId");

-- CreateIndex
CREATE INDEX "Report_status_idx" ON "Report"("status");

-- CreateIndex
CREATE INDEX "Report_createdAt_idx" ON "Report"("createdAt");

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_passengerId_fkey" FOREIGN KEY ("passengerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
