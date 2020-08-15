import {useMemo} from 'react'

export useIdMap = (data, key = '_id') ->
  useMemo ->
    map = {}
    for item in data
      map[item[key]] = item
    map
  , [data]
