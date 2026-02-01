const API_BASE = '/api'

interface ApiError {
  error: string
  details?: string
}

class ApiClient {
  private token: string | null = null

  constructor() {
    this.token = localStorage.getItem('admin_token')
  }

  setToken(token: string | null) {
    this.token = token
    if (token) {
      localStorage.setItem('admin_token', token)
    } else {
      localStorage.removeItem('admin_token')
    }
  }

  getToken() {
    return this.token
  }

  private async request<T>(
    path: string,
    options: RequestInit = {}
  ): Promise<T> {
    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    }

    if (this.token) {
      headers['Authorization'] = `Bearer ${this.token}`
    }

    const response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers,
    })

    if (!response.ok) {
      const error: ApiError = await response.json().catch(() => ({
        error: 'Unknown error',
      }))

      if (response.status === 401) {
        this.setToken(null)
        window.location.href = '/login'
      }

      throw new Error(error.error || 'Request failed')
    }

    return response.json()
  }

  // Auth
  async login(phoneNumber: string, password: string) {
    const result = await this.request<{ token: string; user: User }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ phone: phoneNumber, password }),
    })
    this.setToken(result.token)
    return result
  }

  async logout() {
    await this.request('/auth/logout', { method: 'POST' }).catch(() => {})
    this.setToken(null)
  }

  async getMe() {
    return this.request<{ user: User }>('/auth/me')
  }

  // Stats
  async getStatsOverview() {
    return this.request<StatsOverview>('/stats/overview')
  }

  async getUsersDaily(days = 7) {
    return this.request<DailyStat[]>(`/stats/users/daily?days=${days}`)
  }

  async getEventsDaily(days = 7) {
    return this.request<DailyStat[]>(`/stats/events/daily?days=${days}`)
  }

  async getSystemHealth() {
    return this.request<SystemHealth>('/system/health')
  }

  // Users
  async getUsers(params: UserListParams = {}) {
    const query = new URLSearchParams()
    if (params.page) query.set('page', String(params.page))
    if (params.limit) query.set('limit', String(params.limit))
    if (params.search) query.set('search', params.search)
    if (params.role) query.set('role', params.role)
    if (params.status) query.set('status', params.status)

    return this.request<UserListResponse>(`/users?${query}`)
  }

  async getUser(id: number) {
    return this.request<{ user: UserDetail }>(`/users/${id}`)
  }

  async updateUserStatus(id: number, status: 'ACTIVE' | 'SUSPENDED') {
    return this.request<{ user: User }>(`/users/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    })
  }

  async updateUserRole(id: number, role: string) {
    return this.request<{ user: User }>(`/users/${id}/role`, {
      method: 'PATCH',
      body: JSON.stringify({ role }),
    })
  }

  async deleteUser(id: number) {
    return this.request(`/users/${id}`, { method: 'DELETE' })
  }

  // Events
  async getEvents(params: EventListParams = {}) {
    const query = new URLSearchParams()
    if (params.page) query.set('page', String(params.page))
    if (params.limit) query.set('limit', String(params.limit))
    if (params.status) query.set('status', params.status)

    return this.request<EventListResponse>(`/events?${query}`)
  }

  async getEvent(id: number) {
    return this.request<{ event: EventDetail }>(`/events/${id}`)
  }

  async deleteEvent(id: number) {
    return this.request(`/events/${id}`, { method: 'DELETE' })
  }

  // Audit Logs
  async getAuditLogs(params: AuditLogParams = {}) {
    const query = new URLSearchParams()
    if (params.page) query.set('page', String(params.page))
    if (params.limit) query.set('limit', String(params.limit))
    if (params.action) query.set('action', params.action)
    if (params.adminId) query.set('admin_id', String(params.adminId))

    return this.request<AuditLogListResponse>(`/audit-logs?${query}`)
  }
}

export const api = new ApiClient()

// Types
export interface User {
  id: number
  phone_number: string
  name: string | null
  role: 'USER' | 'BUSINESS' | 'ADMIN' | 'SUPER_ADMIN'
  status: 'ACTIVE' | 'SUSPENDED' | 'DELETED'
  created_at: string
}

export interface UserDetail extends User {
  updated_at: string | null
  events_count?: number
  last_login?: string
}

export interface UserListParams {
  page?: number
  limit?: number
  search?: string
  role?: string
  status?: string
}

export interface UserListResponse {
  users: User[]
  total: number
  page: number
  limit: number
}

export interface Event {
  id: number
  title: string
  description: string | null
  status: string
  start_time: string
  end_time: string | null
  location: string | null
  creator_id: number
  creator_name?: string
  participants_count: number
  created_at: string
}

export interface EventDetail extends Event {
  participants: Participant[]
}

export interface Participant {
  id: number
  user_id: number
  user_name: string | null
  user_phone: string
  status: string
  joined_at: string
}

export interface EventListParams {
  page?: number
  limit?: number
  status?: string
}

export interface EventListResponse {
  events: Event[]
  total: number
  page: number
  limit: number
}

export interface StatsOverview {
  users: {
    total: number
    today: number
    active: number
  }
  events: {
    total: number
    today: number
    active: number
  }
  system: {
    uptime: number
    memory_usage: number
  }
}

export interface DailyStat {
  date: string
  count: number
}

export interface SystemHealth {
  database: {
    status: string
    type: string
  }
  server: {
    status: string
    uptime: number
    memory: {
      heapUsed: number
      heapTotal: number
    }
    version: string
  }
}

export interface AuditLog {
  id: number
  admin_id: number
  admin_name: string | null
  action: string
  target_type: string
  target_id: number | null
  old_value: object | null
  new_value: object | null
  ip_address: string | null
  created_at: string
}

export interface AuditLogParams {
  page?: number
  limit?: number
  action?: string
  adminId?: number
}

export interface AuditLogListResponse {
  logs: AuditLog[]
  total: number
  page: number
  limit: number
}
