## Based on https://usehooks.com/useLocalStorage/ and
## https://github.com/donavon/use-persisted-state/blob/develop/src/usePersistedState.js

import {useState} from 'react'
import useEventListener from '@use-it/event-listener'

export useLocalStorage = (key, initialValue, options) ->
  ## Valid options: noUpdate, sync
  useStorage window.localStorage, key, initialValue, options
export useSessionStorage = (key, initialValue, options) ->
  ## Valid options: noUpdate
  useStorage window.sessionStorage, key, initialValue, options
export useStorage = (storage, key, initialValue, options) ->
  # Pass initial state function to useState so logic is only executed once
  [storedValue, setStoredValue] = useState ->
    getStorage storage, key, initialValue

  # Return a wrapped version of useState's setter function that
  # persists the new value to storage.
  setValue = (value) ->
    try
      # Allow value to be a function so we have same API as useState
      value = value storedValue if value instanceof Function
      # Easy case: no change
      return if value == storedValue
      # Save state, unless requested to not update the state variable
      setStoredValue value unless options?.noUpdate
      # Save to local storage
      storage.setItem key, JSON.stringify value
    catch error
      console.error error

  # If requested to sync across tabs/windows, monitor for storage event.
  if options?.sync
    useEventListener 'storage', (e) ->
      if e.key == key
        try
          setStoredValue JSON.parse e.newValue
        catch error
          console.warn error

  [storedValue, setValue]

export getLocalStorage = (key, initialValue) ->
  getStorage window.localStorage, key, initialValue
export getSessionStorage = (key, initialValue) ->
  getStorage window.sessionStorage, key, initialValue
export getStorage = (storage, key, initialValue) ->
  try
    # Get from local storage by key
    item = storage.getItem key
    # Parse stored json or if none return initialValue
    if item? and item != 'undefined'
      try
        JSON.parse item
      catch
        initial initialValue
    else
      initial initialValue
  catch error
    # If error also return initialValue
    console.warn error
    initial initialValue

# Support raw initial value or function generating that value
initial = (initialValue) ->
  if typeof initialValue == 'function'
    initialValue()
  else
    initialValue
