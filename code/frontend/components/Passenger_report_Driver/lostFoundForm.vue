<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
const { $api } = useNuxtApp()
import ToastNotification from '@/components/ToastNotification.vue'

const toasts = ref([])

const router = useRouter()
const route = useRoute()

// รับค่าจาก query (เผื่อใช้ส่ง backend)
const driverId = route.query.driverId
const bookingId = route.query.bookingId
const category = route.query.category

// ====== FORM STATE ======
const selectedIssue = ref('')
const otherText = ref('')
const description = ref('')
const files = ref([])
const maxFiles = 3
const fileError = ref('')

const maxLength = 500
const remaining = computed(() => maxLength - description.value.length)

// ====== OPTIONS ======
const issueOptions = [
  { value: 'ฉันลืมของไว้บนรถ', label: 'ฉันลืมของไว้บนรถ' },
  { value: 'ฉันพบสิ่งของของผู้อื่นภายหลังการเดินทาง', label: 'ฉันพบสิ่งของของผู้อื่นภายหลังการเดินทาง' },

]
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

  const isRightType = allowedPrefixes.some(prefix =>
    file.type.startsWith(prefix)
  )

  if (!isRightType) {
    fileError.value = 'รองรับเฉพาะไฟล์รูปภาพ วิดีโอ หรือเสียงเท่านั้น'
    return
  }

  if (file.size > 10 * 1024 * 1024) {
    fileError.value = 'ไฟล์ต้องมีขนาดไม่เกิน 10MB ต่อไฟล์'
    return
  }

  validFiles.push({
    file: file,
    preview: URL.createObjectURL(file),
    type: file.type,
    name: file.name
  })

})

  // เพิ่มเฉพาะไฟล์ที่ผ่านการตรวจสอบทั้ง Type และ Size
  files.value.push(...validFiles)

  // ล้างค่าเพื่อให้เลือกไฟล์เดิมซ้ำได้หลังจากลบ
  e.target.value = ''
}

function removeFile(index) {
  const item = files.value[index]

  if (item.preview) {
    URL.revokeObjectURL(item.preview)
  }

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
  
  // ต้องเลือก 1 หัวข้อ
  if (!selectedIssue.value) {
    alert('กรุณาเลือกหัวข้อ')
    return
  }

  // ต้องกรอกรายละเอียด
  if (!description.value.trim()) {
    alert('กรุณากรอกรายละเอียดเพิ่มเติม')
    return
  }

  // บังคับแนบไฟล์เฉพาะกรณี "พบของ"
  if (
    selectedIssue.value === 'ฉันพบสิ่งของของผู้อื่นภายหลังการเดินทาง' &&
    files.value.length === 0
    ) {
     alert('กรุณาแนบรูปสิ่งของที่พบ อย่างน้อย 1 ไฟล์')
     return
    }



  const formData = new FormData()

let finalTypes = [selectedIssue.value]

  formData.append('reportedUserId', driverId)
  formData.append('category', category)
  formData.append('types', JSON.stringify(finalTypes))
  formData.append('description', description.value)

files.value.forEach(item => {
  formData.append('media', item.file)
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
    <h2 class="text-xl font-bold">รายงานการแจ้งของหาย / ของตกหล่น</h2>
    <p class="mt-1 text-sm text-gray-600">
      แจ้งกรณีทรัพย์สินสูญหาย หรือ พบสิ่งของของผู้อื่น
    </p>

    <!-- CHECKBOX -->
    <div class="mt-6">
      <p class="mb-3 font-medium">โปรดเลือกหัวข้อที่ต้องการแจ้งปัญหา</p>

      <div class="space-y-2">
        <label
          v-for="item in issueOptions"
          :key="item.value"
          class="flex items-center space-x-2"
        >
         <input
          type="radio"
          :value="item.value"
          v-model="selectedIssue"
          name="issue"
         />
         <span>{{ item.label }}</span>
         </label>
      </div>

    </div>

    <!-- DESCRIPTION -->
    <div class="mt-6">
      <div class="flex justify-between mb-2">
        <label class="font-medium">
          รายละเอียดเพิ่มเติม  <span class="text-red-500">*จำเป็นต้องกรอก</span>
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

  <span
    v-if="selectedIssue === 'ฉันพบสิ่งของของผู้อื่นภายหลังการเดินทาง'"
    class="text-red-500"
  >
    *ต้องอัปโหลดไฟล์อย่างน้อย 1 ไฟล์
  </span>

  <span
    v-else
    class="text-gray-500"
  >
    (ถ้ามี)
  </span>

  <span class="block text-sm text-gray-500">
    รองรับ: PNG, JPG, MP4, MOV, MP3 (ไม่เกิน 10 MB ต่อไฟล์)
  </span>
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
<div class="grid grid-cols-3 gap-3 mt-4">

<div
  v-for="(item,index) in files"
  :key="index"
  class="relative border rounded-lg overflow-hidden"
>

<img
  v-if="item.type.startsWith('image/')"
  :src="item.preview"
  class="object-cover w-full h-32"
/>

<video
  v-else-if="item.type.startsWith('video/')"
  :src="item.preview"
  class="w-full h-32 object-cover"
  controls
></video>

<div
  v-else
  class="flex items-center justify-center h-32 bg-gray-100"
>
<audio :src="item.preview" controls></audio>
</div>

<button
  @click="removeFile(index)"
  class="absolute top-1 right-1 bg-black/60 text-white w-7 h-7 flex items-center justify-center rounded-full hover:bg-red-500"
>
✕
</button>

</div>

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