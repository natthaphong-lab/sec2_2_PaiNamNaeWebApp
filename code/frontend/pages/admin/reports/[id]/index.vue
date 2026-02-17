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
            <h1 class="text-2xl font-semibold text-gray-800">รายละเอียดการรายงานผู้ขับขี่</h1>
            <span class="text-sm text-gray-500">ดูข้อมูลการรายงานและเปลี่ยนสถานะได้จากหน้านี้</span>
          </div>
        </div>
        <!-- Status & actions -->
        <div class="mb-6 bg-white border border-gray-300 rounded-lg shadow-sm">
          <div class="flex flex-wrap items-center gap-3 px-4 py-4 sm:px-6">
            <div class="text-sm text-gray-700">สถานะปัจจุบัน:</div>
              <span
                class="inline-flex items-center px-2 py-1 text-xs font-semibold rounded-full"
                :class="{
                  'bg-amber-100 text-amber-700': report?.status === 'PENDING',
                  'bg-green-100 text-green-700': report?.status === 'APPROVED',
                  'bg-red-100 text-red-700': report?.status === 'REJECTED'
                }"
              >
              <i class="fa-solid fa-circle mr-1 text-[8px]"></i>
                {{ statusLower(report?.status) }}
              </span>
              <div class="flex gap-2 ml-auto">
                <button class="px-3 py-2 border rounded-md hover:bg-gray-50 disabled:opacity-50"
                  :disabled="isPatchingStatus || !report" @click="patchStatus('PENDING')">
                <i v-if="isPatchingStatus && targetStatus === 'PENDING'"
                  class="mr-1 fa-solid fa-spinner fa-spin"></i>
                  pending
                </button>
                <button
                  class="px-3 py-2 text-green-700 border border-green-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
                  :disabled="isPatchingStatus || !report" @click="patchStatus('APPROVED')">
                  <i v-if="isPatchingStatus && targetStatus === 'APPROVED'"
                    class="mr-1 fa-solid fa-spinner fa-spin"></i>
                    approve
                  </button>
                  <button
                    class="px-3 py-2 text-red-700 border border-red-300 rounded-md hover:bg-gray-50 disabled:opacity-50"
                    :disabled="isPatchingStatus || !report" @click="patchStatus('REJECTED')">
                    <i v-if="isPatchingStatus && targetStatus === 'REJECTED'"
                      class="mr-1 fa-solid fa-spinner fa-spin"></i>
                      reject
                  </button>
                </div>
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
                    <h3 class="mb-3 text-sm font-semibold text-gray-700">ข้อมูลผู้โดยสาร (ผู้แจ้งรายงาน)</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <InfoBox label="ชื่อ-นามสกุล">
                        {{ (report.passenger?.firstName || '-') + ' ' + (report.passenger?.lastName || '') }}
                      </InfoBox>

                      <InfoBox label="อีเมล">
                        {{ report.passenger?.email || '-' }}
                      </InfoBox>

                      <InfoBox label="ชื่อผู้ใช้ (username)">
                        {{ report.passenger?.username || '-' }}
                      </InfoBox>

                      <InfoBox label="เบอร์โทรศัพท์">
                        {{ report.passenger?.phoneNumber || '-' }}
                      </InfoBox>
                    </div>
                  </section>

                  <section>
                    <h3 class="mb-3 text-sm font-semibold text-gray-700">ข้อมูลผู้ขับขี่ (ผู้ถูกรายงาน)</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <InfoBox label="ชื่อ-นามสกุล">
                        {{ (report.driver?.firstName || '-') + ' ' + (report.driver?.lastName || '') }}
                      </InfoBox>

                      <InfoBox label="อีเมล">
                        {{ report.driver?.email || '-' }}
                      </InfoBox>

                      <InfoBox label="ชื่อผู้ใช้ (username)">
                        {{ report.driver?.username || '-' }}
                      </InfoBox>

                      <InfoBox label="เบอร์โทรศัพท์">
                        {{ report.driver?.phoneNumber || '-' }}
                      </InfoBox>
                    </div>
                  </section>

                  <section>
                    <h3 class="mb-3 text-sm font-semibold text-gray-700">รายละเอียดการรายงาน</h3>
                    <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
                      <InfoBox label="ประเภท">
                        {{ report.types?.map(type => mapReportType(type)).join(', ') }}

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

                      <InfoBox label="รูปภาพ">
                        <div v-if="report.photos?.length" class="mt-2 grid grid-cols-2 md:grid-cols-3 gap-4">
                          <img
                            v-for="(photo, index) in report.photos"
                            :key="index"
                            :src="photo"
                            class="h-40 w-full rounded-lg object-cover border cursor-pointer hover:opacity-80"
                            @click="selectedPhoto = photo"
                          />

                        </div>

                        <p v-else class="text-gray-400 mt-2">ไม่มีรูปแนบ</p>
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
import { ref, onMounted } from 'vue'
import { useRoute, useRuntimeConfig, useCookie } from '#app'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
dayjs.locale('th')
import utc from 'dayjs/plugin/utc'
import timezone from 'dayjs/plugin/timezone'
import 'dayjs/locale/th'

definePageMeta({ middleware: ['admin-auth'] })

useHead({
  title: 'ดูรายละเอียดการรายงานผู้ขับขี่ • Admin',
  link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

/* ================= types ================= */
type ReportStatus = 'PENDING' | 'APPROVED' | 'REJECTED'

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
  passengerId: string
  driverId: string
  types: string[]
  description?: string | null
  photos?: string[]
  status: ReportStatus
  createdAt?: string | null
  updatedAt?: string | null
  passenger?: ReportUser | null
  driver?: ReportUser | null
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

const isPatchingStatus = ref(false)
const targetStatus = ref<ReportStatus | ''>('')

function statusLower(st?: ReportStatus | null) {
  if (!st) return '-'
  return st.toLowerCase()
}

async function patchStatus(status: ReportStatus) {
  if (!report.value) return

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
        body: { status }
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
