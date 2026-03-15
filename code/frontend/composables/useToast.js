import { ref } from 'vue'

const toasts = ref([])

const statusToToastType = {
  PENDING: 'warning',
  ON_PROGRESS: 'info',
  COMPLETED: 'success',
  REJECTED: 'error'
}

export function useToast() {
    const addToast = (toast) => {
        toasts.value.push({ ...toast, id: Date.now() })
    }

    const removeToast = (id) => {
        toasts.value = toasts.value.filter(toast => toast.id !== id)
    }

    const toast = {
        
        success: (title, message, duration) => {
            addToast({ type: 'success', title, message, duration })
        },
        error: (title, message, duration) => {
            addToast({ type: 'error', title, message, duration })
        },
        warning: (title, message, duration) => {
            addToast({ type: 'warning', title, message, duration })
        },
        info: (title, message, duration) => {
            addToast({ type: 'info', title, message, duration })
        },

        // ⭐ ต้องอยู่ใน object นี้
        status: (status, title, message, duration) => {
            const type = statusToToastType[status] || 'info'
            addToast({ type, title, message, duration })
        }
    }

    return { toasts, addToast, removeToast, toast }
}