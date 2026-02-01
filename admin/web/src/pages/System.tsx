import { useQuery } from '@tanstack/react-query'
import {
  Database,
  Server,
  CheckCircle,
  XCircle,
  RefreshCw,
} from 'lucide-react'
import { api } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export function SystemPage() {
  const { data, isLoading, refetch, isRefetching } = useQuery({
    queryKey: ['system', 'health'],
    queryFn: () => api.getSystemHealth(),
    refetchInterval: 60000, // Refresh every minute
  })

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">System Health</h1>
          <p className="text-text-secondary">
            Monitor system status and performance
          </p>
        </div>
        <Button
          variant="outline"
          onClick={() => refetch()}
          disabled={isRefetching}
        >
          <RefreshCw
            className={`mr-2 h-4 w-4 ${isRefetching ? 'animate-spin' : ''}`}
          />
          Refresh
        </Button>
      </div>

      {isLoading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
        </div>
      ) : (
        <div className="grid gap-6 md:grid-cols-2">
          {/* Database Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Database className="h-5 w-5" />
                Database
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-text-secondary">Status</span>
                <StatusIndicator status={data?.database.status} />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-text-secondary">Type</span>
                <span className="font-medium">{data?.database.type}</span>
              </div>
            </CardContent>
          </Card>

          {/* Server Status */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Server className="h-5 w-5" />
                Server
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-text-secondary">Status</span>
                <StatusIndicator status={data?.server.status} />
              </div>
              <div className="flex items-center justify-between">
                <span className="text-text-secondary">Uptime</span>
                <span className="font-medium">
                  {formatUptime(data?.server.uptime ?? 0)}
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-text-secondary">Bun Version</span>
                <span className="font-medium">{data?.server.version}</span>
              </div>
            </CardContent>
          </Card>

          {/* Memory Usage */}
          <Card className="md:col-span-2">
            <CardHeader>
              <CardTitle>Memory Usage</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <div className="mb-2 flex justify-between text-sm">
                    <span className="text-text-secondary">Heap Used</span>
                    <span>
                      {formatBytes(data?.server.memory.heapUsed ?? 0)} /{' '}
                      {formatBytes(data?.server.memory.heapTotal ?? 0)}
                    </span>
                  </div>
                  <div className="h-3 overflow-hidden rounded-full bg-surface-hover">
                    <div
                      className="h-full bg-primary transition-all"
                      style={{
                        width: `${
                          ((data?.server.memory.heapUsed ?? 0) /
                            (data?.server.memory.heapTotal || 1)) *
                          100
                        }%`,
                      }}
                    />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}

function StatusIndicator({ status }: { status?: string }) {
  const isHealthy = status === 'healthy'

  return (
    <div className="flex items-center gap-2">
      {isHealthy ? (
        <>
          <CheckCircle className="h-5 w-5 text-success" />
          <span className="font-medium text-success">Healthy</span>
        </>
      ) : (
        <>
          <XCircle className="h-5 w-5 text-error" />
          <span className="font-medium text-error">Unhealthy</span>
        </>
      )}
    </div>
  )
}

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = Math.floor(seconds % 60)

  const parts = []
  if (days > 0) parts.push(`${days}d`)
  if (hours > 0) parts.push(`${hours}h`)
  if (minutes > 0) parts.push(`${minutes}m`)
  if (secs > 0 || parts.length === 0) parts.push(`${secs}s`)

  return parts.join(' ')
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`
}
