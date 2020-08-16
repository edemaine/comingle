import React, {useState} from 'react'
import {Link, useParams, useHistory} from 'react-router-dom'
import {SplitButton, Dropdown} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUser} from '@fortawesome/free-solid-svg-icons'

import {Rooms} from '/lib/rooms'
import {Presence} from '/lib/presence'
import {Loading} from './Loading'
import {Header} from './Header'
import {Name} from './Name'
import {tabTypePage, mangleTab} from './TabNew'
import {getPresenceId, getCreator} from './lib/presenceId'
import {sortNames, uniqCountNames} from './lib/sortNames'
import {meteorCallPromise} from './lib/meteorPromise'

export RoomList = ({loading}) ->
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
  presenceId = getPresenceId()
  if presence?
    myPresence = (presence?.find (p) -> p.id == presenceId)
    clusters = sortNames presence, (p) -> p.name
    clusters = uniqCountNames presence, (p) -> p.name
  myPresenceClass = if myPresence then "room-info-#{myPresence.type}" else ""
  <Link to="/m/#{meetingId}##{room._id}" className="list-group-item list-group-item-action room-info #{myPresenceClass}">
    <span className="title">{room.title}</span>
    {if clusters?.length
      <div className="presence">
        {for person in clusters
          <span key={person.item.id} className="presence-#{person.item.type}">
            <FontAwesomeIcon icon={faUser} className="mr-1"/>
            {person.name}
            {if person.count > 1
              <span className="ml-1 badge badge-secondary">{person.count}</span>
            }
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
    e.preventDefault?()
    return unless title.trim().length
    Meteor.call 'roomNew',
      meeting: meetingId
      title: title.trim()
      creator: getCreator()
    , (error, roomId) ->
      return console.error error if error?
      for type in (e.template ? 'jitsi').split '+' when type
        url = tabTypePage[type].createNew()
        url = await url if url.then?
        await meteorCallPromise 'tabNew', mangleTab(
          meeting: meetingId
          room: roomId
          type: type
          title: ''
          url: url
          creator: getCreator()
        , true)
      history.push "/m/#{meetingId}##{roomId}"
    setTitle ''
  <form onSubmit={submit}>
    <div className="form-group"/>
    <div className="form-group">
      <input type="text" placeholder="Title" className="form-control"
       value={title} onChange={(e) -> setTitle e.target.value}/>
      <SplitButton type="submit" className="btn-block" drop="up"
                   title="Create Room">
        <Dropdown.Item onClick={-> submit template: ''}>
          Empty room
        </Dropdown.Item>
        <Dropdown.Item onClick={-> submit template: 'jitsi'}>
          Jitsi (default)
        </Dropdown.Item>
        <Dropdown.Item onClick={-> submit template: 'jitsi+cocreate'}>
          Jitsi + Cocreate
        </Dropdown.Item>
      </SplitButton>
    </div>
  </form>
