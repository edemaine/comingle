export formatDateTime = (date) ->
  return 'unknown date' unless date
  return 'unknown date' if date == true
  "#{formatDate date} at #{formatTime date}"

export formatDate = (date) ->
  return 'unknown date' unless date
  return 'unknown date' if date == true
  date.toLocaleDateString undefined,
    weekday: 'short'
    month: 'short'
    day: 'numeric'
    year: 'numeric'

export formatTime = (date) ->
  date.toLocaleTimeString undefined,
    hour: 'numeric'
    minute: 'numeric'
    hour12: false
    timeZoneName: 'short'

export formatTimeDelta = (delta) ->
  delta = Math.round delta / 1000
  return '0' if delta == 0
  out = ''
  if delta < 0
    out += '-'
    delta = -delta
  append = (part) ->
    if out.endsWith ':'
      out += "#{part}".padStart 2, '0'
    else
      out += "#{part}"
  for epoch in [24*60*60, 60*60, 60]
    if delta > epoch
      append Math.floor delta / epoch
      out += ':'
      delta %= epoch
  append delta
  out
