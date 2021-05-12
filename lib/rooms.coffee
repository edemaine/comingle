import {Mongo} from 'meteor/mongo'
import {check, Match} from 'meteor/check'

import {validId, updatorPattern} from './id'
import {checkMeeting, checkMeetingSecret} from './meetings'
import {meteorCallPromise} from './meteorPromise'
import {Tabs, tabTypes, checkURL} from './tabs'

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
    for key in ['protected', 'deleted']  # admin-only
      if op[key]?
        throw new Meteor.Error 'roomCheckSecret.unauthorized', "Need meeting secret to use #{key} flag"
    if room.protected
      for key in ['title', 'archived']  # allow 'raised'
        if op[key]?
          throw new Meteor.Error 'roomCheckSecret.protected', "Need meeting secret to modify #{key} in protected room #{room._id}"

export dateFlags = ['archived', 'protected', 'deleted', 'raised']
export setUpdated = (op) ->
  op.updated = new Date
  for key in dateFlags
    if op[key]
      op[key] = op.updated
      # archiver, protecter, deleter, raiser
      op["#{key[...key.length-1]}r"] = op.updator
    ## Use null to indicate false.  (For examples of use, see
    ## publications in server/rooms.coffee and server/tabs.coffee.)
    else if op[key] == false
      op[key] = null
      op["un#{key[...key.length-1]}r"] = op.updator

Meteor.methods
  roomNew: (room) ->
    check room,
      meeting: Match.Where validId
      title: String
      archived: Match.Optional Boolean
      protected: Match.Optional Boolean
      updator: updatorPattern
      secret: Match.Optional String
      tags: Match.Optional Object
      tabs: Match.Optional [
        type: Match.Optional String
        title: Match.Optional String
        url: Match.Optional Match.Where checkURL
        archived: Match.Optional Boolean
      ]
    secret = room.secret  # gets deleted by roomCheckSecret
    ## Check tabs for validity
    tabs = room.tabs ? []
    delete room.tabs
    ## Prepare room
    room.creator = room.updator
    unless @isSimulation
      setUpdated room
      room.created = room.updated
      meeting = checkMeeting room.meeting
      roomCheckSecret room, room, meeting
    room.joined = []
    room.adminVisit = false
    roomId = Rooms.insert room
    room._id = roomId
    ## Add tabs
    for tab in tabs
      tab = Object.assign {}, tab
      tab.secret = secret if secret?
      Meteor.call 'tabNew', Object.assign tab,
        meeting: room.meeting
        room: roomId
        updator: room.updator
    room
  roomEdit: (diff) ->
    check diff,
      id: Match.Where validId
      title: Match.Optional String
      raised: Match.Optional Boolean
      archived: Match.Optional Boolean
      deleted: Match.Optional Boolean
      protected: Match.Optional Boolean
      updator: updatorPattern
      secret: Match.Optional String
      tags: Match.Optional Object
    room = checkRoom diff.id
    roomCheckSecret diff, room
    set = {}
    for key, value of diff when key != 'id' and key != 'tags'
      set[key] = value unless room[key] == value
    for key, value of diff.tags ? {}
      set["tags."+key] = value
    return unless (key for key of set).length  # nothing to update
    unless @isSimulation
      setUpdated set
    Rooms.update diff.id,
      $set: set
  roomGet: (query) ->
    check query,
      meeting: Match.Optional Match.Where validId
      room: Match.Optional Match.Where validId
      rooms: Match.Optional [Match.Where validId]
      title: Match.Optional Match.OneOf String, RegExp
      raised: Match.Optional Boolean
      archived: Match.Optional Boolean
      deleted: Match.Optional Boolean
      protected: Match.Optional Boolean
      secret: Match.Optional String
    delete query[key] for key of query when not query[key]?
    unless query.meeting? or query.room? or query.rooms?
      throw new Meteor.Error 'roomGet.underspecified', 'Need to specify meeting, room, or rooms'
    if query.room?
      query._id = query.room
      delete query.room
    if query.rooms?
      query._id = $in: query.rooms
      delete query.rooms
    if query.secret
      checkMeetingSecret query.meeting, query.secret
      delete query.secret
    else
      ## Only admins can see deleted rooms
      query.deleted = false
    for key in dateFlags
      if query[key]
        query[key] = $ne: null
      else if query[key] == false
        query[key] = null
    Rooms.find(query).fetch()

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

export roomTabs = (roomId, showArchived) ->
  roomId = roomId._id if roomId._id?
  query = room: roomId
  query.archived = null unless showArchived
  Tabs.find(query).fetch()

export roomDuplicate = (room, updator) ->
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
    updator: updator
  ## Duplicate tabs, calling createNew method if desired to avoid e.g.
  ## identical Cocreate boards or identical Jitsi meeting rooms.
  for tab in tabs
    if (createNew = tabTypes[tab.type]?.createNew)?
      url = createNew()
      url = await url if url.then?
    else
      url = tab.url
    await meteorCallPromise 'tabNew',
      type: tab.type
      meeting: tab.meeting
      room: newRoom._id
      title: tab.title
      url: url
      updator: updator
  newRoom
