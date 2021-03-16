import React, {useEffect, useState} from 'react'
import {Button, Card, Form, Nav} from 'react-bootstrap'

import {useMeetingAdmin} from './MeetingSecret'
import {capitalize} from './lib/capitalize'
import {Config} from '/Config'

export Schedule = React.memo ->
  admin = useMeetingAdmin()
  <Card className="schedule sidebar">
    {if admin
      <ScheduleAdd/>
    }
  </Card>
Schedule.displayName = 'Schedule'

## https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/datetime-local
dateToValue = (date) ->
  pad4 = (x) -> x.toString().padStart 4, '0'
  pad2 = (x) -> x.toString().padStart 2, '0'
  "#{pad4 date.getFullYear()}-#{pad2 date.getMonth()+1}-#{pad2 date.getDate()}T#{pad2 date.getHours()}:#{pad2 date.getMinutes()}"

export ScheduleAdd = React.memo ->
  [repeat, setRepeat] = useState 'none'
  [start, setStart] = useState ''
  [finish, setFinish] = useState ''
  useEffect ->
    if start and (not finish or finish.getTime() < start.getTime())
      date = new Date start
      date.setMinutes date.getMinutes() + (Config.defaultScheduleMinutes ? 60)
      setFinish dateToValue date
  , [start, finish]

  <>
    <Card>
      <Card.Header className="tight">Add Event(s) with Title:</Card.Header>
      <Card.Body>
        <Form>
          <Form.Control type="text" placeholder="Meeting / Lecture / ..."/>
        </Form>
      </Card.Body>
    </Card>
    <Card>
      <Card.Header className="tight">
        Start Date/Time:
      </Card.Header>
      <Card.Body>
        <Form>
          <Form.Control type="datetime-local"
           value={start} onChange={(e) -> setStart e.target.value}/>
        </Form>
      </Card.Body>
    </Card>
    <Card>
      <Card.Header className="tight">
        Finish Date/Time:
      </Card.Header>
      <Card.Body>
        <Form>
          <Form.Control type="datetime-local"
           value={finish} onChange={(e) -> setFinish e.target.value}/>
        </Form>
      </Card.Body>
    </Card>
    <Card>
      <Card.Header className="tight">
        Repeat:
        <Nav variant="tabs">
          {for option in ['none', 'weekly', 'monthly']
            <li key={option} className="nav-item" role="presentation">
              <a className="nav-link #{if repeat == option then 'active' else ''}"
               href="#" role="tab" aria-selected="#{repeat == option}"
               onClick={do (option) -> -> setRepeat option}>
                {capitalize option}
              </a>
            </li>
          }
        </Nav>
      </Card.Header>
    </Card>
    {if repeat == 'weekly'
      <Card>
        <Card.Header className="tight">
          Days of Week:
        </Card.Header>
        <Card.Body>
          <Form className="dow-grid">
            {for dow in ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              <React.Fragment key={dow}>
                <div>{dow[0]}</div>
                <Form.Check custom id="check-#{dow}"/>
              </React.Fragment>
            }
          </Form>
        </Card.Body>
      </Card>
    }
    {if repeat != 'none'
      <Card>
        <Card.Header className="tight">
          Repeat Until:
        </Card.Header>
        <Card.Body>
          <Form>
            <Form.Control type="datetime-local"/>
          </Form>
        </Card.Body>
      </Card>
    }
    <Button block>Add Event{'s' unless repeat == 'none'}</Button>
  </>
