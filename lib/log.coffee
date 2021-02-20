import {Mongo} from 'meteor/mongo'

import {Presence} from './presence'
import {sameSorted} from './sort'

Log = new Mongo.Collection 'log' if Meteor.isServer
export {Log}

export logPresence = (presence) ->
  old = Presence.findOne id: presence.id
  diff = type:
    if old?
      'presenceUpdate'
    else
      'presenceJoin'
  ## Always include id, meeting, updated
  diff.id = presence.id
  diff.meeting = presence.meeting
  diff.updated = presence.updated
  ## Diff name and rooms
  diff.name = presence.name unless old? and old.name == presence.name
  diff.admin = presence.admin unless old? and old.admin == presence.admin
  diff.rooms = {}
  for key of presence.rooms
    unless old? and sameSorted old.rooms[key], presence.rooms[key]
      diff.rooms[key] = presence.rooms[key]
  delete diff.rooms unless (key for key of diff.rooms).length
  ## Check for no-op update
  return false unless diff.name? or diff.admin? or diff.rooms?
  ## Write log
  Log.insert diff
  true

export logPresenceRemove = (presenceId) ->
  now = new Date
  old = Presence.findOne id: presenceId
  Log.insert
    type: 'presenceLeave'
    id: presenceId
    meeting: old?.meeting
    updated: now
