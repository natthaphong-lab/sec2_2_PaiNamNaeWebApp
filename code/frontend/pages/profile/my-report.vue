<template>
    <div class="bg-gray-50">
        <div class="flex items-center justify-center min-h-screen py-8">
            <div
                class="flex w-full max-w-6xl mx-4 overflow-hidden bg-white border border-gray-300 rounded-lg shadow-lg">

                <ProfileSidebar />
                <main class="flex-1 p-8">
                    <div class="text-center mb-8">
                        <div class="inline-flex items-center justify-center w-16 h-16 bg-blue-600 rounded-full mb-4">
                            <svg class="w-8 h-8 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z">
                                </path>
                            </svg>
                        </div>
                        <h1 class="text-3xl font-bold text-gray-800 mb-2">ประวัติการรายงาน</h1>
                        <p class="text-gray-600 max-w-md mx-auto">
                            จัดการและตรวจสอบประวัติการรายงานของคุณที่นี่
                        </p>
                    </div>
                    <div class="flex-1 p-8">
<!-- SEARCH + FILTER -->
<div class="mb-6 flex flex-col md:flex-row gap-3 justify-end">

  <select v-model="selectedCategory" class="border rounded-lg px-3 py-2">
    <option value="ALL">ทั้งหมด</option>
    <option value="safety">ความปลอดภัย</option>
    <option value="driverBehavior">พฤติกรรมคนขับ</option>
    <option value="passengerBehavior">พฤติกรรมผู้โดยสาร</option>
    <option value="lostItem">ของหาย</option>
    <option value="vehicle">ปัญหายานพาหนะ</option>
    <option value="damaged">ทรัพย์สินเสียหาย</option>
    <option value="other">อื่น ๆ</option>
  </select>
</div>
                        <!-- Loading -->
                        <div v-if="isLoading" class="text-center py-10 text-gray-500">
                            กำลังโหลดข้อมูล...
                        </div>

                        <!-- Error -->
                        <div v-else-if="error" class="text-center py-10 text-red-600">
                            {{ error }}
                        </div>

                        <!-- Empty -->
                        <div v-else-if="reports.length === 0" class="text-center py-10 text-gray-500">
                            คุณยังไม่มีประวัติการรายงาน
                        </div>

                        <!-- Report List -->
                        <div v-else class="space-y-4">
                            <div
                                v-for="r in filteredReports"
                                :key="r.id"
                                :id="`report-${r.id}`"
                                @click="toggleExpand(r.id)"
                                class="p-4 border border-gray-200 rounded-lg shadow-sm cursor-pointer transition-all duration-300"
                                :class="expandedReportId === r.id
                                    ? 'shadow-xl scale-[1.02] border-blue-400'
                                    : 'hover:shadow-md'"
                            >
                                <div class="flex justify-between items-center mb-2">
<div class="flex items-center gap-2 font-semibold text-gray-800">

  <svg class="w-5 h-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
      d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z">
    </path>
  </svg>

  รายงานเรื่อง : {{ categoryTH(r.category) }}

</div>

<span
class="px-3 py-1 text-xs font-medium rounded-full border"
:class="{
'bg-yellow-50 text-yellow-700 border-yellow-200': r.status === 'PENDING',
'bg-blue-50 text-blue-700 border-blue-200': r.status === 'ON_PROGRESS',
'bg-green-50 text-green-700 border-green-200': r.status === 'COMPLETED',
'bg-red-50 text-red-700 border-red-200': r.status === 'REJECTED'
}">
                                    {{ statusReportTH(r.status, r.category, r.reporterRole) }}
                                    </span>
                                </div>

<div class="bg-gray-50 p-3 rounded-lg mt-2 text-sm">

<div class="font-medium text-gray-700 mb-1">
ข้อมูลผู้ถูกรายงาน
</div>

<div>ชื่อ: {{ r.reportedUser?.firstName }} {{ r.reportedUser?.lastName }}</div>
<div>Username: {{ r.reportedUser?.username }}</div>

<div v-if="r.reportedUser?.phoneNumber">
เบอร์โทรศัพท์: {{ r.reportedUser.phoneNumber }}
</div>

</div>

                                <div class="text-sm text-gray-500 mt-5">
                                    วันที่แจ้ง: {{ formatThaiDate(r.createdAt) }}
                                </div>

                                <div class="text-sm text-gray-500">
                                  วันที่อัปเดตสถานะ: {{ formatThaiDate(r.updatedAt) }}
                                </div>

