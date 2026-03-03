<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
const { $api } = useNuxtApp()
import ToastNotification from '@/components/ToastNotification.vue'

const toasts = ref([])

const router = useRouter()
const route = useRoute()

// รับค่าจาก query (เผื่อใช้ส่ง backend)
const passengerId = route.query.passengerId
const bookingId = route.query.bookingId
const category = route.query.category

// ====== FORM STATE ======
const description = ref('')
const files = ref([])
const maxFiles = 3
const fileError = ref('')

const maxLength = 500
const remaining = computed(() => maxLength - description.value.length)
// ====== FILE HANDLER ======
function handleFileUpload(e) {
  const selected = Array.from(e.target.files)
  fileError.value = ''

  // 1. เช็คจำนวนไฟล์สูงสุดก่อน
  if (files.value.length >= maxFiles) {
    fileError.value = `แนบไฟล์ได้สูงสุด ${maxFiles} ไฟล์`
    e.target.value = ''
    return
  }

  const availableSlots = maxFiles - files.value.length
  const limitedFiles = selected.slice(0, availableSlots)

  const validFiles = []
  
  // กำหนดประเภทที่ยอมรับ (Prefix ของ MIME type)
  const allowedPrefixes = ['image/', 'video/', 'audio/']

  limitedFiles.forEach(file => {
    // --- เพิ่มการเช็คประเภทไฟล์ตรงนี้ ---
    const isRightType = allowedPrefixes.some(prefix => file.type.startsWith(prefix))
    
    if (!isRightType) {
      fileError.value = 'รองรับเฉพาะไฟล์รูปภาพ วิดีโอ หรือเสียงเท่านั้น'
      return // ข้ามไฟล์นี้ไป (ไม่ใส่ใน validFiles)
    }

    // --- เช็คขนาดไฟล์ (10MB) ---
    if (file.size > 10 * 1024 * 1024) {
      fileError.value = 'ไฟล์ต้องมีขนาดไม่เกิน 10MB ต่อไฟล์'
    } else {
      validFiles.push(file)
    }
  })

  // เพิ่มเฉพาะไฟล์ที่ผ่านการตรวจสอบทั้ง Type และ Size
  files.value.push(...validFiles)

  // ล้างค่าเพื่อให้เลือกไฟล์เดิมซ้ำได้หลังจากลบ
  e.target.value = ''
}

function removeFile(index) {
  files.value.splice(index, 1)
}

//show toast
function showToast(type, title, message) {
  toasts.value.push({
    id: Date.now(),
    type,
    title,
    message
  })
}

function removeToast(id) {
  toasts.value = toasts.value.filter(t => t.id !== id)
}


// ====== SUBMIT ======
async function submitForm() {
  
  // ต้องกรอกรายละเอียด
  if (!description.value.trim()) {
    alert('กรุณากรอกรายละเอียดเพิ่มเติม')
    return
  }

  const isConfirm = confirm('ยืนยันการส่งรายงานหรือไม่?')
     if (!isConfirm) {
     return
    }

  const formData = new FormData()

  formData.append('reportedUserId', passengerId)
  formData.append('category', category)
  formData.append('types', JSON.stringify(['ปัญหาอื่น ๆ']))
  formData.append('description', description.value)

  files.value.forEach(file => {
    formData.append('media', file)
  })

  try {
    await $api('/reports', {
      method: 'POST',
      body: formData,
    })
    
    showToast('success', 'สำเร็จ', 'ส่งรายงานเรียบร้อยแล้ว จะนำท่านกลับไปหน้าเลือกหมวดหมู่รายงาน')
    await new Promise(r => setTimeout(r, 5000))
    router.back()

  } catch (err) {
    console.error(err)
    showToast('error', 'ผิดพลาด', 'ส่งรายงานไม่สำเร็จ กรุณาลองใหม่')
  }
  
}

function cancel() {
  router.back()
}

function handleFileClick(e) {
  if (files.value.length >= maxFiles) {
    e.preventDefault() // กันไม่ให้ dialog เปิด
    fileError.value = `แนบไฟล์ได้สูงสุด ${maxFiles} ไฟล์`
  }
}


</script>

<template>
<div class="w-full max-w-6xl mx-auto px-8 py-10">
    <!-- HEADER -->
    <h2 class="text-xl font-bold">รายงานปัญหาอื่น ๆ ที่เกี่ยวข้องกับคนขับ</h2>
    <p class="mt-1 text-sm text-gray-600">
      ใช้สำหรับแจ้งปัญหาที่ไม่อยู่ในหมวดหมู่ข้างต้น กรุณาระบุรายละเอียดให้ชัดเจนเพื่อประกอบการตรวจสอบ
    </p>

    

    <!-- DESCRIPTION -->
    <div class="mt-6">
      <div class="flex justify-between mb-2">
        <label class="font-medium">
          รายละเอียดเพิ่มเติม  <span class="text-red-500">*</span>
        </label>
        <span class="text-sm text-gray-500">
          ({{ description.length }} / {{ maxLength }} ตัวอักษร)
        </span>
      </div>

      <textarea
        v-model="description"
        :maxlength="maxLength"
        rows="4"
        class="w-full p-2 border rounded"
        placeholder="อธิบายรายละเอียดเหตุการณ์"
      />
    </div>

    <!-- FILE UPLOAD -->
    <div class="mt-6">
      <label class="font-medium">
        อัปโหลดรูป วิดีโอ หรือ คลิปเสียง
        <span class="text-sm text-red-500">(ไม่เกิน 10 MB ต่อไฟล์)</span>
      </label>

     <input
      type="file"
      multiple
      accept=".png,.jpg,.jpeg,.mp4,.mov,.mp3"
      @click="handleFileClick"
      @change="handleFileUpload"
      class="block w-full p-2 mt-2 border rounded"
     />

<div class="mt-2 text-sm text-gray-500">
  ({{ files.length }} / {{ maxFiles }} ไฟล์)
</div>
<div
  v-if="fileError"
  class="mt-2 text-sm text-red-500"
>
  {{ fileError }}
</div>

      <!-- FILE LIST -->
      <div class="mt-3 space-y-2">
        <div
          v-for="(file, index) in files"
          :key="index"
          class="flex items-center justify-between px-3 py-2 text-sm bg-gray-100 rounded"
        >
          <span>{{ file.name }}</span>
          <button
            @click="removeFile(index)"
            class="text-gray-500 hover:text-red-500"
          >
            ✕
          </button>
        </div>
      </div>
    </div>

    <!-- BUTTONS -->
    <div class="flex justify-end mt-8 space-x-3">
      <button
        @click="cancel"
        class="px-4 py-2 text-white bg-red-500 rounded hover:bg-red-600"
      >
        ยกเลิก
      </button>

      <button
        @click="submitForm"
        class="px-4 py-2 text-white bg-blue-600 rounded hover:bg-blue-700"
      >
        ยืนยัน
      </button>
    </div>

 <!-- Toast Container -->
<div class="fixed bottom-5 right-5 z-50 flex flex-col items-end space-y-3">
  <ToastNotification
    v-for="toast in toasts"
    :key="toast.id"
    :id="toast.id"
    :type="toast.type"
    :title="toast.title"
    :message="toast.message"
    @close="removeToast"
    class="!w-auto !max-w-md !min-w-[300px] !whitespace-normal"
  />
</div>
  </div>

</template>