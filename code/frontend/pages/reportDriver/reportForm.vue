<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'

import SafetyForm from '@/components/Driver_report_Passenger/SafetyForm.vue'

const route = useRoute()

const category = computed(() => route.query.category)

const componentMap = {
  safety: SafetyForm
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