export formatDate = (date) ->
  return 'unknown date' unless date
  date.toLocaleDateString undefined,
    dateStyle: 'full'
    timeStyle: 'long'
