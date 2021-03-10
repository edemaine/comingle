import React, {useEffect, useRef, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import useEventListener from '@use-it/event-listener'

import {useName} from './Name'
import {useUI} from './Settings'
import {Tabs} from '/lib/tabs'

###
See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Feature-Policy
This list of features to re-enable started from Chrome's disabled list:
https://dev.chromium.org/Home/chromium-security/deprecating-permissions-in-cross-origin-iframes
We also add the new Chrome feature `clipboard-write`
[https://crbug.com/1074489 / https://github.com/w3c/clipboard-apis/pull/120]
so that e.g. Cocreate has a working "copy link to clipboard" button.
###
allowList = [
  # Video conferencing e.g. Jitsi, Zoom
  "camera"
  "display-capture"
  "microphone"
  # Screen control e.g. YouTube
  "fullscreen"
  "wake-lock"
  "screen-wake-lock"
  # Sensors e.g. for games
  "accelerometer"
  "geolocation"
  "gyroscrope"
  "magnetometer"
  # Mobile
  "battery"
  "web-share"
  # Misc
  "clipboard-write" # Cocreate
  "encrypted-media"
  "midi"
]
export allow = allowList.join ';'

export TabIFrame = React.memo ({tabId}) ->
  tab = useTracker ->
    Tabs.findOne tabId
  , [tabId]
  return null unless tab
  ref = useRef()

  ## Send name to tab if it speaks coop protocol
  name = useName()
  dark = useUI("dark")
  [coop, setCoop] = useState 0
  useEventListener 'message', (e) ->
    return unless ref.current
    return unless e.source == ref.current.contentWindow
    return unless e.data?.coop
    setCoop coop + 1  # force update
  useEffect ->
    return unless ref.current
    return unless coop
    ref.current.contentWindow.postMessage
      coop: 1
      user: fullName: name
      theme: dark: dark
    , '*'
    undefined
  , [ref, name, dark, coop]

  <iframe ref={ref} src={tab.url} allow={allow}/>

TabIFrame.displayName = 'TabIFrame'
