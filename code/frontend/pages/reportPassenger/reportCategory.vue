<script setup>
import { useRoute, useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()

const driverId = route.query.driverId
const bookingId = route.query.bookingId

const categories = [
  { key: 'safety', label: 'แจ้งปัญหาด้านความปลอดภัย' },
  { key: 'driverBehavior', label: 'แจ้งปัญหาพฤติกรรมคนขับ' },
  { key: 'vehicle', label: 'แจ้งปัญหาเกี่ยวกับรถ' },
  { key: 'lostItem', label: 'แจ้งของหาย / ของตกหล่น' },
  { key: 'other', label: 'แจ้งปัญหาอื่น ๆ' }
]

function selectCategory(category) {
  router.push({
    path: '/reportPassenger/reportForm',
    query: {
      category,
      driverId,
      bookingId
    }
  })
}
</script>

<template>
  <div class="max-w-2xl p-6 mx-auto mt-10">
    <h1 class="mb-2 text-2xl font-bold text-gray-900">รายงานปัญหา</h1>
    <p class="mb-8 text-lg text-gray-700">กรุณาเลือกหัวข้อที่ท่านต้องการรายงาน</p>

    <div class="space-y-4">
      <button
        v-for="cat in categories"
        :key="cat.key"
        @click="selectCategory(cat.key)"
        class="flex items-center justify-between w-full px-6 py-5 transition-all bg-white border border-gray-100 shadow-sm rounded-2xl hover:shadow-md hover:border-gray-200"
      >
        <span class="text-lg font-medium text-gray-800">{{ cat.label }}</span>
        
        <svg 
          xmlns="http://www.w3.org/2000/svg" 
          fill="none" 
          viewBox="0 0 24 24" 
          stroke-width="2" 
          stroke="currentColor" 
          class="w-5 h-5 text-gray-400"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="m8.25 4.5 7.5 7.5-7.5 7.5" />
        </svg>
      </button>
    </div>

<button
 @click="router.back()"
 class="mt-8 inline-flex items-center px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50"
>
  <i class="fa-solid fa-arrow-left"></i>
  <span>ย้อนกลับ</span>
</button>

  </div>
</template>