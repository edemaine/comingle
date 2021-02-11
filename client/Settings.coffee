import React, {useLayoutEffect} from 'react'
import {Card, Form} from 'react-bootstrap'
import {Session} from 'meteor/session'
import {useTracker} from 'meteor/react-meteor-data'

import {useLocalStorage, getLocalStorage} from './lib/useLocalStorage'

export Settings = React.memo ->
  <Card>
    <Card.Body>
      <Card.Title as="h3">Settings</Card.Title>
      <Form>
        <Dark/>
      </Form>
    </Card.Body>
  </Card>
Settings.displayName = 'Settings'

export Dark = React.memo ->
  [dark, setDark] = useLocalStorage 'dark', preferDark, true
  useLayoutEffect ->
    Session.set 'dark', dark
    undefined
  , [dark]

  <Form.Switch id="dark" label="Dark Mode" checked={dark}
   onChange={(e) -> setDark e.target.checked}/>
Dark.displayName = 'Dark'

export useDark = ->
  [dark] = useLocalStorage 'dark', preferDark, true
  trackedDark = useTracker ->
    Session.get 'dark'
  , []
  trackedDark ? dark

export getDark = ->
  Session.get('dark') ? getLocalStorage 'dark', preferDark

preferDark = ->
  window.matchMedia('(prefers-color-scheme: dark)').matches
