import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'
import * as schema from './schema'

const connectionString = process.env.DATABASE_URL || 'postgres://timingle:timingle@localhost:5432/timingle'

// PostgreSQL 클라이언트 생성
const client = postgres(connectionString)

// Drizzle ORM 인스턴스 생성
export const db = drizzle(client, { schema })

// 연결 테스트
export async function testConnection() {
  try {
    const result = await client`SELECT 1 as test`
    console.log('Database connection successful:', result)
    return true
  } catch (error) {
    console.error('Database connection failed:', error)
    return false
  }
}
