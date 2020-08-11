import React, {useState, useEffect} from 'react'
import {Switch, Route, useParams, useLocation} from 'react-router-dom'
import FlexLayout from 'flexlayout-react'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTimes, faExpandArrowsAlt, faCompressArrowsAlt, faChair} from '@fortawesome/free-solid-svg-icons'

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
  loading = useTracker ->
    sub = Meteor.subscribe 'room', roomId
    tables = Tables.find()
    model.visitNodes (node) ->
      if node.getType() == 'tab' and node.getId() != 'tablesTab'
        table = Tables.findOne node.getId()
        if table?
          model.doAction FlexLayout.Actions.updateNodeAttributes node.getId(),
            name: table.title
    not sub.ready()
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
    if action.type == FlexLayout.Actions.SET_ACTIVE_TABSET and
       action.data.tabsetNode != 'tablesTabSet'
      setCurrentTabSet action.data.tabsetNode
    action
  factory = (tab) ->
    switch tab.getComponent()
      when 'Table' then <Table loading={loading} tableId={tab.getId()}/>
      when 'TableList' then <TableList loading={loading}/>
  iconFactory = (tab) ->
    <FontAwesomeIcon icon={faChair}/>
  onRenderTabSet = (node, {buttons}) ->
    return unless node.isEnableMaximize?()
    maxed = node.isMaximized()
    buttons.push \
      <button key="minmax" className="flexlayout__tab_toolbar_button-fa"
       title={if maxed then 'Unmaximize' else 'Maximize'}
       onClick={-> model.doAction FlexLayout.Actions.maximizeToggle node.getId()}>
        <FontAwesomeIcon icon={if maxed then faCompressArrowsAlt else faExpandArrowsAlt}/>
      </button>
  <FlexLayout.Layout model={model} factory={factory} iconFactory={iconFactory}
   closeIcon={<FontAwesomeIcon icon={faTimes}/>}
   onAction={onAction}
   onRenderTabSet={onRenderTabSet}/>
