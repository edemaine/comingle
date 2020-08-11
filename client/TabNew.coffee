import React, {useState} from 'react'
import {validURL} from '/lib/tabs'

export default TabNew = ({tab, roomId, tableId, replaceTabNew}) ->
  [url, setUrl] = useState ''
  onSubmit = (e) ->
    e.preventDefault()
    id = Meteor.apply 'tabNew', [
      room: roomId
      table: tableId
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
      <button type="submit" className="btn btn-primary btn-block">
        Create New Tab
      </button>
    </div>
  </form>
