import React, {useState} from 'react'
import {Link, useParams, useHistory} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUser} from '@fortawesome/free-solid-svg-icons'

import {Tables} from '/lib/tables'
import {Presence} from '/lib/presence'
import Header from './Header'
import Name from './Name'

export default TableList = ({loading}) ->
  {roomId} = useParams()
  tables = useTracker -> Tables.find(room: roomId).fetch()
  presences = useTracker -> Presence.find(room: roomId).fetch()
  presenceByTable = {}
  for presence in presences
    for type in ['visible', 'invisible']
      for table in presence.tables[type]
        presenceByTable[table] ?= []
        presenceByTable[table].push
          type: type
          name: presence.name
          id: presence.id
  <div className="TableList">
    <Header/>
    <Name/>
    {if tables.length or loading
      <div className="list-group">
        {for table in tables
          <TableInfo key={table._id} table={table}
           presence={presenceByTable[table._id]}/>
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

export TableInfo = ({table, presence}) ->
  {roomId} = useParams()
  <Link to="/r/#{roomId}##{table._id}" className="list-group-item list-group-item-action">
    <span className="title">{table.title}</span>
    {if presence?.length
      <div className="presense">
        {for person in presence
          <span key={person.id} className="presense-#{person.type}">
            <FontAwesomeIcon icon={faUser} className="mr-1"/>
            {person.name}
          </span>
        }
      </div>
    }
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
