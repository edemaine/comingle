import React from 'react'
import {Card} from 'react-bootstrap'

import {homepage, repository} from '/package.json'

export Welcome = ->
  <Card>
    <Card.Body>
      <Card.Title as="h3">Welcome to Comingle!</Card.Title>
      <p>
        <b>Comingle</b> is an <a href={repository.url}>open-source</a> online
        meeting tool whose goal is to approximate the advantages of
        in-person meetings.
        It integrates web tools in an open multiroom environment.
      </p>
      <h5>Getting Started:</h5>
      <ul>
        <li>First, <b>enter your name</b> (first and last) in the left panel (second text box).</li>
        <li>To <b>join a room</b>, click on a room (such as &ldquo;Main Room&rdquo;) in the room list on the left.</li>
        <li>When you click a second room, you'll be offered to &ldquo;<b>Switch to Room</b>&rdquo; which leaves the current room and any video calls  (shortcut: hold <kbd>Shift</kbd> while clicking).</li>
        <li>Each room contains one or more <b>tabs</b>: video call, whiteboard, etc.
          You can drag these tabs to re-arrange them however you like!</li>
        <li><b>Star</b> rooms to (publicly) indicate your interest in that topic. To focus on just starred rooms, unfold the &ldquo;<b>Your Starred Rooms</b>&rdquo; section.</li>
        <li><a href={homepage}>Read the documentation</a> for more information.</li>
      </ul>
    </Card.Body>
  </Card>
