import {Mongo} from 'meteor/mongo'
import {check, Match} from 'meteor/check'
import {fetch} from 'meteor/fetch'
import {Random} from 'meteor/random'

import {validId, updatorPattern} from './id'
import {checkMeeting, checkMeetingSecret} from './meetings'
import {checkRoom, setUpdated, dateFlags} from './rooms'
import {Config} from '/Config'

export Tabs = new Mongo.Collection 'tabs'

export checkTab = (tab) ->
  if validId(tab) and data = Tabs.findOne tab
    data
  else
    throw new Meteor.Error 'checkTab.invalid', "Invalid tab ID #{tab}"

export validURL = (url) ->
  return false unless typeof url == 'string'
  try
    new URL url
    true
  catch
    false
export checkURL = (url) ->
  unless validURL url
    throw new Meteor.Error 'checkURL.invalid', "Invalid URL #{url}"
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
      server = Config.defaultServers.cocreate ?
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
      server = Config.defaultServers.jitsi ? 'https://meet.jit.si'
      "#{trimURL server}/comingle/#{Random.id()}"
  youtube:
    title: 'YouTube'
  zoom:
    title: 'Zoom'
    category: 'Video Conference'
    alwaysRender: true
    onePerRoom: true
    keepVisible: true

export categories =
  'Video Conference':
    onePerRoom: true

tabCheckSecret = (op, tab, room, meeting) ->
  return if Meteor.isClient
  if op.secret
    checkMeetingSecret (meeting ? tab?.meeting), op.secret
    delete op.secret
  else
    for key in ['deleted']  # admin-only
      if op[key]?
        throw new Meteor.Error 'tabCheckSecret.unauthorized', "Need meeting secret to use #{key} flag"
    room ?= checkRoom tab.room
    if room.protected
      throw new Meteor.Error 'tabCheckSecret.protected', "Need meeting secret to modify tab in protected room #{tab.room}"

Meteor.methods
  tabNew: (tab) ->
    check tab,
      type: Match.Optional String  # default set via mangleTab
      meeting: String
      room: String
      title: Match.Optional String  # default set via mangleTab
      url: Match.Optional Match.Where checkURL  # default set via mangleTab
      archived: Match.Optional Boolean
      updator: updatorPattern
      secret: Match.Optional String
    tab.type ?= 'iframe'  # default if mangleTab doesn't set it
    unless tab.type of tabTypes
      throw new Meteor.Error 'tabNew.invalidType', "Invalid tab type: #{tab?.type}"
    unless @isSimulation  # avoid calling createNew() on both client and server
      unless tab.url
        unless tabTypes[tab.type].createNew?
          throw new Meteor.Error 'tabNew.uncreatable', 'Tab needs to have url or creatable type'
        tab.url = tabTypes[tab.type].createNew()
        tab.url = await tab.url if tab.url.then?
        check tab.url, Match.Where checkURL
      tab = mangleTab tab, true
      check tab.title, String
    meeting = checkMeeting tab.meeting
    room = checkRoom tab.room
    tabCheckSecret tab, tab, room, meeting
    if tab.meeting != room.meeting
      throw new Meteor.Error 'tabNew.wrongMeeting', "Meeting #{tab.meeting} doesn't match room #{tab.room}'s meeting #{room.meeting}"
    tab.creator = tab.updator
    unless @isSimulation
      setUpdated tab
      tab.created = tab.updated
    tab._id = Tabs.insert tab
    tab
  tabEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
      archived: Match.Optional Boolean
      deleted: Match.Optional Boolean
      #protected: Match.Optional Boolean
      updator: updatorPattern
      secret: Match.Optional String
    tab = checkTab diff.id
    tabCheckSecret diff, tab
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless tab[key] == value
    return unless (key for key of set).length  # nothing to update
    unless @isSimulation
      setUpdated set
    Tabs.update diff.id,
      $set: set
  tabGet: (query) ->
    check query,
      meeting: Match.Optional Match.Where validId
      room: Match.Optional Match.Where validId
      rooms: Match.Optional [Match.Where validId]
      tab: Match.Optional Match.Where validId
      tabs: Match.Optional [Match.Where validId]
      type: Match.Optional Match.OneOf String, RegExp
      title: Match.Optional Match.OneOf String, RegExp
      url: Match.Optional Match.OneOf String, RegExp
      archived: Match.Optional Boolean
      deleted: Match.Optional Boolean
      #protected: Match.Optional Boolean
      secret: Match.Optional String
    delete query[key] for key of query when not query[key]?
    unless query.meeting? or query.room? or query.rooms? or query.tab? or query.tabs?
      throw new Meteor.Error 'tabGet.underspecified', 'Need to specify meeting, room, rooms, tab, or tabs'
    if query.rooms?
      query.room = $in: query.rooms
      delete query.rooms
    if query.tab?
      query._id = query.tab
      delete query.tab
    if query.tabs?
      query._id = $in: query.tabs
      delete query.tabs
    if query.secret
      checkMeetingSecret query.meeting, query.secret
      delete query.secret
    else
      ## Only admins can see deleted tabs
      query.deleted = false
    for key in dateFlags
      if query[key]
        query[key] = $ne: null
      else if query[key] == false
        query[key] = null
    Tabs.find(query).fetch()

export zoomRegExp =
    ///^(https://[^/]*zoom.us/) (?: j/([0-9]*))? (?: \?pwd=(\w*))? ///

export mangleTab = (tab, dropManualTitle) ->
  tab.url = tab.url.trim()
  return tab unless tab.url

  ## Automatic https:// protocol if unspecified
  if /^\w+[\./]/.test tab.url
    tab.url = "https://#{tab.url}"

  return tab unless validURL tab.url

  ## Force type if we recognize default servers
  for service in ['cocreate', 'jitsi']
    server = Config.defaultServers[service]
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
