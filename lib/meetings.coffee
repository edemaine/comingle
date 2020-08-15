import {validId} from './id.coffee'
import Settings from '../settings.coffee'

export Meetings = new Mongo.Collection 'meetings'

export checkMeeting = (meeting) ->
  if validId(meeting) and data = Meetings.findOne meeting
    data
  else
    throw new Error "Invalid meeting ID #{meeting}"

Meteor.methods
  meetingNew: (meeting) ->
    check meeting, {}
    unless @isSimulation
      meeting.created = new Date
    meetingId = Meetings.insert meeting
    for room in Settings.newMeetingRooms ? []
      Meteor.call 'roomNew', Object.assign {meeting: meetingId}, room
    meetingId
