import {Mongo} from 'meteor/mongo'
import {check, Match} from 'meteor/check'

import {validId, creatorPattern} from './id'
import {checkMeeting} from './meetings'
import {meteorCallPromise} from './meteorPromise'
import {Tabs, tabTypes, mangleTab} from './tabs'

export Rooms = new Mongo.Collection 'rooms'

export checkRoom = (room) ->
  if validId(room) and data = Rooms.findOne room
    data
  else
    throw new Error "Invalid room ID #{room}"

Meteor.methods
  roomNew: (room) ->
    check room,
      meeting: String
      title: String
      creator: creatorPattern
    unless @isSimulation
      room.created = new Date
    checkMeeting room.meeting
    Rooms.insert room
  roomEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      raised: Match.Optional Boolean
      archived: Match.Optional Boolean
      updator: creatorPattern
    room = checkRoom diff.id
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless room[key] == value
    return unless (key for key of set).length  # nothing to update
    unless @isSimulation
      set.updated = new Date
      if set.archived
        set.archived = set.updated
        set.archiver = set.updator
      if set.raised
        set.raised = set.updated
        set.raiser = set.updator
    Rooms.update diff.id,
      $set: set

export roomWithTemplate = (room) ->
  template = room.template ? ''
  delete room.template
  roomId = await meteorCallPromise 'roomNew', room
  for type in template.split '+' when type
    url = tabTypes[type].createNew()
    url = await url if url.then?
    await meteorCallPromise 'tabNew', mangleTab(
      meeting: room.meeting
      room: roomId
      type: type
      title: ''
      url: url
      creator: room.creator
    , true)
  roomId

export roomTabs = (roomId, showArchived) ->
  roomId = roomId._id if roomId._id?
  query = room: roomId
  query.archived = $in: [null, false] unless showArchived
  Tabs.find(query).fetch()

export roomDuplicate = (room, creator) ->
  tabs = roomTabs room, false
  room = checkRoom room unless room._id?
  ## Name room with existing title followed by an unused number like (2).
  i = 2
  base = room.title
  .replace /^([^]*) \(([0-9]+)\)$/, (match, prefix, number) ->
    number = parseInt number
    i = number + 1 unless isNaN number
    prefix
  while Rooms.findOne {title: title = "#{base} (#{i})"}
    i++
  ## Duplicate room
  newRoom = await meteorCallPromise 'roomNew',
    meeting: room.meeting
    title: title
    creator: creator
  ## Duplicate tabs, calling createNew method if desired to avoid e.g.
  ## identical Cocreate boards or identical Jitsi meeting rooms.
  for tab in tabs
    if createNew = tabTypes[tab.type]?.createNew
      url = createNew()
      url = await url if url.then?
    else
      url = tab.url
    await meteorCallPromise 'tabNew',
      type: tab.type
      meeting: tab.meeting
      room: newRoom
      title: tab.title
      url: url
      creator: creator
  newRoom
