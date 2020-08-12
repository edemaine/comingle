import {validId} from './id.coffee'
import {checkRoom} from './rooms.coffee'

export Presence = new Mongo.Collection 'presence'

Meteor.methods
  presenceUpdate: (presence) ->
    check presence,
      id: Match.Where validId
      room: Match.Where validId
      name: String
      tables:
        visible: [Match.Where validId]
        invisible: [Match.Where validId]
    unless @isSimulation
      room = checkRoom presence.room
    Presence.update
      id: presence.id
      room: presence.room
    ,
      $set:
        name: presence.name
        tables: presence.tables
      $setOnInsert:
        id: presence.id
        room: presence.room
    ,
      upsert: true
