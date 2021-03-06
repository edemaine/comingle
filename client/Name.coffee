import React, {useLayoutEffect, useState} from 'react'
import {Card, Form} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'

import {useMeetingAdmin} from './MeetingSecret'
import {LocalStorageVar} from './lib/useLocalStorage'
import {useDebounce} from './lib/useDebounce'

nameVar = new LocalStorageVar 'name', '', sync: true
export useName = -> nameVar.use()
export getName = -> nameVar.get()

export Name = React.memo ->
  [name, setName] = useState -> nameVar.get()
  nameDebounce = useDebounce name, 500
  admin = useMeetingAdmin()

  ## Synchronize global with form state
  useTracker ->
    setName nameVar.get()
  , []
  useLayoutEffect ->
    nameVar.set nameDebounce
    undefined
  , [nameDebounce]

  <Card>
    <Card.Header className="tight">
      Your Name:
    </Card.Header>
    <Card.Body>
      <Form.Control type="text" placeholder="FirstName LastName"
       className="name #{if nameDebounce.trim() then '' else 'is-invalid'} #{if admin then 'admin' else ''}"
       value={name} onChange={(e) -> setName e.target.value}/>
    </Card.Body>
  </Card>
Name.displayName = 'Name'
