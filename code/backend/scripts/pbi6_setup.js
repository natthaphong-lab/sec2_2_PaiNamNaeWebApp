require('dotenv').config();

const prisma = require('../src/utils/prisma');
const bcrypt = require('bcrypt');

function getArg(name) {
  const idx = process.argv.indexOf(name);
  if (idx === -1) return null;
  return process.argv[idx + 1] ?? null;
}

async function main() {
  const reportedUserIdFromArg = getArg('--reportedUserId');

  const reportedUser =
    reportedUserIdFromArg
      ? await prisma.user.findUnique({ where: { id: reportedUserIdFromArg } })
      : await prisma.user.findFirst({ where: { role: 'ADMIN' }, orderBy: { createdAt: 'asc' } });

  if (!reportedUser) {
    throw new Error('No reported user found. Provide --reportedUserId or ensure an ADMIN exists.');
  }

  const suffix = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  const testUsername = `robot_pbi6_${suffix}`.slice(0, 30);
  const testEmail = `robot_pbi6_${suffix}@example.com`.slice(0, 60);
  const testPassword = 'Test123456789';

  const hashed = await bcrypt.hash(testPassword, 10);

  const user = await prisma.user.create({
    data: {
      username: testUsername,
      email: testEmail,
      password: hashed,
      role: 'PASSENGER',
      isActive: true,
      isVerified: true,
      firstName: 'Robot',
      lastName: 'PBI6',
      phoneNumber: '0899999999',
      gender: 'MALE',
    },
    select: { id: true, username: true, email: true },
  });

  const report = await prisma.report.create({
    data: {
      reporterId: user.id,
      reportedUserId: reportedUser.id,
      reporterRole: 'PASSENGER',
      category: 'safety',
      types: ['robot', 'pbi6'],
      description: 'Robot Framework PBI6 API test report',
      mediaUrls: [],
      status: 'PENDING',
    },
    select: { id: true },
  });

  process.stdout.write(
    JSON.stringify({
      testUserId: user.id,
      testUsername,
      testPassword,
      reportId: report.id,
      reportedUserId: reportedUser.id,
    })
  );
}

main()
  .catch((err) => {
    process.stderr.write(String(err?.stack || err));
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

