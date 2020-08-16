import React, {useRef} from 'react'
import {Tooltip, OverlayTrigger} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import FontAwesomeSVG from '@fortawesome/fontawesome-svg-core'
import {faTimes, faExpandArrowsAlt, faCompressArrowsAlt, faWindowRestore} \
  from '@fortawesome/free-solid-svg-icons'

export * from './lib/FlexLayout'
import {Actions, Layout as FlexLayout} from './lib/FlexLayout'
import {capitalize} from './lib/capitalize'

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
     close:
       <OverlayTrigger placement="bottom" overlay={(tipProps) ->
         if props.tabPhrase == 'room'
           <Tooltip {tipProps...}>
             Leave Room<br/>
             <small>You can always rejoin by selecting the room from the list on the left.</small>
           </Tooltip>
         else
           <Tooltip {tipProps...}>Close New Tab</Tooltip>
       }>
         <FontAwesomeIcon icon={faTimes}/>
       </OverlayTrigger>
     maximize:
       <OverlayTrigger placement="bottom" overlay={(tipProps) ->
         <Tooltip {tipProps...}>
           Maximize This {capitalize props.tabPhrase}<br/>
           <small>Temporarily hide all other {props.tabPhrase}s to focus on this one.</small>
         </Tooltip>
       }>
         <FontAwesomeIcon icon={faExpandArrowsAlt}/>
       </OverlayTrigger>
     restore:
       <OverlayTrigger placement="bottom" overlay={(tipProps) ->
         <Tooltip {tipProps...}>
           Unmaximize This {capitalize props.tabPhrase}<br/>
           <small>Restore all other {props.tabPhrase}s.</small>
         </Tooltip>
       }>
         <FontAwesomeIcon icon={faCompressArrowsAlt}/>
       </OverlayTrigger>
     more:
       <OverlayTrigger placement="bottom" overlay={(tipProps) ->
         <Tooltip {tipProps...}>
           Overflow {capitalize props.tabPhrase}s<br/>
           <small>Some additional {props.tabPhrase}s are hiding here because of the limited width.<br/>Select to see the list.</small>
         </Tooltip>
       }>
         <FontAwesomeIcon icon={faWindowRestore} width="12px"/>
       </OverlayTrigger>
   }
   i18nMapper={(label) -> switch label
     when 'Close', 'Maximize', 'Restore' then null}
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

export getTabsets = (model) ->
  tabsets = []
  model.visitNodes (node) ->
    if node.getType() == 'tabset'
      tabsets.push node
  tabsets
