import React, {useEffect} from 'react'
import {Accordion, Card, Form} from 'react-bootstrap'
import {Session} from 'meteor/session'

import {CardToggle} from './CardToggle'
import {useLocalStorage} from './lib/useLocalStorage'
import {useDebounce} from './lib/useDebounce'

export Name = ->
  [name, setName] = useLocalStorage 'name', '', true
  nameDebounce = useDebounce name, 500
  useEffect ->
    Session.set 'name', nameDebounce
    undefined
  , [nameDebounce]
  <Accordion defaultActiveKey="0">
    <Card>
      <CardToggle eventKey="0">
        Your Name:
      </CardToggle>
      <Accordion.Collapse eventKey="0">
        <Card.Body>
          <Form.Control type="text" placeholder="FirstName LastName"
           value={name} onChange={(e) -> setName e.target.value}/>
        </Card.Body>
      </Accordion.Collapse>
    </Card>
  </Accordion>
Name.displayName = 'Name'
