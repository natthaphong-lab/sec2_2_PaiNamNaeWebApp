-- CreateEnum
CREATE TYPE "Role" AS ENUM ('PASSENGER', 'DRIVER', 'ADMIN');

-- CreateEnum
CREATE TYPE "VerificationStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "RouteStatus" AS ENUM ('AVAILABLE', 'FULL', 'COMPLETED', 'CANCELLED', 'IN_TRANSIT');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('PENDING', 'CONFIRMED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "CancelReason" AS ENUM ('CHANGE_OF_PLAN', 'FOUND_ALTERNATIVE', 'DRIVER_DELAY', 'PRICE_ISSUE', 'WRONG_LOCATION', 'DUPLICATE_OR_WRONG_DATE', 'SAFETY_CONCERN', 'WEATHER_OR_FORCE_MAJEURE', 'COMMUNICATION_ISSUE');

-- CreateEnum
CREATE TYPE "LicenseType" AS ENUM ('PRIVATE_CAR_TEMPORARY', 'PRIVATE_CAR', 'PUBLIC_CAR', 'LIFETIME');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('SYSTEM', 'VERIFICATION', 'BOOKING', 'ROUTE', 'REPORT');

-- CreateEnum
CREATE TYPE "ReportCategory" AS ENUM ('safety', 'driverBehavior', 'vehicle', 'lostItem', 'passengerBehavior', 'damaged', 'other');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'ON_PROGRESS', 'COMPLETED', 'REJECTED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "firstName" TEXT,
    "lastName" TEXT,
    "gender" TEXT,
    "phoneNumber" TEXT,
    "profilePicture" TEXT,
    "nationalIdNumber" TEXT,
    "nationalIdPhotoUrl" TEXT,
    "nationalIdExpiryDate" TIMESTAMP(3),
    "selfiePhotoUrl" TEXT,
    "role" "Role" NOT NULL DEFAULT 'PASSENGER',
    "isVerified" BOOLEAN NOT NULL DEFAULT false,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "otpCode" TEXT,
    "lastLogin" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "passengerSuspendedUntil" TIMESTAMP(3),
    "driverSuspendedUntil" TIMESTAMP(3),

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "DriverVerification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "licenseNumber" TEXT NOT NULL,
    "firstNameOnLicense" TEXT NOT NULL,
    "lastNameOnLicense" TEXT NOT NULL,
    "licenseIssueDate" TIMESTAMP(3) NOT NULL,
    "licenseExpiryDate" TIMESTAMP(3) NOT NULL,
    "licensePhotoUrl" TEXT NOT NULL,
    "selfiePhotoUrl" TEXT NOT NULL,
    "typeOnLicense" "LicenseType" NOT NULL,
    "status" "VerificationStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DriverVerification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL DEFAULT 'SYSTEM',
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "link" TEXT,
    "metadata" JSON,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "adminReviewedAt" TIMESTAMP(3),

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vehicle" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "vehicleModel" TEXT NOT NULL,
    "licensePlate" TEXT NOT NULL,
    "vehicleType" TEXT NOT NULL,
    "color" TEXT NOT NULL,
    "seatCapacity" INTEGER NOT NULL,
    "amenities" TEXT[],
    "photos" JSON,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Route" (
    "id" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "vehicleId" TEXT NOT NULL,
    "startLocation" JSON NOT NULL,
    "endLocation" JSON NOT NULL,
    "departureTime" TIMESTAMP(3) NOT NULL,
    "availableSeats" INTEGER NOT NULL,
    "pricePerSeat" DOUBLE PRECISION NOT NULL,
    "conditions" TEXT,
    "status" "RouteStatus" NOT NULL DEFAULT 'AVAILABLE',
    "cancelledAt" TIMESTAMP(3),
    "cancelledBy" TEXT,
    "routePolyline" TEXT,
    "distanceMeters" INTEGER,
    "durationSeconds" INTEGER,
    "routeSummary" TEXT,
    "distance" TEXT,
    "duration" TEXT,
    "waypoints" JSON,
    "landmarks" JSON,
    "steps" JSON,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Route_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Booking" (
    "id" TEXT NOT NULL,
    "routeId" TEXT NOT NULL,
    "passengerId" TEXT NOT NULL,
    "numberOfSeats" INTEGER NOT NULL,
    "status" "BookingStatus" NOT NULL DEFAULT 'PENDING',
    "cancelledAt" TIMESTAMP(3),
    "cancelledBy" TEXT,
    "cancelReason" "CancelReason",
    "pickupLocation" JSON NOT NULL,
    "dropoffLocation" JSON NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
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
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_nationalIdNumber_key" ON "User"("nationalIdNumber");

