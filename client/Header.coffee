import React from 'react'
import {Tooltip, OverlayTrigger} from 'react-bootstrap'

import {useMeetingTitle} from './MeetingTitle'

export Header = React.memo ->
  title = useMeetingTitle()
  <nav>
    <OverlayTrigger placement="bottom" overlay={(props) ->
      <Tooltip {...props}>Comingle</Tooltip>
    }>
      <LinkToFrontPage className="flex-shrink-1 mr-1" style={maxWidth:"30px"}>
        <img src="/comingle.svg" className="w-100"/>
      </LinkToFrontPage>
    </OverlayTrigger>
    <OverlayTrigger placement="bottom" overlay={(props) ->
      <Tooltip {...props}>
        Meeting title<br/>
        <small>(change in Settings)</small>
      </Tooltip>
    }>
      <div className="text-center text-break">
        {title or 'Comingle'}
      </div>
    </OverlayTrigger>
  </nav>
Header.displayName = 'Header'

export LinkToFrontPage = React.memo (props) ->
  <a href={Meteor.absoluteUrl()} target="_blank" {...props}> {### eslint-disable-line react/jsx-no-target-blank ###}
    {props.children}
  </a>
LinkToFrontPage.displayName = 'LinkToFrontPage'
