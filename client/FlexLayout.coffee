import React, {forwardRef} from 'react'
import {Tooltip, OverlayTrigger} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faCompressArrowsAlt} from '@fortawesome/free-solid-svg-icons/faCompressArrowsAlt'
import {faExpandArrowsAlt} from '@fortawesome/free-solid-svg-icons/faExpandArrowsAlt'
import {faTimes} from '@fortawesome/free-solid-svg-icons/faTimes'
import {faWindowRestore} from '@fortawesome/free-solid-svg-icons/faWindowRestore'

export * from './lib/FlexLayout'
import {Actions, Layout as FlexLayout} from './lib/FlexLayout'
import {capitalize} from './lib/capitalize'

export defaultGlobal =
  tabSetTabStripHeight: 22

titleLimit = 20

export icons = (tabPhrase) ->
  close:
    <OverlayTrigger placement="bottom" overlay={(props) ->
      if tabPhrase == 'room'
        <Tooltip {props...}>
          Leave Room
          <div className="small">
            You can always rejoin by selecting the room from the list on the left.
          </div>
        </Tooltip>
      else
        <Tooltip {props...}>Close New Tab</Tooltip>
    }>
      <FontAwesomeIcon icon={faTimes} aria-label="Close New Tab"/>
    </OverlayTrigger>
  maximize:
    <OverlayTrigger placement="bottom" overlay={(props) ->
      <Tooltip {props...}>
        Maximize This {capitalize tabPhrase}
        <div className="small">
          Temporarily hide all other {tabPhrase}s to focus on this one.
        </div>
      </Tooltip>
    }>
      <FontAwesomeIcon icon={faExpandArrowsAlt}
      aria-label="Maximize This #{capitalize tabPhrase}"/>
    </OverlayTrigger>
  restore:
    <OverlayTrigger placement="bottom" overlay={(props) ->
      <Tooltip {props...}>
        Unmaximize This {capitalize tabPhrase}
        <div className="small">
          Restore all other {tabPhrase}s.
        </div>
      </Tooltip>
    }>
      <FontAwesomeIcon icon={faCompressArrowsAlt}
      aria-label="Unmaximize This #{capitalize tabPhrase}"/>
    </OverlayTrigger>
  more:
    <OverlayTrigger placement="bottom" overlay={(props) ->
      <Tooltip {props...}>
        Overflow {capitalize tabPhrase}s
        <div className="small">
          Some additional {tabPhrase}s are off-screen because of the limited width. Use this button to choose from a pop-up list, or scroll the {tabPhrase} bar.
        </div>
      </Tooltip>
    }>
      <FontAwesomeIcon icon={faWindowRestore} width="12px"
      aria-label="Overflow #{capitalize tabPhrase}s"/>
    </OverlayTrigger>

export Layout = React.memo forwardRef ({tabPhrase, ...props}, ref) ->
  ## Shorten titles that are longer than titleLimit.
  titleFactory = (node) ->
    title = node.getName()
    if title.length > titleLimit
      title = title[...titleLimit-1] + '…'
    title
  ## Disable maximization when a single tabset.
  onModelChange = (model) ->
    tabsets = getTabsets model
    ## Can't set this via model.doAction or else we get in an infinite loop:
    enableMaximize = (tabsets.length > 1)
    if enableMaximize != model._getAttribute 'tabSetEnableMaximize'
      model.doAction Actions.updateModelAttributes
        tabSetEnableMaximize: enableMaximize
    if tabsets.length == 1 and tabsets[0].isMaximized()
      model.doAction Actions.maximizeToggle tabsets[0].getId()
    props.onModelChange? model
  onModelChange props.model  # initialize
  <FlexLayout {...props}
   titleFactory={titleFactory}
   onModelChange={onModelChange}
   ref={ref}
   icons={icons tabPhrase}
   i18nMapper={(label) -> switch label
     when 'Close', 'Maximize', 'Restore' then null}
  />
Layout.displayName = 'Layout'

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

export updateNode = (model, id) ->
  model.doAction Actions.updateNodeAttributes id, {}
