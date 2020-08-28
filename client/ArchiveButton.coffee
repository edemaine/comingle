import React, {useState, useRef} from 'react'
import {Button, ButtonGroup, Tooltip, Overlay} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faTrash, faTrashRestore} from '@fortawesome/free-solid-svg-icons'

import {capitalize} from './lib/capitalize'

export ArchiveButton = ({type, noun, archived, help, onClick}) ->
  buttonRef = useRef()
  [click, setClick] = useState false
  [hover, setHover] = useState false
  verb = if archived then 'Restore' else 'Archive'
  noun = capitalize noun
  <div className="flexlayout__#{type}_button_trailing"
   aria-label="#{verb} #{noun} for Everyone"
   onClick={-> setClick not click}
   onMouseEnter={-> setHover true}
   onMouseLeave={-> setHover false}
   onMouseDown={(e) -> e.stopPropagation()}
   onTouchStart={(e) -> e.stopPropagation()}>
    <span ref={buttonRef}>
      {if archived
         <FontAwesomeIcon icon={faTrashRestore}/>
       else
         <FontAwesomeIcon icon={faTrash}/>
      }
    </span>
    <Overlay target={buttonRef.current} placement="bottom"
     show={hover or click}>
      <Tooltip>
        {verb} {noun} for Everyone<br/>
        <small>{help}</small>
        {if click
           <ButtonGroup className="mt-1">
             <Button variant="danger" size="sm"
              onClick={(e) -> onClick e; setClick false; setHover false}>
               {verb} {noun}
             </Button>
             <Button variant="success" size="sm"
              onClick={-> setHover false; setClick false}>
               Cancel
             </Button>
           </ButtonGroup>
        }
      </Tooltip>
    </Overlay>
  </div>
ArchiveButton.displayName = 'ArchiveButton'
