import React, {useState, useEffect, useReducer} from 'react'
import {useParams} from 'react-router-dom'
import FlexLayout from 'flexlayout-react'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faPlus, faTimes} from '@fortawesome/free-solid-svg-icons'

import {Tables} from '/lib/tables'
import {Tabs} from '/lib/tabs'
import useLocalStorage from './lib/useLocalStorage.coffee'
import TabNew from './TabNew'
import TabIFrame from './TabIFrame'

###
export useLayoutModel = (tableId) ->
  [state, setState] = useLocalStorage "layout.#{tableId}", {}
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

export default Table = ({loading, tableId}) ->
  {roomId} = useParams()
  [model, setModel] = useState initModel
  [tabNews, replaceTabNew] = useReducer(
    (state, {id, tab}) -> state[id] = tab; state
  , {})
  {loading, table, tabs} = useTracker ->
    sub = Meteor.subscribe 'table', tableId
    tabs = Tabs.find(table: tableId).fetch()
    loading: loading or not sub.ready()
    table: Tables.findOne tableId
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
    , parent, FlexLayout.DockLocation.CENTER, -1
  ## Start new tab in empty table
  useEffect ->
    unless loading or tabs.length
      model.visitNodes (node) ->
        if node.getType() == 'tabset' and node.getChildren().length == 0
          tabNew node.getId()
  , [loading, tabs.length]
  factory = (tab) ->
    switch tab.getComponent()
      when 'TabNew' then <TabNew {...{tab, roomId, tableId, replaceTabNew}}/>
      when 'TabIFrame' then <TabIFrame tabId={tab.getId()}/>
  onRenderTabSet = (node, {buttons}) ->
    buttons.push \
      <button key="add" className="flexlayout__tab_toolbar_button-fa"
       title="Add Tab" onClick={(e) -> tabNew node.getId()}>
        <FontAwesomeIcon icon={faPlus}/>
      </button>
  <div className="table">
    <h1>{table?.title}</h1>
    <FlexLayout.Layout model={model} factory={factory}
     closeIcon={<FontAwesomeIcon icon={faTimes}/>}
     onRenderTabSet={onRenderTabSet}/>
  </div>
