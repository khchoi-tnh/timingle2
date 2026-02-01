import { SignJWT, jwtVerify, type JWTPayload } from 'jose'

const JWT_SECRET = new TextEncoder().encode(
  process.env.ADMIN_JWT_SECRET || 'timingle-admin-jwt-secret-dev-only'
)

export interface AdminJWTPayload extends JWTPayload {
  sub: string // userId
  role: 'ADMIN' | 'SUPER_ADMIN'
  phone: string
}

// JWT 토큰 생성
export async function createToken(payload: {
  userId: number
  role: 'ADMIN' | 'SUPER_ADMIN'
  phone: string
}): Promise<string> {
  const token = await new SignJWT({
    sub: payload.userId.toString(),
    role: payload.role,
    phone: payload.phone,
  })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('1h') // Admin 토큰은 1시간 만료
    .sign(JWT_SECRET)

  return token
}

// JWT 토큰 검증
export async function verifyToken(token: string): Promise<AdminJWTPayload> {
  const { payload } = await jwtVerify(token, JWT_SECRET)
  return payload as AdminJWTPayload
}

// 토큰에서 userId 추출
export function getUserIdFromPayload(payload: AdminJWTPayload): number {
  return parseInt(payload.sub || '0', 10)
}
