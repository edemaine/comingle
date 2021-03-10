import React from 'react'
import {useParams} from 'react-router-dom'
import {Card, Form} from 'react-bootstrap'

import {LocalStorageVar, StorageDict} from './lib/useLocalStorage'
import {MeetingTitle} from './MeetingTitle'
import {MeetingSecret, useMeetingAdmin} from './MeetingSecret'
import {Config} from '/Config'

export Settings = React.memo ->
  admin = useMeetingAdmin()
  <>
    <Card>
      <Card.Body>
        <Card.Title as="h3">Settings</Card.Title>
        <Form>
          <UIToggles/>
        </Form>
      </Card.Body>
    </Card>
    <div className="sidebar">
      <MeetingTitle/>
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

uiVars = {}
uiLabels = {}
export useUI = (name) -> uiVars[name].use()
export getUI = (name) -> uiVars[name].get()

addUIVar = (name, label, init) ->
  unless init?
    init = ->
      Config["default_" + name]
  uiVars[name] = new LocalStorageVar name, init, sync: true
  uiLabels[name] = label

addUIVar('dark', 'Dark Mode', -> window.matchMedia('(prefers-color-scheme: dark)').matches)
addUIVar('compact', 'Compact Room List')
addUIVar('hideCreate', 'Hide Room Creation Widget')
addUIVar('hideSearch', 'Hide Room Search Widget')
addUIVar('hideStarred', 'Hide Starred Rooms Accordion')
addUIVar('hideTitle', 'Hide Meeting Title')
addUIVar('hideRoombar', 'Hide Room Menubar')

UIToggles = React.memo ->
  for name, label of uiLabels
    <UIToggle name={name} key={name}/>
UIToggles.displayName = 'UIToggles'

export UIToggle = React.memo ({name}) ->
  value = useUI(name)
  label = uiLabels[name]
  <Form.Switch id={name} label={label} checked={value}
   onChange={(e) -> uiVars[name].set e.target.checked}/>
UIToggle.displayName = 'UIToggle'

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
