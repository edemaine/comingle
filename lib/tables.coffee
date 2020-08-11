import {validId} from './id'
import {checkRoom} from './rooms'

export Tables = new Mongo.Collection 'tables'

export checkTable = (table) ->
  if validId(table) and data = Tables.findOne table
    data
  else
    throw new Error "Invalid table ID #{table}"

Meteor.methods
  tableNew: (table) ->
    check table,
      room: String
      title: String
    room = checkRoom table.room
    Tables.insert table
