require('dotenv').config();

const prisma = require('../src/utils/prisma');
const bcrypt = require('bcrypt');

async function main() {
  const ts     = Date.now().toString().slice(-9);
  const suffix = `${ts}_${Math.random().toString(16).slice(2, 7)}`;
  const pw     = 'Test123456789';
  const hashed = await bcrypt.hash(pw, 10);

  // ---- users ---------------------------------------------------------------
  const driverA = await prisma.user.create({
    data: {
      username:    `rb11_da_${suffix}`.slice(0, 30),
      email:       `rb11_da_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'DRIVER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotDriver',
      lastName:    'PBI11A',
      phoneNumber: '0811110011',
      gender:      'MALE',
    },
    select: { id: true, username: true },
  });

  const driverB = await prisma.user.create({
    data: {
      username:    `rb11_db_${suffix}`.slice(0, 30),
      email:       `rb11_db_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'DRIVER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotDriver',
      lastName:    'PBI11B',
      phoneNumber: '0822220011',
      gender:      'MALE',
    },
    select: { id: true, username: true },
  });

  const passengerA = await prisma.user.create({
    data: {
      username:    `rb11_pa_${suffix}`.slice(0, 30),
      email:       `rb11_pa_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'PASSENGER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotPassenger',
      lastName:    'PBI11A',
      phoneNumber: '0833330011',
      gender:      'FEMALE',
    },
    select: { id: true, username: true },
  });

  // passengerB — for "reported user must be the booking passenger" test
  const passengerB = await prisma.user.create({
    data: {
      username:    `rb11_pb_${suffix}`.slice(0, 30),
      email:       `rb11_pb_${suffix}@example.com`.slice(0, 60),
      password:    hashed,
      role:        'PASSENGER',
      isActive:    true,
      isVerified:  true,
      firstName:   'RobotPassenger',
      lastName:    'PBI11B',
      phoneNumber: '0844440011',
      gender:      'MALE',
    },
    select: { id: true },
  });

  // ---- vehicle + route (owned by driverA) ----------------------------------
  const vehicle = await prisma.vehicle.create({
    data: {
      userId:       driverA.id,
      vehicleModel: 'Honda Civic',
      licensePlate: `D${ts}`.slice(0, 10),
      vehicleType:  'car',
      color:        'black',
      seatCapacity: 4,
      amenities:    [],
      isDefault:    true,
    },
    select: { id: true },
  });

  const departureTime = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const route = await prisma.route.create({
    data: {
      driverId:       driverA.id,
      vehicleId:      vehicle.id,
      startLocation:  { name: 'PBI11 Start', lat: 16.0, lng: 102.0 },
      endLocation:    { name: 'PBI11 End',   lat: 16.1, lng: 102.1 },
      departureTime,
      availableSeats: 3,
      pricePerSeat:   80,
      status:         'AVAILABLE',
    },
    select: { id: true },
  });

  // ---- bookings ------------------------------------------------------------
  // bookingA: passengerA on driverA's route (valid for most tests)
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

  // bookingB: passengerB on driverA's route
  // used to test "reported user must be the booking passenger"
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

  // ---- route owned by driverB (for "booking route not belong to driver") ---
  const vehicleB = await prisma.vehicle.create({
    data: {
      userId:       driverB.id,
      vehicleModel: 'Mazda 3',
      licensePlate: `E${ts}`.slice(0, 10),
      vehicleType:  'car',
      color:        'red',
      seatCapacity: 4,
      amenities:    [],
      isDefault:    true,
    },
    select: { id: true },
  });

  const routeB = await prisma.route.create({
    data: {
      driverId:       driverB.id,
      vehicleId:      vehicleB.id,
      startLocation:  { name: 'RouteB Start', lat: 16.2, lng: 102.2 },
      endLocation:    { name: 'RouteB End',   lat: 16.3, lng: 102.3 },
      departureTime,
      availableSeats: 3,
      pricePerSeat:   80,
      status:         'AVAILABLE',
    },
    select: { id: true },
  });

  // bookingC: passengerA on driverB's route
  // driverA tries to use this booking → "Booking route does not belong to this driver"
  const bookingC = await prisma.booking.create({
    data: {
      routeId:         routeB.id,
      passengerId:     passengerA.id,
      numberOfSeats:   1,
      status:          'CONFIRMED',
      pickupLocation:  { name: 'Pickup C',  lat: 16.2, lng: 102.2 },
      dropoffLocation: { name: 'Dropoff C', lat: 16.3, lng: 102.3 },
    },
    select: { id: true },
  });

  // ---- pre-created report (for admin status-update tests) ------------------
  const preReport = await prisma.report.create({
    data: {
      bookingId:      bookingA.id,
      reporterId:     driverA.id,
      reportedUserId: passengerA.id,
      reporterRole:   'DRIVER',
      category:       'passengerBehavior',
      types:          ['robot_pbi11_preset'],
      description:    'Pre-created report for PBI11 admin status update tests',
      mediaUrls:      [],
      status:         'PENDING',
    },
    select: { id: true },
  });

  process.stdout.write(
    JSON.stringify({
      driverAId:          driverA.id,
      driverAUsername:     driverA.username,
      driverAPassword:    pw,
      driverBId:          driverB.id,
      driverBUsername:     driverB.username,
      driverBPassword:    pw,
      passengerAId:       passengerA.id,
      passengerBId:       passengerB.id,
      vehicleId:          vehicle.id,
      vehicleBId:         vehicleB.id,
      routeId:            route.id,
      routeBId:           routeB.id,
      bookingAId:         bookingA.id,
      bookingBId:         bookingB.id,
      bookingCId:         bookingC.id,
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
