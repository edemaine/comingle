import {Random} from 'meteor/random'
import {Session} from 'meteor/session'

## Modeled after Cocreate's remoteId mechanism

unless presenceId = window?.sessionStorage?.getItem? 'presenceId'
  window?.sessionStorage?.setItem? 'presenceId', presenceId = Random.id()
export getPresenceId = -> presenceId

### Persistent version, which causes trouble with multiple windows:
export getPresenceId = (key = 'presenceId') ->
  id = window.localStorage.getItem key
  unless id?
    id = Random.id()
    window.localStorage.setItem key, id
  id
###

export getCreator = ->
  presenceId: getPresenceId()
  name: Session.get('name') ? window.localStorage.getItem('name') ? ''
