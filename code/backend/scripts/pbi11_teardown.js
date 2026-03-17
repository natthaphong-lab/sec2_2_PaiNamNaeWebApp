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
    return null;
  }
}

async function main() {
  const driverAId    = getArg('--driverAId');
  const driverBId    = getArg('--driverBId');
  const passengerAId = getArg('--passengerAId');
  const passengerBId = getArg('--passengerBId');

  const driverIds = [driverAId, driverBId].filter(Boolean);

  // Reports created by drivers must be removed first because
  // Report → Booking FK is onDelete: Restrict.
  if (driverIds.length > 0) {
    await safeDelete(
      prisma.report.deleteMany({ where: { reporterId: { in: driverIds } } })
    );
  }

  // Delete users in safe dependency order.
  // Passengers first (cascades their bookings — now report-free),
  // then drivers (cascades vehicles, routes, notifications).
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
