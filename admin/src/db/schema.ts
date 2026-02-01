import {
  pgTable,
  bigserial,
  varchar,
  text,
  timestamp,
  bigint,
  jsonb,
  inet,
  index,
} from 'drizzle-orm/pg-core'

// 사용자 테이블
export const users = pgTable(
  'users',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    phone: varchar('phone', { length: 20 }).notNull().unique(),
    name: varchar('name', { length: 100 }),
    email: varchar('email', { length: 255 }),
    profileImageUrl: text('profile_image_url'),
    region: varchar('region', { length: 50 }),
    interests: text('interests').array(),
    timezone: varchar('timezone', { length: 50 }).default('UTC'),
    language: varchar('language', { length: 10 }).default('ko'),
    role: varchar('role', { length: 20 }).default('USER').notNull(),
    status: varchar('status', { length: 20 }).default('ACTIVE'),
    createdAt: timestamp('created_at').defaultNow(),
    updatedAt: timestamp('updated_at').defaultNow(),
  },
  (table) => [
    index('idx_users_phone').on(table.phone),
    index('idx_users_role').on(table.role),
    index('idx_users_status').on(table.status),
  ]
)

// 이벤트 테이블
export const events = pgTable(
  'events',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    title: varchar('title', { length: 200 }).notNull(),
    description: text('description'),
    startTime: timestamp('start_time', { withTimezone: true }).notNull(),
    endTime: timestamp('end_time', { withTimezone: true }).notNull(),
    location: varchar('location', { length: 200 }),
    creatorId: bigint('creator_id', { mode: 'number' }).references(() => users.id),
    status: varchar('status', { length: 20 }).default('PROPOSED'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow(),
  },
  (table) => [
    index('idx_events_creator_id').on(table.creatorId),
    index('idx_events_status').on(table.status),
    index('idx_events_start_time').on(table.startTime),
  ]
)

// 이벤트 참가자 테이블
export const eventParticipants = pgTable(
  'event_participants',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    eventId: bigint('event_id', { mode: 'number' })
      .notNull()
      .references(() => events.id),
    userId: bigint('user_id', { mode: 'number' })
      .notNull()
      .references(() => users.id),
    status: varchar('status', { length: 20 }).default('PENDING'),
    role: varchar('role', { length: 20 }).default('PARTICIPANT'),
    joinedAt: timestamp('joined_at', { withTimezone: true }).defaultNow(),
  },
  (table) => [
    index('idx_event_participants_event').on(table.eventId),
    index('idx_event_participants_user').on(table.userId),
  ]
)

// 감사 로그 테이블
export const auditLogs = pgTable(
  'audit_logs',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    adminId: bigint('admin_id', { mode: 'number' })
      .notNull()
      .references(() => users.id),
    action: varchar('action', { length: 100 }).notNull(),
    targetType: varchar('target_type', { length: 50 }).notNull(),
    targetId: bigint('target_id', { mode: 'number' }),
    oldValue: jsonb('old_value'),
    newValue: jsonb('new_value'),
    ipAddress: inet('ip_address'),
    userAgent: text('user_agent'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
  },
  (table) => [
    index('idx_audit_logs_admin_id').on(table.adminId),
    index('idx_audit_logs_action').on(table.action),
    index('idx_audit_logs_created_at').on(table.createdAt),
  ]
)

// 메시지 테이블 (이벤트 채팅)
export const messages = pgTable(
  'messages',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    eventId: bigint('event_id', { mode: 'number' })
      .notNull()
      .references(() => events.id),
    senderId: bigint('sender_id', { mode: 'number' })
      .notNull()
      .references(() => users.id),
    content: text('content').notNull(),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
  },
  (table) => [
    index('idx_messages_event_id').on(table.eventId),
    index('idx_messages_sender_id').on(table.senderId),
  ]
)

// 타입 내보내기
export type User = typeof users.$inferSelect
export type NewUser = typeof users.$inferInsert
export type Event = typeof events.$inferSelect
export type NewEvent = typeof events.$inferInsert
export type AuditLog = typeof auditLogs.$inferSelect
export type NewAuditLog = typeof auditLogs.$inferInsert
