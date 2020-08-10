import React from 'react'
import {useHistory} from 'react-router-dom'

export default FrontPage = ->
  history = useHistory()
  newRoom = ->
    Meteor.call 'roomNew', {}, (error, roomId) ->
      if error?
        return console.error "Room creation failed: #{error}"
      history.push "/r/#{roomId}"
  <div className="jumbotron">
    <h1>Welcome to Comingle!</h1>
    <button className="btn btn-primary btn-lg" onClick={newRoom}>
      Create New Room
    </button>
  </div>
