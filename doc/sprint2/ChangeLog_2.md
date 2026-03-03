# Changelog

## [Sprint 2] - 03-03-2026

### Changed

#### ฐานข้อมูล (Prisma Schema) - การปรับปรุงครั้งใหญ่

**โครงสร้างโมเดล `Report` ที่เปลี่ยนแปลง:**

| ฟิลด์เดิม | ฟิลด์ใหม่ | เหตุผล |
|----------|---------|--------|
| `passengerId` | `reporterId` | รองรับการรายงานจากทั้งผู้โดยสารและคนขับ |
| `driverId` | `reportedUserId` | ยืดหยุ่นในการรายงานผู้ใช้ทุกประเภท |
| - | `reporterRole` (UserRole) | บันทึกบทบาทของผู้รายงาน (PASSENGER/DRIVER) |
| `types` (ReportType enum) | `category` (String) + `types` (String[]) | แยกหมวดหมู่หลักและรายละเอียดย่อยเพื่อความยืดหยุ่น |
| `photos` | `mediaUrls` | รองรับไฟล์หลายประเภท (รูปภาพ, วิดีโอ, เสียง) |

**การปรับปรุง `ReportStatus` enum:**
- เปลี่ยนจาก: `PENDING`, `APPROVED`, `REJECTED`
- เป็น: `PENDING`, `ON_PROGRESS`, `COMPLETED`, `REJECTED`
- เพิ่มสถานะ `ON_PROGRESS` เพื่อติดตามความคืบหน้าระหว่างดำเนินการ

**การจำกัดการอัปโหลดไฟล์:**
- เปลี่ยนจาก 5 รูปภาพ → 3 ไฟล์สื่อ (รูปภาพ/วิดีโอ/เสียง)
- รองรับ formats: jpg, png, gif, webp, mp4, webm, mov, mp3, wav, m4a

#### API Endpoints - รองรับการรายงานแบบสองทิศทาง

**จุดปลายทาง API สำหรับผู้ใช้ (Passenger/Driver):**

| วิธีการ | จุดปลายทาง | การเปลี่ยนแปลง |
|--------|----------|----------------|
| `POST` | `/reports` |  คนขับสามารถรายงานผู้โดยสารได้<br> รองรับ `media` (แทน `photos`)<br> ต้องระบุ `category` + `types` (แทน `types` แบบ enum) |
| `GET` | `/reports/me` |  แสดงรายงานที่ตัวเองสร้าง (ทั้ง PASSENGER/DRIVER) |
| `GET` | `/reports/:id` | ไม่เปลี่ยนแปลง |

**จุดปลายทาง API สำหรับ Admin:**

| วิธีการ | จุดปลายทาง | การเปลี่ยนแปลง |
|--------|----------|----------------|
| `GET` | `/reports/admin` |  เพิ่มตัวกรอง `reporterRole`, `category`<br> รองรับการเรียงลำดับตาม `createdAt`, `status` |
| `PATCH` | `/reports/admin/:id/status` |  เพิ่มฟิลด์ `notificationBody` สำหรับแก้ไขข้อความแจ้งเตือน<br> สถานะที่รองรับ: `PENDING`, `ON_PROGRESS`, `COMPLETED`, `REJECTED` |

#### Service Layer - ตรวจสอบและจัดการตาม Role

**การเปลี่ยนแปลงใน `report.service.js`:**

- `validateCategory(reporterRole, category)`
  - Passenger categories: `safety`, `driverBehavior`, `vehicle`, `lostItem`, `other`
  - Driver categories: `safety`, `passengerBehavior`, `vehicle`, `damaged`, `lostItem`, `other`
  - ไม่อนุญาตให้ผู้โดยสารรายงานผู้โดยสารด้วยกัน

- `uploadMedia(files)`
  - อัปโหลดไปยัง Cloudinary folder: `reports`
  - รองรับไฟล์ประเภท: image, video, audio
  - สูงสุด 3 ไฟล์ (ลดลงจาก 5)

- `adminUpdateReportStatus(id, status, notificationBody)`
  - เพิ่มพารามิเตอร์ `notificationBody` เพื่อปรับแต่งข้อความแจ้งเตือน
  - มีข้อความภาษาไทยเริ่มต้นสำหรับแต่ละสถานะ:
    - `PENDING`: "รายงานของคุณถูกตั้งสถานะเป็นรอดำเนินการ"
    - `ON_PROGRESS`: "ทีมงานกำลังตรวจสอบรายงานของคุณ จะแจ้งผลให้ทราบเร็วๆ นี้"
    - `COMPLETED`: "ทางทีมงานได้ตรวจสอบและดำเนินการตามแนวทางของระบบแล้ว..."
    - `REJECTED`: "ขอขอบคุณสำหรับการรายงาน หลังจากตรวจสอบแล้ว ทีมงานไม่พบการกระทำที่เข้าข่ายการละเมิด..."

