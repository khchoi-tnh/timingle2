import { Routes, Route } from 'react-router-dom'
import { Layout } from '@/components/layout/Layout'
import { LoginPage } from '@/pages/Login'
import { DashboardPage } from '@/pages/Dashboard'
import { UsersPage } from '@/pages/Users'
import { EventsPage } from '@/pages/Events'
import { AuditLogsPage } from '@/pages/AuditLogs'
import { SystemPage } from '@/pages/System'

function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<Layout />}>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/users" element={<UsersPage />} />
        <Route path="/events" element={<EventsPage />} />
        <Route path="/audit-logs" element={<AuditLogsPage />} />
        <Route path="/system" element={<SystemPage />} />
      </Route>
    </Routes>
  )
}

export default App
