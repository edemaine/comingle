import React from 'react'
import {useTracker} from 'meteor/react-meteor-data'

import {Tabs} from '/lib/tabs'

export default TabIFrame = ({tabId}) ->
  tab = useTracker -> Tabs.findOne tabId
  return null unless tab
  <iframe src={tab.url}>
  </iframe>
