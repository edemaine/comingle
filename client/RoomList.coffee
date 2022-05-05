import React, {useState, useMemo, useContext, useRef, useCallback, useEffect} from 'react'
import useInterval from '@use-it/interval'
import {Link, useParams} from 'react-router-dom'
import {useDrop} from 'react-dnd'
import Accordion from 'react-bootstrap/Accordion'
import Alert from 'react-bootstrap/Alert'
import Badge from 'react-bootstrap/Badge'
import Button from 'react-bootstrap/Button'
import ButtonGroup from 'react-bootstrap/ButtonGroup'
import Card from 'react-bootstrap/Card'
import Dropdown from 'react-bootstrap/Dropdown'
import DropdownButton from 'react-bootstrap/DropdownButton'
import Form from 'react-bootstrap/Form'
import ListGroup from 'react-bootstrap/ListGroup'
import SplitButton from 'react-bootstrap/SplitButton'
import Tooltip from 'react-bootstrap/Tooltip'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'
import {useTracker} from 'meteor/react-meteor-data'
import {Session} from 'meteor/session'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faDoorOpen} from '@fortawesome/free-solid-svg-icons/faDoorOpen'
import {faHandPaper} from '@fortawesome/free-solid-svg-icons/faHandPaper'
import {faHourglass} from '@fortawesome/free-solid-svg-icons/faHourglass'
import {faLock} from '@fortawesome/free-solid-svg-icons/faLock'
import {faLockOpen} from '@fortawesome/free-solid-svg-icons/faLockOpen'
import {faSortAlphaDown} from '@fortawesome/free-solid-svg-icons/faSortAlphaDown'
import {faSortAlphaDownAlt} from '@fortawesome/free-solid-svg-icons/faSortAlphaDownAlt'
import {faStar} from '@fortawesome/free-solid-svg-icons/faStar'
import {faTimes} from '@fortawesome/free-solid-svg-icons/faTimes'
import {faTimesCircle} from '@fortawesome/free-solid-svg-icons/faTimesCircle'
import {faTrash} from '@fortawesome/free-solid-svg-icons/faTrash'
import {faTrashRestore} from '@fortawesome/free-solid-svg-icons/faTrashRestore'
import {faUser} from '@fortawesome/free-solid-svg-icons/faUser'
import {faUserTie} from '@fortawesome/free-solid-svg-icons/faUserTie'
import {faClone} from '@fortawesome/free-regular-svg-icons/faClone'
import {faHandPaper as faHandPaperOutline} from '@fortawesome/free-regular-svg-icons/faHandPaper'
import {faStar as faStarOutline} from '@fortawesome/free-regular-svg-icons/faStar'

import FlexLayout from './FlexLayout'
import {Rooms, roomDuplicate} from '/lib/rooms'
import {Presence} from '/lib/presence'
import {CardToggle} from './CardToggle'
import {Header} from './Header'
import {Highlight} from './Highlight'
import {Loading} from './Loading'
import {MeetingContext} from './Meeting'
import {useMeetingAdmin, getMeetingSecret, addMeetingSecret} from './MeetingSecret'
import {Name} from './Name'
import {useAdminVisit, useRaisedSound} from './Settings'
import {Warnings} from './Warnings'
import {getPresenceId, getUpdator} from './lib/presenceId'
import {formatTimeDelta, formatDateTime} from './lib/dates'
import timesync from './lib/timesync'
import {useDebounce} from './lib/useDebounce'
import {Meetings} from '/lib/meetings'
import {meteorCallPromise} from '/lib/meteorPromise'
import {sortByKey, titleKey, sortNames, uniqCountNames} from '/lib/sort'
import {Config} from '/Config'

findMyPresence = (presence) ->
  myPresence = {}
  presenceId = getPresenceId()
  for type, presenceList of presence
    if (me = presenceList?.find (p) -> p.id == presenceId)?
      myPresence[type] = me
  myPresence

