import React, {useMemo} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Session} from 'meteor/session'

globalMarkdown = null  # eventually set to MarkdownIt instance
texLoaded = false

export Markdown = ({body, ...props}) ->
  markdown = useTracker ->
    unless globalMarkdown?
      unless Session.get 'markdownLoading'
        Session.set 'markdownLoading', true  # only one loader
        import('markdown-it').then ({default: MarkdownIt}) ->
          globalMarkdown = new MarkdownIt
            linkify: true
            typographer: true
          Session.set 'markdownLoading', false  # triggers reading globalMarkdown
      undefined
    else
      ## Load LaTeX plugin only if $ present in a message
      if not texLoaded and body.includes '$'
        unless Session.get 'texLoading'
          Session.set 'texLoading', true  # only one loader
          Promise.all [import('katex'), import('markdown-it-texmath')]
          .then ([{default: katex}, {default: texmath}]) ->
            ## Load KaTeX CSS
            style = document.createElement 'link'
            style.setAttribute 'rel', 'stylesheet'
            style.setAttribute 'crossorigin', 'anonymous'
            style.setAttribute 'href', "https://cdn.jsdelivr.net/npm/katex@#{katex.version}/dist/katex.min.css"
            document.head.appendChild style
            ## Add LaTeX plugin to globalMarkdown
            globalMarkdown.use texmath, engine: katex
            texLoaded = true
            Session.set 'texLoading', false  # triggers reading globalMarkdown
      globalMarkdown
  , [body]

  html = useMemo ->
    return unless markdown?
    markdown.renderInline body
    ## Make all links open in separate window, without referrer/opener
    .replace /<a href\b/g, '<a target="_blank" rel="noreferrer" href'
  , [markdown, texLoaded]

  if html?
    <div {...props} dangerouslySetInnerHTML={__html: html}/>
  else
    <div {...props}>{body}</div>
