import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Search, Trash2, Users, MapPin, Clock } from 'lucide-react'
import { api } from '@/lib/api'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { formatDate } from '@/lib/utils'

export function EventsPage() {
  const queryClient = useQueryClient()
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)

  const { data, isLoading } = useQuery({
    queryKey: ['events', { page, status }],
    queryFn: () => api.getEvents({ page, limit: 20, status: status || undefined }),
  })

  const deleteMutation = useMutation({
    mutationFn: (eventId: number) => api.deleteEvent(eventId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['events'] })
    },
  })

  const totalPages = Math.ceil((data?.total ?? 0) / 20)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Events</h1>
        <p className="text-text-secondary">Manage events and meetings</p>
      </div>

      {/* Filters */}
      <div className="flex items-center gap-4">
        <select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value)
            setPage(1)
          }}
          className="h-10 rounded-md border border-border bg-surface px-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
        >
          <option value="">All Status</option>
          <option value="PROPOSED">Proposed</option>
          <option value="CONFIRMED">Confirmed</option>
          <option value="DONE">Done</option>
          <option value="CANCELED">Canceled</option>
        </select>
      </div>

      {/* Events List */}
      <Card>
        <CardHeader>
          <CardTitle>All Events ({data?.total ?? 0})</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
            </div>
          ) : data?.events.length === 0 ? (
            <div className="flex h-40 items-center justify-center text-text-secondary">
              No events found
            </div>
          ) : (
            <div className="space-y-4">
              {data?.events.map((event) => (
                <div
                  key={event.id}
                  className="flex items-start justify-between rounded-lg border border-border p-4"
                >
                  <div className="space-y-2">
                    <div className="flex items-center gap-3">
                      <h3 className="font-medium">{event.title}</h3>
                      <EventStatusBadge status={event.status} />
                    </div>

                    {event.description && (
                      <p className="text-sm text-text-secondary line-clamp-2">
                        {event.description}
                      </p>
                    )}

                    <div className="flex flex-wrap gap-4 text-sm text-text-secondary">
                      <div className="flex items-center gap-1">
                        <Clock className="h-4 w-4" />
                        {formatDate(event.start_time)}
                      </div>
                      {event.location && (
                        <div className="flex items-center gap-1">
                          <MapPin className="h-4 w-4" />
                          {event.location}
                        </div>
                      )}
                      <div className="flex items-center gap-1">
                        <Users className="h-4 w-4" />
                        {event.participants_count} participants
                      </div>
                    </div>

                    <p className="text-xs text-text-muted">
                      Created by {event.creator_name || `User #${event.creator_id}`} on{' '}
                      {formatDate(event.created_at)}
                    </p>
                  </div>

                  <div className="flex items-center gap-2">
                    {event.status !== 'CANCELED' && (
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-error hover:text-error"
                        onClick={() => {
                          if (
                            confirm(
                              'Are you sure you want to cancel this event?'
                            )
                          ) {
                            deleteMutation.mutate(event.id)
                          }
                        }}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </div>
              ))}
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

function EventStatusBadge({ status }: { status: string }) {
  const variant =
    status === 'CONFIRMED'
      ? 'success'
      : status === 'PROPOSED'
        ? 'warning'
        : status === 'DONE'
          ? 'secondary'
          : 'error'

  return <Badge variant={variant}>{status}</Badge>
}
