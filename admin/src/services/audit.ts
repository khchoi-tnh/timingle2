import { db } from '../db'
import { auditLogs } from '../db/schema'
import { desc, eq, and, gte, lte, like, or } from 'drizzle-orm'

export type AuditAction =
  | 'USER_VIEWED'
  | 'USER_SUSPENDED'
  | 'USER_ACTIVATED'
  | 'USER_DELETED'
  | 'USER_ROLE_CHANGED'
  | 'EVENT_VIEWED'
  | 'EVENT_DELETED'
  | 'LOGIN'
  | 'LOGOUT'

// 감사 로그 기록
export async function logAdminAction(params: {
  adminId: number
  action: AuditAction
  targetType: 'user' | 'event' | 'system'
  targetId?: number
  oldValue?: object
  newValue?: object
  ipAddress?: string
  userAgent?: string
}) {
  await db.insert(auditLogs).values({
    adminId: params.adminId,
    action: params.action,
    targetType: params.targetType,
    targetId: params.targetId,
    oldValue: params.oldValue ? JSON.stringify(params.oldValue) : null,
    newValue: params.newValue ? JSON.stringify(params.newValue) : null,
    ipAddress: params.ipAddress,
    userAgent: params.userAgent,
  })
}

// 감사 로그 목록 조회
export async function getAuditLogs(params: {
  page?: number
  limit?: number
  adminId?: number
  action?: string
  targetType?: string
  startDate?: Date
  endDate?: Date
}) {
  const { page = 1, limit = 20, adminId, action, targetType, startDate, endDate } = params
  const offset = (page - 1) * limit

  const conditions = []

  if (adminId) {
    conditions.push(eq(auditLogs.adminId, adminId))
  }
  if (action) {
    conditions.push(like(auditLogs.action, `%${action}%`))
  }
  if (targetType) {
    conditions.push(eq(auditLogs.targetType, targetType))
  }
  if (startDate) {
    conditions.push(gte(auditLogs.createdAt, startDate))
  }
  if (endDate) {
    conditions.push(lte(auditLogs.createdAt, endDate))
  }

  const logs = await db
    .select()
    .from(auditLogs)
    .where(conditions.length > 0 ? and(...conditions) : undefined)
    .orderBy(desc(auditLogs.createdAt))
    .limit(limit)
    .offset(offset)

  return logs
}