<transition name="fade">
  <div
    v-if="expandedReportId === r.id"
    class="mt-4 pt-4 border-t border-gray-200 grid md:grid-cols-2 gap-6 text-sm"
  >

    <!-- LEFT : รายละเอียด -->
    <div>

      <div v-if="r.types && r.types.length" class="mt-2 text-gray-700">
        <span class="font-medium text-gray-700">รายละเอียดหมวดหมู่ : </span>

        <ul class="list-disc ml-5 mt-1">
          <li v-for="(type, index) in r.types" :key="index">
            {{ type }}
          </li>
        </ul>
      </div>

      <div v-if="r.description" class="mt-3 text-gray-700">
        <span class="font-medium text-gray-700">รายละเอียดเพิ่มเติม : </span>
        {{ r.description }}
      </div>

      <div v-if="r.mediaUrls && r.mediaUrls.length > 0" class="mt-4">

        <span class="font-medium text-gray-700 block mb-2">
          หลักฐานที่แนบ :
        </span>

        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">

          <div
            v-for="(url, index) in r.mediaUrls"
            :key="index"
            class="border rounded-lg overflow-hidden bg-gray-50"
            @click.stop
          >

<img
  v-if="isImage(url)"
  :src="url"
  class="w-full aspect-video object-cover cursor-pointer transition-transform duration-200 hover:scale-105"
  @click.stop="openPreview(url)"
/>

<video
  v-else-if="isVideo(url)"
  class="w-full aspect-video object-cover cursor-pointer"
  @click.stop="openPreview(url)"
>
              <source :src="url" />
            </video>

            <audio
              v-else-if="isAudio(url)"
              controls
              class="w-full p-3"
            >
              <source :src="url" />
            </audio>

            <a
              v-else
              :href="url"
              target="_blank"
              class="block p-4 text-blue-600 underline text-center"
            >
              เปิดไฟล์แนบ
            </a>

          </div>
        </div>

      </div>

    </div>

    <!-- RIGHT : สถานะการดำเนินการ -->
<div class="pl-4">

  <div class="font-semibold text-gray-700 mb-4">
    สถานะการดำเนินการ
  </div>

  <div class="relative">

    <!-- เส้น timeline -->
    <div class="absolute left-2 top-0 bottom-0 w-0.5 bg-gray-200"></div>

    <div class="space-y-6">

      <div class="flex items-start gap-3">
        <div :class="timelineDot(r.status,'PENDING')"></div>
        <div>
<div class="font-medium">
  {{ timelineText(r.category,'step1') }}
</div>
        </div>
      </div>

      <div class="flex items-start gap-3">
        <div :class="timelineDot(r.status,'ON_PROGRESS')"></div>
        <div>
<div class="font-medium">
  {{ timelineText(r.category,'step2') }}
</div>

        </div>
      </div>

<div v-if="r.status === 'COMPLETED'" class="flex items-start gap-3">
  <div :class="timelineDot(r.status,'COMPLETED')"></div>
  <div>
    <div class="font-medium">
      {{ timelineText(r.category,'step3') }}
    </div>
  </div>
</div>

<div v-if="r.status === 'REJECTED'" class="flex items-start gap-3">
  <div :class="timelineDot(r.status,'REJECTED')"></div>
  <div>
    <div class="font-medium">
      {{ timelineText(r.category,'step4') }}
    </div>
  </div>
</div>

    </div>

  </div>

</div>  <!-- ปิด RIGHT -->

</div>  <!-- ปิด div v-if -->

</transition>
                            </div>
                        </div>
                    </div>
                </main>
            </div>
        </div>
        <!-- Preview Modal -->
        <div
        v-if="previewUrl"
        class="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4"
        @click="closePreview"
        >
            <div class="max-w-4xl w-full" @click.stop>
                
                <img
                v-if="previewType === 'image'"
                :src="previewUrl"
                class="w-full max-h-[80vh] object-contain rounded-lg"
                />

                <video
                v-else-if="previewType === 'video'"
                controls
                autoplay
                class="w-full max-h-[80vh] object-contain rounded-lg"
                >
                <source :src="previewUrl" />
                </video>

            </div>
        </div>
    </div>
</template>
<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { useRuntimeConfig, useCookie } from '#app'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import ProfileSidebar from '~/components/ProfileSidebar.vue'

const expandedReportId = ref(null)
const selectedStatus = ref('ALL')
const selectedCategory = ref('ALL')

