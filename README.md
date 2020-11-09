# Comingle

**Comingle** is an open-source online meeting tool
whose goal is to approximate the advantages of in-person meetings.
It **integrates web tools** in an open **multiroom** environment,
with the following key features:

* Subgroups of people can freely split off into separate discussions, by
  creating and jumping between **rooms** (something like physical tables).
  To facilitate e.g. deciding which room to go into:
  * Everyone can see who is in what room
  * Users can indicate their interest in multiple rooms
    by "joining" rooms in the background
* Rooms have **state**, such as whiteboard, chat messages,
  or key web pages being discussed.
  * Anyone joining late instantly has access to this state,
    enabling them to catch up without others telling them what tools to open.
  * You can return to a room days or weeks later and pick up where you left off.
* Comingle can be the **glue** that binds together all of the disparate
  web apps you want to use in your meeting
  (even for small meetings with a single room).
  * Instead of sending links to the tools you want people to look at,
    you can add them directly to the room, and everyone instantly sees them.
* Support for the following web **tools**:
  * [Jitsi Meet](https://meet.jit.si/)
    open-source video conferencing
  * [Zoom](https://zoom.us) video conferencing
    (most useful in Main Room only, because users must manually create a
    Zoom meeting and can only host one Zoom meeting at a time)
  * [Cocreate](https://github.com/edemaine/cocreate)
    open-source shared whiteboard
  * [Coauthor](https://github.com/edemaine/coauthor)
    open-source discussion forum / note taking
  * [YouTube videos](https://www.youtube.com/)
  * [Wikipedia pages](https://en.wikipedia.org/)
  * Any `<iframe>`-compatible web tool
* Each user can decide the best **layout** for their screen of each room's
  tools, by dragging tabs to be side-by-side or stacked atop each other.
* Persistent **chat** provided at the meeting and room level.
  * Chat messages can include Markdown formatting and LaTeX math
    (via [KaTeX](https://katex.org)).
* **Dark mode** for light-sensitive users, automatically affecting
  Jitsi, Cocreate, and Coauthor tabs.
* **Coop** protocol automatically passes user's name and dark-mode preference
  to supported apps (Cocreate and Coauthor).
* Instantly create a new meeting and share the URL to meet with others.
  **No accounts required**.
* **Free/open source** ([MIT license](LICENSE))
