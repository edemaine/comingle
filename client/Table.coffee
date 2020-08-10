import React from 'react'
import {useParams} from 'react-router-dom'
import FlexLayout from 'flexlayout-react'
import {useTracker} from 'meteor/react-meteor-data'

import {Tables} from '/lib/tables'
import useLocalStorage from './lib/useLocalStorage.coffee'

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

export default Table = ->
  {tableId} = useParams()
  table = useTracker -> Tables.findOne tableId
  [model, setModel] = useLayoutModel tableId
  <div className="table">
    <h1>{table?.title}</h1>
    <FlexLayout.Layout model={model}/>
  </div>
