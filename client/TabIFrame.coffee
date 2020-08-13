import React, {useContext} from 'react'
import {useTracker} from 'meteor/react-meteor-data'

import {AppSettings} from './App'
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
  {name} = useContext AppSettings
  tab = useTracker -> Tabs.findOne tabId
  return null unless tab
  {type, url} = tab

  ## Force type if standard servers recognized
  type = 'cocreate' if /:\/\/cocreate.csail.mit.edu\b/.test url
  type = 'jitsi' if /:\/\/meet.jit.si\b/.test url

  ## YouTube URL mangling into embed link, based on examples from
  ## https://gist.github.com/rodrigoborgesdeoliveira/987683cfbfcc8d800192da1e73adc486
  url = url.replace ///
    ^ (?: http s? : )? \/\/
    (?: youtu\.be \/ |
      (?: www\. | m\. )? youtube (-nocookie)? .com
      \/ (?: v\/ | vi\/ | e\/ | (?: watch )? \? (?: feature=[^&]* & )? v i? = )
    )
    ( [\w\-]+ ) [^]*
  ///, (match, nocookie, video) ->
    type = 'youtube'
    "https://www.youtube#{nocookie ? ''}.com/embed/#{video}"

  switch type
    when 'jitsi'
      ###
      Encoding from _objectToURLParamsArray()
      as called by _objectToURLParamsArray() in
      https://github.com/jitsi/jitsi-meet/blob/master/react/features/base/util/uri.js
      as called by generateUrl()
      as called by JitsiMeetExternalAPI.constructor() in
      https://github.com/jitsi/jitsi-meet/blob/master/modules/API/external/external_api.js
      ###
      url += "#" + (
        for key, value of {
          jitsi_meet_external_api_id: 0
          'userInfo.displayName': name
          ###
          Interface config as defined in
          https://github.com/jitsi/jitsi-meet/blob/master/interface_config.js
          ###
          'interfaceConfig.TOOLBAR_BUTTONS': [
            'microphone', 'camera', 'closedcaptions', 'desktop',
            'embedmeeting', 'fullscreen', 'fodeviceselection', 'hangup',
            'profile', 'chat', 'recording', 'livestreaming', 'etherpad',
            'sharedvideo', 'settings', 'raisehand', 'videoquality',
            'filmstrip', 'feedback', 'stats', 'shortcuts',
            'tileview', 'videobackgroundblur', 'download', 'help',
            'mute-everyone'
            # omit 'security', 'invite'
          ]
        }
          "#{key}=#{encodeURIComponent JSON.stringify value}"
      ).join '&'
  <iframe src={url} allow={allow}>
  </iframe>
