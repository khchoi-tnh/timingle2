import { Context, Next } from 'hono'
import { verifyToken, getUserIdFromPayload } from '../lib/jwt'

// Admin 인증 미들웨어
export async function adminAuth(c: Context, next: Next) {
  const authHeader = c.req.header('Authorization')

  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Authorization header required' }, 401)
  }

  try {
    const token = authHeader.slice(7)
    const payload = await verifyToken(token)

    // Admin 또는 Super Admin 역할 확인
    if (payload.role !== 'ADMIN' && payload.role !== 'SUPER_ADMIN') {
      return c.json({ error: 'Admin access required' }, 403)
    }

    // Context에 사용자 정보 저장
    c.set('userId', getUserIdFromPayload(payload))
    c.set('role', payload.role)
    c.set('phone', payload.phone)

    await next()
  } catch (error) {
    console.error('Auth error:', error)
    return c.json({ error: 'Invalid or expired token' }, 401)
  }
}

// Super Admin 전용 미들웨어
export async function superAdminOnly(c: Context, next: Next) {
  const role = c.get('role')

  if (role !== 'SUPER_ADMIN') {
    return c.json({ error: 'Super Admin access required' }, 403)
  }

  await next()
}

// 현재 사용자 정보 가져오기 헬퍼
export function getCurrentUser(c: Context) {
  return {
    userId: c.get('userId') as number,
    role: c.get('role') as 'ADMIN' | 'SUPER_ADMIN',
    phone: c.get('phone') as string,
  }
}
