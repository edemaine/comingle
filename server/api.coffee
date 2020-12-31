import bodyParser from 'body-parser';
import {Meetings} from '/lib/meetings'
import {Rooms, roomWithTemplate, roomWithTabs} from '/lib/rooms'
import {Tabs} from '/lib/tabs'

apiMethods =

  '/list': (options) ->
    try
      colltype = options.get 'type'
      switch colltype
        when 'meetings' then coll = Meetings
        when 'rooms' then coll = Rooms
        when 'tabs' then coll = Tabs
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
