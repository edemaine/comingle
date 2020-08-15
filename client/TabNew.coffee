import React, {useState, useEffect} from 'react'
import {Random} from 'meteor/random'

import {validURL, tabTypes} from '/lib/tabs'
import {useDebounce} from './lib/useDebounce'
import {AppSettings} from './App'
import Settings from '/settings.coffee'

trimUrl = (x) -> x.replace /\/+$/, ''

tabMakerSets =
  Whiteboard:
    Cocreate:
      Server: Settings.defaultServers.cocreate ? 'https://cocreate.csail.mit.edu'
      onClick: ->
        url = "#{trimUrl @states.Server[0]}/api/roomNew?grid=1"
        response = await fetch url
        json = await response.json()
        @setUrl json.url
        @setType 'cocreate'
  "Video Conference":
    "Jitsi Meet":
      Server: Settings.defaultServers.jitsi ? 'https://meet.jit.si'
      onClick: ->
        @setUrl "#{trimUrl @states.Server[0]}/comingle/#{Random.id()}"
        @setType 'jitsi'

initialTabMakerSet = (key for key of tabMakerSets)[0]

export default TabNew = ({tab, meetingId, roomId, replaceTabNew}) ->
  [url, setUrl] = useState ''
  [title, setTitle] = useState ''
  [type, setType] = useState 'iframe'
  [manualTitle, setManualTitle] = useState false

  ## Automatic mangling after a little idle time
  urlDebounce = useDebounce url, 100
  useEffect ->
    tab = mangleTab {url, title, manualTitle, type}
    setUrl tab.url if tab.url != url
    setTitle tab.title if tab.title != title
    setType tab.type if tab.type != type
  , [urlDebounce]

  [tabMakerSet, setTabMakerSet] = useState initialTabMakerSet
  tabMakerStates = {}
  for key, tabMakers of tabMakerSets
    tabMakerStates[key] = {}
    for tabMaker, properties of tabMakers
      tabMakerStates[key][tabMaker] = {}
      for property, initial of properties when not property.startsWith 'on'
        tabMakerStates[key][tabMaker][property] = useState initial

  onSubmit = (e) ->
    e.preventDefault()
    tab = mangleTab
      meeting: meetingId
      room: roomId
      title: title.trim()
      type: type
      url: url
      manualTitle: manualTitle
    delete tab.manualTitle
    id = Meteor.apply 'tabNew', [tab], returnStubValue: true
    replaceTabNew {id, tab}
  <div className="card">
    <div className="card-body">
      <h3 className="card-title">Add New Shared Tab to Room</h3>
      <p className="card-text">Create widget using one of the buttons, or just enter a URL
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
                  setUrl: setUrl
                  setType: setType
                  name: name}>
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
           value={url} required
           onChange={(e) -> setUrl e.target.value; setType 'iframe'}/>
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

export mangleTab = (tab) ->
  tab.url = tab.url.trim()
  return tab unless tab.url and validURL tab.url

  ## Force type if we recognize default servers
  for service in ['cocreate', 'jitsi']
    server = Settings.defaultServers[service]
    continue unless server?
    if tab.url.startsWith server
      tab.type = service

  ## YouTube URL mangling into embed link, based on examples from
  ## https://gist.github.com/rodrigoborgesdeoliveira/987683cfbfcc8d800192da1e73adc486
  tab.url = tab.url.replace ///
    ^ (?: http s? : )? //
    (?: youtu\.be/ |
      (?: www\. | m\. )? youtube (-nocookie)? .com /
        (?: v/ | vi/ | e/ | embed/ |
          (?: watch )? \? (?: feature=[^&]* & )? v i? = )
    )
    ( [\w\-]+ ) [^]*
  ///i, (match, nocookie, video) ->
    tab.type = 'youtube'
    "https://www.youtube#{nocookie ? ''}.com/embed/#{video}"

  ## Automatic title
  if tab.manualTitle == false
    if tab.type == 'iframe'
      tab.title = (new URL tab.url).hostname
    else
      tab.title = tabTypes[tab.type].title if tab.type of tabTypes

  tab
