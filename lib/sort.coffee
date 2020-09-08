## Sorting titles with numbers in them.
## Based on code from Coauthor (lib/groups.coffee).
titleDigits = 10
export titleKey = (title) ->
  title = title.title if title.title?
  title.toLowerCase().replace /\d+/g, (n) -> n.padStart titleDigits, '0'

export sortByKey = (array, key) ->
  array.sort (x, y) ->
    x = key x
    y = key y
    if x < y
      -1
    else if x > y
      +1
    else
      0

## Sort by last name if available.
## Based on code from Coauthor (lib/users.coffee).

export nameSortKey = (name) ->
  space = name.lastIndexOf ' '
  if space >= 0
    name[space+1..] + ", " + name[...space]
  else
    name

export sortNames = (items, item2name = (x) -> x) ->
  items.sort (x, y) ->
    x = nameSortKey item2name x
    y = nameSortKey item2name y
    if x < y
      -1
    else if x > y
      +1
    else
      0

export uniqCountNames = (items, item2name = ((x) -> x), distinguisher) ->
  out = []
  for item in items
    name = item2name item
    distinct = distinguisher? item
    if name == lastName and distinct == lastDistinct
      out[out.length-1].count++
    else
      out.push
        item: item
        name: name
        count: 1
      lastName = name
      lastDistinct = distinct
  out
