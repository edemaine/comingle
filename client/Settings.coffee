import React from 'react'
import {useParams} from 'react-router-dom'
import {Card, Form} from 'react-bootstrap'

import {LocalStorageVar, StorageDict} from './lib/useLocalStorage'
import {MeetingTitle} from './MeetingTitle'
import {MeetingSecret, useMeetingAdmin} from './MeetingSecret'
import {Pronouns} from './Name'

export Settings = React.memo ->
  admin = useMeetingAdmin()
  <>
    <Card>
      <Card.Body>
        <Card.Title as="h3">Settings</Card.Title>
        <Form>
          <Dark/>
          <ChatSound/>
        </Form>
      </Card.Body>
    </Card>
    <div className="sidebar">
      <Pronouns/>
      <MeetingTitle/>
      <MeetingSecret/>
    </div>
    {if admin
      <Card>
        <Card.Body>
          <Card.Title as="h3">Admin</Card.Title>
          <Form>
            <AdminVisit/>
            <RaisedSound/>
          </Form>
        </Card.Body>
      </Card>
    }
  </>
Settings.displayName = 'Settings'

darkVar = new LocalStorageVar 'dark', ->
  window.matchMedia('(prefers-color-scheme: dark)').matches
, sync: true
export useDark = -> darkVar.use()
export getDark = -> darkVar.get()

export Dark = React.memo ->
  dark = useDark()
  <Form.Switch id="dark" label="Dark Mode" checked={dark}
   onChange={(e) -> darkVar.set e.target.checked}/>
Dark.displayName = 'Dark'

chatSoundVar = new LocalStorageVar 'chatSound', true, sync: true
export useChatSound = -> chatSoundVar.use()
export getChatSound = -> chatSoundVar.get()

export ChatSound = React.memo ->
  chatSound = useChatSound()
  <Form.Switch id="chatSound" label="Chat Sound" checked={chatSound}
   onChange={(e) -> chatSoundVar.set e.target.checked}/>

adminVisitVars = new StorageDict LocalStorageVar,
  'adminVisit', false, sync: true
export useAdminVisit = ->
  {meetingId} = useParams()
  adminVisitVars.get(meetingId)?.use()

export AdminVisit = React.memo ->
  {meetingId} = useParams()
  adminVisit = useAdminVisit()
  <Form.Switch id="adminVisit" label="Show timer since last admin visit" checked={adminVisit}
   onChange={(e) -> adminVisitVars.get(meetingId).set e.target.checked}/>
AdminVisit.displayName = 'AdminVisit'

raisedSoundVars = new StorageDict LocalStorageVar,
  'raisedSound', true, sync: true
export useRaisedSound = ->
  {meetingId} = useParams()
  raisedSoundVars.get(meetingId)?.use()

export RaisedSound = React.memo ->
  {meetingId} = useParams()
  raisedSound = useRaisedSound()
  <Form.Switch id="raisedSound" label="Play sound when hand gets raised"
   checked={raisedSound}
   onChange={(e) -> raisedSoundVars.get(meetingId).set e.target.checked}/>
