import { Hono } from 'hono'
import { db } from '../db'
import { users } from '../db/schema'
import { eq, like, or, desc, count, sql } from 'drizzle-orm'
import { getCurrentUser } from '../middleware/auth'
import { logAdminAction } from '../services/audit'

const usersRouter = new Hono()

// 사용자 목록 조회
usersRouter.get('/', async (c) => {
  try {
    const page = parseInt(c.req.query('page') || '1')
    const limit = parseInt(c.req.query('limit') || '20')
    const search = c.req.query('search')
    const role = c.req.query('role')
    const status = c.req.query('status')
    const offset = (page - 1) * limit

    // 조건 빌드
    const conditions = []
    if (search) {
      conditions.push(
        or(
          like(users.phone, `%${search}%`),
          like(users.name, `%${search}%`),
          like(users.email, `%${search}%`)
        )
      )
    }
    if (role) {
      conditions.push(eq(users.role, role))
    }
    if (status) {
      conditions.push(eq(users.status, status))
    }

    // 전체 개수 조회
    const totalResult = await db
      .select({ count: count() })
      .from(users)
      .where(conditions.length > 0 ? sql`${conditions.join(' AND ')}` : undefined)

    // 사용자 목록 조회
    let query = db.select().from(users)

    if (conditions.length > 0) {
      // 간단한 필터링
      if (search) {
        query = query.where(
          or(
            like(users.phone, `%${search}%`),
            like(users.name, `%${search}%`)
          )
        )
      }
    }

    const userList = await query
      .orderBy(desc(users.createdAt))
      .limit(limit)
      .offset(offset)

    return c.json({
      data: userList,
      pagination: {
        page,
        limit,
        total: totalResult[0]?.count || 0,
        totalPages: Math.ceil((totalResult[0]?.count || 0) / limit),
      },
    })
  } catch (error) {
    console.error('Get users error:', error)
    return c.json({ error: 'Failed to fetch users' }, 500)
  }
})

// 사용자 상세 조회
usersRouter.get('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'))
    const currentUser = getCurrentUser(c)

    const user = await db.select().from(users).where(eq(users.id, id)).limit(1)

    if (user.length === 0) {
      return c.json({ error: 'User not found' }, 404)
    }

    // 감사 로그 기록
    await logAdminAction({
      adminId: currentUser.userId,
      action: 'USER_VIEWED',
      targetType: 'user',
      targetId: id,
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({ data: user[0] })
  } catch (error) {
    console.error('Get user error:', error)
    return c.json({ error: 'Failed to fetch user' }, 500)
  }
})

// 사용자 상태 변경 (활성/정지)
usersRouter.patch('/:id/status', async (c) => {
  try {
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()
    const { status } = body
    const currentUser = getCurrentUser(c)

    if (!['ACTIVE', 'SUSPENDED'].includes(status)) {
      return c.json({ error: 'Invalid status. Use ACTIVE or SUSPENDED' }, 400)
    }

    // 기존 사용자 조회
    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.id, id))
      .limit(1)

    if (existingUser.length === 0) {
      return c.json({ error: 'User not found' }, 404)
    }

    const oldStatus = existingUser[0].status

    // 상태 업데이트
    await db
      .update(users)
      .set({ status, updatedAt: new Date() })
      .where(eq(users.id, id))

    // 감사 로그 기록
    await logAdminAction({
      adminId: currentUser.userId,
      action: status === 'SUSPENDED' ? 'USER_SUSPENDED' : 'USER_ACTIVATED',
      targetType: 'user',
      targetId: id,
      oldValue: { status: oldStatus },
      newValue: { status },
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({ message: 'User status updated', status })
  } catch (error) {
    console.error('Update status error:', error)
    return c.json({ error: 'Failed to update user status' }, 500)
  }
})

// 사용자 역할 변경 (SUPER_ADMIN만 가능)
usersRouter.patch('/:id/role', async (c) => {
  try {
    const id = parseInt(c.req.param('id'))
    const body = await c.req.json()
    const { role } = body
    const currentUser = getCurrentUser(c)

    // SUPER_ADMIN 권한 체크
    if (currentUser.role !== 'SUPER_ADMIN') {
      return c.json({ error: 'Super Admin access required' }, 403)
    }

    if (!['USER', 'BUSINESS', 'ADMIN', 'SUPER_ADMIN'].includes(role)) {
      return c.json({ error: 'Invalid role' }, 400)
    }

    // 기존 사용자 조회
    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.id, id))
      .limit(1)

    if (existingUser.length === 0) {
      return c.json({ error: 'User not found' }, 404)
    }

    const oldRole = existingUser[0].role

    // 역할 업데이트
    await db
      .update(users)
      .set({ role, updatedAt: new Date() })
      .where(eq(users.id, id))

    // 감사 로그 기록
    await logAdminAction({
      adminId: currentUser.userId,
      action: 'USER_ROLE_CHANGED',
      targetType: 'user',
      targetId: id,
      oldValue: { role: oldRole },
      newValue: { role },
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({ message: 'User role updated', role })
  } catch (error) {
    console.error('Update role error:', error)
    return c.json({ error: 'Failed to update user role' }, 500)
  }
})

// 사용자 삭제 (SUPER_ADMIN만 가능)
usersRouter.delete('/:id', async (c) => {
  try {
    const id = parseInt(c.req.param('id'))
    const currentUser = getCurrentUser(c)

    // SUPER_ADMIN 권한 체크
    if (currentUser.role !== 'SUPER_ADMIN') {
      return c.json({ error: 'Super Admin access required' }, 403)
    }

    // 자기 자신 삭제 방지
    if (id === currentUser.userId) {
      return c.json({ error: 'Cannot delete yourself' }, 400)
    }

    // 기존 사용자 조회
    const existingUser = await db
      .select()
      .from(users)
      .where(eq(users.id, id))
      .limit(1)

    if (existingUser.length === 0) {
      return c.json({ error: 'User not found' }, 404)
    }

    // 소프트 삭제 (status를 DELETED로 변경)
    await db
      .update(users)
      .set({ status: 'DELETED', updatedAt: new Date() })
      .where(eq(users.id, id))

    // 감사 로그 기록
    await logAdminAction({
      adminId: currentUser.userId,
      action: 'USER_DELETED',
      targetType: 'user',
      targetId: id,
      oldValue: { user: existingUser[0] },
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({ message: 'User deleted' })
  } catch (error) {
    console.error('Delete user error:', error)
    return c.json({ error: 'Failed to delete user' }, 500)
  }
})

export { usersRouter as usersRoutes }
