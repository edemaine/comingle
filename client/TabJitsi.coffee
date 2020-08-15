import React, {useContext} from 'react'
import {useTracker} from 'meteor/react-meteor-data'

import {allow} from './TabIFrame'
import {AppSettings} from './App'
import {Tabs} from '/lib/tabs'

export default TabJitsi = ({tabId}) ->
  tab = useTracker -> Tabs.findOne tabId
  return null unless tab
  url = tab.url

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
      'userInfo.displayName': Session.get 'name'
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

  <iframe src={url} allow={allow}/>
