import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { FileText } from 'lucide-react'
import { api } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { formatDate } from '@/lib/utils'

export function AuditLogsPage() {
  const [action, setAction] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading } = useQuery({
    queryKey: ['audit-logs', { page, action }],
    queryFn: () =>
      api.getAuditLogs({ page, limit: 50, action: action || undefined }),
  })

  const totalPages = Math.ceil((data?.total ?? 0) / 50)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Audit Logs</h1>
        <p className="text-text-secondary">
          Track all admin actions and changes
        </p>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <select
          value={action}
          onChange={(e) => {
            setAction(e.target.value)
            setPage(1)
          }}
          className="h-10 rounded-md border border-border bg-surface px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
        >
          <option value="">All Actions</option>
          <option value="LOGIN">Login</option>
          <option value="LOGOUT">Logout</option>
          <option value="VIEW_USER">View User</option>
          <option value="SUSPEND_USER">Suspend User</option>
          <option value="ACTIVATE_USER">Activate User</option>
          <option value="DELETE_USER">Delete User</option>
          <option value="CHANGE_ROLE">Change Role</option>
          <option value="DELETE_EVENT">Delete Event</option>
        </select>
      </div>

      {/* Logs Table */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Audit Logs ({data?.total ?? 0})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
            </div>
          ) : data?.logs.length === 0 ? (
            <div className="flex h-40 items-center justify-center text-text-secondary">
              No audit logs found
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-border text-left text-sm text-text-secondary">
                    <th className="pb-3 font-medium">Timestamp</th>
                    <th className="pb-3 font-medium">Admin</th>
                    <th className="pb-3 font-medium">Action</th>
                    <th className="pb-3 font-medium">Target</th>
                    <th className="pb-3 font-medium">Details</th>
                    <th className="pb-3 font-medium">IP Address</th>
                  </tr>
                </thead>
                <tbody>
                  {data?.logs.map((log) => (
                    <tr key={log.id} className="border-b border-border">
                      <td className="py-3 text-sm text-text-secondary">
                        {formatDate(log.created_at)}
                      </td>
                      <td className="py-3 text-sm font-medium">
                        {log.admin_name || `Admin #${log.admin_id}`}
                      </td>
                      <td className="py-3">
                        <ActionBadge action={log.action} />
                      </td>
                      <td className="py-3 text-sm">
                        {log.target_type}
                        {log.target_id && ` #${log.target_id}`}
                      </td>
                      <td className="py-3 text-sm">
                        <ChangeDetails
                          oldValue={log.old_value}
                          newValue={log.new_value}
                        />
                      </td>
                      <td className="py-3 text-sm text-text-muted">
                        {log.ip_address || '-'}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="mt-4 flex items-center justify-between">
              <p className="text-sm text-text-secondary">
                Page {page} of {totalPages}
              </p>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page === 1}
                  onClick={() => setPage((p) => p - 1)}
                >
                  Previous
                </Button>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={page === totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  )
}

function ActionBadge({ action }: { action: string }) {
  const getVariant = () => {
    if (action.includes('DELETE') || action.includes('SUSPEND')) return 'error'
    if (action.includes('ACTIVATE') || action.includes('CREATE')) return 'success'
    if (action.includes('CHANGE') || action.includes('UPDATE')) return 'warning'
    return 'secondary'
  }

  return <Badge variant={getVariant()}>{action}</Badge>
}

function ChangeDetails({
  oldValue,
  newValue,
}: {
  oldValue: object | null
  newValue: object | null
}) {
  if (!oldValue && !newValue) return <span className="text-text-muted">-</span>

  const formatValue = (val: object | null) => {
    if (!val) return null
    return JSON.stringify(val, null, 0)
  }

  const oldStr = formatValue(oldValue)
  const newStr = formatValue(newValue)

  if (oldStr && newStr) {
    return (
      <div className="max-w-xs truncate">
        <span className="text-error line-through">{oldStr}</span>
        {' → '}
        <span className="text-success">{newStr}</span>
      </div>
    )
  }

  return (
    <div className="max-w-xs truncate text-text-secondary">
      {newStr || oldStr}
    </div>
  )
}
