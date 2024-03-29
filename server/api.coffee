## API via /api HTTP GET/POST.  See /doc/api.md for documentation

import {check, Match} from 'meteor/check'
import {EJSON} from 'meteor/ejson'
import bodyParser from 'body-parser'

import {validId, updatorPattern} from '/lib/id'
import {checkMeeting, checkMeetingSecret} from '/lib/meetings'
import {checkRoom} from '/lib/rooms'
import {checkTab} from '/lib/tabs'

apiId = 'API'

## Allow string updator (just specifying name) or empty updator.
## Missing fields filled by `apiId`.
apiUpdator = (options) ->
  check options.updator, Match.Optional Match.OneOf String, updatorPattern
  unless options.updator?
    options.updator =
      name: apiId
      presenceId: apiId
  else if typeof options.updator == 'string'
    options.updator =
      name: options.updator
      presenceId: apiId

checker =
  meeting: checkMeeting
  room: checkRoom
  tab: checkTab
apiGet = (type) -> (options) ->
  delete options.updator  # for consistency across different API calls
  "#{type}s": Meteor.call "#{type}Get", options
apiNew = (type) -> (options) ->
  ## /api/meeting/new cannot require secret, but other operations do
  checkMeetingSecret options.meeting, options.secret unless type == 'meeting'
  apiUpdator options
  "#{type}s": Meteor.call "#{type}New", options
apiEdit = (type) -> (options) ->
  types = "#{type}s"
  checkMeetingSecret options.meeting ? options[types]?.meeting ?
                     checker[type]?(options[type]).meeting, options.secret
  delete options.meeting unless type == 'meeting'
  unless options[type]? or options[types]?
    throw new Meteor.Error "api/#{type}/edit.underspecified", "Must specify #{type} or #{types}"
  if options[type]?
    check options[type], Match.Where validId
    ids = [options[type]]
    delete options[type]
  if options[types]?
    if options[types] instanceof Array
      check options[types], [Match.Where validId]
      ids = options[types]
    else
      ids =
        for obj in Meteor.call "#{type}Get", options[types]
          obj._id
    delete options[types]
  apiUpdator options
  for id in ids
    Meteor.call "#{type}Edit", Object.assign {id}, options
  "#{types}": Meteor.call "#{type}Get", "#{types}": ids

apiMethods =
  '/meeting/get': apiGet 'meeting'
  '/room/get': apiGet 'room'
  '/tab/get': apiGet 'tab'
  '/meeting/new': apiNew 'meeting'
  '/room/new': apiNew 'room'
  '/tab/new': apiNew 'tab'
  '/meeting/edit': apiEdit 'meeting'
  '/room/edit': apiEdit 'room'
  '/tab/edit': apiEdit 'tab'
  '/log/get': (options) ->
    delete options.updator  # for consistency across different API calls
    ## Allow `finish` as an alternative to `end`
    if options.finish?
      options.end ?= options.finish
      delete options.finish
    for key in ['start', 'end']
      if isDate options[key]
        options[key] = new Date options[key]
    logs: Meteor.call 'logGet', options

## Allow CORS for API calls
WebApp.rawConnectHandlers.use '/api', (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Origin', '*'
  res.setHeader 'Access-Control-Allow-Methods', 'GET, POST, OPTIONS'
  res.setHeader 'Access-Control-Allow-Headers', '*'
  next()

WebApp.connectHandlers.use '/api', bodyParser.text type: 'application/json'

# https://262.ecma-international.org/11.0/#sec-date-time-string-format
isDate = (value) ->
  typeof value == 'string' and
  ///^
    ([+\-]\d\d)?       # 6-digit year
    \d\d\d\d           # YYYY
    (-\d\d             # -MM
      (-\d\d           # -DD
      )?
    )  # Spec doesn't require month, but we do, to distinguish from integers
    (T\d\d:\d\d        # THH:mm
      (:\d\d           # :ss
        (.\d\d\d       # .sss
        )?
      )?
      (Z               # Z (UTC)
      |[+\-]\d\d:\d\d  # +-HH:mm (UTC offset)
      )?
    )?
    $
  ///.test value

WebApp.connectHandlers.use '/api', (req, res) ->
  return unless req.method in ['GET', 'POST', 'OPTIONS']
  url = new URL req.url, Meteor.absoluteUrl()
  if Object.hasOwnProperty.call apiMethods, url.pathname
    if req.method == 'OPTIONS'  # just report that method exists
      res.writeHead 200
      return res.end()
    else
      try
        ## Allow options to be specified as an EJSON-encoded body and/or
        ## query strings in the URL.
        ## See https://docs.meteor.com/api/ejson.html for the EJSON spec.
        if req.body and typeof req.body == 'string'
          options = EJSON.parse req.body
        else
          options = {}
        for [key, value] from url.searchParams
          ## Query string values can be straight IDs (e.g.
          ## meeting, room, or tab IDs) or EJSON-encoded objects.
          if validId value
            options[key] = value
          else if isDate value
            options[key] = new Date value
          else
            options[key] = EJSON.parse value
      catch e
        json =
          ok: false
          error: "Failed to parse API method #{url.pathname}: #{e}"
        status = 400
      unless status?
        try
          json = Object.assign (ok: true), apiMethods[url.pathname] options
          status = 200
        catch e
          json =
            ok: false
            error: "API method #{url.pathname} failed: #{e}"
          json.errorCode = e.error if e instanceof Meteor.Error
          json.errorCode = 'Match.Error' if e instanceof Match.Error
          status = 500
  else
    json =
      ok: false
      error: "Unknown API endpoint: #{url.pathname}"
    status = 404
  unless res.headersSent
    res.writeHead status, 'Content-type': 'application/json'
  unless res.writeableEnded
    res.end EJSON.stringify json
