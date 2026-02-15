<template>
  <div v-if="show" class="overlay">
    <div class="modal">

     <!-- ปุ่มปิด -->
      <button class="close-btn" @click="close">✕</button>

      <!-- หัวข้อใหญ่ -->
      <h2 class="title">รายงานผู้ขับขี่</h2>

      <!-- ประเภทการรายงาน -->
      <h3 class="section">ประเภทการรายงาน</h3>

      <!-- ด้านพฤติกรรม -->
      <h4 class="sub">ด้านพฤติกรรม</h4>
      <div class="options">
      <!-- แก้ไขข้อความที่แสดงในฟอร์ม-->
        <label v-for="item in behaviorReasons" :key="item.value">
          <input type="checkbox" :value="item.value" v-model="selected" />
          {{ item.label }}

        </label>
      </div>

      <!-- ด้านบริการ -->
      <h4 class="sub">ด้านบริการ</h4>
      <div class="options">
        <label v-for="item in serviceReasons" :key="item.value">
          <input type="checkbox" :value="item.value" v-model="selected" />
          {{ item.label }}

        </label>
      </div>

      <!-- อื่น ๆ อัปเดตให้กดcheckboxได้-->
<h4 class="sub">อื่น ๆ</h4>

<label>
  <input
    type="checkbox"
    value="OTHER"
    v-model="selected"
  />
  อื่น ๆ
</label>


      <!-- รายละเอียดเพิ่มเติม -->
      <h3 class="section">รายละเอียดเพิ่มเติม</h3>
      <textarea
        v-model="description"
        rows="4"
        placeholder="อธิบายรายละเอียดเพิ่มเติม (ถ้ามี)"
        class="textarea"
      ></textarea>

     <!-- อัปโหลดรูป พรีวิว-->
<h3 class="section">อัปโหลดรูปภาพเพิ่มเติม</h3>

<input
  ref="fileInput"
  type="file"
  multiple
  accept="image/*"
  @change="handleFileUpload"
/>

<!-- 🔽 เพิ่มตรงนี้ -->
<div class="preview-list">
  <div
    v-for="(img, index) in photoPreviews"
    :key="index"
    class="preview-item"
  >
    <img :src="img" class="preview-img" />
    <button class="remove-btn" @click="removeImage(index)">✕</button>
  </div>
</div>

      <!-- error -->
      <p v-if="error" class="error">
        กรุณาเลือกอย่างน้อย 1 รายการ
      </p>

      <!-- ปุ่ม -->
      <div class="actions">
        <button @click="close">ยกเลิก</button>
        <button @click="confirm">ยืนยัน</button>
      </div>

    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

defineProps({
  show: Boolean
})

const emit = defineEmits(['close'])

const behaviorReasons = [
  { label: 'ขับรถเร็วและประมาท', value: 'DANGEROUS_DRIVING' },
  { label: 'พูดจาไม่สุภาพ', value: 'INAPPROPRIATE_COMMENTS' },
  { label: 'ใช้โทรศัพท์ขณะขับรถ', value: 'USING_PHONE_WHILE_DRIVING' },
  { label: 'แสดงพฤติกรรมคุกคาม', value: 'HARASSMENT' },
]

const serviceReasons = [
  { label: 'มารับล่าช้า', value: 'LATE' },
  { label: 'เก็บเงินเกินราคา', value: 'OVERCHARGING' },
  { label: 'ปฏิเสธผู้โดยสาร', value: 'DECLINE_PASSENGER' },
  { label: 'เส้นทางไม่เป็นไปตามที่ตกลง', value: 'TAKING_WRONG_ROUTE_INTENTIONALLY' },
]

const selected = ref([])
const description = ref('')
const error = ref(false)
const photoFiles = ref([])     // เก็บ File จริง
const photoPreviews = ref([]) // เก็บ base64 สำหรับ preview
const fileInput = ref(null)


function close() {
  emit('close')
  selected.value = []
  description.value = ''
  error.value = false
  photoFiles.value = [] //เก็บไฟล์จริง
  photoPreviews.value = [] //เก็บไฟล์ไว้แสดงพรีวิว
}


async function confirm() {
  if (selected.value.length === 0) {
    error.value = true
    return
  }

  //อัปโหลดรูปยังไม่ได้
  //const uploadedUrls = []

  //for (const file of photoFiles.value) {
  //  const formData = new FormData()
  //  formData.append('file', file)
  //  formData.append('upload_preset', 'YOUR_UPLOAD_PRESET')

  //  const res = await fetch(
  //    'https://api.cloudinary.com/v1_1/YOUR_CLOUD_NAME/image/upload',
  //    {
  //      method: 'POST',
  //      body: formData
  //    }
  //  )

  //  const data = await res.json()
  //  uploadedUrls.push(data.secure_url)
  //}

  emit('submit', {
    types: selected.value,
    description: description.value,
    photos: photoFiles.value,
  })

  close()
}



// พรีวิวบันทึกรูป
const handleFileUpload = (event) => {
  const files = Array.from(event.target.files)
  if (!files.length) return

  files.forEach((file) => {
    const reader = new FileReader()

    reader.onload = (e) => {
      photoPreviews.value.push(e.target.result)
      photoFiles.value.push(file)
    }

    reader.readAsDataURL(file)
  })
}
//ลบรูปออก
const removeImage = (index) => {
  photoPreviews.value.splice(index, 1)
  photoFiles.value.splice(index, 1)

  // ถ้าไม่มีรูปแล้ว ล้าง input file ด้วย
  if (photoFiles.value.length === 0 && fileInput.value) {
    fileInput.value.value = ''
  }
}




</script>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  align-items: center;
}

.modal {
  background: white;
  padding: 24px;
  width: 420px;
  border-radius: 10px;
}

.title {
  font-size: 20px;
  font-weight: bold;
  margin-bottom: 12px;
}

.section {
  margin-top: 16px;
  font-weight: 600;
}

.sub {
  margin-top: 10px;
  font-size: 14px;
}

.options {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 6px 0;
}

.input,
.textarea {
  width: 100%;
  padding: 6px;
  border: 1px solid #ccc;
  border-radius: 4px;
}

.upload-btn {
  margin-top: 6px;
  padding: 6px 10px;
  border: 1px dashed #aaa;
  border-radius: 4px;
  background: #fafafa;
}

.actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 16px;
}

.error {
  color: red;
  font-size: 13px;
  margin-top: 6px;
}

.modal {
  position: relative; /* สำคัญมาก */
  background: white;
  padding: 24px;
  width: 420px;
  border-radius: 10px;
}

/* ปุ่มกากบาท */
.close-btn {
  position: absolute;
  top: 10px;
  right: 12px;
  background: transparent;
  border: none;
  font-size: 18px;
  cursor: pointer;
  color: #555;
}

.close-btn:hover {
  color: #000;
}

.preview-item {
  position: relative;   /* ⭐ สำคัญมาก */
  width: 80px;
  height: 80px;
  border-radius: 6px;
  overflow: hidden;
  border: 1px solid #ddd;
}

.preview-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.remove-btn {
  position: absolute;   /* ⭐ ลอยทับรูป */
  top: 4px;
  right: 4px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  border: none;
  background: rgba(0, 0, 0, 0.7);
  color: white;
  font-size: 12px;
  cursor: pointer;
  line-height: 20px;
  padding: 0;
}


</style>
