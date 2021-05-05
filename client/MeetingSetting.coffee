import React, {useState, useLayoutEffect} from 'react'
import {useParams} from 'react-router-dom'
import {Card, Form} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'

import {Meetings} from '/lib/meetings'
import {getUpdator} from './lib/presenceId'
import {useDebounce} from './lib/useDebounce'

export useMeetingSetting = (setting) ->
  {meetingId} = useParams()
  meeting = useTracker ->
    Meetings.findOne meetingId
  , [meetingId]
  meeting?[setting]

export MeetingSetting = React.memo ({setting, alt, placeholder}) ->
  {meetingId} = useParams()
  meeting = useTracker ->
    Meetings.findOne meetingId
  , [meetingId]
  [value, setValue] = useState ''
  [changed, setChanged] = useState null
  ## Synchronize text box to setting from database whenever it changes
  useLayoutEffect ->
    return unless meeting?[setting]?
    setValue meeting[setting]
    setChanged false
  , [meeting?[setting]]
  ## When text box stabilizes for half a second, update database setting
  changedDebounce = useDebounce changed, 500
  useLayoutEffect ->
    return unless changedDebounce?
    unless value == meeting[setting]
      Meteor.call 'meetingEdit',
        id: meetingId
        "#{setting}": value
        updator: getUpdator()
    setChanged null
  , [changedDebounce]

  <Card>
    <Card.Header className="tight">
      {alt}:
    </Card.Header>
    <Card.Body>
      <Form.Control type="text" placeholder={placeholder}
       value={value} onChange={(e) ->
         setValue e.target.value
         setChanged e.target.value # ensure `change` different for each update
      }/>
    </Card.Body>
  </Card>
MeetingSetting.displayName = 'MeetingSetting'
