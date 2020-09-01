import React, {useState, useEffect, useReducer, useRef} from 'react'
import {useParams} from 'react-router-dom'
import FlexLayout from './FlexLayout'
import {Tooltip, OverlayTrigger} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faComment, faPlus, faRedoAlt, faVideo, faSignInAlt} from '@fortawesome/free-solid-svg-icons'
import {faYoutube} from '@fortawesome/free-brands-svg-icons'

import {Rooms} from '/lib/rooms'
import {Tabs, tabTypes} from '/lib/tabs'
import {getCreator} from './lib/presenceId'
import {useLocalStorage} from './lib/useLocalStorage'
import {useIdMap} from './lib/useIdMap'
import {formatDateTime} from './lib/dates'
import {Loading} from './Loading'
import {ChatRoom} from './ChatRoom'
import {TabNew} from './TabNew'
import {TabIFrame} from './TabIFrame'
import {TabJitsi} from './TabJitsi'
import {TabZoom} from './TabZoom'
import {ArchiveButton} from './ArchiveButton'

tabTitle = (tab) ->
  tab.title or 'Untitled'
tabComponent = (tab) ->
  switch tab.type
    when 'jitsi'
      'TabJitsi'
    when 'zoom'
      'TabZoom'
    else # iframe, cocreate, youtube -- for now
      'TabIFrame'
tabIcon = (tab) -> # eslint-disable-line react/display-name
  switch tab?.type  # undefined for TabNew
    when 'jitsi'
      <FontAwesomeIcon icon={faVideo}/>
    when 'youtube'
      <FontAwesomeIcon icon={faYoutube}/>
    else
      null

