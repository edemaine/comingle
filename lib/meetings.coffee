import {validId} from './id.coffee'

export Meetings = new Mongo.Collection 'meetings'

export newMeetingRooms = Meteor.settings.public.comingle?.newMeetingRooms ? []

export checkMeeting = (meeting) ->
  if validId(meeting) and data = Meetings.findOne meeting
    data
  else
    throw new Error "Invalid meeting ID #{meeting}"

Meteor.methods
  meetingNew: (meeting) ->
    check meeting, {}
    meetingId = Meetings.insert meeting
    for room in newMeetingRooms
      Meteor.call 'roomNew', Object.assign {meeting: meetingId}, room
    meetingId
