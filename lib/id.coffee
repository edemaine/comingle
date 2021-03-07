## From Cocreate

export idRegExp = '[23456789ABCDEFGHJKLMNPQRSTWXYZabcdefghijkmnopqrstuvwxyz]{17}'
export fullIdRegExp = ///^#{idRegExp}$///
export validId = (id) -> typeof id == 'string' and fullIdRegExp.test id
export checkId = (id, type = '') ->
  unless validId id
    type += ' ' if type
    throw new Meteor.Error 'checkId.invalid', "Invalid #{type}ID #{id}"

## Match pattern for `creator` and `updator` fields

export updatorPattern =
  #username: Match.Optional String
  name: String  # name at the time of operation
  presenceId: String
