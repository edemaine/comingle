import {Tables} from '/lib/tables'

Meteor.publish 'tables', ->
  Tables.find {}
