import React, {useState, useMemo, useContext} from 'react'
import useInterval from '@use-it/interval'
import {Link, useParams} from 'react-router-dom'
import {Accordion, Alert, Button, ButtonGroup, Card, Dropdown, DropdownButton, Form, ListGroup, SplitButton, Tooltip, OverlayTrigger} from 'react-bootstrap'
import {useTracker} from 'meteor/react-meteor-data'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUser, faHandPaper, faSortAlphaDown, faSortAlphaDownAlt, faTimesCircle} from '@fortawesome/free-solid-svg-icons'

import {Rooms, roomWithTemplate} from '/lib/rooms'
import {Presence} from '/lib/presence'
import {Loading} from './Loading'
import {Header} from './Header'
import {MeetingContext} from './Meeting'
import {MeetingTitle} from './MeetingTitle'
import {Name} from './Name'
import {Warnings} from './Warnings'
import {CardToggle} from './CardToggle'
import {getPresenceId, getCreator} from './lib/presenceId'
import {formatTimeDelta} from './lib/dates'
import {sortByKey, titleKey, sortNames, uniqCountNames} from '/lib/sort'

findMyPresence = (presence) ->
  presenceId = getPresenceId()
  presence?.find (p) -> p.id == presenceId

sortKeys =
  title: 'Title'
  created: 'Creation time'
  participants: 'Participant count'
  raised: 'Raised hand timer'

export RoomList = ({loading}) ->
  {meetingId} = useParams()
  [sortKey, setSortKey] = useState 'title'
  [reverse, setReverse] = useState false
  [search, setSearch] = useState ''
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
      if room.raised
        -room.raised.getTime()
      else
        -Infinity
  sortedRooms = useMemo ->
    sorted = sortByKey rooms[..], sorters[sortKey]
    sorted.reverse() if reverse
    sorted
  , [rooms, sortKey, reverse, if sortKey == 'participants' then presenceByRoom]
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
                <RoomInfo key={room._id} {...room}
                 presence={presenceByRoom[room._id]}/>
              }
            </ListGroup>
          </Card.Body>
        </Accordion.Collapse>
      </Card>
    </Accordion>
  <div className="d-flex flex-column h-100">
    <div className="RoomList flex-shrink-1 overflow-auto pb-2">
      <Header/>
      <Warnings/>
      <MeetingTitle/>
      <Name/>
      {if rooms.length > 1
        <Accordion defaultActiveKey="0">
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
                    <Button variant="light" onClick={(e) -> setReverse not reverse}>
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
      <Sublist heading="Rooms You're In:"
       filter={(room) -> findMyPresence presenceByRoom[room._id]}/>
      <Sublist heading="Available Rooms:"
       filter={(room) -> not room.archived and
                         not findMyPresence presenceByRoom[room._id]}/>
      <Sublist heading="Archived Rooms:" startClosed
       filter={(room) -> room.archived and
                         not findMyPresence presenceByRoom[room._id]}/>
    </div>
    <RoomNew/>
  </div>

export RoomInfo = ({_id, title, raised, presence}) ->
  {meetingId} = useParams()
  {openRoom} = useContext MeetingContext
  if presence?
    myPresence = findMyPresence presence
    clusters = sortNames presence, (p) -> p.name
    clusters = uniqCountNames presence, (p) -> p.name
  myPresenceClass = if myPresence then "room-info-#{myPresence.type}" else ""
  onClick = (e) ->
    ## Shift-click => open as background tab (without focusing)
    if e.shiftKey
      match = /#([^#]*)/.exec e.currentTarget.href
      return unless match
      e.preventDefault()
      openRoom match[1], false
  <Link to="/m/#{meetingId}##{_id}" onClick={onClick}
   className="list-group-item list-group-item-action room-info #{myPresenceClass}">
    {if myPresence or raised
      help = "#{if raised then 'Lower' else 'Raise'} Hand"
      toggleHand = ->
        Meteor.call 'roomEdit',
          id: _id
          raised: not raised
          updator: getCreator()
      <div className="raise-hand #{if raised then 'active' else ''}"
       aria-label={help}>
        <OverlayTrigger placement="top" overlay={(props) ->
          <Tooltip {...props}>{help}</Tooltip>
        }>
          <FontAwesomeIcon aria-label={help} icon={faHandPaper}
           onClick={toggleHand}/>
        </OverlayTrigger>
        {if raised and typeof raised != 'boolean'
          [timer, setTimer] = useState formatTimeDelta (new Date) - raised
          useInterval ->
            setTimer formatTimeDelta (new Date) - raised
          , 1000
          <div className="timer">
            {timer}
          </div>
        }
      </div>
    }
    <span className="title">{title}</span>
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
  {openRoom} = useContext MeetingContext
  shift = false
  submit = (e) ->
    e.preventDefault?()
    return unless title.trim().length
    shifted = shift
    shift = false
    room =
      meeting: meetingId
      title: title.trim()
      creator: getCreator()
      template: e.template ? 'jitsi'
    setTitle ''
    roomId = await roomWithTemplate room
    openRoom roomId, not shifted
  onClick = (e) ->
    if e.shiftKey
      shift = true
      setTimeout (-> shift = false), 0
  <form onSubmit={submit}>
    <div className="form-group">
      <input type="text" placeholder="Title" className="form-control"
       value={title} onChange={(e) -> setTitle e.target.value}
       onKeyDown={(e) -> if e.key == 'Shift' then shift = true}
       onKeyUp={(e) -> if e.key == 'Shift' then shift = false}
       onBlur={(e) -> shift = false}/>
      <SplitButton type="submit" className="btn-block" drop="up"
       title="Create Room" onClick={onClick}>
        <Dropdown.Item onClick={(e) -> onClick e; submit template: ''}>
          Empty room
        </Dropdown.Item>
        <Dropdown.Item onClick={(e) -> onClick e; submit template: 'jitsi'}>
          Jitsi (default)
        </Dropdown.Item>
        <Dropdown.Item onClick={(e) -> onClick e; submit template: 'jitsi+cocreate'}>
          Jitsi + Cocreate
        </Dropdown.Item>
      </SplitButton>
    </div>
  </form>
