import React, {useEffect, useReducer} from 'react'
import {Alert} from 'react-bootstrap'

import {useAsync} from './lib/useAsync'

export Warnings = ->
  [warnings, updateWarning] = useReducer (warnings, op) ->
    warnings = Object.assign {}, warnings
    switch op.op
      when 'add'
        warnings[op.id] =
          body: op.body
          show: true
      when 'hide'
        warnings[op.id].show = false
    warnings
  , {}
  UAParser = useAsync -> (await import('ua-parser-js')).default
  useEffect ->
    return unless UAParser?
    ua = new UAParser
    switch browser = ua.getBrowser().name
      when 'Safari'
        browserWarning =
          "Comingle and Jitsi do not run well in #{browser}."
      when 'Firefox'
        browserWarning =
          <span>Firefox <a href="https://bugzilla.mozilla.org/show_bug.cgi?id=1401592">does not support Simulcast</a> so it does not work well with Jitsi calls; even if it works for you, it may slow down everyone else.</span>
    if browserWarning?
      updateWarning
        op: 'add'
        id: 'safari'
        body: <>{browserWarning} We recommend switching to Chrome.</>
  , [UAParser]
  for id, warning of warnings
    continue unless warning.show
    do (id) ->
      <Alert key={id} variant="warning" dismissible
       onClose={-> updateWarning {op: 'hide', id}}>
        {warning.body}
      </Alert>
Warnings.displayName = 'Warnings'
