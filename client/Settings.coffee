import React from 'react'
import {Card, Form} from 'react-bootstrap'

import {LocalStorageVar} from './lib/useLocalStorage'
import {MeetingTitle} from './MeetingTitle'
import {MeetingSecret} from './MeetingSecret'

export Settings = React.memo ->
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
      <MeetingTitle/>
      <MeetingSecret/>
    </div>
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
