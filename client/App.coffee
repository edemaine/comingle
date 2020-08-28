import React from 'react'
import {BrowserRouter as Router, Switch, Route} from 'react-router-dom'

import {FrontPage} from './FrontPage'
import {Meeting} from './Meeting'
import {Redirect} from './lib/Redirect'

export App = ->
  <Router>
    <Switch>
      <Route path="/m/:meetingId">
        <Meeting/>
      </Route>
      <Route path="/r/:meetingId">
        {### Old-style URL (when meetings were called rooms) ###}
        <Redirect replace={/^\/r\//} replacement={'/m/'}/>
      </Route>
      <Route path="/">
        <FrontPage/>
      </Route>
    </Switch>
  </Router>
App.displayName = 'App'
