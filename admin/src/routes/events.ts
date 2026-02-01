import { Hono } from 'hono'
import { db } from '../db'
import { events, users, eventParticipants } from '../db/schema'
import { eq, like, desc, count, sql } from 'drizzle-orm'
import { getCurrentUser } from '../middleware/auth'
import { logAdminAction } from '../services/audit'

const eventsRouter = new Hono()

// 이벤트 목록 조회
eventsRouter.get('/', async (c) => {
  try {
    const page = parseInt(c.req.query('page') || '1')
    const limit = parseInt(c.req.query('limit') || '20')
    const search = c.req.query('search')
    const status = c.req.query('status')
    const offset = (page - 1) * limit

    // 전체 개수 조회
    const totalResult = await db.select({ count: count() }).from(events)

    // 이벤트 목록 조회 (creator 정보 포함)
    let query = db
      .select({
        id: events.id,
        title: events.title,
        description: events.description,
        startTime: events.startTime,
        endTime: events.endTime,
        location: events.location,
        status: events.status,
        createdAt: events.createdAt,
        creatorId: events.creatorId,
        creatorName: users.name,
        creatorPhone: users.phone,
      })
      .from(events)
      .leftJoin(users, eq(events.creatorId, users.id))

    if (search) {
      query = query.where(like(events.title, `%${search}%`))
    }

    if (status) {
      query = query.where(eq(events.status, status))
    }

    const eventList = await query
      .orderBy(desc(events.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json({
      data: eventList,
      pagination: {
        page,
        limit,
        total: totalResult[0]?.count || 0,
        totalPages: Math.ceil((totalResult[0]?.count || 0) / limit),
      },
    })
  } catch (error) {
    console.error('Get events error:', error)
    return c.json({ error: 'Failed to fetch events' }, 500)
  }
})

// 이벤트 상세 조회
eventsRouter.get('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'))
    const currentUser = getCurrentUser(c)

    // 이벤트 조회 (creator 정보 포함)
    const event = await db
      .select({
        id: events.id,
        title: events.title,
        description: events.description,
        startTime: events.startTime,
        endTime: events.endTime,
        location: events.location,
        status: events.status,
        createdAt: events.createdAt,
        updatedAt: events.updatedAt,
        creatorId: events.creatorId,
        creatorName: users.name,
        creatorPhone: users.phone,
      })
      .from(events)
      .leftJoin(users, eq(events.creatorId, users.id))
      .where(eq(events.id, id))
      .limit(1)

    if (event.length === 0) {
      return c.json({ error: 'Event not found' }, 404)
    }

    // 참가자 목록 조회
    const participants = await db
      .select({
        id: eventParticipants.id,
        userId: eventParticipants.userId,
        status: eventParticipants.status,
        role: eventParticipants.role,
        joinedAt: eventParticipants.joinedAt,
        userName: users.name,
        userPhone: users.phone,
      })
      .from(eventParticipants)
      .leftJoin(users, eq(eventParticipants.userId, users.id))
      .where(eq(eventParticipants.eventId, id))

    // 감사 로그 기록
    await logAdminAction({
      adminId: currentUser.userId,
      action: 'EVENT_VIEWED',
      targetType: 'event',
      targetId: id,
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({
      data: {
        ...event[0],
        participants,
      },
    })
  } catch (error) {
    console.error('Get event error:', error)
    return c.json({ error: 'Failed to fetch event' }, 500)
  }
})

// 이벤트 삭제
eventsRouter.delete('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'))
    const currentUser = getCurrentUser(c)

    // 기존 이벤트 조회
    const existingEvent = await db
      .select()
      .from(events)
      .where(eq(events.id, id))
      .limit(1)

    if (existingEvent.length === 0) {
      return c.json({ error: 'Event not found' }, 404)
    }

    // 이벤트 상태를 CANCELED로 변경 (소프트 삭제)
    await db
      .update(events)
      .set({ status: 'CANCELED', updatedAt: new Date() })
      .where(eq(events.id, id))

    // 감사 로그 기록
    await logAdminAction({
      adminId: currentUser.userId,
      action: 'EVENT_DELETED',
      targetType: 'event',
      targetId: id,
      oldValue: { event: existingEvent[0] },
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({ message: 'Event deleted' })
  } catch (error) {
    console.error('Delete event error:', error)
    return c.json({ error: 'Failed to delete event' }, 500)
  }
})

export { eventsRouter as eventsRoutes }
