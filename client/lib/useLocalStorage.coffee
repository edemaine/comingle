import {useState} from 'react'
import useEventListener from '@use-it/event-listener'
import {ReactiveVar} from 'meteor/reactive-var'
import {useTracker} from 'meteor/react-meteor-data'

## Based on https://usehooks.com/useLocalStorage/ and
## https://github.com/donavon/use-persisted-state/blob/develop/src/usePersistedState.js

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
    # Allow value to be a function so we have same API as useState
    value = value storedValue if value instanceof Function
    # Easy case: no change
    return if value == storedValue
    # Save state, unless requested to not update the state variable
    setStoredValue value unless options?.noUpdate
    # Save to local storage
    setStorage storage, key, value

  # If requested to sync across tabs/windows, monitor for storage event.
  if options?.sync
    useEventListener 'storage', (e) ->
      if e.key == key
        try
          val = JSON.parse e.newValue
        catch error
          console.warn "Failed to sync storage key #{key}: #{error}"
        setStoredValue val

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
    console.warn "Failed to load storage key #{key}: #{error}"
    initial initialValue

setStorage = (storage, key, value) ->
  try
    # Save to local storage
    storage.setItem key, JSON.stringify value
  catch error
    console.warn "Failed to set storage key #{key}: #{error}"

# Support raw initial value or function generating that value
initial = (initialValue) ->
  if typeof initialValue == 'function'
    initialValue()
  else
    initialValue

###
LocalStorageVar and SessionStorageVar provide a global ReactiveVar that is
synchronized with a localStorage or sessionStorage key.
Based on Cocreate's client/lib/storage.coffee
###

class StorageVar extends ReactiveVar
  constructor: (@key, initialValue, options) ->
    super()
    super.set getStorage @constructor.storage, @key, initialValue
    if options?.sync
      window.addEventListener 'storage', @listener = (e) =>
        if e.key == @key
          try
            val = JSON.parse e.newValue
          catch error
            console.warn "Failed to sync storage key #{@key}: #{error}"
            return
          super.set val  # don't try to set storage again
  set: (value) ->
    super.set value
    setStorage @constructor.storage, @key, value
  use: ->
    useTracker (=> @get()), []
  stop: ->
    window.removeEventListener 'storage', @listener if @listener?
export class LocalStorageVar extends StorageVar
  @storage: window.localStorage
export class SessionStorageVar extends StorageVar
  @storage: window.sessionStorage