sortKeys = (admin) ->
  map =
    title: 'Title'
    created: 'Creation time'
    participants: 'Participant count'
    starred: 'Star count'
    raised: 'Raised hand timer'
  if admin
    Object.assign map,
      adminVisit: 'Last admin visit'
  map

defaultSort = Config.defaultSort ?
  key: 'title'
  reverse: false

export RoomList = React.memo ({loading, model, extraData, updateTab}) ->
  {meetingId} = useParams()
  admin = useMeetingAdmin()
  raisedSound = useRaisedSound()
  raisedAudio = useRef()
  [sortKey, setSortKey] = useState null  # null means "use default"
  [reverse, setReverse] = useState null  # null means "use default"
  meeting = useTracker ->
    Meetings.findOne meetingId
  , [meetingId]
  sortKey ?= meeting?.defaultSort?.key ? defaultSort.key
  reverse ?= meeting?.defaultSort?.reverse ? defaultSort.reverse
  [search, setSearch] = useState ''
  searchDebounce = useDebounce search, 200
  [nonempty, setNonempty] = useState false
  [selected, setSelected] = useState()
  rooms = useTracker ->
    Rooms.find(meeting: meetingId).fetch()
  , [meetingId]

  ## Raised hand maintenance: maintain count for display in Rooms tab heading,
  ## and check for new raised hands that should trigger playing a sound.
  raisedMap = useRef {}
  useEffect ->
    raisedCount = 0
    newRaise = false
    newMap = {}
    for room in rooms
      if room.raised
        raisedCount++
        newMap[room._id] = true
        if raisedMap.current? and not raisedMap.current[room._id]
          newRaise = true
    raisedMap.current = newMap
    if raisedCount != extraData.raisedCount
      extraData.raisedCount = raisedCount
      updateTab()
    if newRaise #and admin and raisedSound  -- checked by raisedAudio.current?
      raisedAudio.current?.play()
  , [rooms]

  presences = useTracker ->
    Presence.find meeting: meetingId
    .fetch()
  , [meetingId]
  presenceByRoom = useMemo ->
    byRoom = {}
    for presence in presences
      match = searchMatches search, presence.name if search
      for type, presenceList of presence.rooms
        for room in presenceList
          byRoom[room] ?= {}
          byRoom[room][type] ?= []
          byRoom[room][type].push
            type: type
            name: presence.name
            pronouns: presence.pronouns
            admin: presence.admin
            id: presence.id
            match: match
    byRoom
  , [presences, search]
  hasJoined = (room) ->
    presenceByRoom[room._id ? room]?.joined?.length
  sorters =
    title: titleKey
    created: (room) -> room.created
    participants: (room) ->
      titleKey "#{presenceByRoom[room._id]?.joined?.length ? 0}.#{room.title}"
    starred: (room) ->
      titleKey "#{presenceByRoom[room._id]?.starred?.length ? 0}.#{room.title}"
    raised: (room) ->
      if (raised = room.raised)
        ## room.raised will briefly be true instead of a time
        raised = new Date if typeof raised == 'boolean'
        -raised.getTime()
      else
        -Infinity
    adminVisit: (room) ->
      adminVisit = room.adminVisit
      if adminVisit instanceof Date
        -adminVisit.getTime()
      else
        -Infinity
  sortedRooms = useMemo ->
    sorted = sortByKey rooms[..], sorters[sortKey]
    sorted.reverse() if reverse
    sorted
  , [rooms, sortKey, reverse,
     (presenceByRoom if sortKey in ['participants', 'starred'])]
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
  onKeyDown = useCallback (e) ->
    if e.key == 'Escape'
      e.preventDefault()
      e.stopPropagation()
      setSelected null
  , []
  {updateStarred, starredOld, starredHasOld} = useContext MeetingContext
  clearStars = useCallback ->
    updateStarred []
  , [updateStarred]

  <div className="d-flex flex-column h-100 RoomList" onKeyDown={onKeyDown}>
    <div className="sidebar flex-grow-1 overflow-auto pb-2" ref={roomList}>
      {if admin and raisedSound
        <audio ref={raisedAudio} src="/sounds/raised.flac"/>
      }
      <Header/>
      <Warnings/>
      <Name/>
      {if starredHasOld
        <Alert variant="info" dismissible onClose={-> updateStarred()}>
          <p>
            Restore your
            {' '}
            <OverlayTrigger placement="right" flip overlay={(props) ->
              <Tooltip {...props}>
                {for id in starredOld
                  <span key={id} className="mr-2">
                    <FontAwesomeIcon className="mr-1" icon={faDoorOpen}/>
                    {Rooms.findOne(id)?.title ? id}
                  </span>
                }
              </Tooltip>
            }>
              <span className="text-help">old starred rooms</span>
            </OverlayTrigger>
            ?
          </p>
          <div className="text-center">
            <ButtonGroup>
              <Button variant="success" onClick={-> updateStarred starredOld}>
                Yes
              </Button>
              <Button variant="danger" onClick={-> updateStarred()}>
                No
              </Button>
            </ButtonGroup>
          </div>
        </Alert>
      }
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
                 onChange={(e) -> setSearch e.target.value}/>
                <ButtonGroup size="sm" className="sorting w-100 text-center">
                  <DropdownButton title="Sort By" variant="light">
                    {for key, phrase of sortKeys admin
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
                <Form.Group controlId="nonempty">
                  <Form.Check label="Only nonempty rooms"
                   className="mx-1 mt-1 mb-n1 text-center" checked={nonempty}
                   onChange={(e) -> setNonempty e.target.checked}/>
                </Form.Group>
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
      <Sublist {...{sortedRooms, presenceByRoom, selected, selectRoom, model}}
       heading="Your Starred Rooms:" startClosed search={searchDebounce}
       filter={(room) -> findMyPresence(presenceByRoom[room._id]).starred}
       className="starred">
        <OverlayTrigger placement="top" overlay={(props) ->
          <Tooltip {...props}>
            Unstar all rooms
          </Tooltip>
        }>
          <div className="text-center">
            <Button size="sm" variant="outline-warning" onClick={clearStars}>
              Clear Stars
            </Button>
          </div>
        </OverlayTrigger>
      </Sublist>
      <Sublist {...{sortedRooms, presenceByRoom, selected, selectRoom, model}}
       heading="Available Rooms:" search={searchDebounce} className="available"
       filter={(room) -> not room.archived and
                         (not nonempty or hasJoined(room) or selected == room._id)}/>
      <Sublist {...{sortedRooms, presenceByRoom, selected, selectRoom, model}}
       heading="Archived Rooms:" startClosed search={searchDebounce}
       className="archived"
       filter={(room) -> room.archived and
                         (not nonempty or hasJoined(room) or selected == room._id)}/>
    </div>
    <RoomNew selectRoom={selectRoom}/>
  </div>
RoomList.displayName = 'RoomList'

RoomList.onRenderTab = (node, renderState) ->
  if (raisedCount = node.getExtraData().raisedCount)
    help = "#{raisedCount} raised hand#{if raisedCount > 1 then 's' else ''}"
    hand = null
    showHand = (e) ->
      e.preventDefault()
      e.stopPropagation()
      hands = document.querySelectorAll '.RoomList .accordion:not(.starred) .raise-hand.active'
      hands = (elt for elt in hands)  # convert to Array
      return unless hands.length
      index = hands.indexOf hand
      hand = hands[(index + 1) % hands.length]
      hand.parentNode.scrollIntoView
        behavior: 'smooth'
    renderState.buttons.push \
      <OverlayTrigger key="handCount" placement="right" overlay={(props) ->
        <Tooltip {...props}>{help}</Tooltip>
      }>
        <Badge variant="danger" className="ml-1 hand-count" onClick={showHand}
         onMouseDown={(e) -> e.stopPropagation()}
         onTouchStart={(e) -> e.stopPropagation()}>
          {raisedCount}
          <FontAwesomeIcon aria-label={help} icon={faHandPaper} className="ml-1"/>
        </Badge>
      </OverlayTrigger>

searchMatches = (search, text) ->
  0 <= text.toLowerCase().indexOf search.toLowerCase()

Sublist = React.memo ({sortedRooms, presenceByRoom, selected, selectRoom, model, heading, search, filter, startClosed, children, className}) ->
  subrooms = useMemo ->
    matching = sortedRooms.filter filter
    if search
      matching = matching.filter (room) ->
        include = searchMatches search, room.title
        for type, presenceList of presenceByRoom[room._id] ? {}
          for presence in presenceList
            include or= presence.match
        include
    matching
  , [sortedRooms, filter, search, (if search then presenceByRoom)]

  <Accordion defaultActiveKey={unless startClosed then '0'}
   className={className}>
    <Card>
      <CardToggle eventKey="0">
        {heading}
        {' '}
        <Badge pill variant={if subrooms.length then 'info' else 'secondary'}>
          {subrooms.length}
        </Badge>
      </CardToggle>
      <Accordion.Collapse eventKey="0">
        <Card.Body>
          {children}
          <ListGroup>
            {for room in subrooms
              do (id = room._id) ->
                <RoomInfo key={room._id} room={room} search={search}
                 presence={presenceByRoom[room._id] ? {}}
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

export RoomInfo = React.memo ({room, search, presence, selected, selectRoom, leave}) ->
  {meetingId} = useParams()
  admin = useMeetingAdmin()
  {openRoom, openRoomWithDragAndDrop, starred, updateStarred} = useContext MeetingContext
  {myPresence, presenceClusters} = useMemo ->
    clusters = {}
    emptyCount = 0
    for type, presenceList of presence
      sortNames presenceList, (p) -> p.name
      clusters[type] = uniqCountNames presenceList, ((p) -> p.name),
        (p) -> emptyCount++ unless p.name?.trim()
    myPresence: findMyPresence presence
    presenceClusters: clusters
  , [presence]
  roomInfoClass = ''
  roomInfoClass += " presence-#{type}" for type of myPresence
  roomInfoClass += " selected" if selected
  roomInfoClass += " archived" if room.archived
  adminVisit = useAdminVisit()
  locked = room.locked and not admin
  [collected, drop] = useDrop ->
    accept: 'move-user'
    drop: (item) ->
      Meteor.call 'presenceMove', item.user, room._id,
        getMeetingSecret meetingId
    collect: (monitor) ->
      isHover: Boolean monitor.isOver() and monitor.canDrop()
  hoverClass = if collected.isHover then ' list-group-item-warning' else ''

  onClick = (force) -> (e) ->
    e.preventDefault()
    e.stopPropagation()
    currentRoom = Session.get 'currentRoom'
    ## Open room with focus in the following cases:
    ##   * We're not in any rooms
    ##   * Shift/Ctrl/Meta-click => force open
    ##   * We clicked on the Switch button (force == true)
    ## ...except if the room is locked
    if (not currentRoom? or e.shiftKey or e.ctrlKey or e.metaKey or
        force == true) and not locked
      openRoom room._id
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
    newRoom = await roomDuplicate room, getUpdator()
    #openRoom newRoom
    selectRoom newRoom._id, false
  onToggle = (attr) -> (e) ->
    e.preventDefault()
    e.stopPropagation()
    await meteorCallPromise 'roomEdit', addMeetingSecret meetingId,
      id: room._id
      [attr]: not room[attr]
      updator: getUpdator()
    selectRoom room._id, true
  onDragStart = (e) ->
    e.preventDefault()
    e.stopPropagation()
    openRoomWithDragAndDrop room._id, 'Open'
  toggleStar = (e) ->
    e.preventDefault()
    e.stopPropagation()
    if starred.includes room._id
      updateStarred (star for star in starred when star != room._id)
    else
      updateStarred starred.concat [room._id]

  <Link ref={drop} to={"/m/#{meetingId}##{room._id}" unless locked}
   onClick={onClick()} onDragStart={onDragStart}
   className="list-group-item list-group-item-action room-info#{roomInfoClass}#{hoverClass}"
   data-room={room._id}>
    <div className="presence-count">
      <PresenceCount type="starred" presenceClusters={presenceClusters.starred}
       onClick={toggleStar}
       heading={<b>{if myPresence.starred then 'Unstar' else 'Star'} This Room</b>}>
        {if myPresence.starred
          <FontAwesomeIcon icon={faStar}/>
        else
          <FontAwesomeIcon icon={faStarOutline}/>
        }
      </PresenceCount>
    </div>
    {if presence.joined?.length
      <div className="presence-count">
        <PresenceCount type="joined" presenceClusters={presenceClusters.joined}>
          <FontAwesomeIcon icon={faUser}/>
        </PresenceCount>
      </div>
    }
    {if room.raised or myPresence.joined
      ## Allow toggling hand only if actively in room or an admin
      canToggle = myPresence.joined or admin
      if room.raised
        label = 'Lower Hand'
        help =
          <>
            {if canToggle
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
        return unless canToggle
        Meteor.call 'roomEdit',
          id: room._id
          raised: not room.raised
          updator: getUpdator()
      <OverlayTrigger placement="top" overlay={(props) ->
        <Tooltip {...props}>{help}</Tooltip>
      }>
        <div className="raise-hand #{if room.raised then 'active' else ''}">
          {if room.raised instanceof Date
            <Timer since={room.raised}/>
          }
          {if room.raised
            <FontAwesomeIcon aria-label={label} icon={faHandPaper}
            onClick={toggleHand}/>
          else
            <FontAwesomeIcon aria-label={label} icon={faHandPaperOutline}
            onClick={toggleHand}/>
          }
        </div>
      </OverlayTrigger>
    }
    {if adminVisit and room.adminVisit instanceof Date
      <OverlayTrigger placement="top" overlay={(props) ->
        <Tooltip {...props}>
          Time since room last visited by admin or room became nonempty
        </Tooltip>
      }>
        <div className="adminVisit">
          <Timer since={room.adminVisit}/>
          <FontAwesomeIcon icon={faHourglass} className="ml-1"/>
        </div>
      </OverlayTrigger>
    }
    <Highlight className="room-title" text={room.title} search={search}/>
    {if room.locked
      <FontAwesomeIcon icon={faLock} size="sm" className="ml-1"/>
    }
    <PresenceList presenceClusters={
      if search  # show matching starred people too
        (presenceClusters.joined ? []).concat (person \
          for person in (presenceClusters.starred ? []) when person.item.match)
      else
        presenceClusters.joined
    } search={search} pronouns={myPresence.joined}/>
    {if selected
      <ButtonGroup vertical className="mx-n2 mt-2 d-block">
        {if myPresence.joined
          <>
            <Button variant="danger" onClick={onLeave}>
              <small className="mr-1"><FontAwesomeIcon icon={faTimes}/></small>
              Leave Room
              <div className="small">
                <b>Leaves</b> current call
              </div>
            </Button>
            <Button variant="primary" onClick={onSplit}>
              <small className="mr-1"><FontAwesomeIcon icon={faClone}/></small>
              Split Room
              <div className="small">
                <b>Duplicate</b> this room (forking discussion)
              </div>
            </Button>
          </>
        else
          <Button variant="warning" onClick={onClick true}
           disabled={locked}>
            <small className="mr-1"><FontAwesomeIcon icon={faDoorOpen}/></small>
            Switch to Room
            <div className="small">
              <b>Leaves</b> current call
            </div>
          </Button>
        }
        {if room.locked and admin
          <Button variant="success" onClick={onToggle 'locked'}>
            <small className="mr-1"><FontAwesomeIcon icon={faLockOpen}/></small>
            Unlock Room
            {### <div className="small"><b>Hides</b> from available room list</div> ###}
          </Button>
        }
        {if room.archived
          <Button variant="success" onClick={onToggle 'archived'}>
            <small className="mr-1"><FontAwesomeIcon icon={faTrashRestore}/></small>
            Unarchive Room
            {### <div className="small"><b>Restores</b> to available room list</div> ###}
          </Button>
        else if admin
          <Button variant="danger" onClick={onToggle 'archived'}>
            <small className="mr-1"><FontAwesomeIcon icon={faTrash}/></small>
            Archive Room
            {### <div className="small"><b>Hides</b> from available room list</div> ###}
          </Button>
        }
      </ButtonGroup>
    }
  </Link>
RoomInfo.displayName = 'RoomInfo'

presencePhrasing =
  starred:
    variant: 'secondary'
    singular: 'person starred this room'
    plural: 'people starred this room'
  joined:
    variant: 'primary'
    singular: 'person in this room'
    plural: 'people in this room'

export PresenceCount = React.memo ({type, presenceClusters, heading, children, onClick}) ->
  phrasing = presencePhrasing[type]
  presenceClusters ?= []
  <OverlayTrigger placement="top" overlay={(props) -> # eslint-disable-line react/display-name
    <Tooltip {...props}>
      {heading}
      {<br/> if heading}
      {presenceClusters.length} {if presenceClusters.length == 1 then phrasing.singular else phrasing.plural}{':' if presenceClusters.length}
      <PresenceList presenceClusters={presenceClusters} pronouns/>
    </Tooltip>
  }>
    <span className="presence-#{type}" onClick={onClick}
     aria-label="#{presenceClusters.length} #{if presenceClusters.length == 1 then phrasing.singular else phrasing.plural}">
      {presenceClusters.length or null}
      {children}
    </span>
  </OverlayTrigger>
PresenceCount.displayName = 'PresenceCount'

export PresenceList = React.memo ({presenceClusters, search, pronouns}) ->
  return null unless presenceClusters?.length
  <div className="presence">
    {for person in presenceClusters
      <React.Fragment key="#{person.item.type}:#{person.item.id}">
        <span className="presence-#{person.item.type} #{if person.item.admin then 'admin' else ''}">
          {switch person.item.type
            when 'joined'
              if person.item.admin
                <FontAwesomeIcon icon={faUserTie}/>
              else
                <FontAwesomeIcon icon={faUser}/>
            when 'starred'
              <FontAwesomeIcon icon={faStar}/>
          }
          &nbsp;
          <Highlight search={search} text={person.name}/>
          {if pronouns and person.item.pronouns
            <span className="pronouns">
              ({person.item.pronouns})
            </span>
          }
          {if person.count > 1
            <span className="ml-1 badge badge-secondary">{person.count}</span>
          }
        </span>
        {' '}
      </React.Fragment>
    }
  </div>
PresenceList.displayName = 'PresenceList'

export Timer = React.memo ({since}) ->
  recomputeTimer = ->
    delta = timesync.offset + (new Date).getTime() - since
    delta = 0 if delta < 0
    if delta <= (99*60 + 59) * 1000
      formatTimeDelta delta
    else
      '>99m'
  [timer, setTimer] = useState recomputeTimer
  useInterval ->
    setTimer recomputeTimer()
  , 1000

  <span className="timer">
    {timer}
  </span>
Timer.displayName = 'Timer'

export RoomNew = React.memo ({selectRoom}) ->
  {meetingId} = useParams()
  [title, setTitle] = useState ''
  {openRoom} = useContext MeetingContext
  submit = (e, template = 'jitsi') ->
    e.preventDefault?()
    return unless title.trim().length
    room =
      meeting: meetingId
      title: title.trim()
      updator: getUpdator()
      tabs:
        for type in template.split '+' when type  # skip blank
          {type}
    setTitle ''
    room = await meteorCallPromise 'roomNew', room
    if e.shiftKey or e.ctrlKey or e.metaKey
      openRoom room._id
      selectRoom null
    else
      selectRoom room._id, true
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