-- CreateIndex
CREATE UNIQUE INDEX "User_nationalIdPhotoUrl_key" ON "User"("nationalIdPhotoUrl");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE INDEX "User_isActive_idx" ON "User"("isActive");

-- CreateIndex
CREATE INDEX "User_isVerified_idx" ON "User"("isVerified");

-- CreateIndex
CREATE INDEX "User_createdAt_idx" ON "User"("createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "DriverVerification_userId_key" ON "DriverVerification"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "DriverVerification_licenseNumber_key" ON "DriverVerification"("licenseNumber");

-- CreateIndex
CREATE INDEX "DriverVerification_status_idx" ON "DriverVerification"("status");

-- CreateIndex
CREATE INDEX "DriverVerification_createdAt_idx" ON "DriverVerification"("createdAt");

-- CreateIndex
CREATE INDEX "DriverVerification_licenseIssueDate_idx" ON "DriverVerification"("licenseIssueDate");

-- CreateIndex
CREATE INDEX "DriverVerification_licenseExpiryDate_idx" ON "DriverVerification"("licenseExpiryDate");

-- CreateIndex
CREATE INDEX "Notification_userId_createdAt_idx" ON "Notification"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "Notification_userId_readAt_idx" ON "Notification"("userId", "readAt");

-- CreateIndex
CREATE INDEX "Notification_adminReviewedAt_idx" ON "Notification"("adminReviewedAt");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_licensePlate_key" ON "Vehicle"("licensePlate");

-- CreateIndex
CREATE INDEX "Vehicle_userId_idx" ON "Vehicle"("userId");

-- CreateIndex
CREATE INDEX "Vehicle_createdAt_idx" ON "Vehicle"("createdAt");

-- CreateIndex
CREATE INDEX "Vehicle_vehicleType_idx" ON "Vehicle"("vehicleType");

-- CreateIndex
CREATE INDEX "Vehicle_seatCapacity_idx" ON "Vehicle"("seatCapacity");

-- CreateIndex
CREATE INDEX "Route_driverId_idx" ON "Route"("driverId");

-- CreateIndex
CREATE INDEX "Route_vehicleId_idx" ON "Route"("vehicleId");

-- CreateIndex
CREATE INDEX "Route_status_idx" ON "Route"("status");

-- CreateIndex
CREATE INDEX "Route_createdAt_idx" ON "Route"("createdAt");

-- CreateIndex
CREATE INDEX "Route_departureTime_idx" ON "Route"("departureTime");

-- CreateIndex
CREATE INDEX "Report_reporterId_idx" ON "Report"("reporterId");

-- CreateIndex
CREATE INDEX "Report_reportedUserId_idx" ON "Report"("reportedUserId");

-- CreateIndex
CREATE INDEX "Report_status_idx" ON "Report"("status");

-- CreateIndex
CREATE INDEX "Report_createdAt_idx" ON "Report"("createdAt");

-- AddForeignKey
ALTER TABLE "DriverVerification" ADD CONSTRAINT "DriverVerification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Route" ADD CONSTRAINT "Route_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Route" ADD CONSTRAINT "Route_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_routeId_fkey" FOREIGN KEY ("routeId") REFERENCES "Route"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_passengerId_fkey" FOREIGN KEY ("passengerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Report" ADD CONSTRAINT "Report_reportedUserId_fkey" FOREIGN KEY ("reportedUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
