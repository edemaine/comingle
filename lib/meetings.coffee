import {Mongo} from 'meteor/mongo'
import {Random} from 'meteor/random'
import {check, Match} from 'meteor/check'

import {validId, creatorPattern} from './id'
import {roomWithTemplate} from './rooms'
import {Config} from '/Config'

export Meetings = new Mongo.Collection 'meetings'

export checkMeeting = (meeting) ->
  if validId(meeting) and data = Meetings.findOne meeting
    data
  else
    throw new Meteor.Error 'checkMeeting.invalid', "Invalid meeting ID #{meeting}"

export makeMeetingSecret = ->
  Random.id()

Meteor.methods
  meetingNew: (meeting) ->
    check meeting,
      title: Match.Optional String
      creator: creatorPattern
    meeting.secret = makeMeetingSecret()
    unless @isSimulation
      meeting.created = new Date
    meetingId = Meetings.insert meeting
    unless @isSimulation
      for room in Config.newMeetingRooms ? []
        roomWithTemplate Object.assign
          meeting: meetingId
          creator: meeting.creator
        , room
    meeting._id = meetingId
    meeting
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
  meetingSecretTest: (meetingId, secret) ->
    return if @isSimulation
    meeting = checkMeeting meetingId
    check secret, String
    secret == meeting.secret
