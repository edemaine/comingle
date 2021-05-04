import React from 'react'
import {useParams} from 'react-router-dom'
import {Card, Form} from 'react-bootstrap'

import {LocalStorageVar, StorageDict} from './lib/useLocalStorage'
import {MeetingSetting} from './MeetingSetting'
import {MeetingSecret, useMeetingAdmin} from './MeetingSecret'

export Settings = React.memo ->
  admin = useMeetingAdmin()
  <>
    <Card>
      <Card.Body>
        <Card.Title as="h3">Settings</Card.Title>
        <Form>
          <Dark/>
        </Form>
      </Card.Body>
    </Card>
    <div className="sidebar">
      <MeetingSetting setting="title" alt="Meeting Title"/>
      <MeetingSecret/>
    </div>
    {if admin
      <Card>
        <Card.Body>
          <Card.Title as="h3">Admin</Card.Title>
          <Form>
            <AdminVisit/>
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
