import React, {useState, useEffect, useReducer} from 'react'
import {useParams} from 'react-router-dom'
import FlexLayout from './FlexLayout'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus, faTimes, faRedoAlt, faVideo} from '@fortawesome/free-solid-svg-icons'
import {faYoutube} from '@fortawesome/free-brands-svg-icons'

import {Rooms} from '/lib/rooms'
import {Tabs, tabTypes} from '/lib/tabs'
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
tabIcon = (tab) ->
  switch tab?.type  # undefined for TabNew
    when 'jitsi'
      <FontAwesomeIcon icon={faVideo}/>
    when 'youtube'
      <FontAwesomeIcon icon={faYoutube}/>
    else
      null
tabDefaultLocation = (tab) ->
  switch tab.type
    when 'jitsi'
      'border_right'
    else
      'lastTabSet'

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
  id2tab = {}
  id2tab[tab._id] = tab for tab in tabs
  [model, setModel] = useState()
  ## Initialize model according to saved layout
  useEffect ->
    return if loading or model?
    setModel FlexLayout.Model.fromJson
      global: {}
      borders: [
        type: 'border'
        location: 'right'
        children: []
      ]
      layout: layout
  , [loading]
  ## Synchronize model with room
  useEffect ->
    return unless model?
    lastTabSet = null
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
        else if node.getComponent() != 'TabNew'
          ## Delete tabs in stored layout that are no longer in room
          actions.push FlexLayout.Actions.deleteTab node.getId()
      lastTabSet = node if node.getType() == 'tabset'
    model.doAction action for action in actions
    ## Add tabs in room but not yet layout
    for id, tab of id2tab when not laidOut[id]
      tabLayout = tabSettings tab
      tabLayout.id = tab._id
      tabLayout.type = 'tab'
      if id of tabNews  # replace TabNew
        model.doAction FlexLayout.Actions.updateNodeAttributes \
          tabNews[id].getId(), tabLayout
        delete tabNews[id]
      else
        location = tabDefaultLocation tab
        location = lastTabSet.getId() if location == 'lastTabSet'
        model.doAction FlexLayout.Actions.addNode tabLayout,
          location, FlexLayout.DockLocation.CENTER, -1
        if tabTypes[tab.type]?.alwaysRender
          model.doAction FlexLayout.Actions.selectTab tabLayout.id
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
  iconFactory = (tab) -> tabIcon id2tab[tab.getId()]
  onRenderTab = (node, {buttons}) ->
    if node.isVisible() and node.getComponent() != 'TabNew'
      type = if node.getParent().getType() == 'border' then 'border' else 'tab'
      buttons.push \
        <div key="reload" className="flexlayout__#{type}_button_trailing"
         title="Reload Tab"
         onClick={(e) -> model.doAction \
           FlexLayout.Actions.updateNodeAttributes node.getId(),
             component: 'TabReload'}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          <FontAwesomeIcon icon={faRedoAlt}/>
        </div>
  onRenderTabSet = (node, {buttons}) ->
    return if node.getType() == 'border'
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
  <FlexLayout.Layout model={model} factory={factory} iconFactory={iconFactory}
   onRenderTab={onRenderTab} onRenderTabSet={onRenderTabSet}
   onAction={onAction} onModelChange={-> setLayout model.toJson().layout}/>