#### Validation - หมวดหมู่และกฎการตรวจสอบความถูกต้อง

**การเปลี่ยนแปลงใน `report.validation.js`:**

```javascript
// หมวดหมู่ที่อนุญาตตาม role
const passengerCategories = ['safety', 'driverBehavior', 'vehicle', 'lostItem', 'other']
const driverCategories = ['safety', 'passengerBehavior', 'vehicle', 'damaged', 'lostItem', 'other']
```

**createReportSchema:**
- `reportedUserId` (CUID) — บังคับ
- `category` (enum) — บังคับ, ต้องอยู่ในรายการที่อนุญาตตาม role
- `types` (string[]) — ไม่บังคับ, รองรับ JSON string, max 20 items, แต่ละ item max 200 chars
- `description` (string) — ไม่บังคับ, max 2000 characters

**listReportsQuerySchema - ตัวกรองเพิ่มเติม:**
- `reporterRole`: กรองตาม `PASSENGER` หรือ `DRIVER`
- `category`: กรองตามหมวดหมู่
- `createdFrom` / `createdTo`: กรองตามช่วงวันที่

#### การแจ้งเตือน - ปรับปรุงโครงสร้าง Metadata

**Metadata สำหรับการแจ้งเตือนประเภท REPORT:**

```json
{
  "kind": "REPORT_CREATED" | "REPORT_STATUS_UPDATED",
  "reportId": "clx...",
  "reportedUserId": "clx...",
  "status": "PENDING" | "ON_PROGRESS" | "COMPLETED" | "REJECTED"
}
```

**การแจ้งเตือนที่ส่งอัตโนมัติ:**

1. **เมื่อสร้างรายงาน** (ส่งถึง reporter):
   - Title: "รายงานของคุณถูกส่งแล้ว"
   - Body: "รายงานของคุณถูกส่งเรียบร้อยแล้ว เราจะตรวจสอบและแจ้งผลให้ทราบ"
   - Metadata: `{ kind: 'REPORT_CREATED', reportId, reportedUserId }`

2. **เมื่อเปลี่ยนสถานะ** (ส่งถึง reporter):
   - Title: "สถานะรายงานของคุณ: [สถานะภาษาไทย]"
   - Body: ข้อความตามสถานะหรือที่ admin กำหนดเอง
   - Metadata: `{ kind: 'REPORT_STATUS_UPDATED', reportId, status }`

---

### Added

#### หน้า Frontend - My Report (`/profile/my-report.vue`)

**ฟีเจอร์หลัก:**
- แสดงรายการรายงานทั้งหมดที่ผู้ใช้สร้าง
- Expand/Collapse รายการเพื่อดูรายละเอียดเต็ม
- **Media Preview Modal:**
  - แสดงรูปภาพแบบเต็มจอ
  - เล่นวิดีโอพร้อม controls
  - เล่นไฟล์เสียงพร้อม waveform
- **สถานะแบบ Context-Aware:**
  - แสดงสถานะภาษาไทยที่แตกต่างกันตาม: `reporterRole`, `category`, และ `status`
  - ตัวอย่าง:
    - Passenger → lostItem → COMPLETED: "แจ้งไปที่คนขับเรียบร้อยแล้ว"
    - Driver → lostItem → COMPLETED: "แจ้งไปที่ผู้โดยสารเรียบร้อย"
- แสดงวันที่แจ้งและวันที่อัปเดตสถานะแบบพุทธศักราช
- แสดงข้อมูลผู้ถูกรายงาน (ชื่อ-นามสกุล, username, เบอร์โทร, อีเมล)

#### Navigation from Notification

**การคลิกการแจ้งเตือนประเภท REPORT (`default.vue`):**

1. **Detection Logic:**
```javascript
if ((n.type === 'REPORT' || kind?.startsWith('REPORT')) && reportId) {
  router.push({ path: '/profile/my-report', query: { reportId } })
}
```

2. **Auto Features เมื่อมี `reportId` query parameter:**
   - Auto-expand รายงานที่เกี่ยวข้อง
   - Smooth scroll ไปยังรายงานนั้นพร้อม highlight
   - Auto mark notification as read

3. **UX Improvements:**
   - เพิ่ม `cursor-pointer` ให้การแจ้งเตือน
   - ส่ง `type` และ `metadata` จาก API มายัง frontend
   - รองรับ old notifications ที่ไม่มี metadata (fallback: ปิดแผงเท่านั้น)

