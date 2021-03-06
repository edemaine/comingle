import {checkId} from '/lib/id'
import {Meetings} from '/lib/meetings'
import {Rooms} from '/lib/rooms'
import {Presence} from '/lib/presence'

Meteor.publish 'meeting', (meetingId) ->
  checkId meetingId
  [
    Meetings.find (_id: meetingId),
      fields: secret: false
    Rooms.find
      meeting: meetingId
      deleted: null
    Presence.find meeting: meetingId
  ]
