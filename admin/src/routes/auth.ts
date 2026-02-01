import { Hono } from 'hono'
import { db } from '../db'
import { users } from '../db/schema'
import { eq, and, or } from 'drizzle-orm'
import { createToken } from '../lib/jwt'
import { logAdminAction } from '../services/audit'
import bcrypt from 'bcrypt'

const auth = new Hono()

// Admin 로그인
auth.post('/login', async (c) => {
  try {
    const body = await c.req.json()
    const { phone, password } = body

    if (!phone || !password) {
      return c.json({ error: 'Phone and password are required' }, 400)
    }

    // 사용자 조회 (ADMIN 또는 SUPER_ADMIN만)
    const user = await db
      .select()
      .from(users)
      .where(
        and(
          eq(users.phone, phone),
          or(eq(users.role, 'ADMIN'), eq(users.role, 'SUPER_ADMIN'))
        )
      )
      .limit(1)

    if (user.length === 0) {
      return c.json({ error: 'Invalid credentials or not an admin' }, 401)
    }

    const adminUser = user[0]

    // 계정 상태 확인
    if (adminUser.status === 'SUSPENDED') {
      return c.json({ error: 'Account is suspended' }, 403)
    }

    // 비밀번호 검증 (실제 구현에서는 password 컬럼이 필요)
    // 지금은 개발용으로 간단한 검증
    // TODO: users 테이블에 password 컬럼 추가 또는 별도 admin_credentials 테이블 사용
    if (password !== 'admin123') {
      // 개발용 임시 비밀번호
      return c.json({ error: 'Invalid credentials' }, 401)
    }

    // JWT 토큰 생성
    const token = await createToken({
      userId: adminUser.id,
      role: adminUser.role as 'ADMIN' | 'SUPER_ADMIN',
      phone: adminUser.phone,
    })

    // 로그인 감사 로그
    await logAdminAction({
      adminId: adminUser.id,
      action: 'LOGIN',
      targetType: 'system',
      ipAddress: c.req.header('X-Forwarded-For') || c.req.header('X-Real-IP'),
      userAgent: c.req.header('User-Agent'),
    })

    return c.json({
      token,
      user: {
        id: adminUser.id,
        phone: adminUser.phone,
        name: adminUser.name,
        role: adminUser.role,
      },
    })
  } catch (error) {
    console.error('Login error:', error)
    return c.json({ error: 'Login failed' }, 500)
  }
})

// 로그아웃 (감사 로그 기록용)
auth.post('/logout', async (c) => {
  // 로그아웃은 클라이언트에서 토큰 삭제로 처리
  // 여기서는 감사 로그만 기록
  return c.json({ message: 'Logged out successfully' })
})

// 현재 사용자 정보 (토큰 검증용)
auth.get('/me', async (c) => {
  // 이 라우트는 adminAuth 미들웨어가 적용된 후 호출됨
  const userId = c.get('userId')
  const role = c.get('role')

  if (!userId) {
    return c.json({ error: 'Not authenticated' }, 401)
  }

  const user = await db.select().from(users).where(eq(users.id, userId)).limit(1)

  if (user.length === 0) {
    return c.json({ error: 'User not found' }, 404)
  }

  return c.json({
    user: {
      id: user[0].id,
      phone: user[0].phone,
      name: user[0].name,
      role: user[0].role,
    },
  })
})

export { auth as authRoutes }
