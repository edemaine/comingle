import React, {useCallback, useEffect, useMemo, useRef, useState} from 'react'
import {useParams, useLocation, useHistory} from 'react-router-dom'
import {Tooltip, OverlayTrigger} from 'react-bootstrap'
import {Session} from 'meteor/session'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faCog, faComment, faDoorOpen, faQuestion} from '@fortawesome/free-solid-svg-icons'
import {clipboardLink} from './icons/clipboardLink'

import FlexLayout from './FlexLayout'
import {ChatRoom} from './ChatRoom'
import {RoomList} from './RoomList'
import {Room, setRoomTitle} from './Room'
import {Settings} from './Settings'
import {Welcome} from './Welcome'
import {useName} from './Name'
import {Presence} from '/lib/presence'
import {Rooms} from '/lib/rooms'
import {validId} from '/lib/id'
import {sameSorted} from '/lib/sort'
import {getPresenceId} from './lib/presenceId'
#import {useIdMap} from './lib/useIdMap'
import {useLocalStorage, useSessionStorage} from './lib/useLocalStorage'

export MeetingContext = React.createContext {}

welcomeTab =
  id: 'welcome'
  type: 'tab'
  name: 'Welcome'
  component: 'Welcome'
  enableRename: false

initModel = ->
  model = FlexLayout.Model.fromJson
    global: Object.assign {}, FlexLayout.defaultGlobal,
      borderEnableDrop: false
      tabSetEnableTabStrip: false
    borders: [
      type: 'border'
      location: 'left'
      selected: 0
      children: [
        id: 'roomsTab'
        type: 'tab'
        name: "Meeting Rooms"
        component: 'RoomList'
        enableClose: false
        enableDrag: false
      ,
        id: 'chat'
        type: 'tab'
        name: "Meeting Chat"
        component: 'ChatRoom'
        enableClose: false
        enableDrag: false
        enableRenderOnDemand: false
      ,
        id: 'settings'
        type: 'tab'
        name: "Settings"
        component: 'Settings'
        enableClose: false
        enableDrag: false
      ]
    ]
    layout:
      id: 'root'
      type: 'row'
      weight: 100
      children: [
        id: 'mainTabset'
        type: 'tabset'
        children: [welcomeTab]
      ]
  ###
  model.setOnAllowDrop (dragNode, dropInfo) ->
    #return false if dropInfo.node.getId() == 'roomsTabSet' and dropInfo.location != FlexLayout.DockLocation.RIGHT
    #return false if dropInfo.node.getType() == 'border'
    #return false if dragNode.getParent()?.getType() == 'border'
    true
  ###
  model

