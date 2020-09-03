import React, {useState, useEffect, useReducer, useMemo} from 'react'
import {useParams, useLocation, useHistory} from 'react-router-dom'
import {Tooltip, OverlayTrigger} from 'react-bootstrap'
import {Session} from 'meteor/session'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faComment, faDoorOpen, faEye, faEyeSlash, faQuestion} from '@fortawesome/free-solid-svg-icons'
import {clipboardLink} from './icons/clipboardLink'

import FlexLayout from './FlexLayout'
import {ArchiveButton} from './ArchiveButton'
import {ChatRoom} from './ChatRoom'
import {RoomList} from './RoomList'
import {Room} from './Room'
import {Rooms} from '/lib/rooms'
import {Welcome} from './Welcome'
import {Presence} from '/lib/presence'
import {validId} from '/lib/id'
import {getPresenceId, getCreator} from './lib/presenceId'
import {useIdMap} from './lib/useIdMap'
import {formatDateTime} from './lib/dates'

export MeetingContext = React.createContext {}

initModel = ->
  model = FlexLayout.Model.fromJson
    global: Object.assign {}, FlexLayout.defaultGlobal,
      borderEnableDrop: false
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
      ]
    ]
    layout:
      id: 'root'
      type: 'row'
      weight: 100
      children: [
        id: 'mainTabset'
        type: 'tabset'
        children: [
          id: 'welcome'
          type: 'tab'
          name: 'Welcome'
          component: 'Welcome'
        ]
      ]
  model.setOnAllowDrop (dragNode, dropInfo) ->
    return false if dropInfo.node.getId() == 'roomsTabSet' and dropInfo.location != FlexLayout.DockLocation.RIGHT
    #return false if dropInfo.node.getType() == 'border'
    #return false if dragNode.getParent()?.getType() == 'border'
    true
  model

