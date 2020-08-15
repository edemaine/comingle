import {validId, creatorPattern} from './id.coffee'
import Settings from '../settings.coffee'

export Meetings = new Mongo.Collection 'meetings'

export checkMeeting = (meeting) ->
  if validId(meeting) and data = Meetings.findOne meeting
    data
  else
    throw new Error "Invalid meeting ID #{meeting}"

Meteor.methods
  meetingNew: (meeting) ->
    check meeting,
      creator: creatorPattern
    unless @isSimulation
      meeting.created = new Date
    meetingId = Meetings.insert meeting
    for room in Settings.newMeetingRooms ? []
      Meteor.call 'roomNew', Object.assign
        meeting: meetingId
        creator: meeting.creator
      , room
    meetingId
