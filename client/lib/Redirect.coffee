import React from 'react'
import {useHistory} from 'react-router-dom'

export Redirect = ({replace, replacement}) ->
  history = useHistory()
  history.replace newUrl =
    (history.location.pathname.replace replace, replacement) +
    "#{history.location.search}#{history.location.hash}"
  <div className="alert">
    Redirecting to #{newUrl}
  </div>
