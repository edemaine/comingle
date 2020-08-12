import React, {useContext} from 'react'

import {AppSettings} from './App'

export default Name = ->
  {name, setName} = useContext AppSettings
  <form onSubmit={(e) -> e.preventDefault()}>
    <div className="form-group">
      <label className="text-center small w-100 mb-n1">Your name:</label>
      <input type="text" placeholder="FirstName LastName" className="form-control"
       value={name} onChange={(e) -> setName e.target.value}/>
    </div>
  </form>
