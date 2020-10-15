import React, {useState, useEffect} from 'react'
import {useParams} from 'react-router-dom'
import {Card, Form} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'

import {Meetings} from '/lib/meetings'
import {getCreator} from './lib/presenceId'
import {useDebounce} from './lib/useDebounce'

export MeetingTitle = ->
  {meetingId} = useParams()
  meeting = useTracker -> Meetings.findOne meetingId
  [title, setTitle] = useState (meeting?.title ? '')
  [changed, setChanged] = useState false
  useEffect ->
    setTitle meeting.title if meeting?.title?
  , [meeting?.title]
  changedDebounce = useDebounce changed, 500
  useEffect ->
    if changedDebounce
      if title != meeting.title
        Meteor.call 'meetingEdit',
          id: meetingId
          title: title
          updator: getCreator()
      setChanged false
  , [changedDebounce]

  <Card>
    <Card.Header className="tight">
      Meeting Title:
    </Card.Header>
    <Card.Body>
      <Form.Control type="text" placeholder="Comingle Meeting"
       value={title} onChange={(e) ->
         setTitle e.target.value
         setChanged e.target.value
      }/>
    </Card.Body>
  </Card>
MeetingTitle.displayName = 'MeetingTitle'
