import {Random} from 'meteor/random'
import useLocalStorage from './useLocalStorage'

## Modeled after Cocreate's remoteId mechanism

presenceId = Random.id()
export default usePresenceId = -> presenceId

### Persistent version, which causes trouble with multiple windows:
export default usePresenceId = (key = 'presenceId') ->
  id = window.localStorage.getItem key
  unless id?
    id = Random.id()
    window.localStorage.setItem key, id
  id
###
