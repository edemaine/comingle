import React, {useRef} from 'react'
import {useHistory} from 'react-router-dom'
import {Button, ButtonGroup, Form, Jumbotron} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faGithub} from '@fortawesome/free-brands-svg-icons'

import {UIToggle} from './Settings'
import {setMeetingSecret} from './MeetingSecret'
import {VisitedMeetings} from './VisitedMeetings'
import {getUpdator} from './lib/presenceId'
import {bugs, changelog, homepage, repository} from '/package.json'

export FrontPage = React.memo ->
  history = useHistory()
  titleRef = useRef()
  newMeeting = (e) ->
    e.preventDefault()
    Meteor.call 'meetingNew',
      updator: getUpdator()
      title: titleRef.current.value
    , (error, meeting) ->
      if error?
        return console.error "Meeting creation failed: #{error}"
      {_id, secret} = meeting
      setMeetingSecret _id, secret
      history.push "/m/#{_id}"

  <Jumbotron className="text-center h-100 overflow-auto">
    <h1 className="mb-3">
      Welcome to Comingle! <img src="/comingle.svg" style={{width: '64px'}}/>
    </h1>
    <p>
      <b>Comingle</b> is an <a href={repository.url}>open-source</a> online
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
    <VisitedMeetings/>
    <p/>
    <UIToggle name="dark"/>
    <p/>
    <ButtonGroup className="flex-wrap">
      <Button variant="info" as="a" href={homepage}>
        Documentation
      </Button>
      <Button variant="info" as="a" href={changelog}>
        Recent Changes
      </Button>
      <Button variant="dark" as="a" href={repository.url}>
        Source Code <FontAwesomeIcon icon={faGithub}/>
      </Button>
      <Button variant="danger" as="a" href={bugs.url}>
        Suggestions/Bugs
      </Button>
    </ButtonGroup>
  </Jumbotron>
FrontPage.displayName = 'FrontPage'
