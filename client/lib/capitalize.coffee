export capitalize = (x) ->
  return x unless x
  x[0].toUpperCase() + x[1..]
