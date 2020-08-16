import {validId, creatorPattern} from './id'
import {checkMeeting} from './meetings'
import {meteorCallPromise} from './meteorPromise'
import {tabTypes, mangleTab} from './tabs'

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
    meeting = checkMeeting room.meeting
    Rooms.insert room
  roomEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      raised: Match.Optional Boolean
      updator: creatorPattern
    unless @isSimulation
      diff.updated = new Date
      diff.raised = diff.updated if diff.raised
    room = checkRoom diff.id
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless room[key] == value
    return unless (key for key of set).length  # nothing to update
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
