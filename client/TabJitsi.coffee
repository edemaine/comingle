import React, {useEffect, useRef, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {ReactiveVar} from 'meteor/reactive-var'
import useScript from 'react-script-hook'
import Alert from 'react-bootstrap/Alert'
import Button from 'react-bootstrap/Button'
import Card from 'react-bootstrap/Card'
import Row from 'react-bootstrap/Row'
import Col from 'react-bootstrap/Col'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faRedoAlt} from '@fortawesome/free-solid-svg-icons/faRedoAlt'
import {faTimes} from '@fortawesome/free-solid-svg-icons/faTimes'

import {Loading} from './Loading'
import {useNameWithPronouns} from './Name'
import {getDark} from './Settings'
import {Tabs} from '/lib/tabs'

## Remember the state of the last Jitsi call, except when there are no calls
## and resetJitsiStatusAfter seconds elapse; then reset to default state.
resetJitsiStatusAfter = 30  # seconds
defaultJitsiStatus = ->
  joined: false
  external: false
  audioMuted: false
  videoMuted: false
lastJitsiStatus = defaultJitsiStatus()
jitsiStartsJoined = (url, possible) ->
  if lastJitsiStatus.external and externalWindow? and not externalWindow.closed
    # prefer to re-use external tab if already open
    externalOpen url
    jitsiStatusReset()
    false
  else if lastJitsiStatus.joined
    if possible  # don't reset joined state if impossible to actually join
      jitsiStatusReset()
      true
jitsiStatusReset = ->
  jitsiStatusCheckStop()
  clean = defaultJitsiStatus()
  for key in ['joined', 'external']
    lastJitsiStatus[key] = clean[key]
  return
numJitsi = 0  # number of joined Jitsi calls

timeoutJitsiStatus = null
jitsiStatusCheckStart = ->
  return unless resetJitsiStatusAfter?
  jitsiStatusCheckStop()
  timeoutJitsiStatus = setTimeout jitsiStatusReset, resetJitsiStatusAfter * 1000
jitsiStatusCheckStop = ->
  clearTimeout timeoutJitsiStatus if timeoutJitsiStatus?
  timeoutJitsiStatus = null

parseJitsiUrl = (url) ->
  return {} unless url?
  parsed = new URL url
  host = parsed.host
  roomName = parsed.pathname
  roomName = roomName[1..] if roomName[0] == '/'
  parsed.pathname = '/external_api.js'
  script = parsed.toString()
  {host, roomName, script}

## When Jitsi is opened in an external tab, these are both set.
externalURL = new ReactiveVar()  # url for active Jitsi call
externalWindow = null            # Window object (for checking .closed)
externalInterval = null          # setInterval checking for closed

## Open Jitsi call in external tab
externalOpen = (url) ->
  externalURL.set url
  externalWindow = window.open url + '#config.prejoinPageEnabled=false', 'jitsi'
  externalInterval ?= setInterval ->
    externalClosed() if externalWindow.closed
  , 1000
  return
externalClose = ->
  externalWindow?.close()
  externalClosed()
externalClosed = ->
  clearInterval externalInterval
  externalInterval = null
  externalWindow = null
  externalURL.set null
  jitsiStatusCheckStart()

