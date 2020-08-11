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
  tableEdit: (diff) ->
    check diff,
      id: String
      title: Match.Optional String
    table = checkTable diff.id
    set = {}
    for key, value of diff when key != 'id'
      set[key] = value unless table[key] == value
    return unless (key for key of set).length  # nothing to update
    Tables.update diff.id,
      $set: set