export Room = ({loading, roomId, showArchived}) ->
  {meetingId} = useParams()
  [layout, setLayout] = useLocalStorage "layout.#{roomId}", {}, false, true
  [tabNews, replaceTabNew] = useReducer(
    (state, {id, node}) -> state[id] = node; state
  , {})
  {loading, room, tabs} = useTracker ->
    sub = Meteor.subscribe 'room', roomId
    query = room: roomId
    query.archived = $in: [null, false] unless showArchived
    tabs = Tabs.find(query).fetch()
    loading: loading or not sub.ready()
    room: Rooms.findOne roomId
    tabs: tabs
  id2tab = useIdMap tabs
  existingTabTypes = useIdMap tabs, 'type'
  tabsetUsed = useRef {}
  ## Initialize model according to saved layout
  [model, setModel] = useState()
  useEffect ->
    return if loading or model?
    setModel FlexLayout.Model.fromJson
      global: FlexLayout.defaultGlobal
      borders: [
        type: 'border'
        location: 'right'
        selected: -1  # chat closed by default
        children: [
          id: 'chat'
          type: 'tab'
          name: "Room Chat"
          component: 'ChatRoom'
          enableClose: false
          enableDrag: false
        ]
      ]
      layout: layout
  , [loading]
  ## Automatic tab layout algorithm.
  direction = (tabset, keepVisible) ->
    rect = tabset.getRect()
    if rect.width < rect.height  # taller than wide
      if keepVisible
        FlexLayout.DockLocation.TOP
      else
        FlexLayout.DockLocation.BOTTOM
    else                         # wider than tall
      if keepVisible
        FlexLayout.DockLocation.RIGHT
      else
        FlexLayout.DockLocation.LEFT
  tabDefaultLocation = (tab) ->
    if tabTypes[tab.type]?.keepVisible
      ## New tab is keepVisible; make sure it's in a tabset by itself.
      if tabNews[tab._id]?
        ## User added this tab via TabNew interface.
        ## If the TabNew is alone in its tabset, replace it there;
        ## otherwise, delete TabNew and add to right/bottom of its tabset.
        parent = tabNews[tab._id].getParent()
        if parent.getChildren().length == 1
          null
        else
          model.doAction FlexLayout.Actions.deleteTab tabNews[tab._id].getId()
          delete tabNews[tab._id]
          [parent.getId(), direction(parent, true), -1]
      else
        ## Automatic layout: add to the right/bottom of the last tabset.
        parent = FlexLayout.getTabsets(model).pop()
        [parent.getId(), direction(parent, true), -1]
    else
      ## New tab is not keepVisible.  Avoid hiding any keepVisible tabs.
      if tabNews[tab._id]?
        ## User added this tab via TabNew interface.  In-place replacement,
        ## unless there's a keepVisible tab adjacent in the same tabset.
        ## (For example, new room with just a Jitsi call and we add a tab.)
        siblings = tabNews[tab._id].getParent().getChildren()
        index = siblings.indexOf tabNews[tab._id]
        if (index == 0 or not
            tabTypes[id2tab[siblings[index-1].getId()]?.type]?.keepVisible) and
           (index == siblings.length-1 or not
            tabTypes[id2tab[siblings[index+1].getId()]?.type]?.keepVisible)
          return null
        ## Delete TabNew now, which may reveal keepVisible sibling.
        model.doAction FlexLayout.Actions.deleteTab tabNews[tab._id].getId()
        delete tabNews[tab._id]
      ## Append non-keepVisible tab to least recently used tabset
      ## that does not have a keepVisible tab visible, if one exists.
      freeTabsets = []
      tabsets = FlexLayout.getTabsets model
      for tabset in tabsets
        unless tabTypes[id2tab[tabset.getSelectedNode()?.getId()]?.type]?.keepVisible
          freeTabsets.push tabset.getId()
      if freeTabsets.length
        oldest = freeTabsets[0]
        if tabsetUsed.current[oldest]? # not in tabsetUsed = infinitely old
          for tabset in freeTabsets[1..]
            if not tabsetUsed.current[tabset]? or
               tabsetUsed.current[tabset] < tabsetUsed.current[oldest]
              oldest = tabset
        location = [oldest, FlexLayout.DockLocation.CENTER, -1]
      else
        ## Otherwise, add to the left/top of first tabset.
        location = [tabsets[0].getId(), direction(tabsets[0], false), -1]
  ## Synchronize model with room
  useEffect ->
    return unless model?
    actions = []  # don't modify model while traversing
    laidOut = {}
    tabSettings = (tab) ->
      name: tabTitle tab
      component: tabComponent tab
      enableRename: true  # override TabNew
      enableClose: false
      enableRenderOnDemand: not tabTypes[tab.type]?.alwaysRender
    model.visitNodes (node) ->
      if node.getType() == 'tab'
        if tab = id2tab[node.getId()]
          ## Update tabs in both layout and room
          actions.push FlexLayout.Actions.updateNodeAttributes node.getId(),
            tabSettings tab
          laidOut[tab._id] = true
        else if node.getComponent() not in ['TabNew', 'ChatRoom']
          ## Delete tabs in stored layout that are no longer in room
          actions.push FlexLayout.Actions.deleteTab node.getId()
    model.doAction action for action in actions
    ## Add tabs in room but not yet layout
    for id, tab of id2tab when not laidOut[id]
      tabLayout = tabSettings tab
      tabLayout.id = tab._id
      tabLayout.type = 'tab'
      location = tabDefaultLocation tab, tabNews[id]
      if tabNews[id]?  # replace TabNew
        model.doAction FlexLayout.Actions.updateNodeAttributes \
          tabNews[id].getId(), tabLayout
        delete tabNews[id]
      else
        model.doAction FlexLayout.Actions.addNode tabLayout, ...location
        if tabTypes[tab.type]?.alwaysRender
          FlexLayout.forceSelectTab model, tabLayout.id
        model.doAction FlexLayout.Actions.setActiveTabset location
    ## Start new tab in every empty tabset
    for tabset in FlexLayout.getTabsets model
      if tabset.getChildren().length == 0
        tabNew tabset
    undefined
  , [model, tabs]
  ## End of hooks
  if loading or not model?  # Post-loading, useEffect needs a tick to set model
    return <Loading/>
  tabNew = (parent) ->
    return unless model?
    ## Add TabNew to the clicked tabset, unless it has a keepVisible tab
    ## showing, in which case put it in the algorithm's default location.
    if tabTypes[id2tab[parent.getSelectedNode?()?.getId?()]?.type]?.keepVisible
      location = tabDefaultLocation {}
    else
      location = [parent.getId(), FlexLayout.DockLocation.CENTER, -1]
    model.doAction FlexLayout.Actions.addNode
      type: 'tab'
      name: 'New Tab'
      component: 'TabNew'
      enableRename: false
    , ...location
  factory = (node) -> # eslint-disable-line react/display-name
    switch node.getComponent()
      when 'ChatRoom' then <ChatRoom channel={roomId} audience="room"/>
      when 'TabIFrame' then <TabIFrame tabId={node.getId()}/>
      when 'TabJitsi' then <TabJitsi tabId={node.getId()} room={room}/>
      when 'TabZoom' then <TabZoom tabId={node.getId()} room={room}/>
      when 'TabNew'
        <TabNew {...{node, meetingId, roomId,
                     replaceTabNew, existingTabTypes}}/>
      when 'TabReload'
        model.doAction FlexLayout.Actions.updateNodeAttributes node.getId(),
          component: tabComponent id2tab[node.getId()]
        <Loading/>
  iconFactory = (node) -> # eslint-disable-line react/display-name
    if node.getComponent() == 'ChatRoom'
      icon = <FontAwesomeIcon icon={faComment}/>
    else
      icon = tabIcon id2tab[node.getId()]
    return icon unless icon?
    <OverlayTrigger placement="bottom" overlay={tooltip node}>
      {icon}
    </OverlayTrigger>
  tooltip = (node) -> (props) -> # eslint-disable-line react/display-name
    tab = id2tab[node.getId()]
    return <span/> unless tab
    <Tooltip {...props}>
      Tab &ldquo;{tab.title}&rdquo;<br/>
      <code>{tab.url}</code><br/>
      created by {tab.creator?.name ? 'unknown'}<br/>
      on {formatDateTime tab.created}
      {if tab.archived
        <i>
          <br/>archived by {tab.archiver?.name ? 'unknown'}
          <br/>on {formatDateTime tab.archived}
        </i>
      }
    </Tooltip>
  onRenderTab = (node, renderState) ->
    return if node.getComponent() == 'TabNew'
    tab = id2tab[node.getId()]
    return unless tab
    renderState.content =
      <OverlayTrigger placement="bottom" overlay={tooltip node}>
        <span className="tab-title">{renderState.content}</span>
      </OverlayTrigger>
    if node.isVisible()  # special buttons for visible tabs
      buttons = renderState.buttons
      type = if node.getParent().getType() == 'border' then 'border' else 'tab'
      if url = tab.url
        buttons?.push \
          <div key="link"
           className="flexlayout__#{type}_button_trailing"
           aria-label="Open in separate browser tab"
           onClick={-> navigator.clipboard.writeText url}
           onMouseDown={(e) -> e.stopPropagation()}
           onTouchStart={(e) -> e.stopPropagation()}>
            <OverlayTrigger placement="bottom" overlay={(props) ->
              <Tooltip {...props}>
                Open in separate browser tab<br/>
                <small>Or right click for more browser options.</small>
              </Tooltip>
            }>
              <a href={url} target="_blank" rel="noopener">
                <FontAwesomeIcon icon={faSignInAlt}/>
              </a>
            </OverlayTrigger>
          </div>
        ###
        buttons?.push \
          <div key="link"
           className="flexlayout__#{type}_button_trailing flexlayout__tab_button_link"
           aria-label="Save tab URL to clipboard"
           onClick={-> navigator.clipboard.writeText url}
           onMouseDown={(e) -> e.stopPropagation()}
           onTouchStart={(e) -> e.stopPropagation()}>
            <OverlayTrigger placement="bottom" overlay={(props) ->
              <Tooltip {...props}>Save tab URL to clipboard</Tooltip>
            }>
              <FontAwesomeIcon icon={clipboardLink}/>
            </OverlayTrigger>
          </div>
        ###
      buttons?.push \
        <div key="reload" className="flexlayout__#{type}_button_trailing"
         aria-label="Reload Tab"
         onClick={-> model.doAction \
           FlexLayout.Actions.updateNodeAttributes node.getId(),
             component: 'TabReload'}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <OverlayTrigger placement="bottom" overlay={(props) ->
            <Tooltip {...props}>
              Reload Tab<br/>
              <small>If it's not working, try rebooting.</small>
            </Tooltip>
          }>
            <FontAwesomeIcon icon={faRedoAlt}/>
          </OverlayTrigger>
        </div>
      archiveTab = ->
        Meteor.call 'tabEdit',
          id: tab._id
          archived: not tab.archived
          updator: getCreator()
      buttons?.push <ArchiveButton key="archive" type={type} noun="tab"
        archived={tab.archived} onClick={archiveTab}
        help="Archived tabs can still be restored using the room's eye icon."
      />
  onRenderTabSet = (node, {buttons}) ->
    return if node.getType() == 'border'
    buttons.push \
      <OverlayTrigger key="add" placement="bottom" overlay={(tipProps) ->
        <Tooltip {tipProps...}>
          Add Tab<br/>
          <small>Add shared tab to room: web page, whiteboard, video conference, etc.</small>
        </Tooltip>
      }>
        <button className="flexlayout__tab_toolbar_button-fa"
         aria-label="Add Tab"
         onClick={-> tabNew node}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <FontAwesomeIcon icon={faPlus}/>
        </button>
      </OverlayTrigger>
  onAction = (action) ->
    switch action.type
      when FlexLayout.Actions.RENAME_TAB
        ## Sanitize tab title and push to other users
        action.data.text = action.data.text.trim()
        return unless action.data.text  # prevent empty title
        Meteor.call 'tabEdit',
          id: action.data.node
          title: action.data.text
          updator: getCreator()
    action
  onModelChange = ->
    ## Update localstorage saved layout whenever layout changes.
    setLayout model.toJson().layout
    ## Track when each tabset was active.
    if tabset = model.getActiveTabset()
      tabsetUsed.current[tabset.getId()] = (new Date).getTime()
  <FlexLayout.Layout model={model} factory={factory} iconFactory={iconFactory}
   onRenderTab={onRenderTab} onRenderTabSet={onRenderTabSet}
   onAction={onAction} onModelChange={onModelChange} tabPhrase="tab"/>
Room.displayName = 'Room'
