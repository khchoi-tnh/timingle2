import { Hono } from 'hono'
import { db } from '../db'
import { users, events, messages, auditLogs } from '../db/schema'
import { sql, eq, gte, count, and } from 'drizzle-orm'

const stats = new Hono()

// 전체 통계 개요
stats.get('/overview', async (c) => {
  try {
    const today = new Date()
    today.setHours(0, 0, 0, 0)

    // 전체 사용자 수
    const totalUsers = await db.select({ count: count() }).from(users)

    // 오늘 가입한 사용자 수
    const todayUsers = await db
      .select({ count: count() })
      .from(users)
      .where(gte(users.createdAt, today))

    // 전체 이벤트 수
    const totalEvents = await db.select({ count: count() }).from(events)

    // 오늘 생성된 이벤트 수
    const todayEvents = await db
      .select({ count: count() })
      .from(events)
      .where(gte(events.createdAt, today))

    // 활성 이벤트 수 (PROPOSED 또는 CONFIRMED)
    const activeEvents = await db
      .select({ count: count() })
      .from(events)
      .where(
        sql`${events.status} IN ('PROPOSED', 'CONFIRMED')`
      )

    // 역할별 사용자 수
    const usersByRole = await db
      .select({
        role: users.role,
        count: count(),
      })
      .from(users)
      .groupBy(users.role)

    // 이벤트 상태별 수
    const eventsByStatus = await db
      .select({
        status: events.status,
        count: count(),
      })
      .from(events)
      .groupBy(events.status)

    return c.json({
      users: {
        total: totalUsers[0]?.count || 0,
        today: todayUsers[0]?.count || 0,
        byRole: usersByRole,
      },
      events: {
        total: totalEvents[0]?.count || 0,
        today: todayEvents[0]?.count || 0,
        active: activeEvents[0]?.count || 0,
        byStatus: eventsByStatus,
      },
    })
  } catch (error) {
    console.error('Stats error:', error)
    return c.json({ error: 'Failed to fetch stats' }, 500)
  }
})

// 일별 사용자 통계 (최근 7일)
stats.get('/users/daily', async (c) => {
  try {
    const days = parseInt(c.req.query('days') || '7')
    const startDate = new Date()
    startDate.setDate(startDate.getDate() - days)

    const dailyStats = await db.execute(sql`
      SELECT
        DATE(created_at) as date,
        COUNT(*) as count
      FROM users
      WHERE created_at >= ${startDate}
      GROUP BY DATE(created_at)
      ORDER BY date DESC
    `)

    return c.json({ data: dailyStats })
  } catch (error) {
    console.error('Daily stats error:', error)
    return c.json({ error: 'Failed to fetch daily stats' }, 500)
  }
})

// 일별 이벤트 통계 (최근 7일)
stats.get('/events/daily', async (c) => {
  try {
    const days = parseInt(c.req.query('days') || '7')
    const startDate = new Date()
    startDate.setDate(startDate.getDate() - days)

    const dailyStats = await db.execute(sql`
      SELECT
        DATE(created_at) as date,
        COUNT(*) as count,
        status
      FROM events
      WHERE created_at >= ${startDate}
      GROUP BY DATE(created_at), status
      ORDER BY date DESC
    `)

    return c.json({ data: dailyStats })
  } catch (error) {
    console.error('Daily event stats error:', error)
    return c.json({ error: 'Failed to fetch daily event stats' }, 500)
  }
})

// 시스템 상태 (간단한 헬스체크)
stats.get('/system', async (c) => {
  try {
    // DB 연결 테스트
    const dbTest = await db.execute(sql`SELECT 1 as test`)
    const dbStatus = dbTest ? 'healthy' : 'unhealthy'

    return c.json({
      database: {
        status: dbStatus,
        type: 'PostgreSQL',
      },
      server: {
        status: 'healthy',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
      },
    })
  } catch (error) {
    console.error('System stats error:', error)
    return c.json({
      database: { status: 'unhealthy', error: String(error) },
      server: { status: 'healthy' },
    })
  }
})

export { stats as statsRoutes }
