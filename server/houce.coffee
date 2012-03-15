

require "./config.coffee"

fs        = require 'fs'
CoffeeKup = require 'coffeekup'

exports.compile_index = ->
  log 'houce: compiling index'
  # create client_config from server config
  # (delete vars you don't want visible in client)
  client_config = config.clone()
  delete client_config.port
  delete client_config.app_dir
  # compile index.ck
  index_ck = fs.readFileSync( config.app_dir+"/client/index.ck" ).toString()
  try
    index_html = CoffeeKup.render index_ck,
      env:    config.env
      config: client_config
  catch err
    throw "Error in compiling index.ck: #{err.message}"
  fs.writeFileSync config.app_dir+'/public/index.html', index_html, 'utf8', (err)-> if err then throw err


exports.create_manifest = ->
  manifest_path = config.app_dir+'public/appcache.mf'
  if config.env is 'development'
    # make sure there is no manifest file to load:
    try fs.unlinkSync manifest_path
    catch err then null
    return
  log 'houce: creating manifest'
  
  manifest_str = """
    CACHE MANIFEST
    # #{Date.now()}

    CACHE:
    index.html
    client_app.js
    templates.js
    stylesheets/stylesheets.css
    https://fonts.googleapis.com/css?family=PT+Sans:700
    https://themes.googleusercontent.com/static/fonts/ptsans/v3/0XxGQsSc1g4rdRdjJKZrNL3hpw3pgy2gAi-Ip7WPMi0.woff
  """
  read_folder = (path)->
    folder_contents = fs.readdirSync path
    for file_or_folder in folder_contents
      fof_path = "#{path}/#{file_or_folder}"
      fof_stat = fs.statSync fof_path
      if fof_stat.isDirectory()
        read_folder fof_path
      else
        fof_path = fof_path.remove "#{config.app_dir}public/"
        if ['jpg', 'png', 'gif', 'js'].has fof_path.split('.').last()
          manifest_str += "\n#{fof_path}"
  read_folder "#{config.app_dir}public/img"
  read_folder "#{config.app_dir}public/lib"
  manifest_str += "\n\nNETWORK:\n*"
    
  fs.writeFileSync manifest_path, manifest_str, 'utf8', (err)-> if err then throw err
  