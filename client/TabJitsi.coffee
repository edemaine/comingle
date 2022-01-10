import React, {useEffect, useRef, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import useScript from 'react-script-hook'
import {Alert, Button, Card} from 'react-bootstrap'

import {Loading} from './Loading'
import {useName} from './Name'
import {getUI} from './Settings'
import {Tabs} from '/lib/tabs'

## Remember the state of the last Jitsi call, except when there are no calls
## and resetJitsiStatusAfter seconds elapse; then reset to default state.
resetJitsiStatusAfter = 30  # seconds
defaultJitsiStatus = ->
  joined: false
  audioMuted: false
  videoMuted: false
lastJitsiStatus = defaultJitsiStatus()
timeoutJitsiStatus = null
numJitsi = 0  # number of joined Jitsi calls

parseJitsiUrl = (url) ->
  return {} unless url?
  parsed = new URL url
  host = parsed.host
  roomName = parsed.pathname
  roomName = roomName[1..] if roomName[0] == '/'
  parsed.pathname = '/external_api.js'
  script = parsed.toString()
  {host, roomName, script}

export TabJitsi = React.memo ({tabId, room}) ->
  tab = useTracker ->
    Tabs.findOne tabId
  , [tabId]
  {host, roomName, script} = parseJitsiUrl tab?.url
  [loading, error] = useScript
    src: script
    checkForExisting: true

  ref = useRef()  # div container for Jitsi iframe
  [joined, setJoined] = useState lastJitsiStatus.joined  # joined call?
  [api, setApi] = useState()  # JitsiMeetExternalAPI object
  name = useName()

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
          if getUI('dark') then '#111' else '#474747'
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
        displayName: name
    jitsi.addListener 'audioMuteStatusChanged', ({muted}) ->
      lastJitsiStatus.audioMuted = muted
    jitsi.addListener 'videoMuteStatusChanged', ({muted}) ->
      lastJitsiStatus.videoMuted = muted
    jitsi.addListener 'readyToClose', ->  # hangup call
      setJoined false
      ## Before hanging up, Jitsi mutes the video and emits an event, so we no
      ## longer know the correct Jitsi status.  So reset to default upon hangup.
      lastJitsiStatus = defaultJitsiStatus()
    ->  # cleanup
      jitsi?.dispose()
  , [tab?.url, loading, error, joined]

  ## Keep settings up-to-date
  useEffect ->
    api?.executeCommand 'displayName', name
    undefined
  , [name]
  useEffect ->
    api?.executeCommand 'subject', room.title
    undefined
  , [room.title]

  ## Maintain number of joined Jitsi calls, and reset state if zero and timeout.
  useEffect ->
    numJitsi++ if joined
    lastJitsiStatus.joined = (numJitsi > 0)
    if timeoutJitsiStatus?
      clearTimeout timeoutJitsiStatus
      timeoutJitsiStatus = null
    ->
      numJitsi-- if joined
      if numJitsi == 0 and resetJitsiStatusAfter?
        timeoutJitsiStatus = setTimeout ->
          timeoutJitsiStatus = null
          #lastJitsiStatus = defaultJitsiStatus()
          lastJitsiStatus.joined = defaultJitsiStatus().joined
        , resetJitsiStatusAfter * 1000
  , [joined]

  return null unless tab
  <div ref={ref}>
    {if error
      <Alert variant="danger">
        Failed to load <a href={script} target="_blank" rel="noopener">Jitsi external API script</a>.
        Is <a href={'https://' + host} target="_blank" rel="noopener">{host}</a> a valid Jitsi server?
      </Alert>
    else if not joined
      <Card>
        <Card.Body>
          <Card.Title>Jitsi Meeting</Card.Title>
          <p>
            <b>Server:</b> <a href={'https://' + host} target="_blank" rel="noopener"><code>{host}</code></a><br/>
            <b>Room ID:</b> <code>{roomName}</code>
          </p>
          <Button block onClick={-> setJoined true}>Join Call</Button>
          <p>When joining, you may need to grant access to your microphone and/or camera. If you want to try again, select the &ldquo;Reload Tab&rdquo; button at the top of this tab.</p>
          <p>If you hang up on the call and receive an ad, click the X button (at the top right of the ad) to fully leave the call, and prevent Comingle from automatically joining future Jitsi calls.</p>
        </Card.Body>
      </Card>
    else if loading
      <Loading/>
    }
  </div>
TabJitsi.displayName = 'TabJitsi'
