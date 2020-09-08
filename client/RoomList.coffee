import React, {useState, useMemo, useContext, useRef, useCallback, useEffect} from 'react'
import useInterval from '@use-it/interval'
import {Link, useParams} from 'react-router-dom'
import {Accordion, Alert, Button, ButtonGroup, Card, Dropdown, DropdownButton, Form, ListGroup, SplitButton, Tooltip, OverlayTrigger} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'
import {Session} from 'meteor/session'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faDoorOpen, faUser, faHandPaper, faSortAlphaDown, faSortAlphaDownAlt, faTimes, faTimesCircle} from '@fortawesome/free-solid-svg-icons'
import {faClone} from '@fortawesome/free-regular-svg-icons'

import FlexLayout from './FlexLayout'
import {Rooms, roomWithTemplate, roomDuplicate} from '/lib/rooms'
import {Presence} from '/lib/presence'
import {Loading} from './Loading'
import {Header} from './Header'
import {MeetingContext} from './Meeting'
import {MeetingTitle} from './MeetingTitle'
import {Name} from './Name'
import {Warnings} from './Warnings'
import {CardToggle} from './CardToggle'
import {getPresenceId, getCreator} from './lib/presenceId'
import {formatTimeDelta, formatDateTime} from './lib/dates'
import timesync from './lib/timesync'
import {sortByKey, titleKey, sortNames, uniqCountNames} from '/lib/sort'

findMyPresence = (presence) ->
  presenceId = getPresenceId()
  presence?.find (p) -> p.id == presenceId

sortKeys =
  title: 'Title'
  created: 'Creation time'
  participants: 'Participant count'
  raised: 'Raised hand timer'

