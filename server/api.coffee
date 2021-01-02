import bodyParser from 'body-parser';
import {Meetings} from '/lib/meetings'
import {Rooms, roomWithTemplate, roomWithTabs, taggedRooms} from '/lib/rooms'
import {Tabs} from '/lib/tabs'

apiMethods =

  '/list': (options, req) ->
    try
      meeting = req.body?.meeting ? options.get 'meeting'
      if not meeting
        throw ("Must specify meeting ID")
      colltype = req.body?.type ? options.get 'type'
      switch colltype
        # when 'meetings' then coll = Meetings
        when 'tabs' then coll = Tabs.find({'meeting': meeting}).fetch()
        else coll = taggedRooms meeting, req.body?.tags
      status: 200
      json:
        ok: true
        data: coll
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
          tags: req.body?.settags ? {}
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
WebApp.connectHandlers.use '/api', (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Origin', '*'
  next()

WebApp.connectHandlers.use '/api', bodyParser.json()

WebApp.connectHandlers.use '/api', (req, res, next) ->
  return unless req.method in ['GET', 'POST']
  url = new URL req.url, Meteor.absoluteUrl()
  if apiMethods.hasOwnProperty url.pathname
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
