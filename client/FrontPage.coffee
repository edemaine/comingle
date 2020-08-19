import React from 'react'
import {useHistory} from 'react-router-dom'
import {Button, ButtonGroup, Jumbotron} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faGithub} from '@fortawesome/free-brands-svg-icons'

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
  <Jumbotron className="text-center">
    <h1 className="mb-3">
      Welcome to Comingle! <img src="/comingle.svg" style={{width: '64px'}}/>
    </h1>
    <p>
      <Button variant="primary" size="lg" onClick={newMeeting}>
        Create New Meeting
      </Button>
    </p>
    <ButtonGroup>
      <Button variant="info" as="a" href="https://github.com/edemaine/comingle">
        Source Code on Github <FontAwesomeIcon icon={faGithub}/>
      </Button>
      <Button variant="danger" as="a" href="https://github.com/edemaine/comingle/issues">
        Report Bugs or Request Features
      </Button>
    </ButtonGroup>
  </Jumbotron>
