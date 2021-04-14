import React from 'react'

import {escapeHTML, escapeRegExp} from './lib/escape'

export Highlight = React.memo ({search, text, ...props}) ->
  unless search
    return <span {...props}>{postprocess text}</span>
  text = escapeHTML text
  .replace (new RegExp (escapeRegExp search), 'gi'), """
    <span class="highlight">$&</span>
  """
  <span {...props} dangerouslySetInnerHTML={__html: postprocess text}/>
Highlight.displayName = 'Highlight'

postprocess = (x) ->
  ## Allow line breaks after slashes via zero-width space U+200B
  x.replace /[/]/g, (match, offset, string) ->
    if inTag string, offset
      match
    else
      "#{match}\u200b"

## From Coauthor (lib/formats.coffee)
export inTag = (string, offset) ->
  ## Known issue: `<a title=">"` looks like a terminated tag to this code.
  open = string.lastIndexOf '<', offset
  if open >= 0
    close = string.lastIndexOf '>', offset
    if close < open  ## potential unclosed HTML tag
      return true
  false
