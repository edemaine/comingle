import React, {useEffect, useState, useRef} from 'react'
import {Button, ButtonGroup, Tooltip, Overlay} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faLock, faLockOpen, faShieldAlt, faSkullCrossbones, faTrash, faTrashRestore, faUserSlash} from '@fortawesome/free-solid-svg-icons'
import {shieldAltSlash} from './icons/shieldAltSlash'

import {capitalize} from './lib/capitalize'

export ConfirmButton = React.memo ({className, action, prefix, suffix, icon, help, onClick, forceClose}) ->
  buttonRef = useRef()
  [click, setClick] = useState false
  [hover, setHover] = useState false
  useEffect ->
    if forceClose
      setClick false
      setHover false
    undefined
  , [forceClose]

  <div className={className}
   aria-label="#{action}#{suffix ? ''}"
   onClick={-> setClick not click}
   onMouseEnter={-> setHover true}
   onMouseLeave={-> setHover false}
   onMouseDown={(e) -> e.stopPropagation()}
   onTouchStart={(e) -> e.stopPropagation()}>
    <span ref={buttonRef}>{icon}</span>
    <Overlay target={buttonRef.current} placement="bottom"
     show={hover or click}>
      <Tooltip>
        {prefix}{action}{suffix}
        <div className="small">{help}</div>
        {if click
           <ButtonGroup className="mt-1">
             <Button variant="danger" size="sm"
              onClick={(e) -> onClick e; setClick false; setHover false}>
               {action}
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
ConfirmButton.displayName = 'ConfirmButton'

export ArchiveButton = React.memo ({noun, archived, ...props}) ->
  <ConfirmButton
   action="#{if archived then 'Restore' else 'Archive'} #{capitalize noun}"
   suffix=" for Everyone"
   icon={<FontAwesomeIcon icon={if archived then faTrashRestore else faTrash}/>}
   {...props}/>
ArchiveButton.displayName = 'ArchiveButton'

export DeleteButton = React.memo ({noun, ...props}) ->
  <ConfirmButton
   action="Delete #{capitalize noun}"
   prefix="Permanently "
   help="Careful! This operation cannot be undone. #{if noun == 'room' then 'All tabs in this room and their URLs will be permanently lost.' else 'This tab and its URL will be permanently lost.'}"
   icon={<FontAwesomeIcon icon={faSkullCrossbones}/>}
   {...props}/>
DeleteButton.displayName = 'DeleteButton'

export ProtectButton = React.memo ({protected: prot, ...props}) ->
  <ConfirmButton
   action="#{if prot then 'Unprotect' else 'Protect'} Room"
   icon={<FontAwesomeIcon icon={if prot then faShieldAlt else shieldAltSlash}/>}
   help="Protected rooms cannot be renamed, (un)archived, or have tabs added/edited except by admins."
   {...props}/>
ProtectButton.displayName = 'ProtectButton'

export LockButton = React.memo ({locked, ...props}) ->
  <ConfirmButton
   action="#{if locked then 'Unlock' else 'Lock'} Room"
   icon={<FontAwesomeIcon icon={if locked then faLock else faLockOpen}/>}
   help="Locked rooms cannot be joined (easily) by users except admins. For private discussion."
   {...props}/>
LockButton.displayName = 'LockButton'

export KickButton = React.memo (props) ->
  <ConfirmButton
   action="Kick User"
   suffix=" from Room"
   icon={<FontAwesomeIcon icon={faUserSlash}/>}
   help="User can still rejoin room, unless the room is locked. Useful for idle users."
   {...props}/>
KickButton.displayName = 'KickButton'
