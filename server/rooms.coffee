import {checkId} from '/lib/id'
import {Rooms} from '/lib/rooms'
import {Tables} from '/lib/tables'

Meteor.publish 'room', (roomId) ->
  checkId roomId
  [
    Rooms.find _id: roomId
    Tables.find room: roomId
  ]
