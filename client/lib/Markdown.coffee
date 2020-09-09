import React, {useLayoutEffect, useMemo} from 'react'

import {useAsync} from './useAsync'

markdown = null  # eventually set to a MarkdownIt instance

export Markdown = ({body, ...props}) ->
  MarkdownIt = useAsync -> (await import('markdown-it')).default
  html = useMemo ->
    return unless MarkdownIt?
    markdown ?= new MarkdownIt
      linkify: true
      typographer: true
    markdown.renderInline body
  , [MarkdownIt]
  if html?
    <div {...props} dangerouslySetInnerHTML={__html: html}/>
  else
    <div {...props}>{body}</div>
