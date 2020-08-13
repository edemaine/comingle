import React, {useState, useEffect} from 'react'
import {Random} from 'meteor/random'

import {validURL} from '/lib/tabs'
import {AppSettings} from './App'

trimUrl = (x) -> x.replace /\/+$/, ''

tabMakerSets =
  Whiteboard:
    Cocreate:
      Server: "https://cocreate.csail.mit.edu"
      onClick: ->
        url = "#{trimUrl @states.Server[0]}/api/roomNew?grid=1"
        response = await fetch url
        json = await response.json()
        @setUrl json.url
  "Video Conference":
    "Jitsi Meet":
      Server: "https://meet.jit.si"
      onClick: ->
        @setUrl "#{trimUrl @states.Server[0]}/comingle/#{Random.id()}"

initialTabMakerSet = (key for key of tabMakerSets)[0]

export default TabNew = ({tab, meetingId, roomId, replaceTabNew}) ->
  [url, setUrl] = useState ''
  [title, setTitle] = useState ''
  [manualTitle, setManualTitle] = useState false
  [tabMakerSet, setTabMakerSetRaw] = useState initialTabMakerSet
  setTabMakerSet = (value) ->
    setTabMakerSetRaw value
    initialTabMakerSet = value
  tabMakerStates = {}
  for key, tabMakers of tabMakerSets
    tabMakerStates[key] = {}
    for tabMaker, properties of tabMakers
      tabMakerStates[key][tabMaker] = {}
      for property, initial of properties when not property.startsWith 'on'
        tabMakerStates[key][tabMaker][property] = useState initial
  useEffect ->
    if url and validURL(url) and not manualTitle
      setTitle (new URL url).hostname
  onSubmit = (e) ->
    e.preventDefault()
    id = Meteor.apply 'tabNew', [
      meeting: meetingId
      room: roomId
      title: title.trim()
      type: 'iframe'
      url: url
    ], returnStubValue: true
    replaceTabNew {id, tab}
  <div class="card">
    <div class="card-body">
      <h3 class="card-title">Add New Shared Tab to Room</h3>
      <p class="card-text">Create widget using one of the buttons, or just enter a URL
         for any embeddable website below. Then click Create New Tab.</p>
      <div className="card form-group">
        <div className="card-header">
          <ul className="nav nav-tabs card-header-tabs" role="tablist">
            <li className="nav-item">
              <span className="nav-link disabled pl-1">Create:</span>
            </li>
            {for key of tabMakerSets
              selected = (tabMakerSet == key)
              <li key={key} className="nav-item" role="presentation">
                <a className="nav-link #{if selected then 'active'}"
                 href="#" role="tab" aria-selected="#{selected}"
                 onClick={do (key) -> (e) -> e.preventDefault(); setTabMakerSet key}>
                  {key}
                </a>
              </li>
            }
          </ul>
        </div>
        <div className="card-body">
          {for tabMaker, properties of tabMakerSets[tabMakerSet]
            <form className="inline-form tabMaker d-flex flex-wrap"
             key={tabMaker} onSubmit={(e) -> e.preventDefault()}>
              <button type="submit" className="btn btn-info"
               onClick={(e) -> properties.onClick.call
                  states: tabMakerStates[tabMakerSet][tabMaker]
                  setUrl: setUrl}>
                {tabMaker}
              </button>
              {for property, value of properties when not property.startsWith 'on'
                <div key={property} className="d-flex flex-grow-1 flex-wrap align-items-baseline">
                  <label className="pl-4 pr-2">{property}:</label>
                  <input className="form-control w-auto flex-grow-1" type="text"
                   value={tabMakerStates[tabMakerSet][tabMaker][property][0]}
                   onChange={do (tabMakerSet, tabMaker, property) -> (e) ->
                     tabMakerStates[tabMakerSet][tabMaker][property][1] e.target.value
                   }/>
                </div>
              }
            </form>
          }
        </div>
      </div>
      <form className="newTab" onSubmit={onSubmit}>
        <div className="form-group">
          <label>URL for webpage to embed (via <code>&lt;iframe&gt;</code>)</label>
          <input type="url" placeholder="https://..." className="form-control"
           value={url} onChange={(e) -> setUrl e.target.value} required/>
        </div>
        <div className="form-group">
          <label>Tab title (can be renamed later)</label>
          <input type="text" placeholder="Cool Site" className="form-control"
           value={title} required pattern=".*\S.*"
           onChange={(e) -> setTitle e.target.value; setManualTitle true}/>
        </div>
        <button type="submit" className="btn btn-primary btn-block mb-1">
          Create New Tab
        </button>
      </form>
    </div>
  </div>
