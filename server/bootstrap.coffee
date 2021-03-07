import {Meetings, makeMeetingSecret} from '/lib/meetings'
import {Rooms} from '/lib/rooms'
import {Tabs} from '/lib/tabs'

## Add missing meeting secrets (though still only gettable via database)
Meetings.find
  secret: $exists: false
.forEach (room) ->
  Meetings.update room._id, $set: secret: makeMeetingSecret()

## Convert `false` to `null` representation for Date flags
for key in ['archived', 'protected', 'raised']  # 'deleted' always used null
  for db in [Rooms, Tabs]
    db.update
      "#{key}": false
    ,
      $set: "#{key}": null
    ,
      multi: true

console.log 'Upgraded database as necessary.'
