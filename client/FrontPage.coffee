import React from 'react'
import {useHistory} from 'react-router-dom'
import {Button, ButtonGroup, Jumbotron} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faGithub} from '@fortawesome/free-brands-svg-icons'

import {Dark} from './Settings'
import {getCreator} from './lib/presenceId'
import {bugs, homepage, repository} from '/package.json'

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
      <b>Comingle</b> is an <a href={repository}>open-source</a> online
      meeting tool whose goal is to approximate the advantages of
      in-person meetings. <br/>
      It integrates web tools in an open multiroom environment.
    </p>
    <p>
      <Button variant="primary" size="lg" onClick={newMeeting}>
        Create New Meeting
      </Button>
    </p>
    <p>
      <ButtonGroup>
        <Button variant="info" as="a" href={homepage}>
          Documentation
        </Button>
        <Button variant="dark" as="a" href={repository.url}>
          Source Code on Github <FontAwesomeIcon icon={faGithub}/>
        </Button>
        <Button variant="danger" as="a" href={bugs.url}>
          Report Bugs or Request Features
        </Button>
      </ButtonGroup>
    </p>
    <p>
      <Dark/>
    </p>
  </Jumbotron>
FrontPage.displayName = 'FrontPage'
