import React from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Tables} from '/lib/tables'

export default TableList = ->
  {tables, loading} = useTracker ->
    sub = Meteor.subscribe 'tables'
    loading: not sub.ready()
    tables: Tables.find({}).fetch()
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
  <a className="list-group-item list-group-item-action" href="#">
    <span className="title">{table.title}</span>
  </a>
