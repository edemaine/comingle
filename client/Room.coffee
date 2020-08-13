import React, {useState, useEffect, useReducer} from 'react'
import {useParams} from 'react-router-dom'
import FlexLayout from './FlexLayout'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus, faTimes} from '@fortawesome/free-solid-svg-icons'

import {Rooms} from '/lib/rooms'
import {Tabs} from '/lib/tabs'
import useLocalStorage from './lib/useLocalStorage.coffee'
import TabNew from './TabNew'
import TabIFrame from './TabIFrame'

###
export useLayoutModel = (roomId) ->
  [state, setState] = useLocalStorage "layout.#{roomId}", {}
  model = FlexLayout.Model.fromJson
    global:
      enableEdgeDock: false
      tabEnableRename: false
      #tabEnableFloat: true
      tabEnableClose: false
    layout: state
    borders: [
      type: 'border'
      location: 'bottom'
      children: []
    ]
  setModel = (model) -> setState model.layout
  [model, setModel]
###

initModel = ->
  model = FlexLayout.Model.fromJson
    global: {}
    borders: []
    layout:
      id: 'root'
      type: 'row'
      weight: 100
      children: []

tabTitle = (tab) ->
  tab.title or 'Untitled'

export default Room = ({loading, roomId}) ->
  {meetingId} = useParams()
  [model, setModel] = useState initModel
  [tabNews, replaceTabNew] = useReducer(
    (state, {id, tab}) -> state[id] = tab; state
  , {})
  {loading, room, tabs} = useTracker ->
    sub = Meteor.subscribe 'room', roomId
    tabs = Tabs.find(room: roomId).fetch()
    loading: loading or not sub.ready()
    room: Rooms.findOne roomId
    tabs: tabs
  useEffect ->
    return if loading
    id2tab = {}
    id2tab[tab._id] = tab for tab in tabs
    lastTabSet = null
    model.visitNodes (node) ->
      if node.getType() == 'tab'
        if tab = id2tab[node.getId()]
          model.doAction FlexLayout.Actions.updateNodeAttributes node.getId(),
            name: tabTitle tab
          delete id2tab[tab._id]
      lastTabSet = node if node.getType() == 'tabset'
    for id, tab of id2tab
      tab =
        id: tab._id
        type: 'tab'
        name: tabTitle tab
        component: 'TabIFrame'
        enableRename: true  # override TabNew
      if id of tabNews  # replace TabNew
        model.doAction FlexLayout.Actions.updateNodeAttributes \
          tabNews[id].getId(), tab
        delete tabNews[id]
      else
        model.doAction FlexLayout.Actions.addNode tab,
          lastTabSet.getId(), FlexLayout.DockLocation.CENTER, -1
    undefined
  , [loading, tabs]
  tabNew = (parent) ->
    model.doAction FlexLayout.Actions.addNode
      type: 'tab'
      name: 'New Tab'
      component: 'TabNew'
      enableRename: false
    , parent, FlexLayout.DockLocation.CENTER, -1
  ## Start new tab in empty room
  useEffect ->
    unless loading or tabs.length
      model.visitNodes (node) ->
        if node.getType() == 'tabset' and node.getChildren().length == 0
          tabNew node.getId()
  , [loading, tabs.length]
  factory = (tab) ->
    switch tab.getComponent()
      when 'TabNew' then <TabNew {...{tab, meetingId, roomId, replaceTabNew}}/>
      when 'TabIFrame' then <TabIFrame tabId={tab.getId()}/>
  onRenderTabSet = (node, {buttons}) ->
    buttons.push \
      <button key="add" className="flexlayout__tab_toolbar_button-fa"
       title="Add Tab" onClick={(e) -> tabNew node.getId()}>
        <FontAwesomeIcon icon={faPlus}/>
      </button>
  onAction = (action) ->
    switch action.type
      when FlexLayout.Actions.RENAME_TAB
        ## Sanitize tab title and push to other users
        action.data.text = action.data.text.trim()
        return unless action.data.text  # prevent empty title
        Meteor.call 'tabEdit',
          id: action.data.node
          title: action.data.text
    action
  <div className="room">
    <h1>{room?.title}</h1>
    <FlexLayout.Layout model={model} factory={factory}
     onRenderTabSet={onRenderTabSet} onAction={onAction}/>
  </div>
