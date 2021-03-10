## Comingle Server Configuration Settings

export Config =

  ## When creating a new meeting, create rooms with the specified
  ## title and (optional) tabs.
  newMeetingRooms: [
    title: 'Main Room'
    tabs: [
      type: 'jitsi'
    ]
  #,
  #  title: 'Empty Room'
  #,
  #  title: 'Drawing Room'
  #  tabs: [
  #    type: 'cocreate'
  #  ]
  #,
  #  title: 'Living Room'
  #  tabs: [
  #    type: 'jitsi'
  #  ,
  #    type: 'cocreate'
  #  ]
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

  ## Whether to have a compact room list by default
  defaultCompact: false

  ## Whether to hide the room creation widget at the bottom of the room list by default
  defaultHideCreate: false

  ## Whether to hide the title / header at the top of the room list by default
  defaultHideTitle: false
