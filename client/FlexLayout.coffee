import React, {useRef} from 'react'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import FontAwesomeSVG from '@fortawesome/fontawesome-svg-core'
import {faTimes, faExpandArrowsAlt, faCompressArrowsAlt, faWindowRestore} \
  from '@fortawesome/free-solid-svg-icons'

export * from './lib/FlexLayout'
import {Actions, Layout as FlexLayout} from './lib/FlexLayout'

titleLimit = 20

export Layout = (props) ->
  titleFactory = (node) ->
    title = node.getName()
    if title.length > titleLimit
      title = title[...titleLimit-1] + '…'
    title
  <FlexLayout {...props}
   titleFactory={titleFactory}
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

export getActiveTabset = (model) ->
  tabset = model.getActiveTabset()
  unless tabset  # if active tabset closed, take another tabset if exists
    model.visitNodes (node) ->
      if node.getType() == 'tabset'
        tabset = node
  tabset
