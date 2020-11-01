import React, {useLayoutEffect} from 'react'
import {Card, Form} from 'react-bootstrap'
import {Session} from 'meteor/session'
import {useTracker} from 'meteor/react-meteor-data'

import {useLocalStorage, getLocalStorage} from './lib/useLocalStorage'
import {useDebounce} from './lib/useDebounce'

export Name = ->
  [name, setName] = useLocalStorage 'name', '', true
  nameDebounce = useDebounce name, 500

  useLayoutEffect ->
    Session.set 'name', nameDebounce
    undefined
  , [nameDebounce]

  <Card>
    <Card.Header className="tight">
      Your Name:
    </Card.Header>
    <Card.Body>
      <Form.Control type="text" placeholder="FirstName LastName"
       className="name #{if nameDebounce.trim() then '' else 'is-invalid'}"
       value={name} onChange={(e) -> setName e.target.value}/>
    </Card.Body>
  </Card>
Name.displayName = 'Name'

export useName = ->
  [name, setName] = useLocalStorage 'name', '', true
  useTracker -> Session.get('name') ? name

export getName = ->
  Session.get('name') ? getLocalStorage 'name', ''
