const { PrismaClient } = require('@prisma/client');
const { PrismaPostgres } = require('@prisma/adapter-pg');
const { Pool } = require('pg');

// 1. สร้าง Pool เชื่อมต่อ Database
const pool = new Pool({ 
    connectionString: process.env.DATABASE_URL 
});

// 2. สร้าง Adapter (จำเป็นมากสำหรับ v7)
const adapter = new PrismaPostgres(pool);

let prisma;

if (process.env.NODE_ENV === 'production') {
    // 3. ใส่ adapter เข้าไปใน constructor
    prisma = new PrismaClient({ adapter });
} else {
    if (!global.prisma) {
        global.prisma = new PrismaClient({ adapter });
    }
    prisma = global.prisma;
}

module.exports = prisma;