const filteredReports = computed(() => {
  return reports.value.filter(r => {
    const matchStatus =
      selectedStatus.value === 'ALL' ||
      r.status === selectedStatus.value

    const matchCategory =
      selectedCategory.value === 'ALL' ||
      r.category === selectedCategory.value

    return matchStatus && matchCategory
  })
})


dayjs.locale('th')

function toggleExpand(id) {
  expandedReportId.value =
    expandedReportId.value === id ? null : id
}

const config = useRuntimeConfig()
const token = useCookie('token')

const reports = ref([])
const isLoading = ref(false)
const error = ref(null)

function formatThaiDate(date) {
  return dayjs(date)
    .add(543, 'year')
    .format('DD MMM YYYY HH:mm')
}

async function fetchMyReports() {
  isLoading.value = true
  error.value = null

  try {
    const res = await $fetch(`${config.public.apiBase}/reports/me`, {
      headers: {
        Authorization: `Bearer ${token.value}`
      }
    })

    const raw = res.data || res
    // normalize items to have consistent fields used by template
    reports.value = (Array.isArray(raw) ? raw : raw.data || [])
      .map((item) => ({
        ...item,
        // support different names for media/photos
        mediaUrls: item.mediaUrls || item.photos || item.media || [],
        // some APIs use updatedAt or updateAt
        updatedAt: item.updatedAt || item.updateAt || null
      }))
  } catch (err) {
    error.value = err?.data?.message || 'โหลดข้อมูลไม่สำเร็จ'
  } finally {
    isLoading.value = false
  }
}

import { useRouter, useRoute } from 'vue-router'

const router = useRouter()
const route = useRoute()

function handleVisibilityChange() {
  if (document.visibilityState === 'visible') {
    fetchMyReports()
  }
}

onMounted(async () => {
  await fetchMyReports()
  // Auto-expand report if reportId query param is present
  const reportId = route.query.reportId
  if (reportId) {
    expandedReportId.value = reportId
    // Scroll to the report card after DOM update
    await nextTick()
    const el = document.getElementById(`report-${reportId}`)
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'center' })
  }
  // Re-fetch when the user returns to this tab so admin deletions are reflected
  document.addEventListener('visibilitychange', handleVisibilityChange)
})

onUnmounted(() => {
  document.removeEventListener('visibilitychange', handleVisibilityChange)
})

const reportCategoryTH = {
  safety: 'ความปลอดภัย',
  driverBehavior: 'พฤติกรรมคนขับ',
  passengerBehavior: 'พฤติกรรมผู้โดยสาร',
  vehicle: 'ปัญหายานพาหนะ',
  lostItem: 'ของหาย',
  damaged: 'ทรัพย์สินเสียหาย',
  other: 'อื่น ๆ'
}

const statusTextMap = {
  DRIVER: {
    passengerBehavior: {
      PENDING: 'รอการดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
      COMPLETED: 'ตักเตือนและลงโทษแล้ว',
      REJECTED: 'ไม่พบความผิด'
    },
    safety: {
      PENDING: 'รอการดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
      COMPLETED: 'ตักเตือนและลงโทษแล้ว',
      REJECTED: 'ไม่พบความผิด'
    },

    lostItem: {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างการติดต่อ',
      COMPLETED: 'แจ้งไปที่ผู้โดยสารเรียบร้อย',
      REJECTED: 'ไม่พบของ'
    },

    damaged: {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างการติดต่อ',
      COMPLETED: 'แจ้งไปที่ผู้โดยสารเรียบร้อย',
      REJECTED: 'ไม่พบความเสียหายที่เกิดขึ้น'
    },

    other: {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'กำลังดำเนินการ',
      COMPLETED: 'ดำเนินการเสร็จสิ้น',
      REJECTED: 'ไม่พบความผิด'
    }
  },

  PASSENGER: {
    safety: {
      PENDING: 'รอการดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
      COMPLETED: 'ตักเตือนและลงโทษแล้ว',
      REJECTED: 'ไม่พบความผิด'
    },
    driverBehavior: {
      PENDING: 'รอการดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
      COMPLETED: 'ตักเตือนและลงโทษแล้ว',
      REJECTED: 'ไม่พบความผิด'
    },
    vehicle: {
      PENDING: 'รอการดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างสอบสวน',
      COMPLETED: 'แจ้งให้แก้ไขแล้ว',
      REJECTED: 'ไม่พบความผิด'
    },
    lostItem: {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'อยู่ระหว่างการติดต่อ',
      COMPLETED: 'แจ้งไปที่คนขับเรียบร้อยแล้ว',
      REJECTED: 'ไม่พบของ'
    },
    other: {
      PENDING: 'รอดำเนินการ',
      ON_PROGRESS: 'กำลังดำเนินการ',
      COMPLETED: 'ดำเนินการเสร็จสิ้น',
      REJECTED: 'ไม่พบความผิด'
    }
  }
}
const defaultStatusText = {
  PENDING: 'รอดำเนินการ',
  ON_PROGRESS: 'กำลังดำเนินการ',
  COMPLETED: 'เสร็จสิ้น',
  REJECTED: 'ปฏิเสธ'
}

