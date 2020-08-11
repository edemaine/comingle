import React, {useState, useEffect} from 'react'
import {Switch, Route, useParams, useLocation} from 'react-router-dom'
import FlexLayout from './FlexLayout'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faChair} from '@fortawesome/free-solid-svg-icons'

import TableList from './TableList'
import TableNew from './TableNew'
import Table from './Table'
import {Tables} from '/lib/tables'
import {validId} from '/lib/id'

initModel = ->
  model = FlexLayout.Model.fromJson
    global:
      borderEnableDrop: false
    borders: [
      type: 'border'
      location: 'left'
      selected: 0
      children: [
        id: 'tablesTab'
        type: 'tab'
        name: "Tables in Room"
        component: 'TableList'
        enableClose: false
        enableDrag: false
      ]
    ]
    layout:
      id: 'root'
      type: 'row'
      weight: 100
      children: []
  model.setOnAllowDrop (dragNode, dropInfo) ->
    return false if dropInfo.node.getId() == 'tablesTabSet' and dropInfo.location != FlexLayout.DockLocation.RIGHT
    #return false if dropInfo.node.getType() == 'border'
    #return false if dragNode.getParent()?.getType() == 'border'
    true
  model

export default Room = ->
  {roomId} = useParams()
  [model, setModel] = useState initModel
  [currentTabSet, setCurrentTabSet] = useState null
  location = useLocation()
  {loading, tables} = useTracker ->
    sub = Meteor.subscribe 'room', roomId
    loading: not sub.ready()
    tables: Tables.find().fetch()
  useEffect ->
    for table in tables
      if model.getNodeById table._id
        model.doAction FlexLayout.Actions.updateNodeAttributes table._id,
          name: table.title
    undefined
  , [tables]
  useEffect ->
    if location.hash and validId id = location.hash[1..]
      unless model.getNodeById id
        tab =
          id: id
          type: 'tab'
          name: Tables.findOne(id)?.title ? id
          component: 'Table'
        if currentTabSet? and model.getNodeById currentTabSet
          model.doAction FlexLayout.Actions.addNode tab,
            currentTabSet, FlexLayout.DockLocation.CENTER, -1
        else
          model.doAction FlexLayout.Actions.addNode tab,
            'root', FlexLayout.DockLocation.RIGHT
          setCurrentTabSet model.getNodeById(id).getParent().getId()
      model.doAction FlexLayout.Actions.selectTab id
    undefined
  , [location]
  onAction = (action) ->
    switch action.type
      when FlexLayout.Actions.SET_ACTIVE_TABSET
        ## TableList is now in border, no longer tabset
        #unless action.data.tabsetNode == 'tablesTabSet'
        setCurrentTabSet action.data.tabsetNode
      when FlexLayout.Actions.RENAME_TAB
        ## Sanitize table title and push to other users
        action.data.text = action.data.text.trim()
        return unless action.data.text  # prevent empty title
        Meteor.call 'tableEdit',
          id: action.data.node
          title: action.data.text
    action
  factory = (tab) ->
    switch tab.getComponent()
      when 'Table' then <Table loading={loading} tableId={tab.getId()}/>
      when 'TableList' then <TableList loading={loading}/>
  iconFactory = (tab) ->
    <FontAwesomeIcon icon={faChair}/>
  <FlexLayout.Layout model={model} factory={factory} iconFactory={iconFactory}
   onAction={onAction}/>
