import {validId, creatorPattern} from './id'
import {roomWithTemplate} from './rooms'
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
    unless @isSimulation
      for room in Settings.newMeetingRooms ? []
        roomWithTemplate Object.assign
          meeting: meetingId
          creator: meeting.creator
        , room
    meetingId
