import React, {useContext} from 'react'
import {AccordionContext, useAccordionToggle, Card} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faChevronCircleUp, faChevronCircleDown} from '@fortawesome/free-solid-svg-icons'

export CardToggle = ({children, eventKey}) ->
  eventKey ?= 0
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
