<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'


import driverBehaviorForm from '@/components/Passenger_report_Driver/driverBehaviorForm.vue'
import vehicleForm from '@/components/Passenger_report_Driver/vehicleForm.vue'
import lostFoundForm from '@/components/Passenger_report_Driver/lostFoundForm.vue'
import otherForm from '@/components/Passenger_report_Driver/otherForm.vue'

const route = useRoute()

const category = computed(() => route.query.category)

const componentMap = {
  safety: SafetyForm,
  driverBehavior: driverBehaviorForm,
  vehicle: vehicleForm,
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