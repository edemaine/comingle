import React, {useState, useEffect, useReducer} from 'react'
import {useParams} from 'react-router-dom'
import FlexLayout from './FlexLayout'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus, faTimes, faRedoAlt} from '@fortawesome/free-solid-svg-icons'

import {Rooms} from '/lib/rooms'
import {Tabs} from '/lib/tabs'
import useLocalStorage from './lib/useLocalStorage.coffee'
import Loading from './Loading.coffee'
import TabNew from './TabNew'
import TabIFrame from './TabIFrame'
import TabJitsi from './TabJitsi'

tabTitle = (tab) ->
  tab.title or 'Untitled'
tabComponent = (tab) ->
  switch tab.type
    when 'jitsi'
      'TabJitsi'
    else # iframe, cocreate, youtube -- for now
      'TabIFrame'

export default Room = ({loading, roomId}) ->
  {meetingId} = useParams()
  [layout, setLayout] = useLocalStorage "layout.#{roomId}", {}, false, true
  [tabNews, replaceTabNew] = useReducer(
    (state, {id, tab}) -> state[id] = tab; state
  , {})
  {loading, room, tabs} = useTracker ->
    sub = Meteor.subscribe 'room', roomId
    tabs = Tabs.find(room: roomId).fetch()
    loading: loading or not sub.ready()
    room: Rooms.findOne roomId
    tabs: tabs
  [model, setModel] = useState()
  ## Initialize model according to saved layout
  useEffect ->
    return if loading or model?
    setModel FlexLayout.Model.fromJson
      global: {}
      borders: []
      layout: layout
  , [loading]
  ## Synchronize model with room
  id2tab = {}
  useEffect ->
    return unless model?
    id2tab[tab._id] = tab for tab in tabs
    lastTabSet = null
    actions = []  # don't modify model while traversing
    model.visitNodes (node) ->
      if node.getType() == 'tab'
        if tab = id2tab[node.getId()]
          ## Update tabs in both layout and room
          actions.push FlexLayout.Actions.updateNodeAttributes node.getId(),
            name: tabTitle tab
          delete id2tab[tab._id]
        else if node.getComponent() != 'TabNew'
          ## Delete tabs in stored layout that are no longer in room
          actions.push FlexLayout.Actions.deleteTab node.getId()
      lastTabSet = node if node.getType() == 'tabset'
    model.doAction action for action in actions
    ## Add tabs in room but not yet layout
    for id, tab of id2tab
      tab =
        id: tab._id
        type: 'tab'
        name: tabTitle tab
        component: tabComponent tab
        enableRename: true  # override TabNew
        enableClose: false
      if id of tabNews  # replace TabNew
        model.doAction FlexLayout.Actions.updateNodeAttributes \
          tabNews[id].getId(), tab
        delete tabNews[id]
      else
        model.doAction FlexLayout.Actions.addNode tab,
          lastTabSet.getId(), FlexLayout.DockLocation.CENTER, -1
    ## Start new tab in every empty tabset
    model.visitNodes (node) ->
      if node.getType() == 'tabset'
        if node.getChildren().length == 0
          tabNew node.getId()
    undefined
  , [model, tabs]
  ## End of hooks
  if loading or not model?  # Post-loading, useEffect needs a tick to set model
    return <Loading/>
  tabNew = (parent) ->
    return unless model?
    model.doAction FlexLayout.Actions.addNode
      type: 'tab'
      name: 'New Tab'
      component: 'TabNew'
      enableRename: false
    , parent, FlexLayout.DockLocation.CENTER, -1
  factory = (tab) ->
    switch tab.getComponent()
      when 'TabNew' then <TabNew {...{tab, meetingId, roomId, replaceTabNew}}/>
      when 'TabIFrame' then <TabIFrame tabId={tab.getId()}/>
      when 'TabJitsi' then <TabJitsi tabId={tab.getId()}/>
      when 'TabReload'
        model.doAction FlexLayout.Actions.updateNodeAttributes tab.getId(),
          component: tabComponent id2tab[tab.getId()]
        <Loading/>
  onRenderTab = (node, {buttons}) ->
    if node.isVisible() and node.getComponent() != 'TabNew'
      buttons.push \
        <div key="reload" className="flexlayout__tab_button_trailing"
         title="Reload Tab"
         onClick={(e) -> model.doAction \
           FlexLayout.Actions.updateNodeAttributes node.getId(),
             component: 'TabReload'}
         onMouseDown={(e) -> e.stopPropagation()}>
          <FontAwesomeIcon icon={faRedoAlt}/>
        </div>
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
  <FlexLayout.Layout model={model} factory={factory}
   onRenderTab={onRenderTab} onRenderTabSet={onRenderTabSet}
   onAction={onAction} onModelChange={-> setLayout model.toJson().layout}/>
