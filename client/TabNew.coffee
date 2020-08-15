import React, {useState, useEffect, useRef} from 'react'
import {Random} from 'meteor/random'

import {validURL, tabTypes} from '/lib/tabs'
import {useDebounce} from './lib/useDebounce'
import Settings from '/settings.coffee'

trimURL = (x) -> x.replace /\/+$/, ''

urlMaker =
  cocreate: ->
    server = Settings.defaultServers.cocreate ?
             'https://cocreate.csail.mit.edu'
    url = "#{trimURL server}/api/roomNew?grid=1"
    response = await fetch url
    json = await response.json()
    json.url
  jitsi: ->
    server = Settings.defaultServers.jitsi ? 'https://meet.jit.si'
    "#{trimURL server}/comingle/#{Random.id()}"

export default TabNew = ({tab: tabNew, meetingId, roomId, replaceTabNew}) ->
  [url, setUrl] = useState ''
  [title, setTitle] = useState ''
  [type, setType] = useState 'iframe'
  [manualTitle, setManualTitle] = useState false
  [submit, setSubmit] = useState false
  submitButton = useRef()

  ## Automatic mangling after a little idle time
  urlDebounce = useDebounce url, 100
  titleDebounce = useDebounce title, 100
  useEffect ->
    tab = mangleTab {url, title, type, manualTitle}
    setUrl tab.url if tab.url != url
    setTitle tab.title if tab.title != title
    setType tab.type if tab.type != type
    setManualTitle tab.manualTitle if tab.manualTitle != manualTitle
    if submit
      setSubmit false
      setTimeout (-> submitButton.current?.click()), 0
    undefined
  , [urlDebounce, titleDebounce, submit]

  onSubmit = (e) ->
    e.preventDefault()
    return unless validURL url
    tab = mangleTab
      meeting: meetingId
      room: roomId
      title: title.trim()
      type: type
      url: url
      manualTitle: manualTitle
    delete tab.manualTitle
    id = Meteor.apply 'tabNew', [tab], returnStubValue: true
    replaceTabNew {id, tab: tabNew}
  <div className="card">
    <div className="card-body">
      <h3 className="card-title">Add Shared Tab to Room</h3>
      <p className="card-text">
        Create/embed a widget for everyone in this room to use.
      </p>
      <div className="card form-group">
        <div className="card-header">
          <ul className="nav nav-tabs card-header-tabs" role="tablist">
            {for tabType, tabData of tabTypes
              selected = (type == tabType)
              <li key={tabType} className="nav-item" role="presentation">
                <a className="nav-link #{if selected then 'active'}"
                 href="#" role="tab" aria-selected="#{selected}"
                 onClick={do (tabType) -> (e) -> e.preventDefault(); setType tabType}>
                  {tabData.category ? tabData.title}
                </a>
              </li>
            }
          </ul>
        </div>
        <div className="card-body">
          <form className="newTab" onSubmit={onSubmit}>
            {switch type
              when 'iframe'
                <p>Paste the URL for any embeddable website, e.g., Wikipedia:</p>
              when 'cocreate'
                <>
                  <p>This server uses <b><a href="https://github.com/edemaine/cocreate">Cocreate</a></b> for a shared whiteboard.</p>
                  <div className="form-group">
                    <button className="btn btn-primary btn-lg btn-block"
                     onClick={-> urlMaker.cocreate().then (url) ->
                                setUrl url; setSubmit true}>
                      New Cocreate Board
                    </button>
                  </div>
                  <p>Or paste the URL for an existing board:</p>
                </>
              when 'jitsi'
                <>
                  <p>This server uses <b><a href="https://meet.jit.si/">Jitsi Meet</a></b> for video conferencing.</p>
                  <div className="form-group">
                    <button className="btn btn-primary btn-lg btn-block"
                     onClick={-> setUrl urlMaker.jitsi(); setSubmit true}>
                      New Jitsi Meet Room
                    </button>
                  </div>
                  <p>Or paste the URL for an existing room:</p>
                </>
              when 'youtube'
                <>
                  <p>Paste a YouTube link and we'll turn it into its embeddable form:</p>
                </>
            }
            <div className="form-group">
              <label>URL</label>
              <input type="url" placeholder="https://..." className="form-control"
               value={url} required
               onChange={(e) -> setUrl e.target.value}/>
            </div>
            <div className="form-group">
              <label>Tab title (can be renamed later)</label>
              <input type="text" placeholder="Cool Site" className="form-control"
               value={title} required pattern=".*\S.*"
               onChange={(e) -> setTitle e.target.value; setManualTitle true}/>
            </div>
            <button ref={submitButton} type="submit"
             className="btn btn-primary btn-lg btn-block mb-1">
              Embed This URL
            </button>
          </form>
        </div>
      </div>
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
  unless tab.title.trim()
    tab.manualTitle = false
  if tab.manualTitle == false
    if tab.type == 'iframe'
      tab.title = (new URL tab.url).hostname
    else
      tab.title = tabTypes[tab.type].title if tab.type of tabTypes

  tab
