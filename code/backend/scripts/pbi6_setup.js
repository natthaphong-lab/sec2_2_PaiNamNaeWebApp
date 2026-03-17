require('dotenv').config();

const prisma = require('../src/utils/prisma');
const bcrypt = require('bcrypt');

function getArg(name) {
  const idx = process.argv.indexOf(name);
  if (idx === -1) return null;
  return process.argv[idx + 1] ?? null;
}

async function main() {
  const suffix = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  const passenger1Username = `robot_pbi6_a_${suffix}`.slice(0, 30);
  const passenger1Email = `robot_pbi6_a_${suffix}@example.com`.slice(0, 60);
  const passenger2Username = `robot_pbi6_b_${suffix}`.slice(0, 30);
  const passenger2Email = `robot_pbi6_b_${suffix}@example.com`.slice(0, 60);
  const driverUsername = `robot_pbi6_d_${suffix}`.slice(0, 30);
  const driverEmail = `robot_pbi6_d_${suffix}@example.com`.slice(0, 60);
  const testPassword = 'Test123456789';

  const hashed = await bcrypt.hash(testPassword, 10);

  const passenger1 = await prisma.user.create({
    data: {
      username: passenger1Username,
      email: passenger1Email,
      password: hashed,
      role: 'PASSENGER',
      isActive: true,
      isVerified: true,
      firstName: 'Robot',
      lastName: 'PBI6A',
      phoneNumber: '0899999999',
      gender: 'MALE',
    },
    select: { id: true, username: true, email: true },
  });

  const passenger2 = await prisma.user.create({
    data: {
      username: passenger2Username,
      email: passenger2Email,
      password: hashed,
      role: 'PASSENGER',
      isActive: true,
      isVerified: true,
      firstName: 'Robot',
      lastName: 'PBI6B',
      phoneNumber: '0888888888',
      gender: 'FEMALE',
    },
    select: { id: true, username: true, email: true },
  });

  const driver = await prisma.user.create({
    data: {
      username: driverUsername,
      email: driverEmail,
      password: hashed,
      role: 'DRIVER',
      isActive: true,
      isVerified: true,
      firstName: 'Robot',
      lastName: 'Driver',
      phoneNumber: '0877777777',
      gender: 'MALE',
    },
    select: { id: true, username: true },
  });

  const vehicle = await prisma.vehicle.create({
    data: {
      userId: driver.id,
      vehicleModel: 'Toyota Vios',
      licensePlate: `P6${Date.now().toString().slice(-6)}`,
      vehicleType: 'car',
      color: 'white',
      seatCapacity: 4,
      amenities: [],
      isDefault: true,
    },
    select: { id: true },
  });

  const route = await prisma.route.create({
    data: {
      driverId: driver.id,
      vehicleId: vehicle.id,
      startLocation: { name: 'PBI6 Start', lat: 16.0, lng: 102.0 },
      endLocation: { name: 'PBI6 End', lat: 16.1, lng: 102.1 },
      departureTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
      availableSeats: 3,
      pricePerSeat: 100,
      status: 'AVAILABLE',
    },
    select: { id: true },
  });

  const booking1 = await prisma.booking.create({
    data: {
      routeId: route.id,
      passengerId: passenger1.id,
      numberOfSeats: 1,
      status: 'CONFIRMED',
      pickupLocation: { name: 'Pickup A', lat: 16.0, lng: 102.0 },
      dropoffLocation: { name: 'Dropoff A', lat: 16.1, lng: 102.1 },
    },
    select: { id: true },
  });

  const booking2 = await prisma.booking.create({
    data: {
      routeId: route.id,
      passengerId: passenger2.id,
      numberOfSeats: 1,
      status: 'CONFIRMED',
      pickupLocation: { name: 'Pickup B', lat: 16.0, lng: 102.0 },
      dropoffLocation: { name: 'Dropoff B', lat: 16.1, lng: 102.1 },
    },
    select: { id: true },
  });

  const report1 = await prisma.report.create({
    data: {
      bookingId: booking1.id,
      reporterId: passenger1.id,
      reportedUserId: driver.id,
      reporterRole: 'PASSENGER',
      category: 'safety',
      types: ['robot', 'pbi6'],
      description: 'Robot Framework PBI6 API test report A',
      mediaUrls: [],
      status: 'PENDING',
    },
    select: { id: true },
  });

  const report2 = await prisma.report.create({
    data: {
      bookingId: booking2.id,
      reporterId: passenger2.id,
      reportedUserId: driver.id,
      reporterRole: 'PASSENGER',
      category: 'safety',
      types: ['robot', 'pbi6', 'duplicate-group'],
      description: 'Robot Framework PBI6 API test report B',
      mediaUrls: [],
      status: 'PENDING',
    },
    select: { id: true },
  });

  process.stdout.write(
    JSON.stringify({
      passenger1Id: passenger1.id,
      passenger1Username,
      passenger2Id: passenger2.id,
      passenger2Username,
      testPassword,
      driverId: driver.id,
      routeId: route.id,
      category: 'safety',
      report1Id: report1.id,
      report2Id: report2.id,
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

