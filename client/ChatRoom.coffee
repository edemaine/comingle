import React, {useState} from 'react'
import {Alert, Button, Form, InputGroup, Tooltip, OverlayTrigger} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faComment} from '@fortawesome/free-solid-svg-icons'
import {useTracker} from 'meteor/react-meteor-data'

import {Loading} from './Loading'
import {Chat, useChat} from './lib/chat'
import {getCreator} from './lib/presenceId'
import {formatDate, formatTime} from './lib/dates'

export ChatRoom = ({channel, audience}) ->
  loading = useChat channel
  messages = useTracker ->
    Chat.find
      channel: channel
    ,
      sort: date: 1
    .fetch()
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
    <div className="messages">
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
