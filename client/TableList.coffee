import React, {useState} from 'react'
import {Link, useParams, useHistory} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'

import {Tables} from '/lib/tables'

export default TableList = ({loading}) ->
  {roomId} = useParams()
  tables = useTracker ->
    Tables.find room: roomId
    .fetch()
  <div className="TableList">
    <nav className="navbar navbar-light">
      <span className="navbar-brand mb-0 h1">Comingle</span>
    </nav>
    {if tables.length or loading
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
    }
    <TableNew/>
  </div>

export TableInfo = ({table}) ->
  {roomId} = useParams()
  <Link to="/r/#{roomId}##{table._id}" className="list-group-item list-group-item-action">
    <span className="title">{table.title}</span>
  </Link>

export TableNew = ->
  {roomId} = useParams()
  [title, setTitle] = useState ''
  history = useHistory()
  submit = (e) ->
    e.preventDefault()
    return unless title.trim().length
    Meteor.call 'tableNew',
      room: roomId
      title: title.trim()
    , (error, tableId) ->
      return console.error error if error?
      history.push "/r/#{roomId}##{tableId}"
    setTitle ''
  <form onSubmit={submit}>
    <div className="form-group"/>
    <div className="form-group">
      <input type="text" placeholder="Title" className="form-control"
       value={title} onChange={(e) -> setTitle e.target.value}/>
      <button type="submit" className="btn btn-primary btn-block">
        Create New Table
      </button>
    </div>
  </form>
