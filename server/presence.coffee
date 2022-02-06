import {Presence, PresenceStream} from '/lib/presence'
import {Rooms} from '/lib/rooms'
import {pulseFrequency, logPresencePulse} from './log'

PresenceStream.allowRead 'all'    # anyone can read if they know channel ID
PresenceStream.allowWrite 'none'  # all messages from server

## On server (re)start, remove old presence values; if they're not expired,
## they will reload and reconnect.
Presence.remove {}
Rooms.update {},
  $set:
    joined: []
    adminVisit: false
,
  multi: true

## Mapping from Meteor connection id to presenceId [server only]
## Used in server/presence.coffee to destroy presence upon disconnect.
connections = {}

## Set presenceId corresponding to a connectionId
## (Called in lib/presence.coffee)
export setConnection = (connectionId, presenceId) ->
  ## Easy case: no change
  return if connections[connectionId]?.presenceId == presenceId
  ## Remove existing connection if we're re-using the same connectionId
  closeConnection connectionId if connections[connectionId]?
  ## Set data and start timer
  connections[connectionId] =
    presenceId: presenceId
    timer:
      Meteor.setInterval ->
        logPresencePulse presenceId
      , pulseFrequency

closeConnection = (connectionId) ->
  connection = connections[connectionId]
  return unless connection?
  delete connections[connectionId]
  Meteor.clearInterval connection.timer
  Meteor.call 'presenceRemove', connection.presenceId

## Detect closed DDP connections, based on a very small piece of
## https://github.com/Meteor-Community-Packages/meteor-user-status/blob/master/server/status.js
Meteor.onConnection (connection) ->
  connection.onClose ->
    closeConnection connection.id
