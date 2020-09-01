import {Mongo} from 'meteor/mongo'
import {check, Match} from 'meteor/check'

import {checkId, creatorPattern} from '/lib/id'
import {ChatStream} from '/lib/chat'
import {Meetings} from '/lib/meetings'
import {Rooms} from '/lib/rooms'

ChatStream.allowRead 'all'    # anyone can read if they know channel ID
ChatStream.allowWrite 'none'  # all messages from server

export Chat = new Mongo.Collection 'chat'

Meteor.methods
  chatLastN: (channel, n, before) ->
    checkId channel
    check n, Match.Integer
    check before, Match.Maybe Date
    query = channel: channel
    query.sent = $lt: before if before?
    Chat.find query,
      sort: sent: -1
      limit: n
    .fetch()
  chatSince: (channel, date) ->
    checkId channel
    check date, Date
    Chat.find
      channel: channel
      sent: $gt: date
    .fetch()
  chatSend: (message) ->
    check message,
      channel: String
      sender: creatorPattern
      type: 'msg'
      body: String
    message.sent = new Date
    unless Meetings.findOne(message.channel) or Rooms.findOne(message.channel)
      throw new Error "Invalid channel #{message.channel}"
    message._id = Chat.insert message
    ChatStream.emit message.channel, message
