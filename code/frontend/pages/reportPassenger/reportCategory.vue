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
  { key: 'other', label: 'รายงานปัญหาอื่น ๆ ที่เกี่ยวข้องกับคนขับ' }
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
  <div class="max-w-xl p-6 mx-auto mt-10 bg-white rounded-lg shadow">
    <h2 class="mb-6 text-xl font-bold">กรุณาเลือกหมวดหมู่การรายงาน</h2>

    <div class="space-y-3">
      <button
        v-for="cat in categories"
        :key="cat.key"
        @click="selectCategory(cat.key)"
        class="w-full px-4 py-3 text-left transition border rounded-md hover:bg-gray-50">
        {{ cat.label }}
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