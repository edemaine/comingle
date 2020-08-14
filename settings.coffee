## Comingle Server Configuration Settings

export default Settings =

  ## When creating a new meeting, create rooms with the specified titles
  newMeetingRooms: [
    title: 'Main Room'
  #,
  #  title: 'Another Room'
  ]

  ## Default servers for each of the (open-source) services.
  ## If you'd rather not use/rely on a publicly deployed server,
  ## consider running your own and changing the default here.
  defaultServers:
    cocreate: 'https://cocreate.csail.mit.edu'
    jitsi: 'https://meet.jit.si'
