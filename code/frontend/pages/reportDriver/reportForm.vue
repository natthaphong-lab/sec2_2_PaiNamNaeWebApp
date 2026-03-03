<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import SafetyForm from '@/components/Driver_report_Passenger/SafetyForm.vue'
import passengerBehaviorForm from '@/components/Driver_report_Passenger/passengerBehaviorForm.vue'
import damagedForm from '@/components/Driver_report_Passenger/damagedForm.vue'
import lostFoundForm from '@/components/Driver_report_Passenger/lostFoundForm.vue'
import otherForm from '@/components/Driver_report_Passenger/otherForm.vue'

const route = useRoute()

const category = computed(() => route.query.category)

const componentMap = {
  safety: SafetyForm,
  passengerBehavior: passengerBehaviorForm,
  damaged: damagedForm,
  lostItem: lostFoundForm,
  other: otherForm
}

const currentComponent = computed(() => {
  return componentMap[category.value] || null
})
</script>

<template>
  <div class="max-w-xl p-6 mx-auto mt-10 bg-white rounded-lg shadow">
    <component v-if="currentComponent" :is="currentComponent" />
  </div>
</template>