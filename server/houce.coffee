

require "./config.coffee"

fs            = require 'fs'
  
LESS          = require 'less'
CoffeeScript  = require 'coffee-script'
CoffeeKup     = require 'coffeekup'
ccss          = require 'ccss'
ccss_helpers  = require config.app_dir+'/client/styles/ccss_helpers.s.coffee'

less_options  = paths: [config.app_dir+'/client', config.app_dir+'/client/styles']
  
# Helpers:

ccss_shortcuts = (obj)->
  for orig_key, val of obj
    ccss_shortcuts val if typeof val is 'object'
    # split multi definitions:
    keys = orig_key.split(/,|__/).map('trim')
    keys.each (k)->
      # change i_plaa to '#plaa' and c_plaa to '.plaa'
      if      k[0..1] is 'i_' then k = '#'+k[2..-1]
      else if k[0..1] is 'c_' then k = '.'+k[2..-1]
      # font_size to font-size
      if typeof val isnt 'object'
        k = k.replace(/_/g,'-')
      # set new key and delete old:
      if k isnt orig_key
        if typeof val is 'object'
          obj[k] ?= {}
          obj[k].merge val
        else
          obj[k] = val
        delete obj[orig_key]
  obj

error_to_client = (err, res)->
  return unless res?
  err_html = err.replace /\n/g, "<br/>"
  style = "<style>body{
    padding: 1em 2em;
    font-family: Verdana;
    font-size: 0.8em;
    line-height: 1.4em;
    color: #333;
  }</style>"
  res.send style+err_html

for_files_in = (path, file_func)->
  (iterator = (path)->
    folder_contents = fs.readdirSync path
    for file_or_folder in folder_contents
      fof_path = "#{path}/#{file_or_folder}"
      fof_stat = fs.statSync fof_path
      if fof_stat.isDirectory()
        iterator fof_path
      else
        file_func fof_path.remove "#{config.app_dir}public/"
    return
  )( path )

# public methods:

@compile_index = ->
  log 'houce: compiling index'
  # create client_config from server config
  # (delete vars you don't want visible in client)
  client_config = config.clone()
  delete client_config.port
  delete client_config.app_dir
  # compile index.ck
  index_ck = fs.readFileSync( config.app_dir+"/client/app/index.ck" ).toString()
  try
    index_html = CoffeeKup.render index_ck,
      env:    config.env
      config: client_config
  catch err
    throw "Error in compiling index.ck: #{err.message}"
  fs.writeFileSync config.app_dir+'/public/index.html', index_html, 'utf8', (err)-> if err then throw err


@create_manifest = ->
  log "houce: creating manifest file"
  manifest_path = config.app_dir+'public/appcache.mf'
  if config.env is 'development'
    # make sure there is no manifest file to load:
    try fs.unlinkSync manifest_path
    catch err then null
    return
  manifest_str = """
    CACHE MANIFEST
    # #{Date.now()}

    CACHE:
    index.html
    client_app.js
    templates.js
    stylesheets/ccss_styles.css
    stylesheets/less_styles.css
    https://fonts.googleapis.com/css?family=PT+Sans:700
    https://themes.googleusercontent.com/static/fonts/ptsans/v3/0XxGQsSc1g4rdRdjJKZrNL3hpw3pgy2gAi-Ip7WPMi0.woff
  """
  file_func = (file_path)->
    if ['jpg', 'png', 'gif', 'js'].has file_path.split('.').last()
      manifest_str += "\n#{file_path}"
  for_files_in "#{config.app_dir}public/img", file_func
  for_files_in "#{config.app_dir}public/lib", file_func
  manifest_str += "\n\nNETWORK:\n*"
  
  fs.writeFileSync manifest_path, manifest_str, 'utf8', (err)-> if err then throw err


