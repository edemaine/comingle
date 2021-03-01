import {Mongo} from 'meteor/mongo'
import {check, Match} from 'meteor/check'

import {validId, creatorPattern} from './id'
import {checkMeeting, checkMeetingSecret} from './meetings'
import {meteorCallPromise} from './meteorPromise'
import {Tabs, tabTypes, mangleTab} from './tabs'

export Rooms = new Mongo.Collection 'rooms'

export checkRoom = (room) ->
  if validId(room) and data = Rooms.findOne room
    data
  else
    throw new Meteor.Error 'checkRoom.invalid', "Invalid room ID #{room}"

roomCheckSecret = (op, room, meeting) ->
  return if Meteor.isClient
  if op.secret
    checkMeetingSecret (meeting ? room?.meeting), op.secret
    delete op.secret
  else
    for key in ['protected']
      if op[key]?
        throw new Meteor.Error 'roomCheckSecret.unauthorized', "Need meeting secret to use '#{key}' flag"
    if room.protected
      for key in ['title', 'archived']  # allow 'raised'
        if op[key]?
          throw new Meteor.Error 'roomCheckSecret.protected', "Need meeting secret to modify #{key} in protected room #{room._id}"

setUpdated = (op) ->
  op.updated = new Date
  if op.archived
    op.archived = op.updated
    op.archiver = op.updator
  if op.protected
    op.protected = op.updated
    op.protecter = op.updator
  if op.raised
    op.raised = op.updated
    op.raiser = op.updator

Meteor.methods
  roomNew: (room) ->
    check room,
      meeting: String
      title: String
      archived: Match.Optional Boolean
      protected: Match.Optional Boolean
      creator: creatorPattern
      secret: Match.Optional String
    unless @isSimulation
      setUpdated room
      room.created = room.updated
      meeting = checkMeeting room.meeting
      roomCheckSecret room, room, meeting
    room.joined = []
    room.adminVisit = false
    Rooms.insert room
  roomEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      raised: Match.Optional Boolean
      archived: Match.Optional Boolean
      protected: Match.Optional Boolean
      updator: creatorPattern
      secret: Match.Optional String
    room = checkRoom diff.id
    roomCheckSecret diff, room
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless room[key] == value
    return unless (key for key of set).length  # nothing to update
    unless @isSimulation
      setUpdated set
    Rooms.update diff.id,
      $set: set

## Server-only methods to maintain `joined` list
export roomJoin = (roomId, presence) ->
  Rooms.update
    _id: roomId
  ,
    $push: joined:
      presenceId: presence.id
      name: presence.name
      admin: presence.admin
  roomCheck roomId, joined: true
export roomChange = (roomId, presenceDiff) ->
  set = {}
  set["joined.$.admin"] = presenceDiff.admin if presenceDiff.admin?
  set["joined.$.name"] = presenceDiff.name if presenceDiff.name?
  return unless (key for own key of set).length
  Rooms.update
    _id: roomId
    joined: $elemMatch: presenceId: presenceDiff.id
  ,
    $set: set
  roomCheck roomId, adminLeft: presenceDiff.admin == false
export roomLeave = (roomId, presence) ->
  Rooms.update
    _id: roomId
  ,
    $pull: joined: presenceId: presence.id
  roomCheck roomId, adminLeft: presence.admin
roomCheck = (roomId, options) ->
  room = Rooms.findOne roomId
  unless room?
    return console.error "Invalid room ID: #{roomId}"
  ## Lower hand in empty rooms
  if not room.joined.length and room.raised
    Rooms.update
      _id: roomId
    ,
      $set: raised: false
  ## Maintain adminVisit = Date of last admin visit or room became occupied,
  ## or true if room has an admin right now, or false if room is empty.
  if room.joined.length
    admins = (presence for presence in room.joined when presence.admin).length
    if admins
      adminVisit = true
    else if options?.adminLeft or (options?.joined and room.joined.length == 1)
      adminVisit = new Date
  else
    adminVisit = false
  if adminVisit? and adminVisit != room.adminVisit
    Rooms.update
      _id: roomId
    ,
      $set: adminVisit: adminVisit

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