export Meeting = React.memo ->
  {meetingId} = useParams()
  model = useMemo initModel, []
  location = useLocation()
  history = useHistory()
  {loading, rooms} = useTracker ->
    sub = Meteor.subscribe 'meeting', meetingId
    loading: not sub.ready()
    rooms: Rooms.find().fetch()
  , [meetingId]
  #id2room = useIdMap rooms
  layoutRef = useRef null
  useEffect ->
    for room in rooms
      if model.getNodeById room._id
        model.doAction FlexLayout.Actions.updateNodeAttributes room._id,
          name: room.title
    undefined
  , [rooms]
  makeRoomTabJson = (id) ->
    id: id
    type: 'tab'
    name: Rooms.findOne(id)?.title ? id
    component: 'Room'
  openRoom = useCallback (id) ->
    ## Replaces current open room
    unless model.getNodeById id
      tabset = FlexLayout.getActiveTabset model
      oldRoom = tabset.getSelectedNode()
      model.doAction FlexLayout.Actions.addNode makeRoomTabJson(id),
        tabset.getId(), FlexLayout.DockLocation.CENTER, -1
      model.doAction FlexLayout.Actions.deleteTab oldRoom.getId() if oldRoom?
    else
      FlexLayout.forceSelectTab model, id
  , [model]
  openRoomWithDragAndDrop = (id, verb) ->
    json = makeRoomTabJson id
    if move = (model.getNodeById id)?
      json.id = 'placeholder'
      json.component = 'Welcome'
    layoutRef.current.addTabWithDragAndDrop \
      "#{verb} &ldquo;#{json.name}&rdquo; (drag to location)", json,
      ->
        return unless newNode = model.getNodeById json.id
        tabset = newNode.getParent()
        ## In move case, replace placeholder tab with actual tab
        if move
          model.doAction FlexLayout.Actions.moveNode id,
            tabset.getId(), FlexLayout.DockLocation.CENTER, -1
          model.doAction FlexLayout.Actions.deleteTab json.id
        ## Delete other tabs in tabset, as they aren't visible
        for child in tabset.getChildren() when child? and child.getId() != id
          model.doAction FlexLayout.Actions.deleteTab child.getId()
  useEffect ->
    if location.hash and validId id = location.hash[1..]
      openRoom id
    undefined
  , [location.hash]
  presenceId = getPresenceId()
  name = useName()

  ## `starredOld` is remembered across the browser (all tabs), and may contain
  ## a list of previously starred rooms.  In this case, `starredHasOld`
  ## starts true.  Once `changeStarred` gets called, though, `starredOld`
  ## mirrors `starred` and `starredHasOld` gets set to false.
  [starredOld, setStarredOld] = useLocalStorage "starredOld.#{meetingId}", []
  [starred, setStarred] = useSessionStorage "starred.#{meetingId}", []
  [starredHasOld, setStarredHasOld] = useState ->
    starredOld?.length and not sameSorted starred, starredOld
  updateStarred = (newStarred) ->
    setStarredHasOld false
    setStarredOld newStarred ? starred
    return unless newStarred?  # no argument means just remove old version
    setStarred newStarred

  updatePresence = ->
    return unless name?  # wait for tracker to load name
    presence =
      id: presenceId
      meeting: meetingId
      name: name
      rooms:
        joined: []
        starred: starred
    model.visitNodes (node) ->
      if node.getType() == 'tab' and node.getComponent() == 'Room'
        presence.rooms.joined.push node.getId()
    current = Presence.findOne
      id: presenceId
      meeting: meetingId
    unless current? and current.name == presence.name and
           current?.rooms?.joined?.toString?() ==
           presence.rooms.joined.toString() and
           current?.rooms?.starred?.toString?() ==
           presence.rooms.starred.toString()
      Meteor.call 'presenceUpdate', presence
  ## Send presence when name changes, when list of starred rooms changes, or
  ## when we reconnect to server (so server may have deleted our presence).
  useEffect updatePresence, [name, starred.join '\t']
  useTracker ->
    updatePresence() if Meteor.status().connected
  , []
  onAction = (action) ->
    switch action.type
      when FlexLayout.Actions.RENAME_TAB
        setRoomTitle action.data.node, action.data.text
    action
  [enableMaximize, setEnableMaximize] = useState false
  onModelChange = ->
    updatePresence()
    setEnableMaximize model._getAttribute 'tabSetEnableMaximize'
    ## Reopen Welcome screen if not in a room
    tabset = FlexLayout.getActiveTabset model
    if tabset? and not tabset.getChildren().length
      model.doAction FlexLayout.Actions.addNode welcomeTab, tabset.getId(),
        FlexLayout.DockLocation.CENTER, -1
    ## Maintain hash part of URL to point to "current" tab.
    tab = tabset?.getSelectedNode()
    if tab?.getComponent() == 'Room'
      unless location.hash == "##{tab.getId()}"
        history.replace "/m/#{meetingId}##{tab.getId()}"
      Session.set 'currentRoom', tab.getId()
    else
      if location.hash
        history.replace "/m/#{meetingId}"
      Session.set 'currentRoom', undefined
  
  factory = (node) -> # eslint-disable-line react/display-name
    updateTab = -> FlexLayout.updateNode model, node.getId()
    switch node.getComponent()
      when 'RoomList'
        <RoomList loading={loading} model={model}
         extraData={node.getExtraData()} updateTab={updateTab}/>
      when 'ChatRoom'
        <ChatRoom channel={meetingId} audience="everyone"
         visible={node.isVisible()}
         extraData={node.getExtraData()} updateTab={updateTab}/>
      when 'Settings'
        <Settings/>
      when 'Welcome'
        <Welcome/>
      when 'Room'
        <Room loading={loading} roomId={node.getId()}
         onClose={-> model.doAction FlexLayout.Actions.deleteTab node.getId()}
         enableMaximize={enableMaximize}
         maximized={node.getParent().isMaximized()}
         onMaximize={-> model.doAction FlexLayout.Actions.maximizeToggle \
           node.getParent().getId()}
         {...node.getConfig()}/>
  iconFactory = (node) -> # eslint-disable-line react/display-name
    if node.getComponent() == 'ChatRoom'
      <FontAwesomeIcon icon={faComment}/>
    else if node.getComponent() == 'Settings'
      <FontAwesomeIcon icon={faCog}/>
    else if node.getComponent() == 'Welcome'
      <FontAwesomeIcon icon={faQuestion}/>
    else
      <FontAwesomeIcon icon={faDoorOpen}/>
  onRenderTab = (node, renderState) ->
    type = if node.getParent().getType() == 'border' then 'border' else 'tab'
    buttons = renderState.buttons
    if node.getComponent() == 'RoomList'
      buttons?.push \
        <div key="link"
         className="flexlayout__#{type}_button_trailing"
         aria-label="Copy meeting link to clipboard"
         onClick={-> navigator.clipboard.writeText \
           Meteor.absoluteUrl "/m/#{meetingId}"}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <OverlayTrigger placement="right" overlay={(props) ->
            <Tooltip {...props}>Copy meeting link to clipboard</Tooltip>
          }>
            <FontAwesomeIcon icon={clipboardLink}/>
          </OverlayTrigger>
        </div>
      return RoomList.onRenderTab node, renderState
    else if node.getComponent() == 'ChatRoom'
      return ChatRoom.onRenderTab node, renderState

  <MeetingContext.Provider value={{openRoom, openRoomWithDragAndDrop, starred, starredOld, starredHasOld, updateStarred}}>
    <FlexLayout.Layout model={model} factory={factory} iconFactory={iconFactory}
     onRenderTab={onRenderTab}
     onAction={onAction} onModelChange={-> setTimeout onModelChange, 0}
     ref={layoutRef}
     tabPhrase="room"/>
  </MeetingContext.Provider>

Meeting.displayName = 'Meeting'
