import React from 'react'
import {useTracker} from 'meteor/react-meteor-data'

import {Tabs} from '/lib/tabs'

## This list of features to re-enable is from
## https://dev.chromium.org/Home/chromium-security/deprecating-permissions-in-cross-origin-iframes
allowList = [
  "camera"
  "microphone"
  "geolocation"
  "midi"
  "encrypted-media"
]
allow = allowList.join ';'

export default TabIFrame = ({tabId}) ->
  tab = useTracker -> Tabs.findOne tabId
  return null unless tab
  <iframe src={tab.url} allow={allow}>
  </iframe>
