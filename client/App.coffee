import React from 'react'
import {BrowserRouter as Router, Switch, Route} from 'react-router-dom'

import {FrontPage} from './FrontPage'
import {Meeting} from './Meeting'
import {useDark} from './Settings'
import {Redirect} from './lib/Redirect'

export App = ->
  <>
    <DarkClass/>
    <AppRouter/>
  </>
App.displayName = 'App'

export AppRouter = ->
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
AppRouter.displayName = 'AppRouter'

export DarkClass = ->
  dark = useDark()
  if dark
    document.body.classList.add 'dark'
  else
    document.body.classList.remove 'dark'
  null
DarkClass.displayName = 'DarkClass'
