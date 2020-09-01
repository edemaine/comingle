import {useEffect, useState} from 'react'
import {Mongo} from 'meteor/mongo'

import {ChatStream} from '/lib/chat'

export Chat = new Mongo.Collection null  # client collection

export useChat = (channel, initial = 50) ->
  [loading, setLoading] = useState true
  useEffect ->
    injestMsg = (msg) ->
      ## Insert received message, replacing any message with same _id
      Chat.update msg._id, msg, upsert: true
    ChatStream.on channel, injestMsg
    injestMsgs = (error, msgs) ->
      return console.error error if error
      injestMsg msg for msg in msgs
      setLoading false
    catchup = ->
      last = ChatStream.getLastMessageFromEvent channel
      setLoading true
      if last?.sent?
        Meteor.call 'chatSince', channel, last, injestMsgs
      else
        Meteor.call 'chatLastN', channel, initial, injestMsgs
    ChatStream.onReconnect catchup
    catchup()  # initial fetch
    ## Cleanup:
    -> ChatStream.unsubscribe channel
  , [channel]
  loading
