/*
  Warnings:

  - The values [APPROVED] on the enum `ReportStatus` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `driverId` on the `Report` table. All the data in the column will be lost.
  - You are about to drop the column `passengerId` on the `Report` table. All the data in the column will be lost.
  - You are about to drop the column `photos` on the `Report` table. All the data in the column will be lost.
  - The `types` column on the `Report` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - Added the required column `category` to the `Report` table without a default value. This is not possible if the table is not empty.
  - Added the required column `reportedUserId` to the `Report` table without a default value. This is not possible if the table is not empty.
  - Added the required column `reporterId` to the `Report` table without a default value. This is not possible if the table is not empty.
  - Added the required column `reporterRole` to the `Report` table without a default value. This is not possible if the table is not empty.

*/
-- CreateEnum
CREATE TYPE "ReportCategory" AS ENUM ('safety', 'driverBehavior', 'vehicle', 'lostItem', 'passengerBehavior', 'damaged', 'other');

-- AlterEnum
BEGIN;
CREATE TYPE "ReportStatus_new" AS ENUM ('PENDING', 'ON_PROGRESS', 'COMPLETED', 'REJECTED');
ALTER TABLE "Report" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Report" ALTER COLUMN "status" TYPE "ReportStatus_new" USING ("status"::text::"ReportStatus_new");
ALTER TYPE "ReportStatus" RENAME TO "ReportStatus_old";
ALTER TYPE "ReportStatus_new" RENAME TO "ReportStatus";
DROP TYPE "ReportStatus_old";
ALTER TABLE "Report" ALTER COLUMN "status" SET DEFAULT 'PENDING';
COMMIT;

-- DropForeignKey
ALTER TABLE "Report" DROP CONSTRAINT "Report_driverId_fkey";

-- DropForeignKey
ALTER TABLE "Report" DROP CONSTRAINT "Report_passengerId_fkey";

-- DropIndex
DROP INDEX "Report_driverId_idx";

-- DropIndex
DROP INDEX "Report_passengerId_idx";

-- AlterTable
ALTER TABLE "Report" DROP COLUMN "driverId",
DROP COLUMN "passengerId",
DROP COLUMN "photos",
ADD COLUMN     "category" "ReportCategory" NOT NULL,
ADD COLUMN     "mediaUrls" TEXT[],
ADD COLUMN     "reportedUserId" TEXT NOT NULL,
ADD COLUMN     "reporterId" TEXT NOT NULL,
ADD COLUMN     "reporterRole" TEXT NOT NULL,
DROP COLUMN "types",
ADD COLUMN     "types" TEXT[];

-- DropEnum
DROP TYPE "ReportType";

-- CreateIndex
CREATE INDEX "Report_reporterId_idx" ON "Report"("reporterId");

-- CreateIndex
CREATE INDEX "Report_reportedUserId_idx" ON "Report"("reportedUserId");

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reportedUserId_fkey" FOREIGN KEY ("reportedUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
