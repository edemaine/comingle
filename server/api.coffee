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

  '/archiveRoom': (options) ->
    try
      room = options.get 'room'
      if not room
        throw ("Must specify room ID")
      result = Meteor.call 'roomEdit',
        id: room
        archived: Boolean JSON.parse options.get 'archive'
        updator: { name: "Web API", presenceId: "none" }
      status: 200
      json:
        ok: true
        data: Rooms.find({'_id': room}).fetch()
    catch e
      status: 500
      json:
        ok: false
        error: e

  '/raiseHand': (options) ->
    try
      room = options.get 'room'
      if not room
        throw ("Must specify room ID")
      result = Meteor.call 'roomEdit',
        id: room
        raised: Boolean JSON.parse options.get 'raise'
        updator: { name: "Web API", presenceId: "none" }
      status: 200
      json:
        ok: true
        data: Rooms.find({'_id': room}).fetch()
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