export RoomList = ({loading, model}) ->
  {meetingId} = useParams()
  [sortKey, setSortKey] = useState 'title'
  [reverse, setReverse] = useState false
  [search, setSearch] = useState ''
  [selected, setSelected] = useState()
  rooms = useTracker -> Rooms.find(meeting: meetingId).fetch()
  presences = useTracker -> Presence.find(meeting: meetingId).fetch()
  presenceByRoom = useMemo ->
    byRoom = {}
    for presence in presences
      for type in ['visible', 'invisible']
        for room in presence.rooms[type]
          byRoom[room] ?= []
          byRoom[room].push
            type: type
            name: presence.name
            id: presence.id
    byRoom
  , [presences]
  sorters =
    title: titleKey
    created: (room) -> room.created
    participants: (room) ->
      titleKey "#{presenceByRoom[room._id]?.length ? 0}.#{room.title}"
    raised: (room) ->
      if raised = room.raised
        ## room.raised will briefly be true instead of a time
        raised = new Date if typeof raised == 'boolean'
        -raised.getTime()
      else
        -Infinity
  sortedRooms = useMemo ->
    sorted = sortByKey rooms[..], sorters[sortKey]
    sorted.reverse() if reverse
    sorted
  , [rooms, sortKey, reverse, if sortKey == 'participants' then presenceByRoom]
  roomList = useRef()
  selectRoom = useCallback (id, scroll) ->
    setSelected id
    return unless id?
    if scroll
      setTimeout ->
        elt = roomList.current?.querySelector """[data-room="#{id}"]"""
        elt?.scrollIntoView
          behavior: 'smooth'
          block: 'nearest'
      , 0
  , []
  Sublist = ({heading, filter, startClosed}) ->
    subrooms = sortedRooms.filter filter
    if search
      pattern = search.toLowerCase()
      match = (x) -> 0 <= x.toLowerCase().indexOf pattern
      subrooms = subrooms.filter (room) ->
        return true if match room.title
        for presence in presenceByRoom[room._id] ? []
          return true if match presence.name
    return null unless subrooms.length
    <Accordion defaultActiveKey={unless startClosed then "0"}>
      <Card>
        <CardToggle eventKey="0">
          {heading}
        </CardToggle>
        <Accordion.Collapse eventKey="0">
          <Card.Body>
            <ListGroup>
              {for room in subrooms
                do (id = room._id) ->
                  <RoomInfo key={room._id} room={room}
                   presence={presenceByRoom[room._id] ? []}
                   selected={selected == room._id}
                   selectRoom={selectRoom}
                   leave={->
                     model.doAction FlexLayout.Actions.deleteTab id}
                  />
              }
            </ListGroup>
          </Card.Body>
        </Accordion.Collapse>
      </Card>
    </Accordion>
  Sublist.displayName = 'Sublist'
  <div className="d-flex flex-column h-100">
    <div className="RoomList flex-shrink-1 overflow-auto pb-2" ref={roomList}>
      <Header/>
      <Warnings/>
      <MeetingTitle/>
      <Name/>
      {if rooms.length > 0
        <Accordion>
          <Card>
            <CardToggle eventKey="0">
              Room Search:
            </CardToggle>
            <Accordion.Collapse eventKey="0">
              <Card.Body>
                <FontAwesomeIcon icon={faTimesCircle} className="search-icon"
                 onClick={(e) -> e.stopPropagation(); setSearch ''}/>
                <Form.Control type="text" value={search}
                 onChange={(e) -> setSearch e.target.value}>
                </Form.Control>
                <ButtonGroup size="sm" className="sorting w-100 text-center">
                  <DropdownButton title="Sort By" variant="light">
                    {for key, phrase of sortKeys
                      <Dropdown.Item key={key} active={key == sortKey}
                       onClick={do (key) -> (e) -> e.stopPropagation(); e.preventDefault(); setSortKey key}>
                        {phrase}
                      </Dropdown.Item>
                    }
                  </DropdownButton>
                  <OverlayTrigger placement="right" overlay={(props) ->
                    <Tooltip {...props}>
                      Currently sorting in {
                        if reverse
                          <b>decreasing</b>
                        else
                          <b>increasing</b>
                      } order. <br/>
                      Select to toggle.
                    </Tooltip>
                  }>
                    <Button variant="light" onClick={-> setReverse not reverse}>
                      {if reverse
                         <FontAwesomeIcon aria-label="Decreasing Order"
                          icon={faSortAlphaDownAlt}/>
                       else
                         <FontAwesomeIcon aria-label="Increasing Order"
                          icon={faSortAlphaDown}/>
                      }
                    </Button>
                  </OverlayTrigger>
                </ButtonGroup>
              </Card.Body>
            </Accordion.Collapse>
          </Card>
        </Accordion>
      }
      {if loading
        <Loading/>
      }
      {unless rooms.length or loading
        <Alert variant="warning">
          No rooms in this meeting.
        </Alert>
      }
      <Sublist heading="Your Open Rooms:"
       filter={(room) -> findMyPresence presenceByRoom[room._id]}/>
      <Sublist heading="Available Rooms:"
       filter={(room) -> not room.archived and
                         not findMyPresence presenceByRoom[room._id]}/>
      <Sublist heading="Archived Rooms:" startClosed
       filter={(room) -> room.archived and
                         not findMyPresence presenceByRoom[room._id]}/>
    </div>
    <RoomNew selectRoom={selectRoom}/>
  </div>
RoomList.displayName = 'RoomList'

