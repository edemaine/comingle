import React, {useMemo} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Session} from 'meteor/session'

globalMarkdown = null  # eventually set to MarkdownIt instance

export Markdown = ({body, ...props}) ->
  markdown = useTracker ->
    return globalMarkdown if globalMarkdown?
    unless Session.get 'markdownLoading'
      Session.set 'markdownLoading', true
      import('markdown-it').then ({default: MarkdownIt}) ->
        globalMarkdown = new MarkdownIt
          linkify: true
          typographer: true
        Session.set 'markdownLoading', false  # triggers reading globalMarkdown
    undefined
  , []

  html = useMemo ->
    return unless markdown?
    markdown.renderInline body
  , [markdown]

  if html?
    <div {...props} dangerouslySetInnerHTML={__html: html}/>
  else
    <div {...props}>{body}</div>
