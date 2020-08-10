import React from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import TableList from './TableList'
import TableNew from './TableNew'
import './bootstrap'

export default App = ->
  <div className="row">
    <div id="tables" className="col-sm-3 bg-light">
      <nav className="navbar navbar-light">
        <span className="navbar-brand mb-0 h1">Comingle</span>
      </nav>
      <TableList/>
      <TableNew/>
    </div>
    <div className="col-sm">
      Room
    </div>
  </div>
