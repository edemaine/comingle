import {check, Match} from 'meteor/check'
import crypto from 'crypto'

###
To use the Zoom Web Client SDK [https://github.com/zoom/sample-app-web],
you need to sign up for an API Key & Secret.  Go to the Zoom Marketplace
[https://marketplace.zoom.us/] and select "Create a JWT App".
See https://marketplace.zoom.us/docs/sdk/native-sdks/web/getting-started/integrate

Then add the API Key & Secret into `settings.json` at the root of this
repository.  It should look something like this:

{
  "zoom": {
    "apiKey": "YOUR_API_KEY",
    "apiSecret": "YOUR_API_SECRET"
  }
}

DO NOT commit your changes to this file into Git; the secret needs to
STAY SECRET.  To ensure Git doesn't accidentally commit your changes, use

    git update-index --assume-unchanged settings.json

If you're deploying via mup, it should pick up these keys.
If you're developing locally, use

    meteor --settings settings.json
###

Meteor.methods
  zoomWebSupport: ->
    Meteor.settings.zoom?.apiKey and
    Meteor.settings.zoom?.apiSecret
  zoomSign: (meetingID, role = 0) ->
    check meetingID, String
    check role, Match.OneOf 0, 1
    ## https://marketplace.zoom.us/docs/sdk/native-sdks/web/essential/signature
    timestamp = (new Date).getTime() - 30000
    msg = Buffer.from(Meteor.settings.zoom.apiKey + meetingID + timestamp + role).toString 'base64'
    hash = crypto.createHmac('sha256', Meteor.settings.zoom.apiSecret).update(msg).digest 'base64'
    console.log "#{Meteor.settings.zoom.apiKey}.#{meetingID}.#{timestamp}.#{role}.#{hash}"
    signature: Buffer.from("#{Meteor.settings.zoom.apiKey}.#{meetingID}.#{timestamp}.#{role}.#{hash}").toString 'base64'
    apiKey: Meteor.settings.zoom.apiKey
