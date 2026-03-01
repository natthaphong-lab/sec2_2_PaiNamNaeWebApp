// const multer = require('multer');
// const ApiError = require('../utils/ApiError');

// // กำหนดค่า Multer ให้เก็บไฟล์ใน memoryชั่วคราวเพื่อรอส่งต่อไปยัง Cloudinary
// const storage = multer.memoryStorage();

// const upload = multer({
//     storage: storage,
//     limits: { fileSize: 5 * 1024 * 1024 }, // จำกัดขนาดไฟล์ไม่เกิน 5 MB
//     fileFilter: (req, file, cb) => {
//         // อนุญาตเฉพาะไฟล์รูปภาพ (jpeg, jpg, png)
//         if (file.mimetype.startsWith('image/')) {
//             cb(null, true);
//         } else {
//             cb(new ApiError(400, 'Only image files are allowed!'), false);
//         }
//     },
// });

// module.exports = upload;

const multer = require('multer');
const ApiError = require('../utils/ApiError');

const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // ปรับเป็น 10MB ให้ตรงกับ frontend
  fileFilter: (req, file, cb) => {

    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/jpg',
      'video/mp4',
      'video/quicktime',   // .mov
      'audio/mpeg',        // .mp3
      'audio/mp3'
    ];

    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new ApiError(400, 'Only image, video, or audio files are allowed!'), false);
    }
  },
});

module.exports = upload;
