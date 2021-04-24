import React, {useState, useEffect, useLayoutEffect, useRef} from 'react'
import {Alert, Button, Card, Form, Nav} from 'react-bootstrap'

import {addMeetingSecret} from './MeetingSecret'
import {validURL, tabTypes, categories, mangleTab, zoomRegExp} from '/lib/tabs'
import {useDebounce} from './lib/useDebounce'
import {getUpdator} from './lib/presenceId'
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

tabCategory = (tabData) -> tabData.category ? tabData.title

tabTypesByCategory = {}
do -> # avoid namespace pollution
  for tabType, tabData of tabTypes
    category = tabCategory tabData
    tabTypesByCategory[category] ?= {}
    tabTypesByCategory[category][tabType] = tabData

export TabNew = React.memo ({initialUrl, node, meetingId, roomId, replaceTabNew, existingTabTypes}) ->
  [url, setUrl] = useState initialUrl ? ''
  useLayoutEffect ->
    setUrl initialUrl if initialUrl? and not url
  , [initialUrl]
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
    if tab.type != type
      setType tab.type
      setCategory tabCategory tabTypes[tab.type]
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
      updator: getUpdator()
    , true
    tab = await Meteor.apply 'tabNew', [addMeetingSecret meetingId, tab],
      returnStubValue: true
    replaceTabNew
      id: tab._id
      node: node
  <Card>
    <Card.Body>
      <Card.Title as="h3">Add Shared Tab to Room</Card.Title>
      <Card.Text as="p">
        Create/embed a widget for everyone in this room to use.
      </Card.Text>
      <Card className="form-group">
        <Card.Header>
          <Nav variant="tabs">
            {for categoryName of tabTypesByCategory
              selected = (category == categoryName)
              <li key={categoryName} className="nav-item" role="presentation">
                <a className="nav-link #{if selected then 'active'}"
                 href="#" role="tab" aria-selected="#{selected}"
                 onClick={onCategory categoryName}>
                  {categoryName}
                </a>
              </li>
            }
          </Nav>
        </Card.Header>
        {if (tabType for tabType of tabTypesByCategory[category]).length > 1
          <Card.Header>
            <Nav variant="tabs">
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
            </Nav>
          </Card.Header>
        }
        <Card.Body>
          <Form className="newTab" onSubmit={onSubmit}>
            {if categories[category]?.onePerRoom and
                (tabType for tabType of tabTypesByCategory[category] \
                 when existingTabTypes[tabType]).length
              <Alert variant="warning">
                WARNING: This room already has a {category} tab. Do you really want another?
              </Alert>
            }
            {tabTypePage[type].topDescription}
            {if tabTypes[type].onePerRoom and existingTabTypes[type]
              <Alert variant="warning">
                WARNING: This room already has a {tabTypes[type].longTitle ? tabTypes[type].title} tab. Do you really want another?
              </Alert>
            }
            {if tabTypes[type].createNew
              onClick = ->
                url = tabTypes[type].createNew()
                url = await url if url.then?
                setUrl url
                setSubmit true
              <>
                <Form.Group>
                  <Button variant="primary" size="lg" block
                   type="button" onClick={onClick}>
                    New {tabTypes[type].longTitle ? tabTypes[type].title} {capitalize tabTypes[type].instance}
                  </Button>
                </Form.Group>
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
            <Form.Group>
              <label>URL</label>
              <input type="url" placeholder="https://..." className="form-control"
               value={url} required
               onChange={(e) -> setUrl e.target.value}/>
            </Form.Group>
            {if mixed
              <Alert variant="warning">
                You cannot use a website with insecure <code>http</code> protocol (because Comingle uses secure <code>https</code> protocol).
              </Alert>
            }
            <Form.Group>
              <label>Tab title (can be renamed later)</label>
              <input type="text" placeholder="Cool Site" className="form-control"
               value={title} required pattern=".*\S.*"
               onChange={(e) -> setTitle e.target.value; setManualTitle true}/>
            </Form.Group>
            <Button ref={submitButton} type="submit"
             variant="primary" size="lg" block className="mb-1">
              Embed This URL
            </Button>
          </Form>
        </Card.Body>
      </Card>
    </Card.Body>
  </Card>
TabNew.displayName = 'TabNew'
