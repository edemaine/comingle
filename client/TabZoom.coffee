import React, {useEffect, useMemo, useRef, useState} from 'react'
import useEventListener from '@use-it/event-listener'
import {useTracker} from 'meteor/react-meteor-data'
import Alert from 'react-bootstrap/Alert'
import Button from 'react-bootstrap/Button'
import Card from 'react-bootstrap/Card'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faRedoAlt} from '@fortawesome/free-solid-svg-icons/faRedoAlt'

import {allow} from './TabIFrame'
import {getNameWithPronouns} from './Name'
import {trigger} from './lib/trigger'
import {Tabs, zoomRegExp} from '/lib/tabs'
import {meteorCallPromise} from '/lib/meteorPromise'

## Remember the state of the last in-browser Zoom call, except when there are
## no calls and resetZoomStatusAfter seconds elapse; then reset to default
## state.  Modeled after analogous code in TabJitsi.coffee.
resetZoomStatusAfter = 30  # seconds
defaultZoomStatus = ->
  joined: false
  ## Might eventually track audio/video status via this feature request:
  ## https://devforum.zoom.us/t/microphone-state-events-in-web-sdk/41941
  #audioMuted: false
  #videoMuted: false
lastZoomStatus = defaultZoomStatus()
zoomStatusReset = ->
  zoomStatusCheck.stop()
  clean = defaultZoomStatus()
  for key in ['joined']
    lastZoomStatus[key] = clean[key]
  return
numZoom = 0  # number of joined in-browser Zoom calls
zoomStatusCheck = trigger resetZoomStatusAfter, zoomStatusReset

## https://github.com/zoom/sample-app-web/blob/master/CDN/js/tool.js
base64 = (str) ->
  ## first we use encodeURIComponent to get percent-encoded UTF-8,
  ## then we convert the percent encodings into raw bytes which
  ## can be fed into btoa.
  btoa encodeURIComponent(str).replace /%([0-9A-F]{2})/g, (match, hex) ->
    String.fromCharCode "0x#{hex}"

export TabZoom = React.memo ({tabId}) ->
  tab = useTracker ->
    Tabs.findOne tabId
  , [tabId]
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
    UAParser = (await import('ua-parser-js')).default
    ua = new UAParser
    prefix = if ua.getDevice().type == 'mobile' then 'zoomus' else 'zoommtg'
    url = "#{prefix}://zoom.us/join?confno=#{zoomID}"
    url += "&pwd=#{zoomPwd}" if zoomPwd
    name = getNameWithPronouns()
    url += "&uname=#{encodeURIComponent name}" if name
    window.location.replace url

  [zoomWebSupport, setZoomWebSupport] = useState()
  useMemo ->
    Meteor.call 'zoomWebSupport', (error, response) ->
      return console.error error if error?
      setZoomWebSupport response
  [embedUrl, setEmbedUrl] = useState()
  zoomWeb = ->
    {signature, sdkKey} = await meteorCallPromise 'zoomSign', zoomID
    setEmbedUrl "/zoom.html?name=#{base64 getNameWithPronouns() ? ''}&mn=#{zoomID}&email=&pwd=#{zoomPwd ? ''}&role=0&lang=en-US&signature=#{signature}&china=0&sdkKey=#{sdkKey}"

  ## Join in-browser if recently switched from a room where we joined in-browser
  useEffect ->
    if zoomWebSupport and lastZoomStatus.joined
      zoomWeb()
    null
  , [zoomWebSupport]

  ## /public/zoomDone.html sends us a {zoom: 'done'} message
  ## to reset from iframe to Card.
  ref = useRef()
  useEventListener 'message', (e) ->
    return unless ref.current
    return unless e.source == ref.current.contentWindow
    return unless e.data?.coop
    if e.data.zoom == 'done'
      setEmbedUrl null

  ## Maintain number of joined in-browser Zoom calls,
  ## and reset state if zero and timeout.
  useEffect ->
    if embedUrl
      numZoom++
      lastZoomStatus.joined = (numZoom > 0)
      zoomStatusCheck.stop()
    ->
      if embedUrl
        numZoom--
        zoomStatusCheck.start() if numZoom == 0
  , [embedUrl]

  return <iframe src={embedUrl} allow={allow} ref={ref}/> if embedUrl

  <Card>
    <Card.Body>
      <Card.Title>Zoom Meeting</Card.Title>
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
          <p>Zoom's desktop or mobile Zoom client has the <b>best quality</b> but will open in a separate window, not within Comingle.</p>
          <p>You must also <a href="https://zoom.us/download">install Zoom</a> before using this option.</p>
        </Col>
      </Row>
      <Row>
        <Col xs={4}>
          <Button block disabled={not zoomWebSupport} onClick={zoomWeb}>
            Web Client
          </Button>
        </Col>
        <Col xs={8}>
          <p>Zoom's web client embeds into Comingle and requires no installation, but the <b>quality is lower</b>, and <a href="https://support.zoom.us/hc/en-us/articles/360027397692-Desktop-client-mobile-app-and-web-client-comparison">some features are missing</a>.</p>
          {unless zoomWebSupport
            <p>However, the Comingle server needs to be configured to support this.</p>
          }
        </Col>
      </Row>
      <p>If you want to make this decision again, select the <FontAwesomeIcon icon={faRedoAlt}/> &ldquo;Reload Tab&rdquo; button at the top of this tab.</p>
    </Card.Body>
  </Card>
TabZoom.displayName = 'TabZoom'
