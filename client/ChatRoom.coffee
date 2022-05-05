import React, {useEffect, useLayoutEffect, useRef, useState} from 'react'
import Alert from 'react-bootstrap/Alert'
import Badge from 'react-bootstrap/Badge'
import Button from 'react-bootstrap/Button'
import Form from 'react-bootstrap/Form'
import InputGroup from 'react-bootstrap/InputGroup'
import Tooltip from 'react-bootstrap/Tooltip'
import OverlayTrigger from 'react-bootstrap/OverlayTrigger'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faComment} from '@fortawesome/free-solid-svg-icons/faComment'
import {useTracker} from 'meteor/react-meteor-data'
import {Session} from 'meteor/session'
import ScrollableFeed from 'react-scrollable-feed'

import {Loading} from './Loading'
import {useChatSound} from './Settings'
import {Markdown} from './lib/Markdown'
import {Chat, useChat} from './lib/chat'
import {getUpdator} from './lib/presenceId'
import {formatDate, formatTime} from './lib/dates'
import {useLocalStorage} from './lib/useLocalStorage'
import {Config} from '/Config'

export ChatRoom = ({channel, audience, visible, extraData, updateTab}) ->
  loading = useChat channel
  messages = useTracker ->
    Chat.find
      channel: channel
    ,
      sort: sent: 1
    .fetch()
  , [channel]

  ## Maintain last seen message and unseen count
  [seen, setSeen] = useLocalStorage "chatSeen-#{channel}", null, sync: true
  loadedSeen = useRef false
  chatSound = useChatSound()
  chatAudio = useRef()
  lastSound = useRef()
  ## When chat becomes visible, mark everything as seen and
  ## reset last-sound timer.
  useLayoutEffect ->
    if visible
      setSeen messages[messages.length-1]?._id
      lastSound.current = undefined
    undefined
  , [messages, visible]
  ## Reset last-sound timer if we toggle sound on/off (confusing otherwise)
  useLayoutEffect ->
    lastSound.current = undefined
  , [chatSound]
  useLayoutEffect ->
    if seen?
      for unseen in [0..messages.length]
        break if unseen == messages.length or
          messages[messages.length-1-unseen]._id == seen
    else
      unseen = messages.length
    if unseen != extraData.unseen
      extraData.unseen = unseen
      extraData.fresh = loadedSeen.current
      updateTab()
      if chatSound and unseen and loadedSeen.current and not visible and
         (not lastSound.current? or
          (new Date) - lastSound.current >= Config.chatSoundTimeout)
        chatAudio.current?.play()
        lastSound.current = new Date
    loadedSeen.current = true unless loading
    undefined
  , [messages, seen]

  ## Form
  [body, setBody] = useState ''
  submit = (e) ->
    e.preventDefault()
    return unless body.trim()
    Meteor.call 'chatSend',
      channel: channel
      sender: getUpdator()
      type: 'msg'
      body: body
    setBody ''

  ## Scroll to bottom when TeX loads
  scrollableRef = useRef()
  texLoaded = useTracker ->
    Session.get 'texLoaded'
  , []
  useEffect ->
    scrollableRef.current?.scrollToBottom()
  , [texLoaded]

  unless visible
    if chatSound
      return <audio ref={chatAudio} src="/sounds/chat.flac"/>
    else
      return null
  <div className="chat">
    <ScrollableFeed className="messages" ref={scrollableRef}>
      {for message in messages
        date = formatDate message.sent
        <React.Fragment key={message._id}>
          {if date != lastDate
            lastDate = date
            <div className="date">
              {date}
            </div>
          }
          <div className="message">
            <div className="header">
              <span className="sender">{message.sender.name or '(anonymous)'}</span>
              <span className="sent">{formatTime message.sent}</span>
            </div>
            <Markdown className="body" body={message.body}/>
          </div>
        </React.Fragment>
      }
      {if loading
        <Loading/>
      else if messages.length == 0
        <Alert variant="info">
          Empty chat. Post the first message below!
        </Alert>
      }
    </ScrollableFeed>
    <Form onSubmit={submit}>
      <InputGroup>
        <Form.Control type="text" placeholder="Message #{audience}"
         value={body} onChange={(e) -> setBody e.target.value}/>
        <OverlayTrigger placement="top"
         overlay={<Tooltip>Send Message</Tooltip>}>
          <Button size="sm" onClick={submit}>
            <FontAwesomeIcon icon={faComment}/>
          </Button>
        </OverlayTrigger>
      </InputGroup>
    </Form>
  </div>

ChatRoom.onRenderTab = (node, renderState) ->
  if (unseen = node.getExtraData().unseen)
    if node.getExtraData().fresh
      variant = 'danger'
    else
      variant = 'secondary'
    renderState.content = <>
      {renderState.content}
      <Badge variant={variant} className="ml-1">{unseen}</Badge>
    </>
