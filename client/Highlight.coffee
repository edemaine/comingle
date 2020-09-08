import React from 'react'

import {escapeHTML, escapeRegExp} from './lib/escape'

export Highlight = (props) ->
  {search, text} = props
  delete props.search
  delete props.text
  unless search
    return <span {...props}>{text}</span>
  text = escapeHTML text
  .replace (new RegExp (escapeRegExp search), 'gi'), """
    <span class="highlight">$&</span>
  """
  <span {...props} dangerouslySetInnerHTML={__html: text}/>
Highlight.displayName = 'Highlight'
