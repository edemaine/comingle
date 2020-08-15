import React, {useRef} from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import FontAwesomeSVG from '@fortawesome/fontawesome-svg-core'
import {faTimes, faExpandArrowsAlt, faCompressArrowsAlt, faWindowRestore} \
  from '@fortawesome/free-solid-svg-icons'

export * from './lib/FlexLayout'
import {Actions, Layout as FlexLayout} from './lib/FlexLayout'

export Layout = (props) ->
  <FlexLayout {...props}
   icons={
     close: <FontAwesomeIcon icon={faTimes}/>
     maximize: <FontAwesomeIcon icon={faExpandArrowsAlt}/>
     restore: <FontAwesomeIcon icon={faCompressArrowsAlt}/>
     more: <FontAwesomeIcon icon={faWindowRestore} width="12px"/>
   }
  />

export forceSelectTab = (model, tab) ->
  tab = model.getNodeById tab if typeof tab == 'string'
  unless tab.getParent().getSelectedNode() == tab
    model.doAction Actions.selectTab tab.getId()
