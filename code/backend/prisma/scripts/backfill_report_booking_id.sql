-- backfill_report_booking_id.sql
-- Purpose: help backfill Report.bookingId before enforcing NOT NULL in environments
-- that already contain Report rows created before bookingId was introduced.
--
-- IMPORTANT:
-- 1) Review every update condition against your business rules.
-- 2) Run this in a transaction first and inspect affected row count.
-- 3) Keep a database backup before running in production.

BEGIN;

-- 0) Inspect rows that still need bookingId
SELECT id, "reporterId", "reportedUserId", "createdAt"
FROM "Report"
WHERE "bookingId" IS NULL
ORDER BY "createdAt" DESC;

-- 1) Example strategy: map report to most recent booking between the same passenger/driver pair.
--    Adjust this logic if your domain has a better deterministic key.
--
--    This sample assumes:
--    - reporterRole = PASSENGER => reporter is Booking.passengerId and reported user is Route.driverId
--    - reporterRole = DRIVER    => reporter is Route.driverId and reported user is Booking.passengerId
WITH candidate AS (
  SELECT
    r.id AS report_id,
    b.id AS booking_id,
    ROW_NUMBER() OVER (
      PARTITION BY r.id
      ORDER BY b."createdAt" DESC
    ) AS rn
  FROM "Report" r
  JOIN "Booking" b ON (
    (r."reporterRole" = 'PASSENGER' AND b."passengerId" = r."reporterId")
    OR
    (r."reporterRole" = 'DRIVER' AND b."passengerId" = r."reportedUserId")
  )
  JOIN "Route" rt ON rt.id = b."routeId"
  WHERE (
    (r."reporterRole" = 'PASSENGER' AND rt."driverId" = r."reportedUserId")
    OR
    (r."reporterRole" = 'DRIVER' AND rt."driverId" = r."reporterId")
  )
)
UPDATE "Report" r
SET "bookingId" = c.booking_id
FROM candidate c
WHERE c.rn = 1
  AND c.report_id = r.id
  AND r."bookingId" IS NULL;

-- 2) Verify unresolved rows (must be 0 before applying NOT NULL)
SELECT COUNT(*) AS unresolved_reports
FROM "Report"
WHERE "bookingId" IS NULL;

COMMIT;
