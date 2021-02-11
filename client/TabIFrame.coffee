import React, {useEffect, useRef, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import useEventListener from '@use-it/event-listener'

import {useName} from './Name'
import {useDark} from './Settings'
import {Tabs} from '/lib/tabs'

###
This list of features to re-enable starts from Chrome's disabled list:
https://dev.chromium.org/Home/chromium-security/deprecating-permissions-in-cross-origin-iframes
We also add the new Chrome feature `clipboard-write`
[https://crbug.com/1074489 / https://github.com/w3c/clipboard-apis/pull/120]
so that e.g. Cocreate has a working "copy link to clipboard" button.
###
allowList = [
  "camera"
  "microphone"
  "geolocation"
  "midi"
  "encrypted-media"
  "clipboard-write"
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
  dark = useDark()
  [coop, setCoop] = useState 0
  useEventListener 'message', (e) ->
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
