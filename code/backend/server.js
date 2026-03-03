require("dotenv").config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
// const rateLimit = require('express-rate-limit');
const promClient = require('prom-client');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./src/config/swagger');
const routes = require('./src/routes');
const { errorHandler } = require('./src/middlewares/errorHandler');
const ApiError = require('./src/utils/ApiError')
const { metricsMiddleware } = require('./src/middlewares/metrics');
const ensureAdmin = require('./src/bootstrap/ensureAdmin');

const app = express();
promClient.collectDefaultMetrics();

// --- แก้ไขใน server.js ---

const allowedOrigins = [
  'http://csse2268.cpkku.com',
  'https://csse2268.cpkku.com',
  'http://localhost:3001',
  'https://api.painamnaeee.fun' // เพิ่มโดเมนของตัว API เองเข้าไปด้วยในบางกรณี
];

const corsOptions = {
  origin: function (origin, callback) {
    // !origin ช่วยให้พวก Postman หรือการเรียกตรงผ่าน Server-to-Server ใช้งานได้
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      // พ่น Log ออกมาดูเลยว่าตัวไหนที่หลุดเข้ามาแล้วโดน Block
      console.log("CORS Blocked for origin:", origin);
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
  credentials: true,
  optionsSuccessStatus: 200 // สำคัญสำหรับ Browser รุ่นเก่าและบางระบบ Proxy
};

app.use(cors(corsOptions));
// ย้ายมาไว้ข้างล่าง CORS
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" } // อนุญาตให้ดึง Resource ข้ามโดเมน
}));
app.options('*', cors(corsOptions));

app.use(express.json());

//Rate Limiting
// const limiter = rateLimit({
//     windowMs: 15 * 60 * 1000, // 15 minutes
//     max: 100,
//     standardHeaders: true,
//     legacyHeaders: false,
// });
// app.use(limiter);

//Metrics Middleware
app.use(metricsMiddleware);

// --- Routes ---
// Health Check Route
app.get('/health', async (req, res) => {
    try {
        const prisma = require('./src/utils/prisma');
        await prisma.$queryRaw`SELECT 1`;
        res.status(200).json({ status: 'ok' });
    } catch (err) {
        res.status(503).json({ status: 'error', detail: err.message });
    }
});

// Prometheus Metrics Route
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', promClient.register.contentType);
    res.end(await promClient.register.metrics());
});

// Swagger Documentation Route
app.use('/documentation', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// Main API Routes
app.use('/api', routes);

app.use((req, res, next) => {
    next(new ApiError(404, `Cannot ${req.method} ${req.originalUrl}`));
});

// --- Error Handling Middleware ---
app.use(errorHandler);

// --- Start Server ---
const PORT = process.env.PORT || 3000;
(async () => {
    try {
        await ensureAdmin();
    } catch (e) {
        console.error('Admin bootstrap failed:', e);
    }

    app.listen(PORT, () => {
        console.log(`🚀 Server running in ${process.env.NODE_ENV} mode on port ${PORT}`);
    });
})();
// Graceful Shutdown
process.on('unhandledRejection', (err) => {
    console.error('UNHANDLED REJECTION! 💥 Shutting down...');
    console.error(err);
    process.exit(1);
});