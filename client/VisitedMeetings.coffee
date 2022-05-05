import React, {useMemo} from 'react'
import {useParams} from 'react-router-dom'
import {Accordion, Badge, Card, Table} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUserTie} from '@fortawesome/free-solid-svg-icons/faUserTie'
import {useTracker} from 'meteor/react-meteor-data'
import {Tracker} from 'meteor/tracker'
import {Session} from 'meteor/session'

import {CardToggle, LazyCollapse} from './CardToggle'
import {useMeetingAdmin} from './MeetingSecret'
import {useName} from './Name'
import {formatDateTime} from './lib/dates'
import {LocalStorageVar} from './lib/useLocalStorage'
import {Meetings} from '/lib/meetings'
import {Rooms} from '/lib/rooms'

visitedMeetings = new LocalStorageVar 'visitedMeetings', {}, sync: true

## React component to remember that we visited the current meeting.
## Doesn't actually render anything.
export VisitMeeting = React.memo ->
  {meetingId} = useParams()
  ## Remember when we joined the meeting, not when last variable updated.
  {visited, visits} = useMemo ->
    visited: new Date
    visits: (visitedMeetings.get()[meetingId]?.visits ? 0) + 1
  , [meetingId]
  name = useName()
  admin = useMeetingAdmin()
  useTracker ->
    meeting = Meetings.findOne meetingId
    return unless meeting?
    {title, created} = meeting
    if (roomId = Session.get 'currentRoom')?
      room = Rooms.findOne roomId
      room =
        _id: roomId
        title: room?.title
    else
      room = undefined
    current = Tracker.nonreactive -> visitedMeetings.get()
    old = current[meetingId]
    unless old? and old.visited == visited and old.visits == visits and
           old.title == title and old.created == created and
           old.room?._id == room?._id and old.room?.title == room?.title and
           old.name == name and old.admin == admin
      firstVisited = old?.firstVisited ? visited
      visitedMeetings.set Object.assign current,
        [meetingId]:
          {_id: meetingId, title, created,
           visited, firstVisited, visits,
           room, name, admin}
  null
VisitMeeting.displayName = 'VisitMeeting'

export MeetingLink = React.memo ({id, children}) ->
  <a href={Meteor.absoluteUrl "/m/#{id}"}>
    {children}
  </a>
MeetingLink.displayName = 'MeetingLink'

export VisitedMeetings = React.memo ->
  visited = visitedMeetings.use()
  nVisited = (id for id of visited).length
  return null unless nVisited
  <Accordion>
    <Card>
      <CardToggle eventKey="0">
        <Badge pill variant="secondary">
          {nVisited}
        </Badge>
        {' '}
        Previously Visited Meetings:
      </CardToggle>
      <LazyCollapse eventKey="0">
        <Card.Body className="p-0">
          <VisitedMeetingsTable visited={visited}/>
        </Card.Body>
      </LazyCollapse>
    </Card>
  </Accordion>
VisitedMeetings.displayName = 'VisitedMeetings'

export VisitedMeetingsTable = React.memo ({visited}) ->
  meetings = (meeting for id, meeting of visited)
  meetings.sort (x, y) -> y.visited.getTime() - x.visited.getTime()
  <Table striped size="sm" className="VisitedMeetings">
    <thead>
      <tr>
        <th>Meeting Title</th>
        <th>Last Visited</th>
      </tr>
    </thead>
    <tbody>
      {
        for meeting in meetings
          <tr key={meeting._id}>
            <td>
              <MeetingLink id={meeting._id}>
                {meeting.title or 'Comingle'}
                {if meeting.admin
                  <>
                    {' '}
                    <FontAwesomeIcon icon={faUserTie} className="admin"/>
                  </>
                }
              </MeetingLink>
            </td>
            <td>
              <MeetingLink id={meeting._id}>
                {formatDateTime meeting.visited}
              </MeetingLink>
            </td>
          </tr>
      }
    </tbody>
  </Table>
VisitedMeetingsTable.displayName = 'VisitedMeetingsTable'
