# Changelog

This file describes significant changes to Comingle to an audience of
both everyday users and administrators running their own Comingle server.
To see every change with descriptions aimed at developers, see
[the Git log](https://github.com/edemaine/comingle/commits/main).
As a continuously updated web app, Comingle uses dates
instead of version numbers.

## 2024-02-09

* Creating a room without entering a room title creates visual feedback
  instead of silently failing.
* Upgrade Zoom web client to
  [v3.1.6](https://developers.zoom.us/changelog/meeting-sdk/web/3.1.6).

## 2023-05-27

* It's now easy to jump between rooms with different Zoom calls: provided
  you join in-browser, you'll automatically join the new Zoom call in-browser
  provided you rejoin within 30 seconds of when you leave the previous room.
  This matches the existing Jitsi behavior.
* Fix Zoom web client to auto-join audio (for easier room switching/joining).
* Upgrade Zoom web client to
  [v2.12.2](https://github.com/zoom/meetingsdk-web-sample/blob/master/CHANGELOG.md#version-2122).

## 2023-04-25

* Upgrade Zoom web client to
  [v2.11.5](https://github.com/zoom/meetingsdk-web-sample/blob/master/CHANGELOG.md#version-2115).
  If you're running your own Comingle server, you need to replace
  your JWT `apiKey` and `apiSecret` with SDK `sdkKey` and `sdkSecret`;
  see [JWT app type migration guide](https://developers.zoom.us/docs/internal-apps/jwt-app-migration/).
  This transition must be made by May 5, 2023.

## 2023-04-24

* Jitsi calls now offer two ways to join the call:
  in this window (as usual) and in external browser tab (new).
  This is important because the public server `meet.jit.si`
  [no longer supports embedding](https://community.jitsi.org/t/important-embedding-meet-jit-si-in-your-web-app-will-no-longer-be-supported-please-use-jaas/123003)
  (so Comingle disables "join in this window" for such servers).
  Comingle supports a seamless room-switching experience
  even when the Jitsi call is opened in a separate tab.
  [[#197](https://github.com/edemaine/coauthor/issues/197)]
* "New" buttons specify default server they'll use

## 2022-07-02

* Upgrade Zoom web client to
  [v2.5.0](https://github.com/zoom/meetingsdk-web-sample/blob/master/CHANGELOG.md#version-250).

## 2022-06-08

* Upgrade Zoom web client to
  [v2.4.5](https://github.com/zoom/sample-app-web/blob/master/CHANGELOG.md#version-245).

## 2022-05-08

* Improve welcome message, including mention of Raise Hand and Chat features,
  pronouns setting, and more use of matching icons.

## 2022-05-05

* JavaScript bundle reduced by a factor of more than 2,
  which should improve load times especially on mobile.
  [[#167](https://github.com/edemaine/coauthor/issues/167)]
* Better refer to buttons (e.g., in Zoom and Jitsi tabs)
  using their icons.

## 2022-05-02

* Upgrade Zoom web client to
  [v2.4.0](https://github.com/zoom/sample-app-web/blob/master/CHANGELOG.md#version-240).
* Leaving a Zoom web call now automatically returns to the Native Client vs.
  Web Client selector.

## 2022-04-05

* Admins can now lower the raised hands of rooms without entering them.
* Upgrade Zoom web client to
  [v2.3.5](https://github.com/zoom/sample-app-web/blob/master/CHANGELOG.md#version-235).

## 2022-03-20

* Maximized tabsets are now unmaximized when entering a room, or when
  reloading Comingle.  This lets confused users more easily reset their view
  to where they can see all tabs.  It also avoids confusion when e.g.
  coming back to a room a week later and not seeing all your tabs.

## 2022-03-18

* Show users' pronouns in the room list for rooms you're currently in,
  as well as the "number of users" popup.
  [[#189](https://github.com/edemaine/comingle/issues/189)]
* Fix Zoom web client missing Join button in small tabs (missing scrollbars).

## 2022-03-11

* Upgrade Zoom web client to
  [v2.3.0](https://github.com/zoom/sample-app-web/blob/master/CHANGELOG.md#version-230).

## 2022-02-28

* Admins can now unlock a room without entering that room, by selecting the
  room in the room list and clicking the resulting Unlock button.

## 2022-02-06

* Rooms now have a dropdown list of users (first button after room title).
* This list shows the users' pronouns, which can now be set in Settings.
  Pronouns are also part of a user's display name in Jitsi and Zoom calls.
  [[#189](https://github.com/edemaine/comingle/issues/189)]
* Admins can move a user from the current room to another room.
  [[#122](https://github.com/edemaine/comingle/issues/122)]
* Admins can kick a user from the current room (e.g. to remove idle users).
  Users can still rejoin the room if they want, unless the room is locked.
  [[#122](https://github.com/edemaine/comingle/issues/122)]
* Admins can bulk move/kick all users from the current room
  (including themselves), e.g., to move the discussion to the correct room.
  [[#122](https://github.com/edemaine/comingle/issues/122)]

## 2022-02-05

* "Protect Room" icon changed from lock to shield.
* "Lock Room" feature (which takes over the lock icon) prevents non-admin users
  from easily joining the room (though they still could by URL manipulation).
  [[#67](https://github.com/edemaine/comingle/issues/67)]
* Fix Zoom web client by upgrading to v2.2.0.
  [[#184](https://github.com/edemaine/comingle/issues/184)]

## 2022-02-04

* Chat messages now make a bird-chirp sound by default, except when chat is
  visible or if that chat triggered a sound within the past 30 seconds
  (a timeout configurable in `Config.coffee`).
  You can turn chat sounds off on a per-browser basis in Settings.
  [[#21](https://github.com/edemaine/comingle/issues/21)]
* Newly raised hands now make a whistling sound by default for admins.
  You can turn it off on a per-meeting basis in Settings.
  [[#98](https://github.com/edemaine/comingle/issues/98)]

## 2021-12-12

* Fix bug with multiple Jitsi calls in a single room

## 2021-12-11

* For less surprises, improved privacy, and easier in-person usage, Jitsi calls
  are no longer automatically joined at the beginning of a Comingle session.
  You need to click the "Join Call" button to join your first Jitsi call.
  Afterward, you can switch between rooms and automatically switch calls
  (as before).  This "autojoin" state resets when you've been out of all
  Jitsi calls for 30 seconds.
  [[#191](https://github.com/edemaine/comingle/issues/191)]
* Jitsi user and room names are now synchronized with Comingle updates.
  [[#39](https://github.com/edemaine/comingle/issues/39)]
* When switching from room to room with Jitsi calls, Comingle preserves your
  audio and video mute status.
  [[#76](https://github.com/edemaine/comingle/issues/76)]

## 2021-06-16

* Move "new tab" button (plus sign) next to last tab (instead of the far right
  of the tabset).  This makes the button easier to discover, and matches Chrome.
  [[#188](https://github.com/edemaine/comingle/issues/188)]
* People and star counts now count only once per unique name, so if you have
  multiple browser tabs open to the same Comingle, you only count once.
  [[#181](https://github.com/edemaine/comingle/issues/181)]
* People with an empty name no longer cluster together, as they're reasonably
  likely to be separate people.
* Support YouTube URLs with start times (`t=...` or `start=...`) and/or
  playlists (`list=...`).
  [[#170](https://github.com/edemaine/comingle/issues/170)]
* Fix color of archived new tabs (red instead of yellow)
  [[#187](https://github.com/edemaine/comingle/issues/187)]

## 2021-06-01

* Tabs you've never seen now have yellow and bold titles.
  Newly shared tabs are created (in this state) without selecting/opening them,
  so you're not interrupted from whatever you were working on.
  [[#5](https://github.com/edemaine/comingle/issues/5)]
* Archived rooms' and tabs' titles are italicized in addition to
  being colored red, for further emphasis

## 2021-05-30

* <kbd>Escape</kbd> key now closes a New Tab (if one of the inputs has focus)
  [[#173](https://github.com/edemaine/comingle/issues/173)]
  or closes the buttons for a room in the room list (if one is selected).

## 2021-04-24

* Rename main branch from `master` to `main`.
  The link to this Changelog has changed (but the old link redirects).

## 2021-04-20

* Custom scrollbars should look nicer especially in dark mode.

## 2021-04-15

* There's now a
  [command-line tool for Comingle attendance tracking](https://github.com/edemaine/comingle-attendance),
  e.g. to measure which students showed up to which classes.

## 2021-04-14

* Revised room-list design stacking stars and people vertically instead of
  horizontally, providing better line breaks for room titles.
  [[#168](https://github.com/edemaine/comingle/issues/168) and
  [#113](https://github.com/edemaine/comingle/issues/113)]
* Logs now include `"presencePulse"` events for users who stay in the same
  meeting for a long time (default 4 hours), to make log processing easier.
  [[#169](https://github.com/edemaine/comingle/issues/169)]

## 2021-04-11

* API call `/log/get` now supports specifying the final date via
  the more common `end` in addition to `finish`.

## 2021-04-10

* Comingle now remembers the meetings you've visited, and offers links to them
  on the front page, reverse-sorted by the last time you visited them.
  [[#159](https://github.com/edemaine/comingle/issues/159)]
* Correct scrolling to bottom of chat when it has math

## 2021-04-05

* Fix dragging of separators between tabsets.  (Needed to drag very slowly.)

## 2021-04-04

* Dragging a link into Comingle now works better when dragging on top of an
  iframe/tab (though you still need to "start" the drag by dragging into a
  simple area like the tab buttons at the top).  On Chrome, it's
  [not possible](https://bugs.chromium.org/p/chromium/issues/detail?id=59081)
  to drag from within a Comingle tab into the same Comingle; see
  [this feature request](https://bugs.chromium.org/p/chromium/issues/detail?id=981124).

## 2021-04-03

* You can now drag a link from another browser window into Comingle, and it
  will create a New Tab interface with that URL filled in; just click the
  Embed This URL button to confirm (after optionally setting the tab title).
  [[#74](https://github.com/edemaine/comingle/issues/74)]
* Tabs within a tabset are now scrollable (similar to e.g. VSCode);
  selecting tabs from the Overflow list just scrolls to that tab.

## 2021-03-26

* The webpage title now includes the meeting and room titles
  (in addition to "Comingle").
  [[#164](https://github.com/edemaine/comingle/issues/164)]

## 2021-03-19

* Fix tab renaming having weird selection behavior on Firefox
  [[#162](https://github.com/edemaine/comingle/issues/162)]
* Fix LaTeX not always formatting when initially loading in chat
  [[#163](https://github.com/edemaine/comingle/issues/163)]

## 2021-03-18

* When you select an archived room in the room list, you now have a new option:
  Unarchive Room directly unarchives the room without having to enter the room.
  Admins also gain the option to archive an unarchived room without joining it.
  [[#109](https://github.com/edemaine/comingle/issues/109)]

## 2021-03-17

* Comingle no longer warns about using Firefox, as it seems to handle Jitsi
  well now.  [[#150](https://github.com/edemaine/comingle/issues/150)]

## 2021-03-16

* Fix the background color of iframes to white,
  in case they use a transparent background (expecting it to be white).
  (In dark mode, this caused some images to appear black on black.)
* API calls can now use strings to specify Dates, instead of requiring
  EJSON representation.
  [[#155](https://github.com/edemaine/comingle/issues/155)]
* All API calls can now specify `updator`, even if it's not needed (`/get`),
  for more consistency.
  [[#156](https://github.com/edemaine/comingle/issues/156)]
* Fix `/api/room/new` when creating a protected room with initial tabs.
  [[#157](https://github.com/edemaine/comingle/issues/157)]

## 2021-03-08

* Comingle now has
  [an API](https://github.com/edemaine/comingle/blob/main/doc/api.md)
  for querying and manipulating Comingle meetings, rooms, tabs, and logs
  from your own software (or via `curl`).
  Queries can run without any special permissions, just like they would in
  the browser, but for safety, all updates require the meeting's secret key.
  [[#131](https://github.com/edemaine/comingle/pull/131)]

## 2021-03-04

* Chat tabs now remain scrolled to the bottom, unless you scroll up to read
  older messages.  [[#111](https://github.com/edemaine/comingle/issues/111)]
* Fix extra New Tabs appearing at random when loading a room.
  [[#151](https://github.com/edemaine/comingle/issues/151)]

## 2021-03-02

* Admins can now permanently **delete** rooms and tabs,
  e.g., to remove sensitive information.  Use with care!
  [[#89](https://github.com/edemaine/comingle/issues/89)]

## 2021-03-01

* Admins can now mark rooms as **protected**, meaning that the room can't be
  renamed or archived, and tabs within the room cannot be added, renamed,
  or archived.  [[#152](https://github.com/edemaine/comingle/issues/152)]

## Older Changes

Refer to [the Git log](https://github.com/edemaine/comingle/commits/main)
for changes older than listed in this document.
