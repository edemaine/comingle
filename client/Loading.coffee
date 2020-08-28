import React from 'react'

export Loading = ->
  <div className="media m-4 align-items-center">
    <div className="spinner-border"/>
    <div className="media-body ml-3">
      Loading...
    </div>
  </div>
Loading.displayName = 'Loading'
