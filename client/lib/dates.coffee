export formatDate = (date) ->
  return date unless date
  date.toLocaleDateString undefined,
    dateStyle: 'full'
    timeStyle: 'long'
