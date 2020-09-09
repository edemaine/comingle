import React from 'react'

export Header = ->
  <nav>
    <LinkToFrontPage className="flex-shrink-1" style={maxWidth:"35px"}>
      <img src="/comingle.svg" className="w-100"/>
    </LinkToFrontPage>
    <LinkToFrontPage className="navbar-brand ml-1 mr-0 mb-0 h1">
      Comingle
    </LinkToFrontPage>
  </nav>
Header.displayName = 'Header'

export LinkToFrontPage = (props) ->
  <a href={Meteor.absoluteUrl()} target="_blank" {...props}> {### eslint-disable-line react/jsx-no-target-blank ###}
    {props.children}
  </a>
LinkToFrontPage.displayName = 'LinkToFrontPage'
