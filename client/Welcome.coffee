import React from 'react'

export Welcome = () =>
  <div className='welcome-page'>
    <h3>Welcome to Comingle!</h3>
    Comingle is an online meeting tool whose goal is to approximate the advantages of in-person meetings.
    <ul>
      <li>Enter your first and last name in the left panel!</li>
      <li>Your open rooms will appear as tabs near the top of your screen.</li>
      <li>Click on a room in the room list on the left to join it (you probably want to join the main room first)
        <ul>
          <li>"Switch to room" (shortcut: Shift+click) opens the room as a new tab and immediately switches to it.
            Note that this will disconnect you from your current video call.</li>
          <li>"Open in background" (shortcut: Ctrl/Cmd+click) opens the room as a new tab, but you stay in your current room.
            You can switch to it later by clicking on the tab.</li>
        </ul>
      </li>
      <li>Each room contains one or more tabs: video call, whiteboard, etc. You can drag these tabs to rearrange them however you like!</li>
    </ul>
  </div>