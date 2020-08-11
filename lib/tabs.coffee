import {validId} from './id'
import {checkRoom} from './rooms'
import {checkTable} from './tables'

export Tabs = new Mongo.Collection 'tabs'

export checkTab = (tab) ->
  if validId(tab) and data = Tabs.findOne tab
    data
  else
    throw new Error "Invalid tab ID #{tab}"

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
      title: String
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
  tabEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
    tab = checkTab diff.id
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless tab[key] == value
    return unless (key for key of set).length  # nothing to update
    Tabs.update diff.id,
      $set: set
