import React, {useEffect} from 'react'
import {Session} from 'meteor/session'

import useLocalStorage from './lib/useLocalStorage'
import {useDebounce} from './lib/useDebounce'

export default Name = ->
  [name, setName] = useLocalStorage 'name', '', true
  nameDebounce = useDebounce name, 500
  useEffect ->
    Session.set 'name', nameDebounce
    undefined
  , [nameDebounce]
  <form onSubmit={(e) -> e.preventDefault()}>
    <div className="form-group">
      <label className="text-center small w-100 mb-n1">Your name:</label>
      <input type="text" placeholder="FirstName LastName" className="form-control"
       value={name} onChange={(e) -> setName e.target.value}/>
    </div>
  </form>
