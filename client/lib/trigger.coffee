## Trigger that can be started multiple times, but only gets called once
## the specified number of seconds after the first start call.
## Can also be stopped, which cancels all starts.

export trigger = (delaySeconds, func) ->
  timeout = null
  start = ->
    return unless delaySeconds?
    stop()
    timeout = setTimeout ->
      timeout = null
      func()
    , delaySeconds * 1000
  stop = ->
    clearTimeout timeout if timeout?
    timeout = null
  {start, stop}
