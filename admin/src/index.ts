import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { testConnection } from './db'
import { adminAuth } from './middleware/auth'
import { authRoutes } from './routes/auth'
import { statsRoutes } from './routes/stats'
import { usersRoutes } from './routes/users'
import { eventsRoutes } from './routes/events'
import { auditRoutes } from './routes/audit'

const app = new Hono()

// 미들웨어
app.use('*', logger())
app.use(
  '*',
  cors({
    origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
    credentials: true,
  })
)

// 헬스 체크 (인증 불필요)
app.get('/health', (c) => {
  return c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'timingle-admin-api',
  })
})

// API 라우트
const api = new Hono()

// 인증 라우트 (로그인은 인증 불필요)
api.route('/auth', authRoutes)

// 인증 필요한 라우트
api.use('/stats/*', adminAuth)
api.use('/users/*', adminAuth)
api.use('/events/*', adminAuth)
api.use('/audit-logs/*', adminAuth)

api.route('/stats', statsRoutes)
api.route('/users', usersRoutes)
api.route('/events', eventsRoutes)
api.route('/audit-logs', auditRoutes)

// 시스템 정보 (인증 필요)
api.get('/system/health', adminAuth, async (c) => {
  try {
    const dbConnected = await testConnection()
    return c.json({
      database: {
        status: dbConnected ? 'healthy' : 'unhealthy',
        type: 'PostgreSQL',
      },
      server: {
        status: 'healthy',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        version: Bun.version,
      },
    })
  } catch (error) {
    return c.json({
      database: { status: 'unhealthy', error: String(error) },
      server: { status: 'healthy' },
    })
  }
})

// API 마운트
app.route('/api', api)

// 404 핸들러
app.notFound((c) => {
  return c.json({ error: 'Not Found' }, 404)
})

// 에러 핸들러
app.onError((err, c) => {
  console.error('Server error:', err)
  return c.json({ error: 'Internal Server Error' }, 500)
})

// 서버 시작
const port = parseInt(process.env.PORT || '3000')

console.log(`
╔═══════════════════════════════════════════════════════╗
║         Timingle Admin API Server                     ║
╠═══════════════════════════════════════════════════════╣
║  🚀 Server running on http://localhost:${port}           ║
║  📚 API Base: http://localhost:${port}/api               ║
║  🔐 Auth: POST /api/auth/login                        ║
║  📊 Stats: GET /api/stats/overview                    ║
║  👥 Users: GET /api/users                             ║
║  📅 Events: GET /api/events                           ║
║  📋 Audit: GET /api/audit-logs                        ║
╚═══════════════════════════════════════════════════════╝
`)

// DB 연결 테스트
testConnection().then((connected) => {
  if (connected) {
    console.log('✅ Database connection successful')
  } else {
    console.log('❌ Database connection failed')
  }
})

export default {
  port,
  fetch: app.fetch,
}
