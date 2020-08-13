import React, {useState} from 'react'
import {Link, useParams, useHistory} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUser} from '@fortawesome/free-solid-svg-icons'

import {Rooms} from '/lib/rooms'
import {Presence} from '/lib/presence'
import Loading from './Loading'
import Header from './Header'
import Name from './Name'

export default RoomList = ({loading}) ->
  {meetingId} = useParams()
  rooms = useTracker -> Rooms.find(meeting: meetingId).fetch()
  presences = useTracker -> Presence.find(meeting: meetingId).fetch()
  presenceByRoom = {}
  for presence in presences
    for type in ['visible', 'invisible']
      for room in presence.rooms[type]
        presenceByRoom[room] ?= []
        presenceByRoom[room].push
          type: type
          name: presence.name
          id: presence.id
  <div className="RoomList">
    <Header/>
    <Name/>
    {if rooms.length or loading
      <div className="list-group">
        {for room in rooms
          <RoomInfo key={room._id} room={room}
           presence={presenceByRoom[room._id]}/>
        }
        {if loading
          <Loading/>
        }
      </div>
    else
      <div className="alert alert-warning" role="alert">
        No rooms in this meeting.
      </div>
    }
    <RoomNew/>
  </div>

export RoomInfo = ({room, presence}) ->
  {meetingId} = useParams()
  <Link to="/m/#{meetingId}##{room._id}" className="list-group-item list-group-item-action">
    <span className="title">{room.title}</span>
    {if presence?.length
      <div className="presence">
        {for person in presence
          <span key={person.id} className="presence-#{person.type}">
            <FontAwesomeIcon icon={faUser} className="mr-1"/>
            {person.name}
          </span>
        }
      </div>
    }
  </Link>

export RoomNew = ->
  {meetingId} = useParams()
  [title, setTitle] = useState ''
  history = useHistory()
  submit = (e) ->
    e.preventDefault()
    return unless title.trim().length
    Meteor.call 'roomNew',
      meeting: meetingId
      title: title.trim()
    , (error, roomId) ->
      return console.error error if error?
      history.push "/m/#{meetingId}##{roomId}"
    setTitle ''
  <form onSubmit={submit}>
    <div className="form-group"/>
    <div className="form-group">
      <input type="text" placeholder="Title" className="form-control"
       value={title} onChange={(e) -> setTitle e.target.value}/>
      <button type="submit" className="btn btn-primary btn-block">
        Create New Room
      </button>
    </div>
  </form>