#### การแสดงหมวดหมู่และสถานะภาษาไทย

**ตัวแปลหมวดหมู่:**
```javascript
const reportCategoryTH = {
  safety: 'ความปลอดภัย',
  driverBehavior: 'พฤติกรรมคนขับ',
  passengerBehavior: 'พฤติกรรมผู้โดยสาร',
  vehicle: 'ปัญหายานพาหนะ',
  lostItem: 'ของหาย',
  damaged: 'ทรัพย์สินเสียหาย',
  other: 'อื่น ๆ'
}
```

**ตัวแปลสถานะ (Context-Aware):**
- แยกตาม `reporterRole` (DRIVER/PASSENGER)
- แยกตาม `category` (safety, vehicle, lostItem, etc.)
- แต่ละ combination มีข้อความภาษาไทยเฉพาะตัว

---

### Technical Implementation Details

#### Backend Changes Summary

**Files Modified:**
- `src/controllers/report.controller.js` — เพิ่มการดึง `reporterRole` จาก JWT
- `src/services/report.service.js` — Logic สำหรับ bi-directional reporting + notification
- `src/validations/report.validation.js` — Category validation per role
- `prisma/schema.prisma` — ปรับ Report model


#### Frontend Changes Summary

**Files Modified/Created:**
- `layouts/default.vue` — เพิ่ม `handleNotifClick`, รองรับ metadata
- `pages/profile/my-report.vue` — หน้าใหม่สำหรับดูประวัติรายงาน
- **Imports เพิ่มเติม:**
  - `useRouter`, `useRoute` สำหรับ navigation
  - `nextTick` สำหรับ DOM manipulation
  - `dayjs` สำหรับ format วันที่ภาษาไทย

**Key Features:**
```javascript
// Auto-expand & scroll on mount
const reportId = route.query.reportId
if (reportId) {
  expandedReportId.value = reportId
  await nextTick()
  document.getElementById(`report-${reportId}`)?.scrollIntoView({ 
    behavior: 'smooth', 
    block: 'center' 
  })
}

// Media type detection
isImage(url)  // .jpg, .png
isVideo(url)  // .mp4
isAudio(url)  // .mp3
```

---

### Breaking Changes

**API Response Structure Changes:**

**Before:**
```json
{
  "passengerId": "...",
  "driverId": "...",
  "types": ["DANGEROUS_DRIVING"],
  "photos": ["url1", "url2"],
  "status": "APPROVED"
}
```

**After:**
```json
{
  "reporterId": "...",
  "reportedUserId": "...",
  "reporterRole": "PASSENGER",
  "category": "safety",
  "types": ["ขับรถเร็วเกินไป", "ขับรถตัดหน้า"],
  "mediaUrls": ["url1", "url2"],
  "status": "COMPLETED"
}
```

**Status Enum Changes:**
- `APPROVED` → `COMPLETED`
- เพิ่ม: `ON_PROGRESS`

**จำเป็นต้อง migrate ข้อมูลเก่า:**
```sql
-- ตัวอย่าง migration (ต้องปรับตามข้อมูลจริง)
UPDATE Report 
SET reporterRole = 'PASSENGER', 
    category = 'other', 
    status = 'COMPLETED' 
WHERE status = 'APPROVED';
```

---

### Migration Guide

สำหรับ clients ที่ใช้ API เวอร์ชันเก่า:

1. **Update field names:**
   - `passengerId` → ใช้ `reporterId` + กรอง `reporterRole = 'PASSENGER'`
   - `driverId` → ใช้ `reportedUserId`
   - `photos` → ใช้ `mediaUrls`

2. **Update status handling:**
   - `APPROVED` → `COMPLETED`
   - เพิ่มการตรวจสอบ `ON_PROGRESS`

3. **Update types structure:**
   - เดิม: `types: ["DANGEROUS_DRIVING"]` (enum)
   - ใหม่: `category: "safety"` + `types: ["ขับรถเร็วเกินไป"]` (free text)

---

### Performance & Security

**Improvements:**
- เพิ่ม database indexes สำหรับ `reporterRole`, `category`
- จำกัดการอัปโหลดไฟล์ที่ 3 ไฟล์ (ลดภาระ storage)
- Validation ที่เข้มงวดสำหรับ category ตาม role
- ป้องกันการรายงานตัวเอง และผู้โดยสารรายงานผู้โดยสาร

**Future Considerations:**
- [ ] เพิ่มการ rate limiting สำหรับ POST /reports
- [ ] เพิ่มการ compress media ก่อนอัปโหลด
- [ ] เพิ่มการแจ้งเตือนถึงผู้ถูกรายงานเมื่อรายงานถูก COMPLETED