@build_client = (res)->
  
  log_str = ''
  log = (msg)->
    log_str += msg + '\n'
    console.log.apply console, arguments
  error = (err)->
    log 'Error in build_client: '+err
    err_msg = "#{log_str}\nERROR: #{err}"
    error_to_client err_msg, res if res?
    throw Error err
  
  log "houce: building client"
  
  files = []
  files_first = []
  files_last  = []
  
  for_files_in config.app_dir+'client', (file_path)->
    file_parts = file_path.split '.'
    switch file_parts.length
      when 2 then files.push file_path # normal file
      when 3 # special files: first, last or skip
        order_or_skip = file_parts[1] #.toUpperCase()
        if order_or_skip.parsesToNumber()
          order = order_or_skip.toNumber()
          if order < 0 then files_last[order.abs()] = file_path \
                       else files_first[order]      = file_path 
        else if order_or_skip.toLowerCase() is 's'
          null # skip this file by doing nothing
        else error "Unknown special type for: #{file_or_folder}"
      else error "Unknown file format: #{file_or_folder}"
  
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
  cu_str = fs.readFileSync(config.app_dir+"/common/common_utils.coffee").toString()
  JS += CoffeeScript.compile cu_str, {}

  # Go through collected files, and parse them based on file type:
  for file_path in files
    error "File not found under '/client'!\n" unless file_path?
    app_file_path = file_path.remove config.app_dir+'/client'
    log "Parsing file: #{app_file_path}"
    [file_name, file_extension] = app_file_path.toLowerCase().split(/\.|\//).last(2)

    # check no duplicate for templates (.html, .ck)
    if templates[file_name]? and ['html','ck','templ','page'].has file_extension
      error "\nERROR! Already has template with same name: #{file_name}.html\n\n"
    
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
              error """
              ------------------------------------------------------------
              ERROR: #{fname}.less: #{e.message}: #{e.extract.join('')}
              ------------------------------------------------------------ """
            less_css += "\n\n/* --- #{fname.toUpperCase()}: --- */\n\n"
            less_css += css
            log "              #{fname}.less length: #{less_css.length}"
            fs.writeFileSync config.app_dir+'/public/stylesheets/less_styles.css', less_css, 'utf8', (err)-> if err then throw err

      when 'ccss'
        try
          file_js = CoffeeScript.compile file_str, bare:true
          `with( ccss_helpers ){
            var ccss_obj = eval(file_js);
          }`
          ccss_obj = ccss_shortcuts ccss_obj
          ccss_css += ccss.compile ccss_obj
        catch err
          error "\nERROR in compiling CCSS file: #{file_name}.#{file_extension}: #{err}"
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
          error "\nError in processing template: #{file_name.toUpperCase()}.#{file_extension.toUpperCase()} #{err.stack[0]}"
          #throw err
        # check .page's have @page
        if file_extension is 'page' and not templates[file_name].page?
          error "#{file_name}.page does not have @page variable! Use .templ extension if it's not a page.\n"
        if file_extension is 'templ'
          # check @html exists in .templ
          unless templates[file_name].html?
            error "#{file_name}.#{file_extension} is missing @html variable!\n"
          # check .templ's don't have @page
          if templates[file_name].page?
            error "#{file_name}.templ has @page variable! You need to change it to .page -extension to keep things clear.\n"
        # Compile style
        if templates[file_name].style?
          ccss_shortcuts templates[file_name].style
          try ccss_css += ccss.compile templates[file_name].style
          catch err
            error "\nERROR in compiling @style in template: #{file_name}.#{file_extension}: #{err}"
          delete templates[file_name].style # no need to send style obj to client
      else
        log "No action for #{app_file_path}"

  
  ### Save coffee files client.js ###
  fs.writeFileSync config.app_dir+'/public/client_app.js', JS, 'utf8', (err)-> if err then error err

  ### Save ccss/css from templates ###
  fs.writeFileSync config.app_dir+'/public/stylesheets/ccss_styles.css', ccss_css, 'utf8'


  ### compile preload.s.coffee  ###
  # preload_js = CoffeeScript.compile fs.readFileSync(config.app_dir+"/client/app/preload.s.coffee").toString()
  # fs.writeFileSync config.app_dir+'/public/preload.js', preload_js, 'utf8', (err)-> if err then throw err

  ### /client/app/index.ck -> /public/index.html ###
  @compile_index()
  
  ### Manifest file ###
  @create_manifest()

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
      else error "#{typeof main_obj}'s not valid objects!"
    
  full_templ_str = "window.Templates = \n#{stringify templates};"
  fs.writeFileSync config.app_dir+'/public/templates.js', full_templ_str, 'utf8', (err)-> if err then error err
  

  console.info "Client files built!"


exports = @