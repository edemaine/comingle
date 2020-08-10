import React from 'react'
import {Link, useParams} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'

import {Tables} from '/lib/tables'

export default TableList = ({loading}) ->
  {roomId} = useParams()
  tables = useTracker ->
    Tables.find room: roomId
    .fetch()
  if tables.length or loading
    <div className="list-group">
      {for table in tables
        <TableInfo key={table._id} table={table}/>
      }
      {if loading
        <span>...loading...</span>
      }
    </div>
  else
    <div className="alert alert-warning" role="alert">
      No tables in this room.
    </div>

export TableInfo = ({table}) ->
  {roomId} = useParams()
  <Link to="/r/#{roomId}/t/#{table._id}" className="list-group-item list-group-item-action">
    <span className="title">{table.title}</span>
  </Link>
