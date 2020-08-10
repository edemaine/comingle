import {validId} from './id.coffee'

export Rooms = new Mongo.Collection 'rooms'

export checkRoom = (room) ->
  if validId(room) and data = Rooms.findOne room
    data
  else
    throw new Error "Invalid room ID #{room}"

Meteor.methods
  roomNew: (room) ->
    check room, {}
    Rooms.insert room
