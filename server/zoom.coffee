import {check, Match} from 'meteor/check'

###
To use the Zoom Web Client SDK [https://github.com/zoom/sample-app-web],
you need to sign up for an SDK Key & Secret.  Go to the Zoom Marketplace
[https://marketplace.zoom.us/] and select "Develop / Build App / Meeting SDK".
See https://developers.zoom.us/docs/meeting-sdk/create/

Then add the SDK Key & Secret (under App credentials / Client ID and Secret)
into `.deploy/settings.json`.  It should look something like this:

{
  "zoom": {
    "sdkKey": "YOUR_SDK_KEY_AKA_CLIENT_ID",
    "sdkSecret": "YOUR_SDK_SECRET_AKA_CLIENT_SECRET"
  }
}

DO NOT commit this file into Git; the secret needs to STAY SECRET.
Thus we recommend copying root `settings.json` file into `.deploy`
and editing the copy only.

If you're deploying a public server via `mup`, it should pick up these keys.
If you're developing on a local test server, use the following instead of
`meteor`:

    meteor --settings settings.json
###

Meteor.methods
  zoomWebSupport: ->
    Meteor.settings.zoom?.sdkKey and
    Meteor.settings.zoom?.sdkSecret
  zoomSign: (meetingID, role = 0) ->
    check meetingID, String
    check role, Match.OneOf 0, 1
    {sdkKey, sdkSecret} = Meteor.settings.zoom
    ## https://developers.zoom.us/docs/meeting-sdk/auth/
    timestamp = Math.round((new Date).getTime() / 1000) - 30
    expiration = timestamp + 24 * 60 * 60  # max expiration seems to be 24 hrs
    header =
      alg: 'HS256'
      typ: 'JWT'
    payload =
      sdkKey: sdkKey
      mn: meetingID
      role: role
      iat: timestamp
      exp: expiration
      tokenExp: expiration
    console.log payload
    sdkKey: sdkKey
    signature: require('jsrsasign').jws.JWS.sign 'HS256',
      JSON.stringify header
      JSON.stringify payload
      sdkSecret
