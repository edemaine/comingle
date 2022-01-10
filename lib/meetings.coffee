import {Mongo} from 'meteor/mongo'
import {Random} from 'meteor/random'
import {check, Match} from 'meteor/check'

import {validId, updatorPattern} from './id'
import {Config} from '/Config'

export Meetings = new Mongo.Collection 'meetings'

export checkMeeting = (meeting) ->
  if validId(meeting) and data = Meetings.findOne meeting
    data
  else
    throw new Meteor.Error 'checkMeeting.invalid', "Invalid meeting ID #{meeting}"

export checkMeetingSecret = (meeting, secret) ->
  meeting = checkMeeting meeting if typeof meeting == 'string'
  unless meeting?.secret? and meeting.secret == secret
    throw new Meteor.Error 'checkMeetingSecret.invalid', "Incorrect meeting secret for meeting #{meeting._id}"

export makeMeetingSecret = ->
  Random.id()

meetingCheckSecret = (op, meeting) ->
  return if Meteor.isClient
  if op.secret
    checkMeetingSecret meeting, op.secret
    delete op.secret

Meteor.methods
  meetingNew: (meeting) ->
    check meeting,
      title: Match.Optional String
      updator: updatorPattern
    meeting.secret = makeMeetingSecret()
    unless @isSimulation
      meeting.created = new Date
    meetingId = Meetings.insert meeting
    unless @isSimulation
      for room in Config.newMeetingRooms ? []
        Meteor.call 'roomNew', Object.assign room,
          meeting: meetingId
          updator: meeting.updator
    meeting._id = meetingId
    meeting
  meetingEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      defaultSort: Match.Optional {
        gather: Match.Optional String
        key: Match.Optional String
        reverse: Match.Optional Boolean
      }
      updator: updatorPattern
      secret: Match.Optional String
    unless @isSimulation
      diff.updated = new Date
    meeting = checkMeeting diff.id
    meetingCheckSecret diff, meeting
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
  meetingGet: (query) ->
    check query,
      meeting: Match.Optional Match.Where validId
      meetings: Match.Optional [Match.Where validId]
      secret: Match.Optional String
    unless query.meeting? or query.meetings?
      throw new Meteor.Error 'meetingGet.underspecified', 'Need to specify meeting or meetings'
    if query.meeting?
      search = _id: query.meeting
    if query.meetings?
      search = _id: $in: query.meetings
    Meetings.find search,
      fields: secret: false
    .fetch()
