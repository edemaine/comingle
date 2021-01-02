import bodyParser from 'body-parser';
import {Meetings} from '/lib/meetings'
import {Rooms, roomWithTemplate, roomWithTabs} from '/lib/rooms'
import {Tabs} from '/lib/tabs'

apiMethods =

  '/list': (options) ->
    try
      meeting = options.get 'meeting'
      if not meeting
        throw ("Must specify meeting ID")
      colltype = options.get 'type'
      switch colltype
        # when 'meetings' then coll = Meetings
        when 'tabs' then coll = Tabs
        else coll = Rooms
      status: 200
      json:
        ok: true
        data: coll.find({'meeting': meeting}).fetch()
    catch e
      status: 500
      json:
        ok: false
        error: e

  '/editRoom': (options, req) ->
    try
      room = req.body?.room ? options.get 'room'
      meeting = req.body?.meeting ? options.get 'meeting'
      tags = req.body?.tags

      if (meeting and tags)
        roomlist = taggedRooms meeting, tags
      else if room 
        roomlist = Rooms.find({'_id': room}).fetch()
      else 
        throw ("Must specify either room ID or meeting ID and tags to filter")
      idlist = (room._id for room in roomlist)

      checkflag = (optname, setname) ->
        getvar = options.get optname
        reqvar = req.body?[optname]
        if not getvar? and not reqvar?
          return null
        [setname] : reqvar or Boolean JSON.parse getvar

      for id in idlist
        diff = 
          id: id
          updator: { name: "Web API", presenceId: "none" } 
        diff = {...diff, ...checkflag('archive', 'archived'), ...checkflag('raise', 'raised')}
        Meteor.call 'roomEdit', diff

      status: 200
      json:
        ok: true
        data: idlist
    catch e
      status: 500
      json:
        ok: false
        error: e

  '/delete': (options) ->
    try
      colltype = options.get 'type'
      id = options.get 'id'
      switch colltype
        when 'meeting' then coll = Meetings; Rooms.remove {'meeting': id}; Tabs.remove {'meeting': id}
        when 'room' then coll = Rooms; Tabs.remove {'room': id}
        when 'tab' then coll = Tabs
      coll.remove id
      status: 200
      json:
        ok: true
        data: coll.find().fetch()
    catch e
      status: 500
      json:
        ok: false
        error: "Error listing #{colltype}: #{e}"

  '/addRoom': (options, req) ->
    try
      room = req.body
      roomId = Meteor.call 'roomWithTabs', room
      status: 200
      json:
        ok: true
        roomId: roomId
    catch e
      status: 500
      json:
        ok: false
        error: "Error adding room with tabs: #{e}"

## Allow CORS for API calls
WebApp.rawConnectHandlers.use '/api', (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Origin', '*'
  res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, OPTIONS'
  res.setHeader 'Access-Control-Allow-Headers', '*'
  next()

WebApp.connectHandlers.use '/api', bodyParser.json()

WebApp.connectHandlers.use '/api', (req, res, next) ->
  return unless req.method in ['GET', 'POST', 'OPTIONS']
  url = new URL req.url, Meteor.absoluteUrl()
  if apiMethods.hasOwnProperty url.pathname
    if req.method == 'OPTIONS'  # just report that method exists
      res.writeHead 200
      return res.end()
    else
      result = apiMethods[url.pathname] url.searchParams, req, res, next
  else
    result =
      status: 404
      json:
        ok: false
        error: "Unknown API endpoint: #{url.pathname}"
  unless res.headersSent
    res.writeHead result.status, 'Content-type': 'application/json'
  unless res.writeableEnded
    res.end JSON.stringify result.json
