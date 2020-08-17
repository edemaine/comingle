import {Random} from 'meteor/random'

import {validId, creatorPattern} from './id'
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
export trimURL = (x) -> x.replace /\/+$/, ''

export tabTypes =
  iframe:
    title: 'Web'
  cocreate:
    title: 'Cocreate'
    category: 'Whiteboard'
    instance: 'board'
    createNew: ->
      server = Settings.defaultServers.cocreate ?
               'https://cocreate.csail.mit.edu'
      url = "#{trimURL server}/api/roomNew?grid=1"
      response = await fetch url
      json = await response.json()
      json.url
  jitsi:
    title: 'Jitsi'
    longTitle: 'Jitsi Meet'
    category: 'Video Conference'
    instance: 'room'
    alwaysRender: true
    onePerRoom: true
    keepVisible: true
    createNew: ->
      server = Settings.defaultServers.jitsi ? 'https://meet.jit.si'
      "#{trimURL server}/comingle/#{Random.id()}"
  youtube:
    title: 'YouTube'
  zoom:
    title: 'Zoom'
    category: 'Zoom'
    alwaysRender: true
    onePerRoom: true
    keepVisible: true

Meteor.methods
  tabNew: (tab) ->
    pattern =
      type: String
      meeting: String
      room: String
      title: String
      url: Match.Where checkURL
      creator: creatorPattern
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
    unless @isSimulation
      tab.created = new Date
    Tabs.insert tab
  tabEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      archived: Match.Optional Boolean
      updator: creatorPattern
    tab = checkTab diff.id
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless tab[key] == value
    return unless (key for key of set).length  # nothing to update
    unless @isSimulation
      set.updated = new Date
    Tabs.update diff.id,
      $set: set

export zoomRegExp =
    ///^(https://[^/]*zoom.us/) (?: j/([0-9]*))? (?: \?pwd=(\w*))? ///

export mangleTab = (tab, dropManualTitle) ->
  tab.url = tab.url.trim()
  return tab unless tab.url and validURL tab.url

  ## Force type if we recognize default servers
  for service in ['cocreate', 'jitsi']
    server = Settings.defaultServers[service]
    continue unless server?
    if tab.url.startsWith server
      tab.type = service

  ## YouTube URL mangling into embed link, based on examples from
  ## https://gist.github.com/rodrigoborgesdeoliveira/987683cfbfcc8d800192da1e73adc486
  tab.url = tab.url.replace ///
    ^ (?: http s? : )? //
    (?: youtu\.be/ |
      (?: www\. | m\. )? youtube (-nocookie)? .com /
        (?: v/ | vi/ | e/ | embed/ |
          (?: watch )? \? (?: feature=[^&]* & )? v i? = )
    )
    ( [\w\-]+ ) [^]*
  ///i, (match, nocookie, video) ->
    tab.type = 'youtube'
    "https://www.youtube#{nocookie ? ''}.com/embed/#{video}"

  ## Zoom URL detection
  if ///^https://[^/]*zoom.us/ ///.test tab.url
    tab.type = 'zoom'

  ## Automatic title
  unless tab.title?.trim()
    tab.manualTitle = false
  if tab.manualTitle == false
    if tab.type == 'iframe'
      tab.title = (new URL tab.url).hostname
    else
      tab.title = tabTypes[tab.type].title if tab.type of tabTypes
  delete tab.manualTitle if dropManualTitle

  tab
