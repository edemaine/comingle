import React from 'react'
import {useParams} from 'react-router-dom'
import Card from 'react-bootstrap/Card'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'
import Tooltip from 'react-bootstrap/Tooltip'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {clipboardLink} from './icons/clipboardLink'
import {faCog} from '@fortawesome/free-solid-svg-icons/faCog'
import {faComment} from '@fortawesome/free-solid-svg-icons/faComment'
import {faDoorOpen} from '@fortawesome/free-solid-svg-icons/faDoorOpen'
#import {faHandPaper} from '@fortawesome/free-solid-svg-icons/faHandPaper'
import {faHandPaper} from '@fortawesome/free-regular-svg-icons/faHandPaper'
#import {faStar} from '@fortawesome/free-solid-svg-icons/faStar'
import {faStar} from '@fortawesome/free-regular-svg-icons/faStar'

import {useMeetingSecret} from './MeetingSecret'
import {homepage, repository} from '/package.json'

export Welcome = ->
  {meetingId} = useParams()
  meetingUrl = Meteor.absoluteUrl "/m/#{meetingId}"
  meetingSecret = useMeetingSecret()

  <Card>
    <Card.Body>
      <Card.Title as="h3">Welcome to Comingle!</Card.Title>
      <p>
        <b>Comingle</b> is an <a href={repository.url} target="_blank" rel="noopener">open-source</a> online
        meeting tool whose goal is to approximate the advantages of
        in-person meetings.
        It integrates web tools in an open multiroom environment.
      </p>
      <h5>Getting Started:</h5>
      <ul>
        <li>First, <b>enter your name</b> (first and last) in the left panel (top text box). Optionally, set your <b>pronouns</b> under <FontAwesomeIcon icon={faCog}/> Settings.</li>
        <li>To <b>join a room</b>, click on a room (such as &ldquo;Main Room&rdquo;) in the <FontAwesomeIcon icon={faDoorOpen}/> <b>Meeting Rooms</b> list on the left.</li>
        <li>When you click a second room, you'll be offered to <FontAwesomeIcon icon={faDoorOpen}/> <b>Switch to Room</b> which leaves the current room and any video calls  (shortcut: hold <kbd>Shift</kbd> while clicking).</li>
        <li>Each room contains one or more <b>tabs</b>: video call, whiteboard, etc.
          You can drag these tabs to re-arrange them however you like!</li>
        <li><FontAwesomeIcon className="raise-hand" icon={faHandPaper}/> <b>Raise Hand</b> within a room to signal that you'd like someone to come visit/help.</li>
        <li><FontAwesomeIcon className="presence-starred" icon={faStar}/> <b>Star</b> rooms to (publicly) indicate your interest in that topic. To focus on just starred rooms, unfold the &ldquo;<b>Your Starred Rooms</b>&rdquo; section.</li>
        <li><FontAwesomeIcon icon={faComment}/> <b>Chat</b> is available both global to the meeting (via the tab on the left) and local to each room (via the tab on the right, within the room).</li>
        <li><a href={homepage} target="_blank" rel="noopener">Read the documentation</a> for more information.</li>
      </ul>
      <h5>
        <span className="mr-2">Meeting&nbsp;Link:</span>
        {' '}
        <code className="text-break user-select-all">{meetingUrl}</code>
        <OverlayTrigger placement="top" overlay={(props) ->
          <Tooltip {...props}>Copy meeting link to clipboard</Tooltip>
        }>
          <div aria-label="Copy meeting link to clipboard"
           onClick={-> navigator.clipboard.writeText meetingUrl}
           className="flexlayout__tab_button_trailing">
            <FontAwesomeIcon icon={clipboardLink}/>
          </div>
        </OverlayTrigger>
      </h5>
      <p className="ml-4">
        Send this link to other people to let them join the meeting.
      </p>
      {if meetingSecret
        <>
          <h5>Administrative Access</h5>
          <p className="ml-4">
            You have administrative access to this meeting because you either created it or entered the <b>Meeting Secret</b> (under <FontAwesomeIcon icon={faCog}/> Settings). You should record the secret (for gaining access on other machines/browsers) and give it to anyone you want to have administrative access.
          </p>
        </>
      }
    </Card.Body>
  </Card>
