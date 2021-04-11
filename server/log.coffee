import {check, Match} from 'meteor/check'
import {Mongo} from 'meteor/mongo'

import {validId} from '/lib/id'
import {checkMeetingSecret} from '/lib/meetings'
import {Presence} from '/lib/presence'
import {sameSorted} from '/lib/sort'

export Log = new Mongo.Collection 'log'

## Returns an object with up to two keys
## * `old` is the fetched old presence with the same ID.
## * `diff` is an object with changed presence keys, missing if no changes.
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
  return {old} unless diff.name? or diff.admin? or diff.rooms?
  ## Write log.  Use rawCollection() to let server assign _id,
  ## which guarantees no conflict.
  Log.rawCollection().insert diff
  {old, diff}

export logPresenceRemove = (presenceId) ->
  now = new Date
  old = Presence.findOne id: presenceId
  Log.insert
    type: 'presenceLeave'
    id: presenceId
    meeting: old?.meeting
    updated: now
  {old}

Meteor.methods
  logGet: (spec) ->
    check spec,
      meeting: Match.Where validId
      secret: String
      start: Match.Optional Date
      end: Match.Optional Date
    checkMeetingSecret spec.meeting, spec.secret
    query = meeting: spec.meeting
    query.updated = {} if spec.start? or spec.to?
    query.updated.$gte = spec.start if spec.start?
    query.updated.$lte = spec.end if spec.end?
    Log.find query,
      sort: updated: 1
      fields:
        meeting: false  # redundant with query
        _id: false
    .fetch()
