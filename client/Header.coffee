import React from 'react'
import Tooltip from 'react-bootstrap/Tooltip'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'

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
        Meeting title
        <div className="small">
          (change in Settings)
        </div>
      </Tooltip>
    }>
      <div className="text-center text-break">
        {title or 'Comingle'}
      </div>
    </OverlayTrigger>
  </nav>
Header.displayName = 'Header'

export LinkToFrontPage = React.memo (props) ->
  <a href={Meteor.absoluteUrl()} target="_blank" {...props}> {### eslint-disable-line coffee/jsx-no-target-blank ###}
    {props.children}
  </a>
LinkToFrontPage.displayName = 'LinkToFrontPage'
