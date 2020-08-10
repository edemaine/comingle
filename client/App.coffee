import React from 'react'
import {BrowserRouter as Router, Switch, Route} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'

import FrontPage from './FrontPage'
import Room from './Room'
import './bootstrap'

export default App = ->
  <Router>
    <Switch>
      <Route path="/r/:roomId">
        <Room/>
      </Route>
      <Route path="/">
        <FrontPage/>
      </Route>
    </Switch>
  </Router>
