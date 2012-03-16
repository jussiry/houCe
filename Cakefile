
## Require libs

task_name = process.argv[2]

# In docs_to_github we need to delete all code from gh-pages branch, so we must
# skip requiring most libraries when making docs.
unless task_name in ['build_docs', 'docs_to_github']
  require 'sugar'
  Object.extend()
  require './common/common_utils' # not so sure if it's such a good idea to load these in the first place. only used for log-shorthand
  
  less_options  = paths: ['./client', './client/styles']
  
  LESS          = require 'less'
  CoffeeScript  = require 'coffee-script'
  CoffeeKup     = require 'coffeekup'
  ccss          = require 'ccss'
  ccss_helpers  = require './client/styles/ccss_helpers.s.coffee'
  houce         = require "./server/houce.coffee"

fs     = require 'fs'
{exec} = require 'child_process'

standard_exec_func = (err, stdout, stderr)->
  throw err if err
  console.log stdout + stderr

ccss_shortcuts = (obj)->
  for key, val of obj
    ccss_shortcuts val if typeof val is 'object'
    # split multi definitions:
    keys = key.split(/,|_and_/).map('trim')
    keys.each (k)->
      # change i_plaa to '#plaa' and c_plaa to '.plaa'
      new_key =  if      k[0..1] is 'i_' then '#'+k[2..-1] \
                 else if k[0..1] is 'c_' then '.'+k[2..-1] \
                 else if keys.length > 1 then k
                 else false
      if new_key
        obj[new_key] ?= {}
        obj[new_key].merge val
        delete obj[key]
  obj

## Build client

task 'build_client', ->
  log "Starting to build client files..."
  
  files = []
  files_first = []
  files_last  = []
  
  # Collect all files from /client folder:
  ind = 0
  read_folder = (path)->
    ind += 1
    #log "path #{path}"
    folder_contents = fs.readdirSync path
    for file_or_folder in folder_contents
      fof_path = path+'/'+file_or_folder
      fof_stat = fs.statSync fof_path
      if fof_stat.isDirectory()
        read_folder fof_path
      else
        file_parts = file_or_folder.split '.'
        switch file_parts.length
          when 2
            files.push fof_path # normal file
          when 3
            # special files: first, last or skip
            order_or_skip = file_parts[1] #.toUpperCase()
            if order_or_skip.parsesToNumber()
              order = order_or_skip.toNumber()
              if order < 0 then files_last[order.abs()] = fof_path \
                           else files_first[order]      = fof_path 
            else if order_or_skip.toLowerCase() is 's'
              null # skip this file by doing nothing
            else
              throw "Unknown special type for: #{file_or_folder}"
          else
            throw "Unknown file format: #{file_or_folder}"
  read_folder __dirname+'/client'
  
  # put files marked with name.FX.coffee in front of client_app.js
  for fof_path in files_first.compact().reverse()
    files.unshift fof_path #files.skipped.find (path)-> path.has file_name
  
  for fof_path in files_last.compact().reverse()
    files.push fof_path #files.skipped.find (path)-> path.has file_name

  templates = {}
  JS        = ""
  less_css  = ""
  ccss_css = ""
  
  # compile common_utils.coffee to JS:
  JS += "\n\n\n/* --- COMMON_UTILS.COFFEE --- */\n\n"
  cu_str = fs.readFileSync(__dirname+"/common/common_utils.coffee").toString()
  JS += CoffeeScript.compile cu_str, {}

  # Go through collected files, and parse them based on file type:
  for file_path in files
    throw "File not found under '/client'!\n" unless file_path?
    app_file_path = file_path.remove __dirname+'/client'
    log "Parsing file: #{app_file_path}"
    [file_name, file_extension] = app_file_path.toLowerCase().split(/\.|\//).last(2)

    # check no duplicate for templates (.html, .ck)
    if templates[file_name]? and ['html','ck','templ','page'].has file_extension
      throw "\nERROR! Already has template with same name: #{file_name}.html\n\n"
    
    file_str = fs.readFileSync(file_path).toString()

    switch file_extension
      when 'coffee'
        JS += "\n\n\n/* --- #{app_file_path.toUpperCase()} --- */\n\n"
        JS += CoffeeScript.compile file_str, {'filename': app_file_path} #, (err) -> throw err if err
      when 'less'
        do ->
          fname = file_name
          LESS.render file_str, less_options, (e,css)->
            if e
              log """
              ------------------------------------------------------------
              ERROR: #{fname}.less: #{e.message}: #{e.extract.join('')}
              ------------------------------------------------------------ """
              throw "Less parsing failed"
            less_css += "\n\n/* --- #{fname.toUpperCase()}: --- */\n\n"
            less_css += css
            log "              #{fname}.less length: #{less_css.length}"
            fs.writeFileSync __dirname+'/public/stylesheets/less_styles.css', less_css, 'utf8', (err)-> if err then throw err

      when 'ccss'
        try
          file_js = CoffeeScript.compile file_str, bare:true
          `with( ccss_helpers ){
            var ccss_obj = eval(file_js);
          }`
          ccss_obj = ccss_shortcuts ccss_obj
          ccss_css += ccss.compile ccss_obj
        catch err
          log "\nERROR in compiling CCSS file: #{file_name}.#{file_extension}"
          throw err
      when 'templ', 'page'
        # _page properties: templ, style, page, init_
        # Call template file with empty object and bind all functions to that:
        try
          templ_str = (CoffeeScript.compile file_str, {}).replace /\}\).call\(this\);\n$/,
                                                                "return this;}).call({});"  # 
          `with( ccss_helpers ){
            templates[file_name] = eval(templ_str);
          }`
        catch err
          log "\nError in processing template: #{file_name.toUpperCase()}.#{file_extension.toUpperCase()}"
          log "#{err.stack}"
          throw ''
          #throw err
        # check @html exists
        unless templates[file_name].html?
          err = "#{file_name}.#{file_extension} is missing @html variable!\n"
          throw err
        # check .page's have @page
        if file_extension == 'page' and not templates[file_name].page?
          err = "#{file_name}.page does not have @page variable! Use .templ extension if it's not a page.\n"
          throw err
        # check .templ's don't have @page
        else if file_extension == 'templ' and templates[file_name].page?
          err = "#{file_name}.templ has @page variable! You need to change it to .page -extension to keep things clear.\n"
          throw err
        # Compile style
        if templates[file_name].style?
          ccss_shortcuts templates[file_name].style
          try ccss_css += ccss.compile templates[file_name].style
          catch err
            log "\nERROR in compiling @style in template: #{file_name}.#{file_extension}"
            throw err
          delete templates[file_name].style # no need to send style obj to client
      else
        log "No action for #{app_file_path}"

  
  ### Save coffee files client.js ###
  fs.writeFileSync __dirname+'/public/client_app.js', JS, 'utf8', (err)-> if err then throw err

  ### Save ccss/css from templates ###
  fs.writeFileSync __dirname+'/public/stylesheets/ccss_styles.css', ccss_css, 'utf8'


  ### compile preload.s.coffee  ###
  # preload_js = CoffeeScript.compile fs.readFileSync(__dirname+"/client/app/preload.s.coffee").toString()
  # fs.writeFileSync __dirname+'/public/preload.js', preload_js, 'utf8', (err)-> if err then throw err

  ### /client/index.ck -> /public/index.html ###
  houce.compile_index()
  
  ### Manifest file ###
  houce.create_manifest()

  ### Save templates to templates.js ###
  stringify = (main_obj)->
    switch typeof main_obj
      when 'object'
        return 'null' if main_obj is null
        obj_strings = []
        main_obj.each (name, obj)->
          #log "processing: #{name}"
          obj_strings.push "'#{name}': #{stringify obj}"
        "{ #{obj_strings.join ',\n'} }"
      when 'function'  then main_obj.toString()
      when 'string'    then "'#{main_obj}'"
      when 'number'    then main_obj
      when 'undefined' then 'undefined'
      else throw "#{typeof main_obj}'s not valid objects!"
    
  full_templ_str = "window.Templates = \n#{stringify templates};"
  fs.writeFileSync __dirname+'/public/templates.js', full_templ_str, 'utf8', (err)-> if err then throw err
  

  console.info "Client files built!"


