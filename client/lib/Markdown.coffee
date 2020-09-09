import React, {useMemo, useState} from 'react'

import {useAsync} from './useAsync'

globalMarkdown = null  # eventually set to a MarkdownIt instance

export Markdown = ({body, ...props}) ->
  [markdown, setMarkdown] = useState globalMarkdown
  unless markdown?
    import('markdown-it').then ({default: MarkdownIt}) ->
      setMarkdown globalMarkdown = new MarkdownIt
        linkify: true
        typographer: true
  html = useMemo ->
    return unless markdown?
    markdown.renderInline body
  , [markdown]
  if html?
    <div {...props} dangerouslySetInnerHTML={__html: html}/>
  else
    <div {...props}>{body}</div>
