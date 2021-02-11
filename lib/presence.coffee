import {Mongo} from 'meteor/mongo'
import {check, Match} from 'meteor/check'

import {validId, checkId} from './id.coffee'
import {checkMeeting} from './meetings.coffee'

export Presence = new Mongo.Collection 'presence'

## Mapping from Meteor connection id to presenceId [server only]
export connections = {}

Meteor.methods
  presenceUpdate: (presence) ->
    check presence,
      id: Match.Where validId
      meeting: Match.Where validId
      name: String
      rooms:
        joined: [Match.Where validId]
        starred: [Match.Where validId]
    unless @isSimulation
      checkMeeting presence.meeting
      connections[@connection.id] = presence.id
      presence.updated = new Date
    Presence.update
      id: presence.id
    ,
      $set:
        meeting: presence.meeting
        name: presence.name
        rooms: presence.rooms
      $setOnInsert:
        id: presence.id
    ,
      upsert: true
  presenceRemove: (presenceId) ->
    checkId presenceId
    Presence.remove id: presenceId
