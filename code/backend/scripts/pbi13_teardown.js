require('dotenv').config();

const prisma = require('../src/utils/prisma');

function getArg(name) {
  const idx = process.argv.indexOf(name);
  if (idx === -1) return null;
  return process.argv[idx + 1] ?? null;
}

async function safeDelete(promise) {
  try {
    return await promise;
  } catch {
    // Ignore "record not found" errors to keep teardown idempotent.
    return null;
  }
}

async function main() {
  const passengerAId = getArg('--passengerAId');
  const passengerBId = getArg('--passengerBId');
  const driverAId    = getArg('--driverAId');
  const driverBId    = getArg('--driverBId');

  const passengerIds = [passengerAId, passengerBId].filter(Boolean);

  // Step 1: delete reports whose reporter is passengerA or passengerB.
  // This is required BEFORE deleting their bookings because Report has
  // onDelete: Restrict on the Booking FK.  Includes both the pre-created
  // fixture report and any reports created by API test cases (TC001).
  if (passengerIds.length > 0) {
    await safeDelete(
      prisma.report.deleteMany({ where: { reporterId: { in: passengerIds } } })
    );
  }

  // Step 2: delete users in safe dependency order.
  //   passengerA / passengerB  → cascades their bookings (now report-free) and notifications
  //   driverA                  → cascades vehicle, route (bookings already gone), notifications
  //   driverB                  → cascades notifications (no bookings or routes)
  for (const id of [passengerAId, passengerBId, driverAId, driverBId]) {
    if (id) await safeDelete(prisma.user.delete({ where: { id } }));
  }

  process.stdout.write(JSON.stringify({ ok: true }));
}

main()
  .catch((err) => {
    process.stderr.write(String(err?.stack || err));
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
