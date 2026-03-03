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
                                v-for="r in reports"
                                :key="r.id"
                                :id="`report-${r.id}`"
                                @click="toggleExpand(r.id)"
                                class="p-4 border border-gray-200 rounded-lg shadow-sm cursor-pointer transition-all duration-300"
                                :class="expandedReportId === r.id
                                    ? 'shadow-xl scale-[1.02] border-blue-400'
                                    : 'hover:shadow-md'"
                            >
                                <div class="flex justify-between items-center mb-2">
                                    <div class="font-semibold text-gray-800">
                                    รายงานเรื่อง : {{ categoryTH(r.category) }}
                                    </div>

                                    <span class="px-2 py-1 text-xs rounded-full"
                                    :class="{
                                        'bg-yellow-100 text-yellow-700': r.status === 'PENDING',
                                        'bg-blue-100 text-blue-700': r.status === 'ON_PROGRESS',
                                        'bg-green-100 text-green-700': r.status === 'COMPLETED',
                                        'bg-red-100 text-red-700': r.status === 'REJECTED'
                                    }">
                                    {{ statusReportTH(r.status, r.category, r.reporterRole) }}
                                    </span>
                                </div>

                                <div class="text-sm text-gray-600 mb-2">
                                  <span class="font-medium text-gray-700">ข้อมูลผู้ถูกรายงาน </span>
                                  <div>ชื่อ-นามสกุล : {{ r.reportedUser?.firstName || '-' }} {{ r.reportedUser?.lastName || '' }} ({{ r.reportedUser?.username }})</div>
                                  <div v-if="r.reportedUser?.phoneNumber">เบอร์โทรศัพท์: {{ r.reportedUser.phoneNumber }}</div>
                                  <div v-if="r.reportedUser?.email">อีเมล: {{ r.reportedUser.email }}</div>
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
                                        class="mt-4 pt-4 border-t border-gray-200 space-y-2 text-sm"
                                    >
                                        <div v-if="r.types && r.types.length" class="mt-2 text-sm text-gray-700">
                                            <span class="font-medium text-gray-700">รายละเอียดหมวดหมู่ : </span>
                                            
                                            <ul class="list-disc ml-5 mt-1">
                                                <li v-for="(type, index) in r.types" :key="index">
                                                {{ type }}
                                                </li>
                                            </ul>
                                        </div>

                                        <div v-if="r.description" class="mt-2 text-sm text-gray-700">
                                            <span class="font-medium text-gray-700">รายละเอียดเพิ่มเติม : </span>{{ r.description }}
                                        </div>
                                        
                                       
                                        <div v-if="r.mediaUrls && r.mediaUrls.length > 0">
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
                                            class="w-full h-48 object-cover cursor-pointer"
                                            @click.stop="openPreview(url)"
                                            />

                                            
                                            <video
                                            v-else-if="isVideo(url)"
                                            class="w-full h-48 object-cover cursor-pointer"
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
import { ref, onMounted, nextTick } from 'vue'
import { useRuntimeConfig, useCookie } from '#app'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import ProfileSidebar from '~/components/ProfileSidebar.vue'

const expandedReportId = ref(null)

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