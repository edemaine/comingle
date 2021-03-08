# Comingle API

Comingle provides an [**API**](https://en.wikipedia.org/wiki/API) to let you
query and manipulate Comingle meetings, rooms, tabs, and logs from your own
software.

## Access Control

Queries can run without any special permissions, just like they would in the
browser.  For safety, however, all updates require the meeting's secret key.

## Request Format

API operations can be HTTP GET or POST requests on the Comingle server, on
the path `/api` followed by the operation name (see below).

Operation parameters can be specified in two different ways,
or a mixture thereof:

1. The request body can contain an
   [EJSON](https://docs.meteor.com/api/ejson.html)-encoded object with
   key/value pairs specifying parameters.
2. The query URL can have a
   [query string](https://en.wikipedia.org/wiki/Query_string)
   specifying key/value pairs as parameters.
   Values should generally be
   [EJSON](https://docs.meteor.com/api/ejson.html)-encoded,
   but as a special case, Meteor-style 17-character IDs (used a lot by the API)
   can be included without quotes.
3. You can use both a request body and URL query parameters to provide a
   mixture of keys.  If the same key is present in both, the URL query
   parameter takes precedence.

[EJSON](https://docs.meteor.com/api/ejson.html) is an extension of JSON that in
particular has support for `Date`s and `RegExp`s needed by some API operations.
If you're not using `Date`s or `RegExp`s in your API operations, you can use a
regular [JSON](https://www.json.org/json-en.html) encoder.

## Response Format

The response consists of an
[EJSON](https://docs.meteor.com/api/ejson.html)-encoded object
with the following fields:

* `ok`: `true` or `false` according to whether the operation succeeded.
* `error`: When `ok` is `false`, a human-readable string error message.
* `errorCode`: When `ok` is `false`, sometimes contains a computer-readable
  string error code.
* `meetings`, `rooms`, `tabs`, `logs`: When `ok` is `true`, sometimes contain
  arrays of matching meetings/rooms/tabs/logs, depending on the operation.

Responses often include "presence" objects which consist of two fields:

* `name` (string): Name of user
  (defaulting to `"API"` for API operations)
* `presenceId` (string): Unique ID for that user/browser tab
  (defaulting to `"API"` for API operations)

## Query Operations

### `/api/meeting/get`: Fetch data for one or more meetings

Request fields: (either `meeting` or `meetings` is required)

* `meeting` (corequired string): ID of meeting to fetch
* `meetings` (corequired array of strings): Array of IDs of meetings to fetch

Response fields (when `ok` is `true`):

* `meetings`: Array of meeting details (excluding `secret`s), each including:
  * `_id` (string): Meeting ID
  * `title` (string): Meeting title
  * `creator` (presence): Who created the meeting
  * `created` (date): When the meeting was created
  * `updator` (presence): Who last updated the meeting
  * `updated` (date): When the meeting was last updated

### `/api/room/get`: Fetch data for one or more rooms

Request fields: (either `room` or `rooms` or `meeting` is required)

* `room` (corequired string): ID of room to fetch
* `rooms` (corequired array of strings): Array of IDs of rooms to fetch
* `meeting` (corequired string): ID of meeting to fetch all rooms from
  (unless `room` or `rooms` is specified)
* `secret` (optional string): The meeting secret
* `title` (optional string or regexp): Restrict to rooms with matching title
* `raised` (optional boolean): Restrict to rooms with(out) raised hand
* `archived` (optional boolean): Restrict to rooms that are (not) archived
* `protected` (optional boolean): Restrict to rooms that are (not) protected
* `deleted` (optional boolean): Restrict to rooms that are (not) deleted
  (works only with meeting `secret`)

The meeting `secret` can be specified in combination with `meeting` or `room`.
In this case, it allows searching for deleted rooms via `deleted: true`, or
finding both deleted and undeleted rooms via unspecified `deleted`.
(If you do not want to return deleted rooms, use `deleted: false` or
don't specify `secret`.)

Response fields (when `ok` is `true`):

* `rooms`: Array of room details, each including:
  * `_id` (string): Room ID
  * `title` (string): Room title
  * `creator` (presence): Who created the room
  * `created` (date): When the room was created
  * `updator` (presence): Who last updated the room
  * `updated` (date): When the room was last updated
  * `raised` (date or null): When the hand was raised, or `null`/absent if not
  * `raiser` (presence): Who last raised the hand
  * `archived` (date or null): When the room was archived,
    or `null`/absent if not
  * `archiver` (presence): Who last archived the room
  * `protected` (date or null): When the room was protected,
    or `null`/absent if not
  * `protecter` (presence): Who last protected the room
  * `deleted` (date or null): When the room was deleted, or `null`/absent if not
  * `deleter` (presence): Who last deleted the room
  * `joined` (array of presences): Array of who is currently in the room
  * `adminVisit` (date or boolean): When the room was last visited by an admin,
    or `true` if the room has an admin now,
    or `false` if the room is currently empty

### `/api/tab/get`: Fetch data for one or more tabs

Request fields:
(either `tab` or `tabs` or `room` or `rooms` or `meeting` is required)

* `tab` (corequired string): ID of tab to fetch
* `tabs` (corequired array of strings): Array of IDs of tabs to fetch
* `room` (corequired string): ID of room to fetch all tabs from
  (unless `tab` or `tabs` is specified)
* `rooms` (corequired array of strings):
  Array of IDs of rooms to fetch all tabs from
  (unless `tab` or `tabs` is specified)
* `meeting` (corequired string): ID of meeting to fetch all tabs from
  (unless `room` or `rooms` or `tab` or `tabs` is specified)
* `secret` (optional string): The meeting secret
* `type` (optional string or regexp): Restrict to tabs with matching type
* `title` (optional string or regexp): Restrict to tabs with matching title
* `url` (optional string or regexp): Restrict to tabs with matching URL
* `archived` (optional boolean): Restrict to tabs that are (not) archived
* `deleted` (optional boolean): Restrict to tabs that are (not) deleted
  (works only with meeting `secret`)

The meeting `secret` can be specified in combination with `meeting` or `tab`.
In this case, it allows searching for deleted tabs via `deleted: true`, or
finding both deleted and undeleted tabs via unspecified `deleted`.
(If you do not want to return deleted tabs, use `deleted: false` or
don't specify `secret`.)

Response fields (when `ok` is `true`):

* `tabs`: Array of tab details, each including:
  * `_id` (string): Tab ID
  * `type` (string): Tab type, one of:
    * `"iframe"`: General web page
    * `"cocreate"`: Cocreate whiteboard
    * `"jitsi"`: Jitsi Meet video call
    * `"youtube"`: YouTube video
    * `"zoom"`: Zoom video call
  * `title` (string): Tab title
  * `url` (string): Tab URL
  * `creator` (presence): Who created the tab
  * `created` (date): When the tab was created
  * `updator` (presence): Who last updated the tab
  * `updated` (date): When the tab was last updated
  * `archived` (date or null): When the tab was archived, or `null`/absent if not
  * `archiver` (presence): Who last archived the tab
  * `deleted` (date or null): When the tab was deleted, or `null`/absent if not
  * `deleter` (presence): Who last deleted the tab

### `/api/log/get`: Fetch log data

Request fields:

* `meeting` (required string): ID of meeting to get logs for
* `secret` (required string): The meeting secret
* `start` (optional date): Restrict to logs &ge; this date
* `finish` (optional date): Restrict to logs &le; this date

Response fields (when `ok` is `true`):

* `logs`: Array of logs sorted by `updated`, each including:
  * `updated` (date): When the logged event occurred
  * `type` (string): Type of logged event, one of:
    * `"presenceJoin"`: User newly joined the meeting;
      all presence fields included
    * `"presenceUpdate"`: User updated their presence information;
      changed presence fields included
    * `"presenceLeave"`: User left meeting; no presence fields included
  * `id` (optional string): Presence ID
  * `name` (optional string): Name of user
  * `rooms` (optional object):
    * `joined` (optional array of strings):
      Array of IDs of rooms that the user has joined (typically length 1)
    * `starred` (optional array of strings):
      Array of IDs of rooms that the user has starred

## Edit Operations

All edit and create operations support the following request fields:

* `secret` (required string): The meeting secret
* `updator` (optional): String for name of updator (defaults to `"API"`), or
  an object with keys `name` and `presenceId` (as used by the web interface)

### `/api/meeting/edit`: Modify data for a meeting

Request fields (in addition to `secret` and `updator` described above):

* `meeting` (required string): ID of meeting to modify
* `title` (optional string): New title for meeting

Response fields (when `ok` is `true`):

* `meetings`: Array containing the updated meeting

### `/api/room/edit`: Modify data for one or more rooms

Request fields (in addition to `secret` and `updator` described above):

* `room` (corequired string): ID of room to modify
* `rooms` (corequired object or array of strings):
  Array of IDs of rooms to modify, or a query object like
  [`/api/room/get`](#apiroomget-fetch-data-for-one-or-more-rooms)
  (e.g. `{"meeting": ...}`)
* `title` (optional string): New title for room(s)
* `raised` (optional boolean): New raised-hand state for room(s)
* `archived` (optional boolean): New archived state for room(s)
* `deleted` (optional boolean): New deleted state for room(s)
* `protected` (optional boolean): New protected state for room(s)

For example, the following query object matches all unprotected unarchived
rooms and sets them to archived:

```json
{
  "rooms": {
    "meeting": ...,
    "protected": false,
    "archived": false
  },
  "archived": true,
  "secret": ...,
  "updator": "Auto archive"
}
```

Response fields (when `ok` is `true`):

* `rooms`: Array containing the updated rooms

### `/api/tab/edit`: Modify data for one or more tabs

Request fields (in addition to `secret` and `updator` described above):

* `tab` (corequired string): ID of tab to modify
* `tabs` (corequired object or array of strings):
  Array of IDs of tabs to modify, or a query object like
  [`/api/tab/get`](#apitabget-fetch-data-for-one-or-more-tabs)
  (e.g. `{"meeting": ...}`)
* `title` (optional string): New title for tab(s)
* `archived` (optional boolean): New archived state for tab(s)
* `deleted` (optional boolean): New deleted state for tab(s)

Response fields (when `ok` is `true`):

* `tabs`: Array containing the updated tabs

## Create Operations

All create operations except
[`/api/meeting/new`](#apimeetingnew-create-new-meeting) require `secret`,
and all create operations support `updator` request fields.
See [Edit Operations](#edit-operations) for their description.

### `/api/meeting/new`: Create new meeting

Request fields (in addition to `updator` described above):

* `title` (optional string): Title for new meeting

### `/api/room/new`: Create new room

Request fields (in addition to `secret` and `updator` described above):

* `meeting` (required string): ID of meeting to add room to
* `title` (optional string): Title for new room
* `archived` (optional boolean): Whether new room should be archived
* `protected` (optional boolean): Whether new room should be protected
* `tabs` (optional array of objects): Initial tabs to create within room.
  Each object should have the same fields as in
  [`/api/tab/new`](#apitabnew-create-new-tab),
  excluding `meeting`, `room`, `secret`, and `updator`.

### `/api/tab/new`: Create new tab

Request fields (in addition to `secret` and `updator` described above):

* `meeting` (required string): ID of meeting to add tab to
* `room` (required string): ID of room to add tab to
* `type` (optional string): Tab type as defined in
  [`/api/tab/get`](#apitabget-fetch-data-for-one-or-more-tabs),
  defaulting to a guessed value based on `url`
* `title` (optional string): Title of new tab,
  defaulting to a value based on `url`
* `url` (optional string): URL of new tab,
  defaulting to a newly created Cocreate room (when `type` is `"cocreate"`)
  or Jitsi video call (when `type` is `"jitsi"`)
* `archived` (optional boolean): Whether new tab should be archived
