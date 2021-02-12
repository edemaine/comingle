import {Chat} from './chat'
import {Log} from '/lib/log'
import {Rooms} from '/lib/rooms'
import {Tabs} from '/lib/tabs'
import {Presence} from '/lib/presence'

## meeting subscription
Rooms.rawCollection().createIndex
  meeting: 1
Presence.rawCollection().createIndex
  meeting: 1

## presenceUpdate, presenceRemove methods
Presence.rawCollection().createIndex
  id: 1

## room subscription
Tabs.rawCollection().createIndex
  room: 1

## chatLastN, chatSince methods
Chat.rawCollection().createIndex
  channel: 1
  sent: 1

## log query
Log.rawCollection().createIndex
  meeting: 1
  updated: 1
