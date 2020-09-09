import React from 'react'

import {escapeHTML, escapeRegExp} from './lib/escape'

export Highlight = ({search, text, ...props}) ->
  unless search
    return <span {...props}>{text}</span>
  text = escapeHTML text
  .replace (new RegExp (escapeRegExp search), 'gi'), """
    <span class="highlight">$&</span>
  """
  <span {...props} dangerouslySetInnerHTML={__html: text}/>
Highlight.displayName = 'Highlight'
