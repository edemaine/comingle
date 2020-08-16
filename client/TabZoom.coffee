import React, {useState, useMemo} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Alert, Form, Button, Row, Col} from 'react-bootstrap'
import {Session} from 'meteor/session'

import {allow} from './TabIFrame'
import {Tabs, zoomRegExp} from '/lib/tabs'

export TabZoom = ({tabId, room}) ->
  tab = useTracker -> Tabs.findOne tabId
  return null unless tab
  match = zoomRegExp.exec tab.url
  unless match
    return <Alert variant="danger">
      Could not parse Zoom URL <code>{tab.url}</code>
    </Alert>
  [match, prefix, zoomID, zoomPwd] = match

  zoomNative = ->
    ## Zoom client URL schemes are documented here:
    ## https://marketplace.zoom.us/docs/guides/guides/client-url-schemes
    MobileDetect = (await import('mobile-detect')).default
    md = new MobileDetect window.navigator.userAgent
    prefix = if md.mobile() then 'zoomus' else 'zoommtg'
    url = "#{prefix}://zoom.us/join?confno=#{zoomID}"
    url += "&pwd=#{zoomPwd}" if zoomPwd
    name = Session.get 'name'
    url += "&uname=#{encodeURIComponent name}" if name
    window.location.replace url

  [zoomEmbed, setZoomEmbed] = useState()
  useMemo ->
    Meteor.call 'zoomEmbed', (error, response) ->
      return console.error error if error?
      setZoomEmbed response

  <div className="card">
    <div className="card-body">
      <h3 className="card-title">Zoom Meeting</h3>
      <p>
        <b>Meeting ID:</b> <code>{zoomID}</code><br/>
        <b>Meeting Password:</b> <code>{zoomPwd}</code>
      </p>
      <p>Choose how you would like to join:</p>
      <Row>
        <Col xs={4}>
          <Button block onClick={zoomNative}>Native Client</Button>
        </Col>
        <Col xs={8}>
          <p>Zoom's desktop or mobile Zoom client has the best quality but will open in a separate window, not within comingle.</p>
          <p>You must also <a href="https://zoom.us/download">install Zoom</a> before using this option.</p>
        </Col>
      </Row>
      <Row>
        <Col xs={4}>
          <Button block disabled={not zoomEmbed}>Web Client</Button>
        </Col>
        <Col xs={8}>
          <p>Zoom's web client embeds into Comingle and requires no installation, but the quality is somewhat lower, and <a href="https://support.zoom.us/hc/en-us/articles/360027397692-Desktop-client-mobile-app-and-web-client-comparison">some features are missing</a>.</p>
          {unless zoomEmbed
            <p>However, the Comingle server needs to be configured to support this.</p>
          }
        </Col>
      </Row>
    </div>
  </div>
  #<iframe src={tab.url} allow={allow}/>
