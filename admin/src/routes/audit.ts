import { Hono } from 'hono'
import { db } from '../db'
import { auditLogs, users } from '../db/schema'
import { eq, desc, gte, lte, and, like } from 'drizzle-orm'

const auditRouter = new Hono()

// 감사 로그 목록 조회
auditRouter.get('/', async (c) => {
  try {
    const page = parseInt(c.req.query('page') || '1')
    const limit = parseInt(c.req.query('limit') || '20')
    const action = c.req.query('action')
    const targetType = c.req.query('targetType')
    const adminId = c.req.query('adminId')
    const startDate = c.req.query('startDate')
    const endDate = c.req.query('endDate')
    const offset = (page - 1) * limit

    // 조건 빌드
    const conditions = []

    if (action) {
      conditions.push(like(auditLogs.action, `%${action}%`))
    }
    if (targetType) {
      conditions.push(eq(auditLogs.targetType, targetType))
    }
    if (adminId) {
      conditions.push(eq(auditLogs.adminId, parseInt(adminId)))
    }
    if (startDate) {
      conditions.push(gte(auditLogs.createdAt, new Date(startDate)))
    }
    if (endDate) {
      conditions.push(lte(auditLogs.createdAt, new Date(endDate)))
    }

    // 감사 로그 조회 (관리자 정보 포함)
    const logs = await db
      .select({
        id: auditLogs.id,
        action: auditLogs.action,
        targetType: auditLogs.targetType,
        targetId: auditLogs.targetId,
        oldValue: auditLogs.oldValue,
        newValue: auditLogs.newValue,
        ipAddress: auditLogs.ipAddress,
        userAgent: auditLogs.userAgent,
        createdAt: auditLogs.createdAt,
        adminId: auditLogs.adminId,
        adminName: users.name,
        adminPhone: users.phone,
      })
      .from(auditLogs)
      .leftJoin(users, eq(auditLogs.adminId, users.id))
      .where(conditions.length > 0 ? and(...conditions) : undefined)
      .orderBy(desc(auditLogs.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json({
      data: logs,
      pagination: {
        page,
        limit,
      },
    })
  } catch (error) {
    console.error('Get audit logs error:', error)
    return c.json({ error: 'Failed to fetch audit logs' }, 500)
  }
})

// 특정 대상의 감사 로그 조회
auditRouter.get('/target/:type/:id', async (c) => {
  try {
    const targetType = c.req.param('type')
    const targetId = parseInt(c.req.param('id'))

    const logs = await db
      .select({
        id: auditLogs.id,
        action: auditLogs.action,
        targetType: auditLogs.targetType,
        targetId: auditLogs.targetId,
        oldValue: auditLogs.oldValue,
        newValue: auditLogs.newValue,
        createdAt: auditLogs.createdAt,
        adminId: auditLogs.adminId,
        adminName: users.name,
      })
      .from(auditLogs)
      .leftJoin(users, eq(auditLogs.adminId, users.id))
      .where(
        and(
          eq(auditLogs.targetType, targetType),
          eq(auditLogs.targetId, targetId)
        )
      )
      .orderBy(desc(auditLogs.createdAt))
      .limit(50)

    return c.json({ data: logs })
  } catch (error) {
    console.error('Get target audit logs error:', error)
    return c.json({ error: 'Failed to fetch audit logs' }, 500)
  }
})

export { auditRouter as auditRoutes }
