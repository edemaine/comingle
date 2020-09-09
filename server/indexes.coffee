import {Chat} from './chat'
import {Rooms} from '/lib/rooms'
import {Tabs} from '/lib/tabs'
import {Presence} from '/lib/presence'

## meeting subscription
Rooms.rawCollection().createIndex
  meeting: 1
## also for presenceUpdate, presenceRemove methods:
Presence.rawCollection().createIndex
  meeting: 1
  id: 1

## room subscription
Tabs.rawCollection().createIndex
  room: 1

## chatLastN, chatSince methods
Chat.rawCollection().createIndex
  channel: 1
  sent: 1