### Pull new version of houCe from github ###

task 'update_houce', ->
  exec "git pull git://github.com/jussiry/houCe.git", (err, stdout, stderr)->
    if err then console.log err    \
           else console.log stdout


## Build documentation under /docs

task 'build_docs', ->
  exec "./node_modules/.bin/docco-husky start.coffee client common server", (err, stdout, stderr)->
    if err then console.log err    \
           else console.log stdout



## Create docs to gh-branch and push them to Github pages

task 'docs_to_github', ->  
  log = (m)-> console.log m         
  exec "git branch -D gh-pages", (err, stdout, stderr)->
    # causes error if branch don't exist; no need to log it.
    exec "git symbolic-ref HEAD refs/heads/gh-pages", (err, stdout, stderr)->
      return log err if err
      exec "cake 'build_docs'", (err, stdout, stderr)->
        return log err if err
        log "docs built"
        exec "rm -R client common public server", (err, stdout, stderr)->
          return log err if err
          log "code removed"
          exec "mv ./public/docs/** .", (err, stdout, stderr)->
            return log err if err
            log "docs moved/linked"
            exec "git add .", (err, stdout, stderr)->
              return log err if err
              log "git add done"
              exec "git commit -a -m 'Docs updated'", (err, stdout, stderr)->
                return log err if err
                log "git commit done"
                exec "git push -f origin gh-pages", (err, stdout, stderr)->
                  return log err if err
                  log "git push done"
                  exec "git checkout master", (err, stdout, stderr)->
                    return log err if err
                    log "Done. Will take a while for http://jussiry.github.com/houCe to be refreshed."
