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
  const reportId = getArg('--reportId');
  const testUserId = getArg('--testUserId');

  if (reportId) {
    await safeDelete(prisma.report.delete({ where: { id: reportId } }));
  }

  if (testUserId) {
    await safeDelete(prisma.user.delete({ where: { id: testUserId } }));
  }

  process.stdout.write(JSON.stringify({ ok: true, reportId, testUserId }));
}

main()
  .catch((err) => {
    process.stderr.write(String(err?.stack || err));
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

