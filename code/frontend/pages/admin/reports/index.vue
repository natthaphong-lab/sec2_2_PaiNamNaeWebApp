<template>
    <div>
        <AdminHeader />
        <AdminSidebar />

        <main id="main-content" class="main-content mt-16 ml-0 lg:ml-[280px] p-6">
            <div class="mx-auto max-w-8xl">
                <div class="flex flex-col gap-3 mb-6 sm:flex-row sm:items-center sm:justify-between">
                    <div class="flex items-center gap-3">
                        <h1 class="text-2xl font-semibold text-gray-800">Report Management</h1>
                    </div>

                    <div class="flex items-center gap-2">
                        <input v-model.trim="filters.q" @keyup.enter="applyFilters" type="text"
                            placeholder="ค้นหา: ผู้โดยสาร,ไดเวอร์,อีเมล"
                            class="max-w-full px-3 py-2 border border-gray-300 rounded-md w-72 focus:outline-none focus:ring-2 focus:ring-blue-500" />
                        <button @click="applyFilters"
                            class="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700">
                            ค้นหา
                        </button>
                    </div>
                </div>

                <!-- Filters -->
                <div class="mb-4 bg-white border border-gray-300 rounded-lg shadow-sm">
                    <div class="grid grid-cols-1 gap-3 px-4 py-4 sm:px-6 lg:grid-cols-[repeat(24,minmax(0,1fr))]">

                        <div class="lg:col-span-4">
                            <label class="block mb-1 text-xs font-medium text-gray-600">สถานะคำขอ</label>
                            <select v-model="filters.status"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500">
                                <option value="">ทั้งหมด</option>
                                <option value="PENDING">PENDING</option>
                                <option value="APPROVED">APPROVED</option>
                                <option value="REJECTED">REJECTED</option>
                            </select>
                        </div>

                        <div class="lg:col-span-6">
                            <label class="block mb-1 text-xs font-medium text-gray-600">เรียงตาม</label>
                            <select v-model="filters.sort"
                                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500">
                                <option value="">(ค่าเริ่มต้น)</option>
                                <option value="createdAt:desc">สร้างล่าสุด</option>
                                <option value="createdAt:asc">สร้างเก่าสุด</option>
                                <option value="updatedAt:desc">อัปเดตล่าสุด</option>
                                <option value="updatedAt:asc">อัปเดตเก่าสุด</option>
                            </select>
                        </div>

                        <div class="flex items-center justify-end gap-2 lg:col-span-6 lg:col-start-19">
                            <button @click="clearFilters"
                                class="px-3 py-2 text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50">
                                ล้างตัวกรอง
                            </button>
                            <button @click="applyFilters"
                                class="px-4 py-2 text-white bg-blue-600 rounded-md hover:bg-blue-700">
                                ใช้ตัวกรอง
                            </button>
                        </div>
                    </div>
                </div>
                <div class="bg-white border border-gray-300 rounded-lg shadow-sm">
                    <div class="flex items-center justify-between px-4 py-4 border-b border-gray-200 sm:px-6">
                        <div class="text-sm text-gray-600">
                            หน้าที่ {{ pagination.page }} / {{ totalPages }} • ทั้งหมด {{ pagination.total }} รายการ
                        </div>
                    </div>

                    <div v-if="isLoading" class="p-8 text-center text-gray-500">
                        <i class="text-3xl fa-solid fa-spinner fa-spin"></i>
                        <p class="mt-2">กำลังโหลดข้อมูล...</p>
                    </div>

                    <div v-else-if="loadError" class="p-8 text-center text-red-600">
                        {{ loadError }}
                    </div>

                    <div v-else class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        ผู้รายงาน</th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        ผู้ถูกรายงาน</th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        ประเภท</th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        วันที่แจ้ง</th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        สถานะ</th>
                                    <th class="px-4 py-3 text-xs font-medium text-left text-gray-500 uppercase">
                                        การกระทำ</th>
                                </tr>
                            </thead>
                            <tbody class="bg-white divide-y divide-gray-200">
                                <tr v-for="r in rows" :key="r.id" class="transition-colors hover:bg-gray-50">

                                    <!-- <td class="px-4 py-3 text-sm text-gray-700">
                                        {{ r.passenger.firstName}}
                                    </td> -->

                                    <td class="px-4 py-3">
                                        <div class="flex items-center gap-3">
                                            <img :src="r.passenger.profilePicture || 'https://via.placeholder.com/80x80?text=Selfie'"
                                            class="object-cover w-12 h-12 rounded-full" alt="avatar" />
                                            <div>
                                                <div class="font-medium text-gray-900">
                                                    {{ r.passenger.firstName }} {{ r.passenger.lastName }}
                                                    <span class="text-xs text-gray-500" v-if="r.passenger.username">(@{{
                                                        r.passenger.username }})</span>
                                                </div>
                                                <div class="text-xs text-gray-500">{{ r.passenger.email }}</div>
                                                <div class="text-xs text-gray-400" v-if="r.passenger.phoneNumber">Tel: {{
                                                    r.passenger.phoneNumber }}</div>
                                            </div>
                                        </div>
                                    </td>

                                    <!-- <td class="px-4 py-3 text-sm text-gray-700">
                                        {{ r.driverId }}
                                    </td> -->

                                    <td class="px-4 py-3">
                                        <div class="flex items-center gap-3">
                                            <img :src="r.driver.profilePicture || 'https://via.placeholder.com/80x80?text=Selfie'"
                                                class="object-cover w-12 h-12 rounded-full" alt="avatar" />
                                            <div>
                                                <div class="font-medium text-gray-900">
                                                    {{ r.driver.firstName }} {{ r.driver.lastName }}
                                                    <span class="text-xs text-gray-500" v-if="r.driver.username">(@{{
                                                        r.driver.username }})</span>
                                                </div>
                                                <div class="text-xs text-gray-500">{{ r.driver.email }}</div>
                                                <div class="text-xs text-gray-400" v-if="r.driver.phoneNumber">Tel: {{
                                                    r.driver.phoneNumber }}</div>
                                            </div>
                                        </div>
                                    </td>

                                    <td class="px-4 py-3 text-sm text-gray-700">
                                        {{
                                            r.types
                                            ?.map(type => reportTypeTH[type] || type)
                                            .join(', ')
                                        }}
                                    </td>

                                    <td class="px-4 py-3 text-sm text-gray-700">
                                        {{formatThaiDate(r.createdAt)}}
                                    </td>

                                    <td class="px-4 py-3">
                                        <span
                                            class="px-2 py-1 text-xs font-medium rounded-full"
                                            :class="{
                                                'bg-yellow-100 text-yellow-700': r.status === 'PENDING',
                                                'bg-green-100 text-green-700': r.status === 'APPROVED',
                                                'bg-red-100 text-red-700': r.status === 'REJECTED'
                                            }"
                                        >
                                            {{ r.status }}
                                        </span>
                                    </td>

                                    <td class="px-4 py-3">
                                        <div class="flex items-center gap-1">
                                            <button @click="onView(r)" class="p-2 text-gray-500 hover:text-emerald-600"
                                                title="ดูรายละเอียด">
                                                <i class="text-lg fa-regular fa-eye"></i>
                                            </button>
                                            <button @click="onDelete(r)" class="p-2 text-gray-500 hover:text-red-600"
                                                title="ลบ">
                                                <i class="text-lg fa-regular fa-trash-can"></i>
                                            </button>
                                        </div>
                                    </td>
                                    
                                </tr>
                            </tbody>
                        </table>
                    </div>
                    <!-- Footer / Pagination -->
                    <div
                        class="flex flex-col gap-3 px-4 py-4 border-t border-gray-200 sm:px-6 sm:flex-row sm:items-center sm:justify-between">
                        <div class="flex flex-wrap items-center gap-3 text-sm">
                            <div class="flex items-center gap-2">
                                <span class="text-xs text-gray-500">Limit:</span>
                                <select v-model.number="pagination.limit" @change="applyFilters"
                                    class="px-2 py-1 text-sm border border-gray-300 rounded-md focus:ring-blue-500">
                                    <option :value="10">10</option>
                                    <option :value="20">20</option>
                                    <option :value="50">50</option>
                                </select>
                            </div>
                        </div>
                        <nav class="flex items-center gap-1">
                            <button class="px-3 py-2 text-sm border rounded-md disabled:opacity-50"
                                :disabled="pagination.page <= 1 || isLoading" @click="changePage(pagination.page - 1)">
                                Previous
                            </button>
                            <template v-for="(p, idx) in pageButtons" :key="`p-${idx}-${p}`">
                                <span v-if="p === '…'" class="px-2 text-sm text-gray-500">…</span>
                                <button v-else class="px-3 py-2 text-sm border rounded-md"
                                    :class="p === pagination.page ? 'bg-blue-50 text-blue-600 border-blue-200' : 'hover:bg-gray-50'"
                                    :disabled="isLoading" @click="changePage(p)">
                                    {{ p }}
                                </button>
                            </template>
                            <button class="px-3 py-2 text-sm border rounded-md disabled:opacity-50"
                                :disabled="pagination.page >= totalPages || isLoading"
                                @click="changePage(pagination.page + 1)">
                                Next
                            </button>
                        </nav>
                    </div>
                </div>
            </div>
        </main>
    </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, onUnmounted } from 'vue'
