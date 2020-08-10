import React from 'react'
import {useParams} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'

import TableList from './TableList'
import TableNew from './TableNew'

export default Room = ->
  {roomId} = useParams()
  loading = useTracker ->
    sub = Meteor.subscribe 'room', roomId
    not sub.ready()
  <div className="row">
    <div id="tables" className="col-sm-3 bg-light">
      <nav className="navbar navbar-light">
        <span className="navbar-brand mb-0 h1">Comingle</span>
      </nav>
      <TableList loading={loading}/>
      <TableNew/>
    </div>
    <div className="col-sm">
      Room
    </div>
  </div>
