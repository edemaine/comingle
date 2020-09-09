import {useState, useLayoutEffect} from 'react'

export useAsync = (asyncFunc) ->
  [value, setValue] = useState()
  useLayoutEffect ->
    setValue undefined
    asyncFunc()
    .then (response) ->
      setValue -> response  # avoid setValue calling function response
    undefined
  , []
  value
