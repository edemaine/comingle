import React, {useMemo} from 'react'
import {useTracker} from 'meteor/react-meteor-data'
import {Session} from 'meteor/session'

globalMarkdown = null  # eventually set to MarkdownIt instance
globalTexLoaded = false
Session.set 'markdownLoading', false
Session.set 'texLoading', false
Session.set 'texLoaded', false

export Markdown = React.memo ({body, ...props}) ->
  {markdown, tex} = useTracker ->
    unless globalMarkdown?
      unless Session.get 'markdownLoading'
        Session.set 'markdownLoading', true  # only one loader
        import('markdown-it').then ({default: MarkdownIt}) ->
          globalMarkdown = new MarkdownIt
            linkify: true
            typographer: true
          Session.set 'markdownLoading', false  # triggers reading globalMarkdown

    else
      ## Load LaTeX plugin only if $ present in a message
      if not globalTexLoaded and body.includes '$'
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
            style.onload = ->
              ## Add LaTeX plugin to globalMarkdown
              globalMarkdown.use texmath, engine: katex
              globalTexLoaded = true
              Session.set 'texLoading', false  # triggers reading globalMarkdown
              Session.set 'texLoaded', true
    markdown: globalMarkdown
    tex: globalTexLoaded
  , [body]

  html = useMemo ->
    return unless markdown?
    markdown.renderInline body
    ## Make all links open in separate window, without referrer/opener
    .replace /<a href\b/g, '<a target="_blank" rel="noreferrer" href'
  , [markdown, tex]

  if html?
    <div {...props} dangerouslySetInnerHTML={__html: html}/>
  else
    <div {...props}>{body}</div>
