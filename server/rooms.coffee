import {checkId} from '/lib/id'
import {Tabs} from '/lib/tabs'

Meteor.publish 'room', (roomId) ->
  checkId roomId
  Tabs.find room: roomId
