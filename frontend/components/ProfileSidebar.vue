<template>
  <!-- modal overlay -->
  <div class="fixed inset-0 bg-black/40 flex items-center justify-center">
    <div class="bg-white w-[520px] p-6 rounded-lg">
      <h2 class="text-lg font-bold mb-4">รายงานผู้ขับขี่</h2>

      <!-- checkbox -->
      <label class="block">
        <input type="checkbox" value="late" v-model="reasons" />
        มารับล่าช้า
      </label>

      <label class="block">
        <input type="checkbox" value="rude" v-model="reasons" />
        พูดจาไม่สุภาพ
      </label>

      <p v-if="error" class="text-red-500 text-sm mt-2">{{ error }}</p>

      <div class="flex justify-end mt-4">
        <button
          @click="submitReport"
          class="px-4 py-2 bg-blue-600 text-white rounded"
        >
          ยืนยัน
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const emit = defineEmits(['submit', 'close'])

const reasons = ref([])
const error = ref('')

const submitReport = () => {
  if (reasons.value.length === 0) {
    error.value = 'กรุณาเลือกอย่างน้อย 1 ข้อ'
    return
  }

  emit('submit', { reasons: reasons.value })
}
</script>