export RoomInfo = ({room, presence, selected, selectRoom, leave}) ->
  {meetingId} = useParams()
  {openRoom, openRoomWithDragAndDrop} = useContext MeetingContext
  link = useRef()
  myPresence = findMyPresence presence
  clusters = sortNames presence, (p) -> p.name
  clusters = uniqCountNames presence, (p) -> p.name
  roomInfoClass = ''
  roomInfoClass += " presence-#{myPresence.type}" if myPresence
  roomInfoClass += " selected" if selected
  roomInfoClass += " archived" if room.archived
  presenceCount = {}
  for person in presence
    presenceCount[person.type] ?= 0
    presenceCount[person.type]++
  onClick = (force) -> (e) ->
    e.preventDefault()
    e.stopPropagation()
    currentRoom = Session.get 'currentRoom'
    ## Open room with focus in the following cases:
    ##   * We're not in any rooms
    ##   * Shift-click => force open as foreground tab
    ##   * We clicked on the Switch button (force == true)
    if not currentRoom? or e.shiftKey or force == true
      openRoom room._id, true
      selectRoom null
    ## Open room as background tab (without focusing) in the following cases:
    ##   * Ctrl/Command-click => force open as background tab
    ##   * We clicked on the Join In Background button (force == false)
    else if e.ctrlKey or e.metaKey or force == false
      openRoom room._id, false
      selectRoom null
    ## Otherwise, toggle whether this room is selected.
    else if selected
      selectRoom null
    else
      selectRoom room._id
  onLeave = (e) ->
    e.preventDefault()
    e.stopPropagation()
    leave()
    selectRoom null
  onSplit = (e) ->
    e.preventDefault()
    e.stopPropagation()
    newRoom = await roomDuplicate room, getCreator()
    openRoom newRoom, false
    selectRoom newRoom, false
  onDragStart = (e) ->
    e.preventDefault()
    e.stopPropagation()
    openRoomWithDragAndDrop(room._id)
  PresenceList = ({clusters, filter}) ->
    if filter
      clusters = clusters?.filter filter
    if clusters.length
      <div className="presence">
        {for person in clusters
          <span key={person.item.id} className="presence-#{person.item.type}">
            <FontAwesomeIcon icon={faUser}/>
            {person.name}
            {if person.count > 1
              <span className="ml-1 badge badge-secondary">{person.count}</span>
            }
          </span>
        }
      </div>
    else null
  PresenceList.displayName = 'PresenceList'
  <Link ref={link} to="/m/#{meetingId}##{room._id}" onClick={onClick()} onDragStart={onDragStart}
   className="list-group-item list-group-item-action room-info#{roomInfoClass}"
   data-room={room._id}>
    <div className="presence-count">
      {for kind in [
         type: 'invisible'
         variant: 'secondary'
         singular: 'person has this room open in the background'
         plural: 'people have this room open in the background'
       ,
         type: 'visible'
         variant: 'primary'
         singular: 'person is in this room'
         plural: 'people are in this room'
       ]
         continue unless presenceCount[kind.type]
         <OverlayTrigger key={kind.type} placement="top"
          overlay={do (kind) -> (props) ->
            <Tooltip {...props}>
              {presenceCount[kind.type]} {if presenceCount[kind.type] == 1 then kind.singular else kind.plural}:
              <PresenceList clusters={clusters}
               filter={(person) -> person.item.type == kind.type}/>
            </Tooltip>
          }>
           <span className="presence-#{kind.type}"
            aria-label="#{presenceCount[kind.type]} #{if presenceCount[kind.type] == 1 then kind.singular else kind.plural}">
             <FontAwesomeIcon icon={faUser}/>
             {presenceCount[kind.type]}
           </span>
         </OverlayTrigger>
      }
    </div>
    {if room.raised or myPresence?.type == 'visible'
      if room.raised
        label = 'Lower Hand'
        help =
          <>
            {if myPresence?.type == 'visible'
              <><b>Lower Hand</b><br/></>
            }
            raised by {room.raiser?.name ? 'unknown'}<br/>
            on {formatDateTime room.raised}
          </>
      else
        label = 'Raise Hand'
        help = <b>Raise Hand</b>
      toggleHand = (e) ->
        e.preventDefault()
        e.stopPropagation()
        ## Allow toggling hand only if actively in room
        return unless myPresence?.type == 'visible'
        Meteor.call 'roomEdit',
          id: room._id
          raised: not room.raised
          updator: getCreator()
      <div className="raise-hand #{if room.raised then 'active' else ''}">
        <OverlayTrigger placement="top" overlay={(props) ->
          <Tooltip {...props}>{help}</Tooltip>
        }>
          <FontAwesomeIcon aria-label={label} icon={faHandPaper}
           onClick={toggleHand}/>
        </OverlayTrigger>
        {if room.raised and typeof room.raised != 'boolean'
          recomputeTimer = ->
            delta = timesync.offset + (new Date).getTime() - room.raised
            delta = 0 if delta < 0
            if delta <= 5 * 60*60 * 1000
              formatTimeDelta delta
            else
              '>5hr'
          [timer, setTimer] = useState recomputeTimer
          [timerHeight, setTimerHeight] = useState 0
          timerRef = useRef()
          useInterval ->
            setTimer recomputeTimer()
          , 1000
          useEffect ->
            return unless timerRef.current
            setTimerHeight(timerRef.current.clientWidth)
          , [timer]

          <div style={{height: timerHeight}}>
            <div className="timer" ref={timerRef}>
              {timer}
            </div>
          </div>
        }
      </div>
    }
    <span className="title">{room.title}</span>
    <PresenceList clusters={clusters} filter={(person) ->
      person.item.type == 'visible' # or person.name == myPresence?.name
    }/>
    {if selected
      <ButtonGroup vertical className="mx-n2 mt-2 d-block">
        {unless myPresence?.type == 'visible'
          <Button variant="warning" onClick={onClick true}>
            <small className="mr-1"><FontAwesomeIcon icon={faDoorOpen}/></small>
            Switch to Room<br/>
            <small><b>Leaves</b> current call</small>
          </Button>
        }
        {if myPresence
          <Button variant="danger" onClick={onLeave}>
            <small className="mr-1"><FontAwesomeIcon icon={faTimes}/></small>
            Leave Room<br/>
            {if myPresence.type == 'visible'
              <small><b>Leaves</b> current call</small>
            else
              <small>Close background room</small>
            }
          </Button>
        else
          <Button variant="secondary" onClick={onClick false} className="px-1">
            Join in Background<br/>
            <small><b>Stays</b> in current room</small>
          </Button>
        }
        {if myPresence?.type == 'visible'
          <Button variant="primary" onClick={onSplit}>
            <small className="mr-1"><FontAwesomeIcon icon={faClone}/></small>
            Split Room<br/>
            <small><b>Duplicate</b> this room (forking discussion)</small>
          </Button>
        }
      </ButtonGroup>
    }
  </Link>
