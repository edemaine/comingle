# Changelog

This file describes significant changes to Comingle to an audience of
both everyday users and administrators running their own Comingle server.
To see every change with descriptions aimed at developers, see
[the Git log](https://github.com/edemaine/comingle/commits/main).
As a continuously updated web app, Comingle uses dates
instead of version numbers.

## 2022-02-04

* Newly raised hands will make a whistling sound by default for admins.
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
