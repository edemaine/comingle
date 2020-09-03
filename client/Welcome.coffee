import React from 'react'
import {Card} from 'react-bootstrap'

import {Ctrl} from './lib/keys'
import {homepage, repository} from '/package.json'

export Welcome = () =>
  <Card>
    <Card.Body>
      <Card.Title as="h3">Welcome to Comingle!</Card.Title>
      <p>
        <b>Comingle</b> is an <a href={repository}>open-source</a> online
        meeting tool whose goal is to approximate the advantages of
        in-person meetings.
        It integrates web tools in an open multiroom environment.
      </p>
      <h5>Getting Started:</h5>
      <ul>
        <li>First, <b>enter your name</b> (first and last) at the top of the left panel.</li>
        <li><b>Your open rooms</b> will appear as tabs near the top of your screen.</li>
        <li>To <b>join a room</b>, click on a room (such as "Main Room") in the room list on the left.</li>
        <li>When you click a second room, you'll have two choices:
          <ul>
            <li> "<b>Switch to Room</b>" (shortcut: hold <kbd>Shift</kbd> while clicking) opens the room as a new tab and immediately switches to it.  Note that this will <b>disconnect</b> you from any current Comingle video call.</li>
            <li> "<b>Open in Background</b>" (shortcut: hold <kbd>{Ctrl}</kbd> while clicking) opens the room as a new tab, but you stay in your current room.  You can switch to it later by clicking on the tab.</li>
          </ul>
        </li>
        <li>Each room contains one or more <b>tabs</b>: video call, whiteboard, etc.
          You can drag these tabs to re-arrange them however you like!</li>
        <li><a href={homepage}>Read the documentation</a> for more information.</li>
      </ul>
    </Card.Body>
  </Card>
