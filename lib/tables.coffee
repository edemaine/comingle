export Tables = new Mongo.Collection 'Tables'

Meteor.methods
  tableNew: (table) ->
    check table,
      title: String
    Tables.insert table
