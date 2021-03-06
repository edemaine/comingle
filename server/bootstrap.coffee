import {Meetings, makeMeetingSecret} from '/lib/meetings'

## Add missing meeting secrets (though still only gettable via database)
Meetings.find
  secret: $exists: false
.forEach (room) ->
  Meetings.update room._id, $set: secret: makeMeetingSecret()

console.log 'Upgraded database as necessary.'
