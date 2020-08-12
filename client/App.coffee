import React from 'react'
import {BrowserRouter as Router, Switch, Route} from 'react-router-dom'
import {useTracker} from 'meteor/react-meteor-data'

import FrontPage from './FrontPage'
import Room from './Room'
import useLocalStorage from './lib/useLocalStorage'

export default App = ->
  [name, setName] = useLocalStorage 'name', '', true  # set by <Name>
  <AppSettings.Provider value={{name, setName}}>
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
  </AppSettings.Provider>

export AppSettings = React.createContext()
