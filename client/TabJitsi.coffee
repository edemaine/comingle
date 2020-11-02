import React from 'react'
import {useTracker} from 'meteor/react-meteor-data'

import {allow} from './TabIFrame'
import {getName} from './Name'
import {getDark} from './Settings'
import {Tabs} from '/lib/tabs'

export TabJitsi = ({tabId, room}) ->
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
      'userInfo.displayName': getName()
      ###
      Config as defined in
      https://github.com/jitsi/jitsi-meet/blob/master/config.js
      ###
      'config.prejoinPageEnabled': false
      'config.subject': room.title
      ###
      Interface config as defined in
      https://github.com/jitsi/jitsi-meet/blob/master/interface_config.js
      ###
      'interfaceConfig.DEFAULT_BACKGROUND':
        if getDark() then '#111' else '#474747'
      'interfaceConfig.DISABLE_VIDEO_BACKGROUND': true
      'interfaceConfig.TOOLBAR_BUTTONS': [
        'microphone', 'camera', 'closedcaptions', 'desktop',
        'embedmeeting', 'fullscreen', 'fodeviceselection', 'hangup',
        'profile', 'recording', 'livestreaming', 'etherpad',
        'settings', 'videoquality', 'filmstrip', 'feedback', 'stats',
        'shortcuts', 'tileview', 'videobackgroundblur', 'download', 'help',
        'mute-everyone'
      ] # omit 'chat', 'security', 'invite', 'raisehand', 'sharedvideo' [YouTube]
      'interfaceConfig.SETTINGS_SECTIONS': [
        'devices', 'language', 'moderator'
      ] # omit 'profile' and 'calendar'
      'interfaceConfig.DISPLAY_WELCOME_PAGE_CONTENT': false
      'interfaceConfig.SHOW_CHROME_EXTENSION_BANNER': false
      'interfaceConfig.HIDE_INVITE_MORE_HEADER': true
      'interfaceConfig.RECENT_LIST_ENABLED': false
      'interfaceConfig.DEFAULT_REMOTE_DISPLAY_NAME': 'Fellow Comingler'
    }
      "#{key}=#{encodeURIComponent JSON.stringify value}"
  ).join '&'

  <iframe src={url} allow={allow}/>
TabJitsi.displayName = 'TabJitsi'
