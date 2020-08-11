import {validId} from './id'
import {checkRoom} from './rooms'
import {checkTable} from './tables'

export Tabs = new Mongo.Collection 'tabs'

export validURL = (url) ->
  return false unless typeof url == 'string'
  try
    new URL url
    true
  catch
    false
export checkURL = (url) ->
  unless validURL url
    throw new Error "Invalid URL #{url}"
  true

Meteor.methods
  tabNew: (tab) ->
    pattern =
      type: String
      room: String
      table: String
    switch tab?.type
      when 'iframe'
        Object.assign pattern,
          url: Match.Where checkURL
      else
        throw new Error "Invalid tab type: #{tab?.type}"
    check tab, pattern
    room = checkRoom tab.room
    table = checkTable tab.table
    if tab.room != table.room
      throw new Error "Room #{tab.room} doesn't match table #{tab.table}'s room #{table.room}"
    Tabs.insert tab
