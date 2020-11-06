import React, {useState, useEffect, useRef} from 'react'
import {Alert, Form} from 'react-bootstrap'

import {validURL, tabTypes, categories, mangleTab, zoomRegExp} from '/lib/tabs'
import {useDebounce} from './lib/useDebounce'
import {getCreator} from './lib/presenceId'
import {capitalize} from './lib/capitalize'

export tabTypePage =
  iframe:
    topDescription: <p>Paste the URL for any embeddable website, e.g., Wikipedia:</p>
  cocreate:
    topDescription: <p>This server uses <a className="font-weight-bold" href="https://github.com/edemaine/cocreate">Cocreate</a> for a shared whiteboard.</p>
  jitsi:
    topDescription: <p>This server recommends <a className="font-weight-bold" href="https://meet.jit.si/">Jitsi Meet</a> for video conferencing, because it allows free creation of unlimited rooms.</p>
  youtube:
    topDescription: <p>Paste a <a className="font-weight-bold" href="https://www.youtube.com/">YouTube</a> link and we'll turn it into its embeddable form:</p>
  zoom:
    topDescription:
      <p>If you create a <a className="font-weight-bold" href="https://zoom.us/">Zoom</a> meeting yourself, you can embed it here.</p>
    bottomDescription:
      <p>Or paste a Zoom invitation link:</p>

tabTypesByCategory = {}
do -> # avoid namespace pollution
  for tabType, tabData of tabTypes
    category = tabData.category ? tabData.title
    tabTypesByCategory[category] ?= {}
    tabTypesByCategory[category][tabType] = tabData

export TabNew = ({node, meetingId, roomId,
                  replaceTabNew, existingTabTypes}) ->
  [url, setUrl] = useState ''
  [mixed, setMixed] = useState false
  [title, setTitle] = useState ''
  [category, setCategory] = useState 'Web'
  [type, setType] = useState 'iframe'
  [manualTitle, setManualTitle] = useState false
  [submit, setSubmit] = useState false
  submitButton = useRef()

  ## Zoom
  [zoomID, setZoomID] = useState ''
  [zoomPwd, setZoomPwd] = useState ''
  useEffect ->
    return unless type == 'zoom'
    if zoomID
      match = zoomRegExp.exec url
      setUrl "#{match?[1] ? 'https://zoom.us/'}j/#{zoomID}" +
        if zoomPwd then "?pwd=#{zoomPwd}" else ''
  , [zoomID, zoomPwd, type]
  useEffect ->
    return unless type == 'zoom'
    match = zoomRegExp.exec url
    setZoomID match[2] if match?[2]
    setZoomPwd match[3] if match?[3]
  , [url, type]

  ## Automatic mangling after a little idle time
  urlDebounce = useDebounce url, 100
  titleDebounce = useDebounce title, 100
  useEffect ->
    tab = mangleTab {url, title, type, manualTitle}
    setUrl tab.url if tab.url != url
    setTitle tab.title if tab.title != title
    setType tab.type if tab.type != type
    setManualTitle tab.manualTitle if tab.manualTitle != manualTitle
    setMixed window.location.protocol == 'https:' and /^http:\/\//i.test tab.url
    if submit
      setSubmit false
      setTimeout (-> submitButton.current?.click()), 0
    undefined
  , [urlDebounce, titleDebounce, submit]

  onCategory = (categoryName) -> (e) ->
    e.preventDefault()
    unless category == categoryName
      setCategory categoryName
      for tabType of tabTypesByCategory[categoryName]
        break  # choose first tabType within category
      setType tabType
  onType = (tabType) -> (e) ->
    e.preventDefault()
    setType tabType
  onSubmit = (e) ->
    e.preventDefault()
    return unless validURL url
    ## One last mangle (in case didn't reach idle threshold)
    tab = mangleTab
      meeting: meetingId
      room: roomId
      title: title.trim()
      type: type
      url: url
      manualTitle: manualTitle
      creator: getCreator()
    , true
    id = Meteor.apply 'tabNew', [tab], returnStubValue: true
    replaceTabNew {id, node}
  <div className="card">
    <div className="card-body">
      <h3 className="card-title">Add Shared Tab to Room</h3>
      <p className="card-text">
        Create/embed a widget for everyone in this room to use.
      </p>
      <div className="card form-group">
        <div className="card-header">
          <ul className="nav nav-tabs card-header-tabs" role="tablist">
            {for categoryName, categoryTabTypes of tabTypesByCategory
              selected = (category == categoryName)
              <li key={categoryName} className="nav-item" role="presentation">
                <a className="nav-link #{if selected then 'active'}"
                 href="#" role="tab" aria-selected="#{selected}"
                 onClick={onCategory categoryName}>
                  {categoryName}
                </a>
              </li>
            }
          </ul>
        </div>
        {if (tabType for tabType of tabTypesByCategory[category]).length > 1
          <div className="card-header">
            <ul className="nav nav-tabs card-header-tabs" role="tablist">
              {for tabType, tabData of tabTypesByCategory[category]
                selected = (type == tabType)
                disabled = tabData.onePerRoom and existingTabTypes[tabType]
                <li key={tabType} disabled={disabled} className="nav-item" role="presentation">
                  <a className="nav-link #{if selected then 'active'}"
                   href="#" role="tab" aria-selected="#{selected}"
                   onClick={onType tabType}>
                    {tabData.title}
                  </a>
                </li>
              }
            </ul>
          </div>
        }
        <div className="card-body">
          <form className="newTab" onSubmit={onSubmit}>
            {if categories[category]?.onePerRoom and
                (tabType for tabType of tabTypesByCategory[category] \
                 when existingTabTypes[tabType]).length
              <div className="alert alert-warning">
                WARNING: This room already has a {category} tab. Do you really want another?
              </div>
            }
            {tabTypePage[type].topDescription}
            {if tabTypes[type].onePerRoom and existingTabTypes[type]
              <div className="alert alert-warning">
                WARNING: This room already has a {tabTypes[type].longTitle ? tabTypes[type].title} tab. Do you really want another?
              </div>
            }
            {if tabTypes[type].createNew
              onClick = ->
                url = tabTypes[type].createNew()
                url = await url if url.then?
                setUrl url
                setSubmit true
              <>
                <div className="form-group">
                  <button className="btn btn-primary btn-lg btn-block"
                   type="button" onClick={onClick}>
                    New {tabTypes[type].longTitle ? tabTypes[type].title} {capitalize tabTypes[type].instance}
                  </button>
                </div>
                <p>Or paste the URL for an existing {tabTypes[type].instance}:</p>
              </>
            }
            {if type == 'zoom'
              <>
                <Form.Group>
                  <Form.Label>Room number</Form.Label>
                  <Form.Control type="text" placeholder="123456789"
                   value={zoomID}
                   onChange={(e) -> setZoomID e.target.value}/>
                </Form.Group>
                <Form.Group>
                  <Form.Label>Room password / hash (if needed)</Form.Label>
                  <Form.Control type="text" placeholder="MzN..."
                   value={zoomPwd}
                   onChange={(e) -> setZoomPwd e.target.value}/>
                </Form.Group>
              </>
            }
            {tabTypePage[type].bottomDescription}
            <div className="form-group">
              <label>URL</label>
              <input type="url" placeholder="https://..." className="form-control"
               value={url} required
               onChange={(e) -> setUrl e.target.value}/>
            </div>
            {if mixed
              <Alert variant="warning">
                You cannot use a website with insecure <code>http</code> protocol (because Comingle uses secure <code>https</code> protocol).
              </Alert>
            }
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
TabNew.displayName = 'TabNew'
