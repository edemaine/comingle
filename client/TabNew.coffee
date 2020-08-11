import React, {useState, useEffect} from 'react'
import {validURL} from '/lib/tabs'

export default TabNew = ({tab, roomId, tableId, replaceTabNew}) ->
  [url, setUrl] = useState ''
  [title, setTitle] = useState ''
  [manualTitle, setManualTitle] = useState false
  useEffect ->
    if url and validURL(url) and not manualTitle
      setTitle (new URL url).hostname
  onSubmit = (e) ->
    e.preventDefault()
    id = Meteor.apply 'tabNew', [
      room: roomId
      table: tableId
      title: title.trim()
      type: 'iframe'
      url: url
    ], returnStubValue: true
    replaceTabNew {id, tab}
  <form className="newTab" onSubmit={onSubmit}>
    <div className="form-group"/>
    <div className="form-group">
      <label>URL for <code>&lt;iframe&gt;</code></label>
      <input type="url" placeholder="https://..." className="form-control"
       value={url} onChange={(e) -> setUrl e.target.value} required/>
    </div>
    <div className="form-group">
      <label>Tab title</label>
      <input type="text" placeholder="Cool Site" className="form-control"
       value={title} required pattern=".*\S.*"
       onChange={(e) -> setTitle e.target.value; setManualTitle true}/>
    </div>
    <div className="form-group">
      <button type="submit" className="btn btn-primary btn-block">
        Create New Tab
      </button>
    </div>
  </form>
