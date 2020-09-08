import React, {useState, useEffect, useLayoutEffect, useRef} from 'react'
import {Alert, Badge, Button, Form, InputGroup, Tooltip, OverlayTrigger} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faComment} from '@fortawesome/free-solid-svg-icons'
import {useTracker} from 'meteor/react-meteor-data'

import {Loading} from './Loading'
import {Chat, useChat} from './lib/chat'
import {getCreator} from './lib/presenceId'
import {formatDate, formatTime} from './lib/dates'
import {useLocalStorage} from './lib/useLocalStorage'

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
  [seen, setSeen] = useLocalStorage "chatSeen-#{channel}", null, true
  [loadedSeen, setLoadedSeen] = useState()
  useLayoutEffect ->
    setSeen messages[messages.length-1]?._id if visible
    undefined
  , [messages, visible]
  useLayoutEffect ->
    if seen?
      for unseen in [0..messages.length]
        break if unseen == messages.length or
          messages[messages.length-1-unseen]._id == seen
    else
      unseen = messages.length
    if unseen != extraData.unseen
      extraData.unseen = unseen
      extraData.fresh = loadedSeen
      updateTab()
    setLoadedSeen true unless loading or loadedSeen
    undefined
  , [messages, seen]

  ## Keep chat scrolled to bottom unless user modifies scroll position.
  messagesDiv = useRef()
  if elt = messagesDiv.current
    atBottom = (elt.scrollHeight - elt.scrollTop - elt.clientHeight <= 3)
  useEffect ->
    if atBottom
      ## Setting scrollTop to too-large value pushes us to the bottom.
      messagesDiv.current?.scrollTop = messagesDiv.current.scrollHeight
    undefined

  ## Form
  [body, setBody] = useState ''
  submit = (e) ->
    e.preventDefault()
    return unless body.trim()
    Meteor.call 'chatSend',
      channel: channel
      sender: getCreator()
      type: 'msg'
      body: body
    setBody ''

  <div className="chat">
    <div className="messages" ref={messagesDiv}>
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
            <div className="body">{message.body}</div>
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
    </div>
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
  if unseen = node.getExtraData().unseen
    if node.getExtraData().fresh
      variant = 'danger'
    else
      variant = 'secondary'
    renderState.content = <>
      {renderState.content}
      <Badge variant={variant} className="ml-1">{unseen}</Badge>
    </>
