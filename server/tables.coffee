import {checkId} from '/lib/id'
import {Tabs} from '/lib/tabs'

Meteor.publish 'table', (tableId) ->
  checkId tableId
  Tabs.find table: tableId
