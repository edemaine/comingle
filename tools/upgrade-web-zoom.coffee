fetch = require 'isomorphic-fetch'
fs = require 'fs/promises'
path = require 'path'

rootUrl = 'https://github.com/zoom/sample-app-web/raw/master/CDN'
dest = path.join __dirname, '../public'

vconsoleCdn = ->
  vconsoleZoom = await fetch "#{rootUrl}/js/vconsole.min.js"
  vconsoleZoom = await vconsoleZoom.text()
  unless match = vconsoleZoom.match /\* vConsole v(\d+\.\d+\.\d+)\s/
    throw new Error "unable to parse vConsole version"
  cdnUrl = "https://cdnjs.cloudflare.com/ajax/libs/vConsole/#{match[1]}/vconsole.min.js"
  vconsoleCdn = await fetch cdnUrl
  vconsoleCdn = await vconsoleCdn.text()
  unless vconsoleZoom == vconsoleCdn
    throw new Error "#{cdnUrl} doesn't match #{rootUrl}/js/vconsole.min.js"
  cdnUrl

makeHtml = ->
  vconsole = await vconsoleCdn()
  url = "#{rootUrl}/meeting.html"
  html = await fetch url
  html = await html.text()
  changes = 0
  html = html
  .replace /<!DOCTYPE[^<>]*>\n/, (m) ->
    changes++
    "#{m}<!-- based on #{url} -->\n"
  .replace /^\s+<script src="js\/(tool|meeting|vconsole.min).js"><\/script>\s*\n/mg, (m, file) ->
    changes++
    switch file
      when 'meeting'
        m.replace /"js\/meeting.js"/, '"/zoom.js"'
      when 'vconsole.min'
        m.replace /"js\/vconsole.min.js"/, '"'+vconsole+'"'
      else
        ""
  .replace /\n\s+<script>\s*<\/script>/, ''  # remove empty <script>
  .replace /[^\n]$/s, '$&\n'  # add trailing newline
  unless changes == 4
    console.log html
    throw new Error "Made #{changes} changes; expected 4"
  filename = path.join dest, 'zoom.html'
  await fs.writeFile filename, html
  console.log "Wrote #{filename}"

makeJs = ->
  js = '''
    // Concatenation of two files:

  '''
  for filename, i in ['tool.js', 'meeting.js']
    url = "#{rootUrl}/js/#{filename}"
    js += """

      //////////////////////////////////////////////////////////////////////////
      // #{i+1}. #{url}

    """
    if filename == 'meeting.js'
      js += """
      // customized below to use apiKey over sdkKey, and custom leaveUrl:
      //  leaveUrl: "/zoomDone.html",

      """
    js += """
      //////////////////////////////////////////////////////////////////////////


    """
    code = await fetch url
    code = await code.text()
    if filename == 'meeting.js'
      changes = 0
      code = code
      .replace /\bleaveUrl: "[^"]*"/g, (m) ->
        changes++
        m.replace /"[^"]*"/, '"/zoomDone.html"'
      # Override sdkKey mechanism (introduced in 2.3.0) back to regular apiKey
      .replace /\bsdkKey: \w+\.sdkKey,/g, (m) ->
        changes++
        m.replace /sdkKey/g, 'apiKey'
      unless changes == 3
        console.log code
        throw new Error "Made #{changes} changes; expected 3"
    js += code
  filename = path.join dest, 'zoom.js'
  await fs.writeFile filename, js
  console.log "Wrote #{filename}"

make = ->
  await makeHtml()
  await makeJs()

make()