export TabJitsi = React.memo ({tabId, room}) ->
  tab = useTracker ->
    Tabs.findOne tabId
  , [tabId]
  {host, roomName, script} = parseJitsiUrl tab?.url
  embeddable = (host != 'meet.jit.si')
  [loading, error] = useScript
    src: script
    checkForExisting: true

  ref = useRef()  # div container for Jitsi iframe
  [joined, setJoined] = useState ->  # joined call?
    jitsiStartsJoined tab?.url, embeddable
  [ready, setReady] = useState false  # connected to API?
  [api, setApi] = useState()  # JitsiMeetExternalAPI object
  name = useNameWithPronouns()

  ## Jitsi API
  useEffect ->
    return unless tab?
    return if loading or error
    return unless joined

    Jitsi = window.exports?.JitsiMeetExternalAPI ? window.JitsiMeetExternalAPI
    setApi jitsi = new Jitsi host,
      parentNode: ref.current
      roomName: roomName
      configOverwrite:
        # See https://github.com/jitsi/jitsi-meet/blob/master/config.js
        prejoinPageEnabled: false
        subject: room.title
        defaultRemoteDisplayName: 'Fellow Comingler'
        startWithAudioMuted: lastJitsiStatus.audioMuted
        startWithVideoMuted: lastJitsiStatus.videoMuted
      interfaceConfigOverwrite:
        # See https://github.com/jitsi/jitsi-meet/blob/master/interface_config.js
        DEFAULT_BACKGROUND:
          if getDark() then '#111' else '#474747'
        DISABLE_VIDEO_BACKGROUND: true
        TOOLBAR_BUTTONS: [
          'microphone', 'camera', 'closedcaptions', 'desktop',
          'embedmeeting', 'fullscreen', 'fodeviceselection', 'hangup',
          'profile', 'recording', 'livestreaming', 'etherpad',
          'settings', 'videoquality', 'filmstrip', 'feedback', 'stats',
          'shortcuts', 'tileview', 'videobackgroundblur', 'download', 'help',
          'mute-everyone'
        ] # omit 'chat', 'security', 'invite', 'raisehand', 'sharedvideo' [YouTube]
        SETTINGS_SECTIONS: [
          'devices', 'language', 'moderator'
        ] # omit 'profile' and 'calendar'
        DISPLAY_WELCOME_PAGE_CONTENT: false
        SHOW_CHROME_EXTENSION_BANNER: false
        HIDE_INVITE_MORE_HEADER: true
        RECENT_LIST_ENABLED: false
        SHOW_PROMOTIONAL_CLOSE_PAGE: false  # if supported by server
      userInfo:
        displayName: name  # this gets escaped funny, but will get cleaned up
    # Want to listen for 'dataChannelOpened' but doesn't seem to fire.
    jitsi.addListener 'browserSupport', ->
      setReady true
    jitsi.addListener 'audioMuteStatusChanged', ({muted}) ->
      lastJitsiStatus.audioMuted = muted
    jitsi.addListener 'videoMuteStatusChanged', ({muted}) ->
      lastJitsiStatus.videoMuted = muted
    jitsi.addListener 'readyToClose', ->  # hangup call
      setJoined false
      setReady false
      ## Before hanging up, Jitsi mutes the video and emits an event, so we no
      ## longer know the correct Jitsi status.  So reset to default upon hangup.
      lastJitsiStatus = defaultJitsiStatus()
    ->  # cleanup
      jitsi?.dispose()
  , [tab?.url, loading, error, joined]

  ## Keep settings up-to-date
  useEffect ->
    return unless ready
    api.executeCommand 'displayName', name
    undefined
  , [ready, name]
  useEffect ->
    return unless ready
    api.executeCommand 'subject', room.title
    undefined
  , [ready, room.title]

  ## Maintain number of joined Jitsi calls, and reset state if zero and timeout.
  useEffect ->
    numJitsi++ if joined
    lastJitsiStatus.joined = (numJitsi > 0)
    jitsiStatusCheckStop()
    ->
      numJitsi-- if joined
      jitsiStatusCheckStart() if numJitsi == 0
  , [joined]

  external = useTracker => (externalURL.get() == tab.url)
  useEffect ->
    -> # when tab closed
      if externalURL.get() == tab.url
        # encourage external join in next Jitsi tab
        lastJitsiStatus.external = true
  , []

  return null unless tab
  <div ref={ref}>
    {if error
      <Alert variant="danger">
        Failed to load <a href={script} target="_blank" rel="noopener">Jitsi external API script</a>.
        Is <a href={'https://' + host} target="_blank" rel="noopener">{host}</a> a valid Jitsi server?
      </Alert>
    else if not joined
      join = if external then 'Rejoin' else 'Join'
      <Card>
        <Card.Body>
          <Card.Title>Jitsi Meeting</Card.Title>
          <p>
            <b>Server:</b> <a href={'https://' + host} target="_blank" rel="noopener"><code>{host}</code></a><br/>
            <b>Room ID:</b> <code>{roomName}</code>
          </p>
          <Row>
            <Col xs={4}>
              <Button block disabled={not embeddable}
               onClick={-> externalClose(); setJoined true}>
                {join} Call Here
              </Button>
            </Col>
            <Col xs={8}>
              {if embeddable
                <p>{join} the call within this window.</p>
              else
                <p>The <code>meet.jit.si</code> server <a href="https://community.jitsi.org/t/important-embedding-meet-jit-si-in-your-web-app-will-no-longer-be-supported-please-use-jaas/123003">no longer supports embedding</a> into Comingle. Instead use:</p>
              }
            </Col>
          </Row>
          <Row>
            <Col xs={4}>
              {if external
                <Button block variant="danger" onClick={externalClose}>Leave Call</Button>
              else
                <Button block onClick={-> externalOpen tab.url}>Join Call in External Tab</Button>
              }
            </Col>
            <Col xs={8}>
              {if external
                <p>Close the separate browser tab.</p>
              else
                <p>Join the call within a separate browser tab.</p>
              }
            </Col>
          </Row>
          <p>When joining, you may need to grant access to your microphone and/or camera. If you want to try again, select the <FontAwesomeIcon icon={faRedoAlt}/> &ldquo;Reload Tab&rdquo; button at the top of this tab.</p>
          <p>If you hang up on the call and receive an ad, click the <FontAwesomeIcon icon={faTimes}/> button (at the top right of the ad) to fully leave the call, and prevent Comingle from automatically joining future Jitsi calls.</p>
        </Card.Body>
      </Card>
    else if loading
      <Loading/>
    }
  </div>
TabJitsi.displayName = 'TabJitsi'
