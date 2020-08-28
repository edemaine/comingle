import {useState, useEffect} from 'react'

export useAsync = (asyncFunc) ->
  [value, setValue] = useState()
  useEffect ->
    setValue undefined
    asyncFunc()
    .then (response) ->
      setValue -> response  # avoid setValue calling function response
    undefined
  , []
  value
