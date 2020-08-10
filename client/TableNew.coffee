import React, {useState} from 'react'

export default TableNew = ->
  [title, setTitle] = useState ''
  submit = (e) ->
    e.preventDefault()
    return unless title.trim().length
    Meteor.call 'tableNew',
      title: title.trim()
    setTitle ''
  <form onSubmit={submit}>
    <div className="form-group"/>
    <div className="form-group">
      <input type="text" placeholder="Title" className="form-control"
       value={title} onChange={(e) -> setTitle e.target.value}/>
      <button type="submit" className="btn btn-primary btn-block">
        Create New Table
      </button>
    </div>
  </form>
