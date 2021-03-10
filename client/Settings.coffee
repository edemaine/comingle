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
          <UIToggle name="dark"/>
          <UIToggle name="compact"/>
          <UIToggle name="hidecreate"/>
          <UIToggle name="hidetitle"/>
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

addUIVar = (name, init, label) ->
  uiVars[name] = new LocalStorageVar name, init, sync: true
  uiLabels[name] = label

addUIVar('dark', ->
  window.matchMedia('(prefers-color-scheme: dark)').matches
, 'Dark Mode')

addUIVar('compact', ->
  Config.defaultCompact
, 'Compact Room List')

addUIVar('hidecreate', ->
  Config.defaultHideCreate
, 'Hide Room Creation Widget')

addUIVar('hidetitle', ->
  Config.defaultHideTitle
, 'Hide Meeting Title')

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
