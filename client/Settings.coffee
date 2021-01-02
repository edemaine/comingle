import React, {useLayoutEffect} from 'react'
import {Card, Form} from 'react-bootstrap'
import {Session} from 'meteor/session'
import {useTracker} from 'meteor/react-meteor-data'
import {Config} from '/Config'

import {useLocalStorage, getLocalStorage} from './lib/useLocalStorage'

export Settings = ->
  <Card>
    <Card.Body>
      <Card.Title as="h3">Settings</Card.Title>
      <Form>
        <Dark/>
        <Compact/>
      </Form>
    </Card.Body>
  </Card>
Settings.displayName = 'Settings'

export Dark = ->
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
  useTracker -> Session.get('dark') ? dark

export getDark = ->
  Session.get('dark') ? getLocalStorage 'dark', preferDark

preferDark = ->
  window.matchMedia('(prefers-color-scheme: dark)').matches

export Compact = ->
  [compact, setCompact] = useLocalStorage 'compact', preferCompact, true
  useLayoutEffect ->
    Session.set 'compact', compact
    undefined
  , [compact]

  <Form.Switch id="compact" label="Compact Mode" checked={compact}
   onChange={(e) -> setCompact e.target.checked}/>
Compact.displayName = 'Compact'

export useCompact = ->
  [compact] = useLocalStorage 'compact', preferCompact, true
  useTracker -> Session.get('compact') ? compact

export getCompact = ->
  Session.get('compact') ? getLocalStorage 'compact', preferCompact

preferCompact = ->
  Config.preferCompact
