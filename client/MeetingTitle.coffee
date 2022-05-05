import React, {useState, useLayoutEffect} from 'react'
import {useParams} from 'react-router-dom'
import Card from 'react-bootstrap/Card'
import Form from 'react-bootstrap/Form'
import {useTracker} from 'meteor/react-meteor-data'

import {Meetings} from '/lib/meetings'
import {getUpdator} from './lib/presenceId'
import {useDebounce} from './lib/useDebounce'

export useMeetingTitle = ->
  {meetingId} = useParams()
  meeting = useTracker ->
    Meetings.findOne meetingId
  , [meetingId]
  meeting?.title

export MeetingTitle = React.memo ->
  {meetingId} = useParams()
  meeting = useTracker ->
    Meetings.findOne meetingId
  , [meetingId]
  [title, setTitle] = useState ''
  [changed, setChanged] = useState null
  ## Synchronize text box to title from database whenever it changes
  useLayoutEffect ->
    return unless meeting?.title?
    setTitle meeting.title
    setChanged false
  , [meeting?.title]
  ## When text box stabilizes for half a second, update database title
  changedDebounce = useDebounce changed, 500
  useLayoutEffect ->
    return unless changedDebounce?
    unless title == meeting.title
      Meteor.call 'meetingEdit',
        id: meetingId
        title: title
        updator: getUpdator()
    setChanged null
  , [changedDebounce]

  <Card>
    <Card.Header className="tight">
      Meeting Title:
    </Card.Header>
    <Card.Body>
      <Form.Control type="text" placeholder="Comingle Meeting"
       value={title} onChange={(e) ->
         setTitle e.target.value
         setChanged e.target.value # ensure `change` different for each update
      }/>
    </Card.Body>
  </Card>
MeetingTitle.displayName = 'MeetingTitle'
