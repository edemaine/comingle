import React, {useRef, useState} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Dropdown, Overlay, Tooltip} from 'react-bootstrap'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {faUser, faUserFriends, faUserTie, faUsers} from '@fortawesome/free-solid-svg-icons'

import {Presence} from '/lib/presence'
import {sortNames} from '/lib/sort'
import {KickButton} from './ConfirmButton'
import {useMeetingAdmin} from './MeetingSecret'

export RoomUsersButton = React.forwardRef ({className, onClick, count}, ref) ->
  className = className.replace /\bdropdown-toggle\b/, ''  # omit caret
  [hover, setHover] = useState false
  iconRef = useRef()

  <div className={className} ref={ref}
   onClick={(e) -> setHover false; onClick e}
   onMouseEnter={-> setHover true}
   onMouseLeave={-> setHover false}
   onMouseDown={(e) -> e.stopPropagation()}
   onTouchStart={(e) -> e.stopPropagation()}>
    <span ref={iconRef}>
      <FontAwesomeIcon aria-label="List Users in Room" icon={
        switch count
          when 0, 1 then faUser
          when 2 then faUserFriends
          else faUsers
      }/>
    </span>
    <Overlay target={iconRef} placement="bottom" show={hover}>
      <Tooltip>List Users in Room</Tooltip>
    </Overlay>
  </div>
RoomUsersButton.displayName = 'RoomUsersButton'

export RoomUsers = React.memo ({className, room}) ->
  presence = useTracker ->
    presenceList = Presence.find
      meeting: room.meeting
      'rooms.joined': room._id
    .fetch()
    sortNames presenceList, (p) -> p.name
  admin = useMeetingAdmin()
  [forceClose, setForceClose] = useState false
  onKick = (user) -> ->
    Meteor.call 'presenceKick', user.id, room._id

  <Dropdown className="room-users" onToggle={(open) -> setForceClose not open}>
    <Dropdown.Toggle as={RoomUsersButton} className={className} count={presence.length}>
      <span>{room?.users?.length}</span>
    </Dropdown.Toggle>
    <Dropdown.Menu className="presence">
      {for user in presence
        <Dropdown.ItemText key={user.id}>
          {if admin
            <div className="float-right">
              <KickButton className="admin flexlayout__tab_button_trailing"
               forceClose={forceClose} onClick={onKick user}/>
            </div>
          }
          <span className={if user.admin then 'admin' else ''}>
            {if user.admin
              <FontAwesomeIcon icon={faUserTie}/>
            else
              <FontAwesomeIcon icon={faUser}/>
            }
            &nbsp;
            {user.name}
            {if user.pronouns
              <span className="pronouns">
                ({user.pronouns})
              </span>
            }
          </span>
        </Dropdown.ItemText>
      }
    </Dropdown.Menu>
  </Dropdown>

RoomUsers.displayName = 'RoomUsers'
