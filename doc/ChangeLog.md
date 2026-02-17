# Changelog

## [Sprint 1] - 17-2-2026

### Added

#### ฐานข้อมูล (Prisma Schema)

- เพิ่มโมเดล `Report` ที่มีฟิลด์: `id`, `passengerId`, `driverId`, `types`, `description`, `photos`, `status`, `createdAt`, `updatedAt`
- เพิ่มดัชนีสำหรับ `passengerId`, `driverId`, `status`, และ `createdAt` เพื่อปรับปรุงประสิทธิภาพการค้นหา
- เพิ่ม `ReportType` enum (`DANGEROUS_DRIVING`, `INAPPROPRIATE_COMMENTS`, `USING_PHONE_WHILE_DRIVING`, `HARASSMENT`, `LATE`, `OVERCHARGING`, `DECLINE_PASSENGER`, `TAKING_WRONG_ROUTE_INTENTIONALLY`, `OTHER`)
- เพิ่ม `ReportStatus` enum (`PENDING`, `APPROVED`, `REJECTED`)
- เพิ่ม `REPORT` ลงในแบบหมายเหตุการแจ้งเตือน `NotificationType`
- เพิ่มความสัมพันธ์ `reportsMade` และ `reportsReceived` ในโมเดล `User`

#### จุดปลายทาง API สำหรับผู้โดยสาร

| วิธีการ | จุดปลายทาง | รายละเอียด |
|--------|----------|-------------|
| `POST` | `/reports` | ส่งรายงานต่อคนขับรถ (รองรับการอัปโหลดรูปภาพสูงสุด 5 รูป) |
| `GET` | `/reports/me` | ดึงข้อมูลรายงานของตนเอง |
| `GET` | `/reports/:id` | ดึงข้อมูลรายงานเฉพาะที่ผู้โดยสารสร้างไว้ |

#### จุดปลายทาง API สำหรับการจัดการรายงาน (ผู้ดูแล)

| วิธีการ | จุดปลายทาง | รายละเอียด |
|--------|----------|-------------|
| `GET` | `/reports/admin` | แสดงรายการรายงานทั้งหมดพร้อมการแบ่งหน้า และการกรองตามสถานะ/วันที่/ค้นหา |
| `GET` | `/reports/admin/:id` | ดึงข้อมูลรายงานเฉพาะพร้อมรายละเอียดผู้โดยสารและคนขับรถ |
| `PATCH` | `/reports/admin/:id/status` | อนุมัติหรือปฏิเสธรายงาน |
| `DELETE` | `/reports/admin/:id` | ลบรายงาน |

#### Service Layer (`report.service.js`)

- `createReport` — ตรวจสอบว่าคนขับรถมีอยู่ ป้องกันการรายงานตัวเอง อัปโหลดรูปภาพไปยัง Cloudinary สร้างรายงานในลำดับการทำงาน และส่งการแจ้งเตือนให้ผู้โดยสาร
- `getMyReports` / `getMyReportById` — คำสั่ง SQL ที่จำกัดเฉพาะผู้โดยสารสามารถดูรายงานของตนเองได้เท่านั้น
- `listReportsAdmin` — แสดงรายการพร้อมการแบ่งหน้า และตัวกรอง (`q`, `status`, `passengerId`, `driverId`, `createdFrom`, `createdTo`) และการเรียงลำดับ
- `adminGetReportById` — ดึงข้อมูลรายงานฉบับสมบูรณ์พร้อมข้อมูลผู้โดยสารและคนขับรถ
- `adminUpdateReportStatus` — อัปเดตสถานะ และส่งการแจ้งเตือนให้ผู้โดยสารเกี่ยวกับผลการตรวจสอบ
- `adminDeleteReport` — ลบรายงานถาวรหลังจากยืนยันว่ามีอยู่

#### การตรวจสอบความถูกต้อง (`report.validation.js`)

- `createReportSchema` — ตรวจสอบ `driverId` (CUID), `types` (array ของ `ReportType`, ขั้นต่ำ 1), `description` (ไม่บังคับ)
- `idParamSchema` — ตรวจสอบพารามิเตอร์เส้นทางเป็น CUID ที่ถูกต้อง
- `updateReportStatusSchema` — ตรวจสอบ `status` เป็น `ReportStatus` ที่ถูกต้อง
- `listReportsQuerySchema` — ตรวจสอบพารามิเตอร์การแบ่งหน้า การเรียงลำดับ และการกรอง

#### Middleware & การตรวจสอบสิทธิ์

- เส้นทาง API ทั้งหมดของรายงานได้รับการคุ้มครองผ่าน middleware `protect` (ต้องมี JWT)
- เส้นทาง API ของผู้ดูแลต้องมี middleware `requireAdmin` เพิ่มเติม
- การอัปโหลดรูปภาพจัดการผ่าน `upload.array('photos', 5)`

#### การแจ้งเตือน

- ผู้โดยสารได้รับการแจ้งเตือนเมื่อรายงานถูกส่ง
- ผู้โดยสารได้รับการแจ้งเตือนเมื่อผู้ดูแลอนุมัติหรือปฏิเสธรายงาน
