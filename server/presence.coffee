import {Presence, connections} from '/lib/presence'

## On server (re)start, remove old presence values; if they're not expired,
## they will reload and reconnect.
Presence.remove {}

## Detect closed DDP connections, based on a very small piece of
## https://github.com/Meteor-Community-Packages/meteor-user-status/blob/master/server/status.js
Meteor.onConnection (connection) ->
  connection.onClose ->
    presenceId = connections[connection.id]
    Meteor.call 'presenceRemove', presenceId if presenceId?