RoomInfo.displayName = 'RoomInfo'

export RoomNew = ({selectRoom}) ->
  {meetingId} = useParams()
  [title, setTitle] = useState ''
  {openRoom} = useContext MeetingContext
  submit = (e, template) ->
    e.preventDefault?()
    return unless title.trim().length
    {shiftKey, ctrlKey, metaKey} = e
    room =
      meeting: meetingId
      title: title.trim()
      creator: getCreator()
      template: template ? 'jitsi'
    setTitle ''
    roomId = await roomWithTemplate room
    if shiftKey
      openRoom roomId, true
      selectRoom null
    else if ctrlKey or metaKey
      openRoom roomId, false
      selectRoom null
    else
      selectRoom roomId, true
  ## We need to manually capture Enter so that e.g. Ctrl-Enter works.
  ## This has the added benefit of getting modifiers' state.
  onKeyDown = (e) ->
    if e.key == 'Enter'
      submit e
  <form onSubmit={submit}>
    <input type="text" placeholder="Title" className="form-control"
     value={title} onChange={(e) -> setTitle e.target.value}
     onKeyDown={onKeyDown}/>
    <SplitButton type="submit" className="btn-block" drop="up"
     title="Create Room" onClick={submit}>
      <Dropdown.Item onClick={(e) -> submit e, ''}>
        Empty room
      </Dropdown.Item>
      <Dropdown.Item onClick={(e) -> submit e, 'jitsi'}>
        Jitsi (default)
      </Dropdown.Item>
      <Dropdown.Item onClick={(e) -> submit e, 'jitsi+cocreate'}>
        Jitsi + Cocreate
      </Dropdown.Item>
    </SplitButton>
  </form>
RoomNew.displayName = 'RoomNew'
