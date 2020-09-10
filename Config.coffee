## Comingle Server Configuration Settings

export Config =

  ## When creating a new meeting, create rooms with the specified
  ## title and template.  Template can be '' (blank), 'cocreate', 'jitsi',
  ## or a combination via plus, e.g., 'cocreate+jitsi'.
  newMeetingRooms: [
    title: 'Main Room'
    template: 'jitsi'
  #,
  #  title: 'Empty Room'
  #  template: ''
  ]

  ## Default servers for each of the (open-source) services.
  ## If you'd rather not use/rely on a publicly deployed server,
  ## consider running your own and changing the default here.
  defaultServers:
    cocreate: 'https://cocreate.csail.mit.edu'
    jitsi: 'https://meet.jit.si'

  ## Default sort key for all meetings
  defaultSort:
    key: 'title'  # see client/RoomList.coffee for other options
    reverse: false
