require('dotenv').config();

const prisma = require('../src/utils/prisma');
const bcrypt = require('bcrypt');

async function main() {
  const ts     = Date.now().toString().slice(-9);
  const suffix = `${ts}_${Math.random().toString(16).slice(2, 7)}`;
  const pw     = 'Test123456789';
  const hashed = await bcrypt.hash(pw, 10);

  // ---- users ---------------------------------------------------------------
  const passengerA = await prisma.user.create({
    data: {
      username:    `rb13_pa_${suffix}`.slice(0, 30),
      email:       `rb13_pa_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'PASSENGER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotPassenger',
      lastName:    'PBI13A',
      phoneNumber: '0811111111',
      gender:      'MALE',
    },
    select: { id: true, username: true },
  });

  const passengerB = await prisma.user.create({
    data: {
      username:    `rb13_pb_${suffix}`.slice(0, 30),
      email:       `rb13_pb_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'PASSENGER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotPassenger',
      lastName:    'PBI13B',
      phoneNumber: '0822222222',
      gender:      'FEMALE',
    },
    select: { id: true, username: true },
  });

  const driverA = await prisma.user.create({
    data: {
      username:    `rb13_da_${suffix}`.slice(0, 30),
      email:       `rb13_da_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'DRIVER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotDriver',
      lastName:    'PBI13A',
      phoneNumber: '0833333333',
      gender:      'MALE',
    },
    select: { id: true, username: true },
  });

  // driverB — used only as a "wrong driver" in the booking-mismatch test case
  const driverB = await prisma.user.create({
    data: {
      username:    `rb13_db_${suffix}`.slice(0, 30),
      email:       `rb13_db_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'DRIVER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotDriver',
      lastName:    'PBI13B',
      phoneNumber: '0844444444',
      gender:      'MALE',
    },
    select: { id: true },
  });

  // ---- vehicle + route (owned by driverA) ----------------------------------
  const vehicle = await prisma.vehicle.create({
    data: {
      userId:       driverA.id,
      vehicleModel: 'Toyota Camry',
      licensePlate: `T${ts}`.slice(0, 10),
      vehicleType:  'car',
      color:        'white',
      seatCapacity: 4,
      amenities:    [],
      isDefault:    true,
    },
    select: { id: true },
  });

  const departureTime = new Date(Date.now() + 24 * 60 * 60 * 1000); // tomorrow
  const route = await prisma.route.create({
    data: {
      driverId:      driverA.id,
      vehicleId:     vehicle.id,
      startLocation: { name: 'Test Start', lat: 16.0, lng: 102.0 },
      endLocation:   { name: 'Test End',   lat: 16.1, lng: 102.1 },
      departureTime,
      availableSeats: 3,
      pricePerSeat:   100,
      status:         'AVAILABLE',
    },
    select: { id: true },
  });

  // ---- bookings ------------------------------------------------------------
  // bookingA: passengerA on driverA's route (the "valid" booking for most tests)
  const bookingA = await prisma.booking.create({
    data: {
      routeId:         route.id,
      passengerId:     passengerA.id,
      numberOfSeats:   1,
      status:          'CONFIRMED',
      pickupLocation:  { name: 'Pickup A',  lat: 16.0, lng: 102.0 },
      dropoffLocation: { name: 'Dropoff A', lat: 16.1, lng: 102.1 },
    },
    select: { id: true },
  });

  // bookingB: passengerB on the same route
  // used to test "booking does not belong to this passenger"
  const bookingB = await prisma.booking.create({
    data: {
      routeId:         route.id,
      passengerId:     passengerB.id,
      numberOfSeats:   1,
      status:          'CONFIRMED',
      pickupLocation:  { name: 'Pickup B',  lat: 16.0, lng: 102.0 },
      dropoffLocation: { name: 'Dropoff B', lat: 16.1, lng: 102.1 },
    },
    select: { id: true },
  });

  // ---- pre-created report (for admin status-update tests) ------------------
  const preReport = await prisma.report.create({
    data: {
      bookingId:      bookingA.id,
      reporterId:     passengerA.id,
      reportedUserId: driverA.id,
      reporterRole:   'PASSENGER',
      category:       'driverBehavior',
      types:          ['robot_pbi13_preset'],
      description:    'Pre-created report for PBI13 admin status update tests',
      mediaUrls:      [],
      status:         'PENDING',
    },
    select: { id: true },
  });

  process.stdout.write(
    JSON.stringify({
      passengerAId:       passengerA.id,
      passengerAUsername: passengerA.username,
      passengerAPassword: pw,
      passengerBId:       passengerB.id,
      passengerBUsername: passengerB.username,
      passengerBPassword: pw,
      driverAId:          driverA.id,
      driverBId:          driverB.id,
      vehicleId:          vehicle.id,
      routeId:            route.id,
      bookingAId:         bookingA.id,
      bookingBId:         bookingB.id,
      preReportId:        preReport.id,
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
