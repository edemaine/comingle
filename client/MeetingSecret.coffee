import React, {useState, useLayoutEffect} from 'react'
import {useParams} from 'react-router-dom'
import {Accordion, Card, Form} from 'react-bootstrap'
import SelectableContext from 'react-bootstrap/SelectableContext'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faKey} from '@fortawesome/free-solid-svg-icons'

import {CardToggle} from './CardToggle'
import {LocalStorageVar} from './lib/useLocalStorage'
import {useDebounce} from './lib/useDebounce'

meetingSecrets = {}
meetingSecret = (meetingId) ->
  return unless meetingId?
  meetingSecrets[meetingId] ?=
    new LocalStorageVar "secret.#{meetingId}", '', sync: true
  meetingSecrets[meetingId]

export useMeetingSecret = ->
  {meetingId} = useParams()
  meetingSecret(meetingId)?.use()

export setMeetingSecret = (meetingId, secret) ->
  meetingSecret(meetingId)?.set secret

export MeetingSecret = React.memo ->
  {meetingId} = useParams()
  storedSecret = useMeetingSecret meetingId
  [secret, setSecret] = useState storedSecret
  secretDebounce = useDebounce secret, 500
  [state, setState] = useState()

  ## Synchronize text box with localStorage
  useLayoutEffect ->
    setSecret storedSecret
  , [storedSecret]
  ## When text box stabilizes for half a second, test secret
  useLayoutEffect ->
    trimmed = secretDebounce.trim()
    unless trimmed  # blank
      setMeetingSecret meetingId, trimmed
      setState ''
      return
    Meteor.call 'meetingSecretTest', meetingId, trimmed, (error, response) ->
      if response  # test success
        setMeetingSecret meetingId, trimmed
        setState 'is-valid'
      else
        ## Keep existing secret, if any
        setState 'is-invalid'
    undefined
  , [secretDebounce]

  <Accordion>
    {###<AutoHideAccordion ms={60000}/>###}
    <Card>
      <CardToggle eventKey="0">
        Meeting Secret:
        {if storedSecret
          <FontAwesomeIcon icon={faKey} className="ml-1"/>
        }
      </CardToggle>
      <Accordion.Collapse eventKey="0">
        <SelectableContext.Provider value={null}>
          <Card.Body>
            <Form.Control type="text" placeholder="(administrative access)"
            value={secret} onChange={(e) -> setSecret e.target.value}
            className={state}/>
          </Card.Body>
        </SelectableContext.Provider>
      </Accordion.Collapse>
    </Card>
  </Accordion>
MeetingSecret.displayName = 'MeetingSecret'
