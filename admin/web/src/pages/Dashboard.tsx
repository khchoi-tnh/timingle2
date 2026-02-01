import { useQuery } from '@tanstack/react-query'
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import { Users, Calendar, Activity, Clock } from 'lucide-react'
import { api } from '@/lib/api'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { formatNumber } from '@/lib/utils'

export function DashboardPage() {
  const { data: stats, isLoading: statsLoading } = useQuery({
    queryKey: ['stats', 'overview'],
    queryFn: () => api.getStatsOverview(),
    refetchInterval: 30000, // Refresh every 30 seconds
  })

  const { data: usersDaily } = useQuery({
    queryKey: ['stats', 'users', 'daily'],
    queryFn: () => api.getUsersDaily(7),
  })

  const { data: eventsDaily } = useQuery({
    queryKey: ['stats', 'events', 'daily'],
    queryFn: () => api.getEventsDaily(7),
  })

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-text-secondary">
          Welcome to Timingle Admin Dashboard
        </p>
      </div>

      {/* KPI Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Total Users
            </CardTitle>
            <Users className="h-4 w-4 text-text-muted" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {statsLoading ? '...' : formatNumber(stats?.users.total ?? 0)}
            </div>
            <p className="text-xs text-text-secondary">
              +{stats?.users.today ?? 0} today
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Active Users
            </CardTitle>
            <Activity className="h-4 w-4 text-text-muted" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {statsLoading ? '...' : formatNumber(stats?.users.active ?? 0)}
            </div>
            <p className="text-xs text-text-secondary">
              Currently active accounts
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Total Events
            </CardTitle>
            <Calendar className="h-4 w-4 text-text-muted" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {statsLoading ? '...' : formatNumber(stats?.events.total ?? 0)}
            </div>
            <p className="text-xs text-text-secondary">
              +{stats?.events.today ?? 0} today
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Server Uptime
            </CardTitle>
            <Clock className="h-4 w-4 text-text-muted" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {statsLoading
                ? '...'
                : formatUptime(stats?.system.uptime ?? 0)}
            </div>
            <p className="text-xs text-text-secondary">
              Memory: {Math.round((stats?.system.memory_usage ?? 0) * 100)}%
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Charts */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>User Registrations (7 days)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={usersDaily ?? []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                  <XAxis
                    dataKey="date"
                    tickFormatter={(date) =>
                      new Date(date).toLocaleDateString('ko-KR', {
                        month: 'short',
                        day: 'numeric',
                      })
                    }
                    stroke="#6B7280"
                  />
                  <YAxis stroke="#6B7280" />
                  <Tooltip
                    labelFormatter={(date) =>
                      new Date(date).toLocaleDateString('ko-KR')
                    }
                  />
                  <Line
                    type="monotone"
                    dataKey="count"
                    name="Users"
                    stroke="#2E4A8F"
                    strokeWidth={2}
                    dot={{ fill: '#2E4A8F' }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Events Created (7 days)</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={eventsDaily ?? []}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
                  <XAxis
                    dataKey="date"
                    tickFormatter={(date) =>
                      new Date(date).toLocaleDateString('ko-KR', {
                        month: 'short',
                        day: 'numeric',
                      })
                    }
                    stroke="#6B7280"
                  />
                  <YAxis stroke="#6B7280" />
                  <Tooltip
                    labelFormatter={(date) =>
                      new Date(date).toLocaleDateString('ko-KR')
                    }
                  />
                  <Line
                    type="monotone"
                    dataKey="count"
                    name="Events"
                    stroke="#5EC4E8"
                    strokeWidth={2}
                    dot={{ fill: '#5EC4E8' }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)

  if (days > 0) {
    return `${days}d ${hours}h`
  }
  if (hours > 0) {
    return `${hours}h ${minutes}m`
  }
  return `${minutes}m`
}
