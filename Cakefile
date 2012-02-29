
task_name = process.argv[2]

unless task_name in ['build_docs', 'docs_to_github']
  require 'sugar'
  Object.extend()
  require './common/common_utils' # not so sure if it's such a good idea to load these in the first place. only used for log-shorthand
  {JSONstring} = require('./public/lib/jsonStringify') #so that common_utils won't crash
  JSONstring.includeFunctions = true
  LESS   = require 'less'
  less_options = paths: ['./client', './client/styles']
  CoffeeScript = require 'coffee-script'

fs     = require 'fs'
{exec} = require 'child_process'

standard_exec_func = (err, stdout, stderr)->
  throw err if err
  console.log stdout + stderr


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
  CSS       = ""
  
  # compile common_utils.coffee to JS:
  JS += "\n\n\n/* --- COMMON_UTILS.COFFEE --- */\n\n"
  cu_str = fs.readFileSync(__dirname+"/common/common_utils.coffee").toString()
  JS += CoffeeScript.compile cu_str, {}
    
  scss_files = 0 # counter to detect when all scss callbacks have been called

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
            CSS += "\n\n/* --- #{fname.toUpperCase()}: --- */\n\n"
            CSS += css
            log "              #{fname}.less length: #{CSS.length}"
            fs.writeFileSync __dirname+'/public/stylesheets/stylesheets.css', CSS, 'utf8', (err)-> if err then throw err

      when 'templ', 'page'
        # _page properties: templ, style, page, init_
        # Call template file with empty object and bind all functions to that:
        templ_str = (CoffeeScript.compile file_str, {}).replace /\}\).call\(this\);\n$/,
                                                                "return this;}).call({});"  # 
        templates[file_name] = eval templ_str
        unless templates[file_name].html?
          err = "#{file_name}.#{file_extension} is missing @html variable!\n"
          throw err
        if file_extension == 'page' and not templates[file_name].page?
          err = "#{file_name}.page does not have @page variable! Use .templ extension if it's not a page.\n"
          throw err
        else if file_extension == 'templ' and templates[file_name].page?
          err = "#{file_name}.templ has @page variable! You need to change it to .page -extension to keep things clear.\n"
          throw err 
      else
        log "No action for #{app_file_path}"

  # .coffee files:
  fs.writeFileSync __dirname+'/public/client_app.js', JS, 'utf8', (err)-> if err then throw err
  

  # Dunno why this don't work..:
  # save_css = _.after scss_files, ->
  #   fs.writeFileSync __dirname+'/public/stylesheets.css', CSS, 'utf8', (err)-> if err then throw err

  # Save templates to templates.js
  
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



task 'build_docs', ->
  exec "./node_modules/.bin/docco-husky start.coffee client common server", (err, stdout, stderr)->
    if err then console.log err    \
           else console.log stdout

# Create docs to gh-branch and push to Github pages
task 'docs_to_github', ->  
  log = (m)-> console.log m         
  # Make sure we are in the right branch
  exec "git branch -D gh-pages", (err, stdout, stderr)->
    return log err if err
    exec "git symbolic-ref HEAD refs/heads/gh-pages", (err, stdout, stderr)->
      return log err if err
      # return
      # exec "git merge master", (err, stdout, stderr)->
      #   return log err if err
      #   log "master branch merged"
      exec "cake 'build_docs'", (err, stdout, stderr)->
        return log err if err
        log "docs built"
        exec "rm -R client common public server", (err, stdout, stderr)->
          return log err if err
          log "code removed"
          exec "mv ./docs/** .", (err, stdout, stderr)->
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
                    log "Now go to: http://jussiry.github.com/houCe/"
