## Based on https://usehooks.com/useLocalStorage/ and
## https://github.com/donavon/use-persisted-state/blob/develop/src/usePersistedState.js

import {useState} from 'react'
import useEventListener from '@use-it/event-listener'

export useLocalStorage = (key, initialValue, sync, noUpdate) ->
  # Support raw initial value or function generating that value
  initial = ->
    if typeof initialValue == 'function'
      initialValue()
    else
      initialValue

  # Pass initial state function to useState so logic is only executed once
  [storedValue, setStoredValue] = useState ->
    try
      # Get from local storage by key
      item = window.localStorage.getItem key
      # Parse stored json or if none return initialValue
      if item? and item != 'undefined'
        try
          JSON.parse item
        catch
          initial()
      else
        initial()
    catch error
      # If error also return initialValue
      console.warn error
      initial()

  # Return a wrapped version of useState's setter function that
  # persists the new value to localStorage.
  setValue = (value) ->
    try
      # Allow value to be a function so we have same API as useState
      value = value storedValue if value instanceof Function
      # Easy case: no change
      return if value == storedValue
      # Save state
      setStoredValue value unless noUpdate
      # Save to local storage
      window.localStorage.setItem key, JSON.stringify value
    catch error
      console.error error

  # If requested to sync across tabs/windows, monitor for storage event.
  if sync
    useEventListener 'storage', (e) ->
      if e.key == key
        try
          setStoredValue JSON.parse e.newValue
        catch error
          console.warn error

  [storedValue, setValue]
