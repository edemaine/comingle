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

export uniqCountNames = (items, item2name = (x) -> x) ->
  out = []
  for item in items
    name = item2name item
    if name == last
      out[out.length-1].count++
    else
      out.push
        item: item
        name: name
        count: 1
      last = name
  out
