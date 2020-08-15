import React from 'react'
import {useHistory} from 'react-router-dom'

import {getCreator} from './lib/presenceId'

export FrontPage = ->
  history = useHistory()
  newMeeting = ->
    Meteor.call 'meetingNew',
      creator: getCreator()
    , (error, meetingId) ->
      if error?
        return console.error "Meeting creation failed: #{error}"
      history.push "/m/#{meetingId}"
  <div className="jumbotron">
    <h1>Welcome to Comingle!</h1>
    <button className="btn btn-primary btn-lg" onClick={newMeeting}>
      Create New Meeting
    </button>
  </div>
