import {validId} from './id'
import {checkMeeting} from './meetings'
import {checkRoom} from './rooms'
import Settings from '../settings.coffee'

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

export tabTypes =
  iframe:
    title: 'Web'
  cocreate:
    title: 'Cocreate'
    category: 'Whiteboard'
    instance: 'board'
  jitsi:
    title: 'Jitsi'
    longTitle: 'Jitsi Meet'
    category: 'Video Conference'
    instance: 'room'
  youtube:
    title: 'YouTube'

Meteor.methods
  tabNew: (tab) ->
    pattern =
      type: String
      meeting: String
      room: String
      title: String
      url: Match.Where checkURL
    unless tab.type of tabTypes
      throw new Error "Invalid tab type: #{tab?.type}"
    #switch tab?.type
    #  when 'iframe', 'cocreate', 'jitsi'
    #    Object.assign pattern,
    #      url: Match.Where checkURL
    #  else
    #    throw new Error "Invalid tab type: #{tab?.type}"
    check tab, pattern
    meeting = checkMeeting tab.meeting
    room = checkRoom tab.room
    if tab.meeting != room.meeting
      throw new Error "Meeting #{tab.meeting} doesn't match room #{tab.room}'s meeting #{room.meeting}"
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
