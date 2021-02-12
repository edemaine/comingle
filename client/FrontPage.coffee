import React, {useRef} from 'react'
import {useHistory} from 'react-router-dom'
import {Button, ButtonGroup, Form, Jumbotron} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faGithub} from '@fortawesome/free-brands-svg-icons'

import {Dark} from './Settings'
import {getCreator} from './lib/presenceId'
import {bugs, homepage, repository} from '/package.json'

export FrontPage = React.memo ->
  history = useHistory()
  titleRef = useRef()
  newMeeting = (e) ->
    e.preventDefault()
    Meteor.call 'meetingNew',
      creator: getCreator()
      title: titleRef.current.value
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
    <Form inline className="justify-content-center">
      <Button type="submit" variant="primary" size="lg" onClick={newMeeting}>
        Create New Meeting
      </Button>
      <Form.Control type="text" size="lg" placeholder="Meeting Title (optional)"
       ref={titleRef}/>
    </Form>
    <p/>
    <Dark/>
    <p/>
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
  </Jumbotron>
FrontPage.displayName = 'FrontPage'