export Meeting = ->
  {meetingId} = useParams()
  [model, setModel] = useState initModel
  location = useLocation()
  history = useHistory()
  {loading, rooms} = useTracker ->
    sub = Meteor.subscribe 'meeting', meetingId
    loading: not sub.ready()
    rooms: Rooms.find().fetch()
  id2room = useIdMap rooms
  useEffect ->
    for room in rooms
      if model.getNodeById room._id
        model.doAction FlexLayout.Actions.updateNodeAttributes room._id,
          name: room.title
    undefined
  , [rooms]
  openRoom = useMemo -> (id, focus = true) ->
    tabset = FlexLayout.getActiveTabset model
    unless model.getNodeById id
      tab =
        id: id
        type: 'tab'
        name: Rooms.findOne(id)?.title ? id
        component: 'Room'
        config: showArchived: false
      model.doAction FlexLayout.Actions.addNode tab,
        tabset.getId(), FlexLayout.DockLocation.CENTER, -1, focus
    else
      FlexLayout.forceSelectTab model, id
  useEffect ->
    if location.hash and validId id = location.hash[1..]
      openRoom id
    undefined
  , [location.hash]
  [showArchived, setShowArchived] = useReducer(
    (state, {id, value}) ->
      if model.getNodeById id
        model.doAction FlexLayout.Actions.updateNodeAttributes id,
          config: showArchived: value
      state[id] = value
      state
  , {})
  presenceId = getPresenceId()
  name = useTracker -> Session.get 'name'
  updatePresence = ->
    return unless name?  # wait for tracker to load name
    presence =
      id: presenceId
      meeting: meetingId
      name: name
      rooms:
        visible: []
        invisible: []
    model.visitNodes (node) ->
      if node.getType() == 'tab' and node.getComponent() == 'Room'
        if node.isVisible()
          presence.rooms.visible.push node.getId()
        else
          presence.rooms.invisible.push node.getId()
    current = Presence.findOne
      id: presenceId
      meeting: meetingId
    unless current? and current.name == presence.name and
           current?.rooms?.visible?.toString?() ==
           presence.rooms.visible.toString() and
           current?.rooms?.invisible?.toString?() ==
           presence.rooms.invisible.toString()
      Meteor.call 'presenceUpdate', presence
  ## Send presence when name changes or when we reconnect to server
  ## (so server may have deleted our presence information).
  useEffect updatePresence, [name]
  useTracker -> updatePresence() if Meteor.status().connected
  onAction = (action) ->
    switch action.type
      when FlexLayout.Actions.RENAME_TAB
        ## Sanitize room title and push to other users
        action.data.text = action.data.text.trim()
        return unless action.data.text  # prevent empty title
        Meteor.call 'roomEdit',
          id: action.data.node
          title: action.data.text
          updator: getCreator()
    action
  onModelChange = ->
    updatePresence()
    ## Maintain hash part of URL to point to "current" tab.
    tabset = FlexLayout.getActiveTabset model
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
    switch node.getComponent()
      when 'RoomList'
        <RoomList loading={loading} model={model}/>
      when 'ChatRoom'
        <ChatRoom channel={meetingId} audience="everyone"
         visible={node.isVisible()} extraData={node.getExtraData()}
         updateTab={-> FlexLayout.updateNode model, node.getId()}/>
      when 'Welcome'
        <Welcome/>
      when 'Room'
        if node.isVisible()
          <Room loading={loading} roomId={node.getId()} {...node.getConfig()}/>
        else
          null  # don't render hidden rooms, in particular to cancel all calls
  tooltip = (node) -> (props) -> # eslint-disable-line react/display-name
    room = id2room[node.getId()]
    return <span/> unless room
    <Tooltip {...props}>
      Room &ldquo;{room.title}&rdquo;<br/>
      created by {room.creator?.name ? 'unknown'}<br/>
      on {formatDateTime room.created}
      {if room.archived
        <>
          <br/>archived by {room.archiver?.name ? 'unknown'}
          <br/>on {formatDateTime room.archived}
        </>
      }
    </Tooltip>
  iconFactory = (node) -> # eslint-disable-line react/display-name
    <OverlayTrigger placement="bottom" overlay={tooltip node}>
      {if node.getComponent() == 'ChatRoom'
        <FontAwesomeIcon icon={faComment}/>
      else if node.getComponent() == 'Welcome'
        <FontAwesomeIcon icon={faQuestion}/>
      else
        <FontAwesomeIcon icon={faDoorOpen}/>
      }
    </OverlayTrigger>
  onRenderTab = (node, renderState) ->
    type = if node.getParent().getType() == 'border' then 'border' else 'tab'
    buttons = renderState.buttons
    if node.getComponent() == 'RoomList'
      buttons?.push \
        <div key="link"
         className="flexlayout__#{type}_button_trailing"
         aria-label="Save meeting link to clipboard"
         onClick={-> navigator.clipboard.writeText \
           Meteor.absoluteUrl "/m/#{meetingId}"}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <OverlayTrigger placement="bottom" overlay={(props) ->
            <Tooltip {...props}>Save meeting link to clipboard</Tooltip>
          }>
            <FontAwesomeIcon icon={clipboardLink}/>
          </OverlayTrigger>
        </div>
    else if node.getComponent() == 'ChatRoom'
      return ChatRoom.onRenderTab node, renderState
    return if node.getComponent() != 'Room'
    room = id2room[node.getId()]
    return unless room
    className = 'tab-title'
    className += ' archived' if room.archived
    renderState.content =
      <OverlayTrigger placement="bottom" overlay={tooltip node}>
        <span className={className}>{renderState.content}</span>
      </OverlayTrigger>
    if node.isVisible()  # special buttons for visible tabs
      id = node.getId()
      buttons?.push \
        <div key="link"
         className="flexlayout__#{type}_button_trailing flexlayout__tab_button_link"
         aria-label="Save room link to clipboard"
         onClick={-> navigator.clipboard.writeText \
           Meteor.absoluteUrl "/m/#{meetingId}##{node.getId()}"}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <OverlayTrigger placement="bottom" overlay={(props) ->
            <Tooltip {...props}>Save room link to clipboard</Tooltip>
          }>
            <FontAwesomeIcon icon={clipboardLink}/>
          </OverlayTrigger>
        </div>
      showArchived = node.getConfig()?.showArchived
      label =
        if showArchived
          "Hide Archived Tabs"
        else
          "Show Archived Tabs"
      buttons?.push \
        <div key="archived"
         className="flexlayout__#{type}_button_trailing"
         aria-label={label}
         onClick={-> setShowArchived {id, value: not showArchived}}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <OverlayTrigger placement="bottom" overlay={(props) ->
            <Tooltip {...props}>
              {label}<br/>
              <small>Currently {unless showArchived then <b>not</b>} showing archived tabs.</small>
            </Tooltip>
          }>
            <FontAwesomeIcon icon={if showArchived then faEye else faEyeSlash}/>
          </OverlayTrigger>
        </div>
      archiveRoom = ->
        Meteor.call 'roomEdit',
          id: room._id
          archived: not room.archived
          updator: getCreator()
      if room = id2room[id]
        buttons?.push <ArchiveButton key="archive" type={type} noun="room"
          archived={room.archived} onClick={archiveRoom}
          help="Archived rooms can still be viewed and restored from the list at the bottom."
        />
  <MeetingContext.Provider value={{openRoom}}>
    <FlexLayout.Layout model={model} factory={factory} iconFactory={iconFactory}
     onRenderTab={onRenderTab}
     onAction={onAction} onModelChange={-> setTimeout onModelChange, 0}
     tabPhrase="room"/>
  </MeetingContext.Provider>
Meeting.displayName = 'Meeting'