import { useRuntimeConfig, useCookie } from '#app'
import dayjs from 'dayjs'
import 'dayjs/locale/th'
import AdminHeader from '~/components/admin/AdminHeader.vue'
import AdminSidebar from '~/components/admin/AdminSidebar.vue'
import ConfirmModal from '~/components/ConfirmModal.vue'
import { useToast } from '~/composables/useToast'
import { useRouter } from 'vue-router'

const rows = ref([])
const isLoading = ref(false)
const loadError = ref(null)

const config = useRuntimeConfig()
const token = useCookie('token')
dayjs.locale('th')

definePageMeta({ middleware: ['admin-auth'] })
useHead({
    title: 'Report Management • Admin',
    link: [{ rel: 'stylesheet', href: 'https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css' }]
})

const pagination = reactive({
    page: 1,
    limit: 10,
    total: 0,
    totalPages: 1
})

const reportTypeTH = {
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


const totalPages = computed(() =>
    Math.max(1, pagination.totalPages || Math.ceil((pagination.total || 0) / (pagination.limit || 10)))
)

const filters = reactive({
    q: '',
    status: '',
    typeOnLicense: '',
    sort: 'createdAt:desc'
})
function applyFilters() {
    pagination.page = 1
    fetchRows(1)
}
function clearFilters() {
    filters.q = ''
    filters.status = ''
    filters.typeOnLicense = ''
    filters.sort = 'createdAt:desc'
    pagination.page = 1
    fetchRows(1)
}

function formatThaiDate(date) {
  return dayjs(date)
    .add(543, 'year')
    .format('DD MMM YYYY HH:mm')
}


async function fetchRows(page = pagination.page) {
    isLoading.value = true
    loadError.value = null

    try {
        const res = await $fetch(`${config.public.apiBase}/reports/admin`, {
            headers: {
                Authorization: `Bearer ${token.value || token}`
            },
            params: {
                page,
                limit: pagination.limit,
                q: filters.q || undefined,
                status: filters.status || undefined,
                sort: filters.sort || undefined
            }
        })

        rows.value = res.data
        pagination.total = res.pagination?.total || res.data.length
        pagination.totalPages = res.pagination?.totalPages ||
            Math.ceil(pagination.total / pagination.limit)
        pagination.page = page

    } catch (err) {
        console.error(err)
        loadError.value = 'ไม่สามารถโหลดข้อมูลรายงานได้'
    } finally {
        isLoading.value = false
    }
}
onMounted(() => {
    fetchRows(1)
})

function onView(r) {
    navigateTo(`/admin/reports/${r.id}`).catch(() => { })
}

const onDelete = async (report) => {
  const ok = confirm('คุณแน่ใจหรือไม่ว่าต้องการลบรายการรายงานนี้?')
  if (!ok) return

  await deleteReport(report.id)
}


const deleteReport = async (reportId) => {
  try {
    await $fetch(`/reports/admin/${reportId}`, {
      baseURL: config.public.apiBase,
      method: 'DELETE',
      headers: {
        Authorization: `Bearer ${token.value}`
      }
    })

    rows.value = rows.value.filter(r => r.id !== reportId)
    pagination.total--

  } catch (err) {
    console.error(err)
    alert('ลบรายการไม่สำเร็จ')
  }
}

const changePage = (page) => {
  if (page < 1 || page > totalPages.value) return
  pagination.page = page
  fetchRows(page)
}
const pageButtons = computed(() => {
  const pages = []
  const total = totalPages.value
  const current = pagination.page
  const delta = 2

  let start = Math.max(1, current - delta)
  let end = Math.min(total, current + delta)

  if (start > 1) pages.push(1)
  if (start > 2) pages.push('…')

  for (let i = start; i <= end; i++) {
    pages.push(i)
  }

  if (end < total - 1) pages.push('…')
  if (end < total) pages.push(total)

  return pages
})

</script>