import React, {useEffect, useRef, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import useScript from 'react-script-hook'
import {Alert} from 'react-bootstrap'

import {Loading} from './Loading'
import {useName} from './Name'
import {getDark} from './Settings'
import {Tabs} from '/lib/tabs'

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
  #[joined, setJoined] = useState false  # joined call?
  [api, setApi] = useState()  # JitsiMeetExternalAPI object
  name = useName()

  useEffect ->
    return unless tab?
    return if loading or error
    Jitsi = window.exports?.JitsiMeetExternalAPI ? window.JitsiMeetExternalAPI
    setApi jitsi = new Jitsi host,
      parentNode: ref.current
      roomName: roomName
      configOverwrite:
        # See https://github.com/jitsi/jitsi-meet/blob/master/config.js
        prejoinPageEnabled: false
        subject: room.title
        defaultRemoteDisplayName: 'Fellow Comingler'
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
      userInfo:
        displayName: name
    -> jitsi?.dispose()
  , [tab?.url, loading, error]
  ## Keep settings up-to-date
  useEffect ->
    api?.executeCommand 'displayName', name
  , [name]
  useEffect ->
    api?.executeCommand 'subject', room.title
  , [room.title]

  return null unless tab
  <div ref={ref}>
    {if error
      <Alert variant="danger">
        Failed to load <a href={script} target="_blank" rel="noopener">Jitsi external API script</a>.
        Is <a href={'https://' + host} target="_blank" rel="noopener">{host}</a> a valid Jitsi server?
      </Alert>
    else if loading
      <Loading/>
    }
  </div>
TabJitsi.displayName = 'TabJitsi'
