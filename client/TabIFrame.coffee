import React from 'react'
import {useTracker} from 'meteor/react-meteor-data'

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

export TabIFrame = ({tabId}) ->
  tab = useTracker -> Tabs.findOne tabId
  return null unless tab
  <iframe src={tab.url} allow={allow}/>
