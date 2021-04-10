import React, {useContext, useState} from 'react'
import {Accordion, AccordionContext, useAccordionToggle, Card} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faChevronCircleUp, faChevronCircleDown} from '@fortawesome/free-solid-svg-icons'

export CardToggle = React.memo ({children, eventKey}) ->
  eventKey ?= '0'
  currentEventKey = useContext AccordionContext
  onClick = useAccordionToggle eventKey
  <Card.Header onClick={onClick} className="toggle">
    {children}
    {if eventKey == currentEventKey
      <FontAwesomeIcon icon={faChevronCircleUp} className="float-right"/>
    else
      <FontAwesomeIcon icon={faChevronCircleDown} className="float-right"/>
    }
  </Card.Header>
CardToggle.displayName = 'CardToggle'

###
export AutoHideAccordion = React.memo ({ms, eventKey}) ->
  eventKey ?= '0'
  currentEventKey = useContext AccordionContext
  toggle = useAccordionToggle eventKey
  useEffect ->
    return unless currentEventKey == eventKey
    timeout = setTimeout toggle, ms
    -> clearTimeout timeout
  , [currentEventKey]
  null
AutoHideAccordion.displayName = 'AutoHideAccordion'
###

export LazyCollapse = React.memo ({children, eventKey}) ->
  eventKey ?= '0'
  [render, setRender] = useState false
  <Accordion.Collapse eventKey={eventKey}
   onEnter={-> setRender true} onExited={-> setRender false}>
    {if render
      children
    else
      <div/>
    }
  </Accordion.Collapse>
LazyCollapse.displayName = 'LazyCollapse'
