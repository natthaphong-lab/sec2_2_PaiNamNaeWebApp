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
  } catch (err) {
    // Ignore "record not found" errors to keep teardown idempotent.
    return null;
  }
}

async function main() {
  const passenger1Id = getArg('--passenger1Id');
  const passenger2Id = getArg('--passenger2Id');
  const driverId = getArg('--driverId');
  const reporterIds = [passenger1Id, passenger2Id].filter(Boolean);

  if (reporterIds.length > 0) {
    await safeDelete(prisma.report.deleteMany({ where: { reporterId: { in: reporterIds } } }));
  }

  if (passenger1Id) {
    await safeDelete(prisma.user.delete({ where: { id: passenger1Id } }));
  }

  if (passenger2Id) {
    await safeDelete(prisma.user.delete({ where: { id: passenger2Id } }));
  }

  if (driverId) {
    await safeDelete(prisma.user.delete({ where: { id: driverId } }));
  }

  process.stdout.write(JSON.stringify({ ok: true, passenger1Id, passenger2Id, driverId }));
}

main()
  .catch((err) => {
    process.stderr.write(String(err?.stack || err));
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

