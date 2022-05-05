import React, {useState, useLayoutEffect} from 'react'
import {useParams} from 'react-router-dom'
import Accordion from 'react-bootstrap/Accordion'
import Button from 'react-bootstrap/Button'
import Card from 'react-bootstrap/Card'
import Form from 'react-bootstrap/Form'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'
import Tooltip from 'react-bootstrap/Tooltip'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faKey} from '@fortawesome/free-solid-svg-icons/faKey'
import {clipboardLink} from './icons/clipboardLink'

import {CardToggle} from './CardToggle'
import {LocalStorageVar, StorageDict} from './lib/useLocalStorage'
import {useDebounce} from './lib/useDebounce'

meetingSecrets = new StorageDict LocalStorageVar, 'secret', '', sync: true

export useMeetingSecret = ->
  {meetingId} = useParams()
  meetingSecrets.get(meetingId)?.use()

export useMeetingAdmin = ->
  Boolean useMeetingSecret()

export getMeetingSecret = (meetingId) ->
  meetingSecrets.get(meetingId)?.get()

export getMeetingAdmin = (meetingId) ->
  Boolean getMeetingSecret meetingId

export setMeetingSecret = (meetingId, secret) ->
  meetingSecrets.get(meetingId)?.set secret

export addMeetingSecret = (meetingId, obj) ->
  secret = getMeetingSecret meetingId
  obj.secret = secret if secret
  obj

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
        <OverlayTrigger position="top" overlay={(props) ->
          <Tooltip {...props}>
            {if storedSecret
              "You have administrative access via the meeting secret. Send the secret to anyone you want to give administrative access."
            else
              "Enter the meeting secret to gain administrative access."
            }
          </Tooltip>
        }>
          <span>
            Meeting Secret:
            {if storedSecret
              <FontAwesomeIcon icon={faKey} className="ml-1"/>
            }
          </span>
        </OverlayTrigger>
      </CardToggle>
      <Accordion.Collapse eventKey="0">
        <Card.Body>
          <Form.Control type="text" placeholder="(administrative access)"
           value={secret} onChange={(e) -> setSecret e.target.value}
           className={state}/>
          <Button block
           onClick={-> navigator.clipboard.writeText storedSecret}>
            Copy to clipboard
            <FontAwesomeIcon icon={clipboardLink} className="ml-1"/>
          </Button>
        </Card.Body>
      </Accordion.Collapse>
    </Card>
  </Accordion>
MeetingSecret.displayName = 'MeetingSecret'
