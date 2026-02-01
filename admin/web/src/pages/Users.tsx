import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Search, MoreVertical, UserX, UserCheck, Trash2 } from 'lucide-react'
import { api, type User } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { formatDate, formatPhoneNumber } from '@/lib/utils'

export function UsersPage() {
  const { user: currentUser } = useAuth()
  const queryClient = useQueryClient()
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [selectedUser, setSelectedUser] = useState<User | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: ['users', { page, search }],
    queryFn: () => api.getUsers({ page, limit: 20, search }),
  })

  const suspendMutation = useMutation({
    mutationFn: (userId: number) => api.updateUserStatus(userId, 'SUSPENDED'),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setSelectedUser(null)
    },
  })

  const activateMutation = useMutation({
    mutationFn: (userId: number) => api.updateUserStatus(userId, 'ACTIVE'),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setSelectedUser(null)
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (userId: number) => api.deleteUser(userId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setSelectedUser(null)
    },
  })

  const isSuperAdmin = currentUser?.role === 'SUPER_ADMIN'
  const totalPages = Math.ceil((data?.total ?? 0) / 20)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Users</h1>
        <p className="text-text-secondary">Manage user accounts</p>
      </div>

      {/* Search */}
      <div className="flex items-center gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-text-muted" />
          <Input
            placeholder="Search by name or phone..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value)
              setPage(1)
            }}
            className="pl-10"
          />
        </div>
      </div>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Users ({data?.total ?? 0})</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-border text-left text-sm text-text-secondary">
                    <th className="pb-3 font-medium">ID</th>
                    <th className="pb-3 font-medium">Name</th>
                    <th className="pb-3 font-medium">Phone</th>
                    <th className="pb-3 font-medium">Role</th>
                    <th className="pb-3 font-medium">Status</th>
                    <th className="pb-3 font-medium">Created</th>
                    <th className="pb-3 font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {data?.users.map((user) => (
                    <tr key={user.id} className="border-b border-border">
                      <td className="py-3 text-sm">{user.id}</td>
                      <td className="py-3 text-sm font-medium">
                        {user.name || '-'}
                      </td>
                      <td className="py-3 text-sm">
                        {formatPhoneNumber(user.phone_number)}
                      </td>
                      <td className="py-3">
                        <RoleBadge role={user.role} />
                      </td>
                      <td className="py-3">
                        <StatusBadge status={user.status} />
                      </td>
                      <td className="py-3 text-sm text-text-secondary">
                        {formatDate(user.created_at)}
                      </td>
                      <td className="py-3">
                        <div className="relative">
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() =>
                              setSelectedUser(
                                selectedUser?.id === user.id ? null : user
                              )
                            }
                          >
                            <MoreVertical className="h-4 w-4" />
                          </Button>

                          {selectedUser?.id === user.id && (
                            <div className="absolute right-0 top-full z-10 mt-1 w-48 rounded-md border border-border bg-surface shadow-lg">
                              {user.status === 'ACTIVE' ? (
                                <button
                                  onClick={() => suspendMutation.mutate(user.id)}
                                  className="flex w-full items-center gap-2 px-4 py-2 text-sm text-warning hover:bg-surface-hover"
                                >
                                  <UserX className="h-4 w-4" />
                                  Suspend User
                                </button>
                              ) : (
                                <button
                                  onClick={() => activateMutation.mutate(user.id)}
                                  className="flex w-full items-center gap-2 px-4 py-2 text-sm text-success hover:bg-surface-hover"
                                >
                                  <UserCheck className="h-4 w-4" />
                                  Activate User
                                </button>
                              )}
                              {isSuperAdmin && (
                                <button
                                  onClick={() => {
                                    if (
                                      confirm(
                                        'Are you sure you want to delete this user?'
                                      )
                                    ) {
                                      deleteMutation.mutate(user.id)
                                    }
                                  }}
                                  className="flex w-full items-center gap-2 px-4 py-2 text-sm text-error hover:bg-surface-hover"
                                >
                                  <Trash2 className="h-4 w-4" />
                                  Delete User
                                </button>
                              )}
                            </div>
                          )}
                        </div>
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

function RoleBadge({ role }: { role: string }) {
  const variant =
    role === 'SUPER_ADMIN'
      ? 'error'
      : role === 'ADMIN'
        ? 'warning'
        : role === 'BUSINESS'
          ? 'success'
          : 'secondary'

  return <Badge variant={variant}>{role}</Badge>
}

function StatusBadge({ status }: { status: string }) {
  const variant =
    status === 'ACTIVE'
      ? 'success'
      : status === 'SUSPENDED'
        ? 'warning'
        : 'error'

  return <Badge variant={variant}>{status}</Badge>
}
