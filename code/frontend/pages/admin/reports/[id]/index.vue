<template>
  <div>
    <AdminHeader /> 
    <AdminSidebar />

    <!-- Main Content -->
    <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
      <!-- Back -->
      <div class="mb-8">
        <NuxtLink to="/admin/reports" class="inline-flex items-center gap-2 px-3 py-2 border border-gray-300 rounded-md hover:bg-gray-50">
          <i class="fa-solid fa-arrow-left"></i>
          <span>ย้อนกลับ</span>
          </NuxtLink>
      </div>

      <div class="mx-auto max-w-8xl">
        <!-- Title -->
        <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
          <div class="flex items-center gap-3">
            <h1 class="text-2xl font-semibold text-gray-800">รายละเอียดการรายงาน</h1>
            <span class="text-sm text-gray-500">ดูข้อมูลการรายงานและเปลี่ยนสถานะได้จากหน้านี้</span>
          </div>
        </div>
        <!-- Status & actions -->
        <div class="mb-6 bg-white border border-gray-300 rounded-lg shadow-sm">
          <div class="flex flex-wrap items-center gap-3 px-4 py-4 sm:px-6">
            <div class="text-sm text-gray-700">สถานะปัจจุบัน:</div>
              <span
                class="inline-flex items-center px-2 py-1 text-xs font-semibold rounded-full"
                :class="statusClass(report?.status)"
              >
              <i class="fa-solid fa-circle mr-1 text-[8px]"></i>
                {{ statusReportTH(report?.status, report?.category , report?.reporterRole) }}
              </span>
              <div class="flex gap-2 ml-auto">
                <!-- PENDING -->
                <button
                  class="px-3 py-2 border rounded-md hover:bg-gray-50 disabled:opacity-50"
                  :disabled="
                              isPatchingStatus ||
                              !report ||
                              report.status !== 'PENDING' ||
                              report.status === 'PENDING'
                            "
                  @click="patchStatus('PENDING')"
                >
                  <i
                    v-if="isPatchingStatus && targetStatus === 'PENDING'"
                    class="mr-1 fa-solid fa-spinner fa-spin"
                  ></i>
                  {{ statusReportTH("PENDING", report?.category , report?.reporterRole) }}
                </button>

                <!-- ON_PROGRESS -->
                <button
                  class="px-3 py-2 text-blue-700 border border-blue-300 rounded-md hover:bg-blue-50 disabled:opacity-50"
                  :disabled="isPatchingStatus || !report || report.status === 'ON_PROGRESS' || report.status === 'COMPLETED' || report.status === 'REJECTED'"
                  @click="patchStatus('ON_PROGRESS')"
                >
                  <i
                    v-if="isPatchingStatus && targetStatus === 'ON_PROGRESS'"
                    class="mr-1 fa-solid fa-spinner fa-spin"
                  ></i>
                  {{ statusReportTH("ON_PROGRESS", report?.category , report?.reporterRole) }}
                </button>

                <!-- COMPLETED -->
                <button
                  class="px-3 py-2 text-green-700 border border-green-300 rounded-md hover:bg-green-50 disabled:opacity-50"
                  :disabled="isPatchingStatus || !report || report.status === 'COMPLETED' || report.status === 'REJECTED'"
                  @click="patchStatus('COMPLETED')"
                >
                  <i
                    v-if="isPatchingStatus && targetStatus === 'COMPLETED'"
                    class="mr-1 fa-solid fa-spinner fa-spin"
                  ></i>
                  {{ statusReportTH("COMPLETED", report?.category , report?.reporterRole) }}
                </button>

                <!-- REJECTED -->
                <button
                  class="px-3 py-2 text-red-700 border border-red-300 rounded-md hover:bg-red-50 disabled:opacity-50"
                  :disabled="isPatchingStatus || !report || report.status === 'REJECTED' || report.status === 'COMPLETED'"
                  @click="patchStatus('REJECTED')"
                >
                  <i
                    v-if="isPatchingStatus && targetStatus === 'REJECTED'"
                    class="mr-1 fa-solid fa-spinner fa-spin"
                  ></i>
                  {{ statusReportTH("REJECTED", report?.category , report?.reporterRole) }}
                </button>
                </div>
              </div>

             <!-- Custom notification body -->
              <div class="px-4 pb-4 sm:px-6">
                <label class="block mb-1 text-xs font-medium text-gray-600">
                  ข้อความแจ้งเตือนถึงผู้รายงาน <span class="text-gray-400">(ไม่บังคับ — ถ้าไม่กรอกจะใช้ข้อความเริ่มต้น)</span>
                </label>
                <textarea
                  v-model="notificationBody"
                  rows="3"
                  maxlength="500"
                  placeholder="เช่น เราตรวจสอบแล้วพบว่า..."
                  class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md bg-white resize-none focus:outline-none focus:ring-2 focus:ring-blue-300"
                />
                <p class="mt-1 text-xs text-gray-400 text-right">
                   {{ (notificationBody || '').length }}/500
                </p>
              </div>
              <!-- Custom notification body -->
              <div class="px-4 pb-4 sm:px-6">
                <label class="block mb-1 text-xs font-medium text-gray-600">
                  ข้อความแจ้งเตือนถึงผู้รายงาน <span class="text-gray-400">(ไม่บังคับ — ถ้าไม่กรอกจะใช้ข้อความเริ่มต้น)</span>
                </label>
                <textarea
                  v-model="notificationBody"
                  rows="3"
                  maxlength="500"
                  placeholder="เช่น เราตรวจสอบแล้วพบว่า..."
                  class="w-full px-3 py-2 text-sm border border-gray-300 rounded-md bg-white resize-none focus:outline-none focus:ring-2 focus:ring-blue-300"
                />
                <p class="mt-1 text-xs text-gray-400 text-right">{{ notificationBody.length }}/500</p>
              </div>
            </div>
            
            <!-- Card -->
            <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
              <!-- Loading / Error -->
              <div v-if="isLoading" class="p-8 text-center text-gray-500">กำลังโหลดข้อมูล...</div>
              <div v-else-if="loadError" class="p-8 text-center text-red-600">{{ loadError }}</div>

              <div v-else-if="report" class="grid grid-cols-1 gap-6 p-4 sm:p-6 text-[15px]">
                <div class="w-full max-w-[80rem] mx-auto space-y-6">
                  <!-- ผู้ใช้ -->
                  <section>
                    <h3 class="mb-3 text-sm font-semibold text-gray-700">ข้อมูลผู้แจ้งรายงาน</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <InfoBox label="ชื่อ-นามสกุล">
                        {{ (report.reporter?.firstName || '-') + ' ' + (report.reporter?.lastName || '') }}
                      </InfoBox>

                      <InfoBox label="อีเมล">
                        {{ report.reporter?.email || '-' }}
                      </InfoBox>

                      <InfoBox label="ชื่อผู้ใช้ (username)">
                        {{ report.reporter?.username || '-' }}
                      </InfoBox>

                      <InfoBox label="เบอร์โทรศัพท์">
                        {{ report.reporter?.phoneNumber || '-' }}
                      </InfoBox>
                      <InfoBox label="บทบาท">
                        {{ report.reporterRole === 'DRIVER' ? 'ไดรเวอร์' : 'ผู้โดยสาร' }}
                      </InfoBox>
                    </div>
                  </section>

                  <section>
                    <h3 class="mb-3 text-sm font-semibold text-gray-700">ข้อมูลผู้ถูกรายงาน</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <InfoBox label="ชื่อ-นามสกุล">
                        {{ (report.reportedUser?.firstName || '-') + ' ' + (report.reportedUser?.lastName || '') }}
                      </InfoBox>

                      <InfoBox label="อีเมล">
                        {{ report.reportedUser?.email || '-' }}
                      </InfoBox>

                      <InfoBox label="ชื่อผู้ใช้ (username)">
                        {{ report.reportedUser?.username || '-' }}
                      </InfoBox>

                      <InfoBox label="เบอร์โทรศัพท์">
                        {{ report.reportedUser?.phoneNumber || '-' }}
                      </InfoBox>
                      <InfoBox label="บทบาท">
                        {{ report.reporterRole === 'DRIVER' ? 'ผู้โดยสาร' : 'ไดรเวอร์'}}
                      </InfoBox>
                    </div>
                  </section>

                  <section>
                    <h3 class="mb-3 text-sm font-semibold text-gray-700">รายละเอียดการรายงาน</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <InfoBox label="ประเภท">
                        {{ reportCategoryTH(report?.category) }}
                        <span v-if="report?.types?.length">
                          : {{ report.types.map(type => mapReportType(type)).join(', ') }}
                        </span>
                      </InfoBox>

                      <InfoBox label="รายละเอียด">
                        {{ report.description || '-' }}
                      </InfoBox>

                      <InfoBox label="วันเวลาที่แจ้ง">
                        {{formatDate(report.createdAt)}}
                      </InfoBox>
                      <!-- <InfoBox label="วันเวลาที่อัปเดต">
                        {{formatDate(report.updatedAt)}}
                      </InfoBox> -->
                      
 <!--แก้ไขส่วนแสดงสื่อ-->
          <InfoBox label="ไฟล์แนบ" class="col-span-1 md:col-span-3">
             <div v-if="report.mediaUrls?.length">
                      <div
                      class="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
                        >
                          <div
                          v-for="(media, index) in report.mediaUrls"
                          :key="index"
                            >
                        <div class="w-full aspect-video bg-gray-100 rounded-xl overflow-hidden border shadow-sm flex items-center justify-center">

                           <!-- รูป -->
                            <img
                             v-if="/\.(jpg|jpeg|png|webp)$/i.test(media)"
                             :src="media"
                             class="w-full h-full object-cover cursor-pointer"
                             @click="selectedPhoto = media"
                            />

                           <!-- วิดีโอ -->
                            <video
                             v-else-if="/\.(mp4|webm|mov)$/i.test(media)"
                             controls
                             class="w-full h-full object-cover"
                            >
                             <source :src="media" type="video/mp4" />
                            </video>

                            <!-- เสียง -->
                            <div
                             v-else-if="/\.(mp3|wav|ogg)$/i.test(media)"
                             class="w-full flex items-center justify-center"
                            >
                            <audio controls class="w-3/4">
                            <source :src="media" type="audio/mpeg" />
                            </audio>
                          </div>

                         </div>
                        </div>
                       </div>
                      </div>

                       <!-- ต้องอยู่ติด v-if ด้านบน -->
                       <p v-else class="text-gray-400 mt-4">
                          ไม่มีไฟล์แนบ
                       </p>
          </InfoBox>

                    </div>
                  </section>
                </div>
              </div>
            </div>
      </div>
    </main>
    <div
      v-if="selectedPhoto"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/70"
      @click.self="selectedPhoto = null"
    >
      <img
        :src="selectedPhoto"
        class="max-h-[90vh] max-w-[90vw] rounded-lg shadow-lg"
      />
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, defineComponent, h } from 'vue'
import { useRoute, useRuntimeConfig, useCookie } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
dayjs.locale('th')
import utc from 'dayjs/plugin/utc'
import timezone from 'dayjs/plugin/timezone'

