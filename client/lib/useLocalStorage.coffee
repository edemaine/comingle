## Based on https://usehooks.com/useLocalStorage/

import {useState} from 'react'

export default useLocalStorage = (key, initialValue) ->
  # Pass initial state function to useState so logic is only executed once
  [storedValue, setStoredValue] = useState ->
    try
      # Get from local storage by key
      item = window.localStorage.getItem key
      # Parse stored json or if none return initialValue
      if item?
        JSON.parse item
      else
        initialValue
    catch error
      # If error also return initialValue
      console.error error
      initialValue

  # Return a wrapped version of useState's setter function that
  # persists the new value to localStorage.
  setValue = (value) ->
    try
      # Allow value to be a function so we have same API as useState
      value = value storedValue if value instanceof Function
      # Save state
      setStoredValue value
      # Save to local storage
      window.localStorage.setItem key, JSON.stringify value
    catch error
      console.error error

  [storedValue, setValue]