function categoryTH(category) {
  return reportCategoryTH[category] || category
}
function statusReportTH(status, category, role) {
  if (!status) return '-'

  if (
    role &&
    category &&
    statusTextMap[role]?.[category]?.[status]
  ) {
    return statusTextMap[role][category][status]
  }

  return defaultStatusText[status] ?? status
}

function isImage(url) {
  if (!url) return false
  return /\.(jpeg|jpg|gif|png|webp|bmp)(\?.*)?$/i.test(url)
}

function isVideo(url) {
  if (!url) return false
  return /\.(mp4|webm|ogg|mov)(\?.*)?$/i.test(url)
}

function isAudio(url) {
  if (!url) return false
  return /\.(mp3|wav|m4a|aac|ogg)(\?.*)?$/i.test(url)
}

const previewUrl = ref(null)
const previewType = ref(null) // image | video

function openPreview(url) {
  if (isImage(url)) {
    previewType.value = 'image'
  } else if (isVideo(url)) {
    previewType.value = 'video'
  } else {
    return
  }

  previewUrl.value = url
}

function closePreview() {
  previewUrl.value = null
  previewType.value = null
}

function stepClass(currentStatus, step) {

  const base = "w-4 h-4 rounded-full border-2"

  const order = {
    PENDING: 1,
    ON_PROGRESS: 2,
    COMPLETED: 3,
    REJECTED: 3
  }

  if (currentStatus === step)
    return `${base} bg-blue-500 border-blue-500`

  if (order[currentStatus] > order[step])
    return `${base} bg-green-500 border-green-500`

  return `${base} bg-gray-200 border-gray-300`
}

function timelineDot(currentStatus, step) {

  const order = {
    PENDING: 1,
    ON_PROGRESS: 2,
    COMPLETED: 3,
    REJECTED: 3
  }

  const base = "w-4 h-4 rounded-full mt-1 z-10"

  if (currentStatus === step) {
    if (currentStatus === "REJECTED")
      return `${base} bg-red-500`

    return `${base} bg-blue-500`
  }

  if (order[currentStatus] > order[step])
    return `${base} bg-green-500`

  return `${base} bg-gray-300`
}


const timelineTextMap = {
  safety: {
    step1: 'รับเรื่องรายงาน',
    step2: 'กำลังดำเนินการ',
    step3: 'ตักเตือนและลงโทษแล้ว',
    step4: 'ไม่พบความผิด'
  },

  driverBehavior: {
    step1: 'รับเรื่องรายงาน',
    step2: 'กำลังดำเนินการ',
    step3: 'ตักเตือนและลงโทษแล้ว',
    step4: 'ไม่พบความผิด'
  },

  passengerBehavior: {
    step1: 'รับเรื่องรายงาน',
    step2: 'กำลังดำเนินการ',
    step3: 'ตักเตือนและลงโทษแล้ว',
    step4: 'ไม่พบความผิด'
  },

  lostItem: {
    step1: 'รับเรื่องรายงาน',
    step2: 'อยู่ระหว่างการติดต่อ',
    step3: 'แจ้งไปที่ผู้โดยสารเรียบร้อย',
    step4: 'ไม่พบของ'
  },

  vehicle: {
    step1: 'รับเรื่องรายงาน',
    step2: 'อยู่ระหว่างสอบสวน',
    step3: 'แจ้งให้แก้ไขแล้ว',
    step4: 'ไม่พบความผิด'
  },

  damaged: {
    step1: 'รับเรื่องรายงาน',
    step2: 'อยู่ระหว่างสอบสวน',
    step3: 'แจ้งให้แก้ไขแล้ว',
    step4: 'ไม่พบความผิด'
  },

  other: {
    step1: 'รับเรื่องรายงาน',
    step2: 'กำลังดำเนินการ',
    step3: 'ดำเนินการเสร็จสิ้น',
    step4: 'ไม่พบความผิด'
  }
}

function timelineText(category, step) {
  return timelineTextMap[category]?.[step] || '-'
}

</script>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: all 0.25s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-5px);
}
</style>