definePageMeta({ middleware: ['admin-auth'] })

useHead({
  title: 'ดูรายละเอียดการรายงานผู้ขับขี่ • Admin',
  link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

/* ================= types ================= */
type ReportStatus = 'PENDING' | 'ON_PROGRESS' | 'COMPLETED' | 'REJECTED'

interface ReportUser {
  id: string
  firstName?: string | null
  lastName?: string | null
  email?: string | null
  username?: string | null
  phoneNumber?: string | null
  profilePicture?: string | null
}

interface Report {
  id: string
  reporter: ReportUser
  reportedUser: ReportUser
  reporterRole: 'PASSENGER' | 'DRIVER'
  category: string
  types: string[]
  description?: string | null
  mediaUrls: string[]
  status: string
  createdAt: string
  updatedAt: string
}

interface ApiResponse<T> {
  success: boolean
  message: string
  data: T
}


const route = useRoute()
const config = useRuntimeConfig()
const token = useCookie('token').value

const reportId = route.params.id as string
const report = ref<Report | null>(null)
const isLoading = ref(true)
const loadError = ref('')


onMounted(async () => {
  try {
    const res = await $fetch<ApiResponse<Report>>(
      `/reports/admin/${reportId}`,
      {
        baseURL: config.public.apiBase,
        headers: {
          Accept: 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        }
      }
    )
    report.value = res.data
  } catch (err: any) {
    console.error(err)
    loadError.value = err?.data?.message || 'โหลดข้อมูลไม่สำเร็จ'
  } finally {
    isLoading.value = false
  }
})

dayjs.extend(utc)
dayjs.extend(timezone)
dayjs.locale('th')
function formatDate(iso?: string | null) {
  if (!iso) return '-'
  return dayjs
    .utc(iso)
    .tz('Asia/Bangkok')
  .format('D MMM YYYY / HH:mm')
}

function mapReportType(type: string) {
  const map: Record<string, string> = {
    DANGEROUS_DRIVING: 'ขับรถเร็วและประมาท',
    INAPPROPRIATE_COMMENTS: 'พูดจาไม่สุภาพ',
    USING_PHONE_WHILE_DRIVING: 'ใช้โทรศัพท์ขณะขับรถ',
    HARASSMENT: 'แสดงพฤติกรรมคุกคาม',
    LATE: 'มารับล่าช้า',
    OVERCHARGING: 'เก็บเงินเกินราคา',
    DECLINE_PASSENGER: 'ปฏิเสธผู้โดยสาร',
    TAKING_WRONG_ROUTE_INTENTIONALLY: 'เส้นทางไม่เป็นไปตามที่ตกลง',
    OTHER: 'อื่น ๆ'
  }
  return map[type] || type
}

const statusTextMap: Record<
  string,
  Record<string, Record<string, string>>
> = {
  // ================= DRIVER =================
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

  // ================= PASSENGER =================
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


function statusReportTH(
  status?: string | null,
  category?: string | null,
  role?: 'DRIVER' | 'PASSENGER' | null
) {
  if (!status) return '-'
  if (
    role &&
    category &&
    statusTextMap[role]?.[category]?.[status]
  ) {
    return statusTextMap[role][category][status]
  }

  // 2️⃣ fallback: default ตาม status
  return defaultStatusText[status] ?? status
}

const defaultStatusText: Record<string, string> = {
  PENDING: 'รอดำเนินการ',
  ON_PROGRESS: 'กำลังดำเนินการ',
  COMPLETED: 'เสร็จสิ้น',
  REJECTED: 'ปฏิเสธ'
}


const isPatchingStatus = ref(false)
const targetStatus = ref<ReportStatus | ''>('')
const notificationBody = ref('')
const notificationBody = ref('')

function statusLower(st?: ReportStatus | null) {
  if (!st) return '-'
  return st.toLowerCase()
}

function reportCategoryTH(category?: string | null) {
  if (!category) return '-'

  const map: Record<string, string> = {
    safety: 'ความปลอดภัย',
    driverBehavior: 'พฤติกรรมคนขับ',
    passengerBehavior: 'พฤติกรรมผู้โดยสาร',
    vehicle: 'ปัญหายานพาหนะ',
    lostItem: 'ของหาย',
    damaged: 'ทรัพย์สินเสียหาย',
    other: 'อื่น ๆ'
  }

  return map[category] ?? category
}

function statusLabel(st?: string | null) {
  if (!st) return '-'
  switch (st) {
    case 'PENDING':
      return 'รอดำเนินการ'
    case 'ON_PROGRESS':
      return 'กำลังดำเนินการ'
    case 'COMPLETED':
      return 'เสร็จสิ้น'
    case 'REJECTED':
      return 'ปฏิเสธ'
    default:
      return st
  }
}

function statusClass(st?: string | null) {
  if (!st) return 'bg-gray-100 text-gray-700'
  switch (st) {
    case 'PENDING':
      return 'bg-amber-100 text-amber-700'
    case 'ON_PROGRESS':
      return 'bg-blue-100 text-blue-700'
    case 'COMPLETED':
      return 'bg-green-100 text-green-700'
    case 'REJECTED':
      return 'bg-red-100 text-red-700'
    default:
      return 'bg-gray-100 text-gray-700'
  }
}

async function patchStatus(status: ReportStatus) {
  if (!report.value) return
  if (!confirm(`ยืนยันเปลี่ยนสถานะเป็น "${statusLabel(status)}" ?`)) return

  isPatchingStatus.value = true
  targetStatus.value = status

  try {
    const res = await $fetch<ApiResponse<Report>>(
      `/reports/admin/${reportId}/status`,
      {
        baseURL: config.public.apiBase,
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {})
        },
        body: {
          status,
          ...(notificationBody.value.trim() ? { notificationBody: notificationBody.value.trim() } : {})
        }
      }
    )

    report.value = {
      ...report.value,
      status: res.data.status,
      updatedAt: res.data.updatedAt
    }
  } catch (err) {
    console.error(err)
    alert('อัปเดตสถานะไม่สำเร็จ')
  } finally {
    isPatchingStatus.value = false
    targetStatus.value = ''
  }
}

/* Reusable display box */
const InfoBox = defineComponent({
    name: 'InfoBox',
    props: { label: { type: String, required: true } },
    setup(props, { slots }) {
        return () =>
            h('div', {}, [
                h('div', { class: 'block mb-1 text-xs font-medium text-gray-600' }, props.label),
                h(
                    'div',
                    { class: 'w-full px-3 py-2.5 border border-gray-300 rounded-md bg-gray-50 text-gray-900' },
                    slots.default ? slots.default() : ''
                )
            ])
    }
})

const selectedPhoto = ref<string | null>(null)


</script>
