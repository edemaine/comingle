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
      title: Match.Optional String
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
  meetingEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      updator: creatorPattern
    unless @isSimulation
      diff.updated = new Date
    meeting = checkMeeting diff.id
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless meeting[key] == value
    return unless (key for key of set).length  # nothing to update
    Meetings.update diff.id,
      $set: set
