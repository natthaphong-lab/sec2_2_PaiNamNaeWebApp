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
        <label v-for="item in behaviorReasons" :key="item">
          <input type="checkbox" :value="item" v-model="selected" />
          {{ item }}
        </label>
      </div>

      <!-- ด้านบริการ -->
      <h4 class="sub">ด้านบริการ</h4>
      <div class="options">
        <label v-for="item in serviceReasons" :key="item">
          <input type="checkbox" :value="item" v-model="selected" />
          {{ item }}
        </label>
      </div>

      <!-- อื่น ๆ -->
      <h4 class="sub">อื่น ๆ</h4>
      <input
        type="text"
        v-model="otherReason"
        placeholder="ระบุเหตุผลอื่น ๆ"
        class="input"
      />

      <!-- รายละเอียดเพิ่มเติม -->
      <h3 class="section">รายละเอียดเพิ่มเติม</h3>
      <textarea
        v-model="description"
        rows="4"
        placeholder="อธิบายรายละเอียดเพิ่มเติม (ถ้ามี)"
        class="textarea"
      ></textarea>

      <!-- อัปโหลดรูป -->
      <h3 class="section">อัปโหลดรูปภาพเพิ่มเติม</h3>
      <button class="upload-btn" @click="uploadImage">
        อัปโหลดรูป
      </button>

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
  'DANGEROUS_DRIVING',
  'INAPPROPRIATE_COMMENTS',
  'USING_PHONE_WHILE_DRIVING',
  'HARASSMENT',
]

const serviceReasons = [
  'LATE',
  'OVERCHARGING',
  'DECLINE_PASSENGER',
  'TAKING_WRONG_ROUTE_INTENTIONALLY',
]

const selected = ref([])
const otherReason = ref('')
const description = ref('')
const error = ref(false)

function close() {
  emit('close')
  selected.value = []
  otherReason.value = ''
  description.value = ''
  error.value = false
}

function confirm() {
  const reasons = [...selected.value]

  if (otherReason.value.trim()) {
    reasons.push(otherReason.value)
  }

  if (reasons.length === 0) {
    error.value = true
    return
  }

  emit('submit', {
    types: reasons,
    description: description.value
  })

  close()
}


// placeholder Cloudinary
function uploadImage() {
  alert('เดี๋ยวค่อยต่อ Cloudinary')
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
</style>
