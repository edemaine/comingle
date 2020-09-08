export escapeHTML = (html) ->
  html
  .replace /&/g, '&amp;'
  .replace /</g, '&lt;'
  .replace />/g, '&gt;'

export escapeRegExp = (regex) ->
  ## https://stackoverflow.com/questions/3446170/escape-string-for-use-in-javascript-regex
  regex.replace /[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&"
