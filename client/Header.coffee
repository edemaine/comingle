import React from 'react'

LinkToFrontPage = (props) ->
  <a href={Meteor.absoluteUrl()} target="_blank" {...props}>
    {props.children}
  </a>

export Header = ->
  <nav>
    <LinkToFrontPage className="flex-shrink-1" style={maxWidth:"35px"}>
      <img src="/comingle.svg" className="w-100"/>
    </LinkToFrontPage>
    <LinkToFrontPage className="navbar-brand ml-1 mr-0 mb-0 h1">
      Comingle
    </LinkToFrontPage>
  </nav>
