

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
  log 'houce: creating manifest'
  
  manifest_str = "
      CACHE MANIFEST\n
      # #{Date.now()}\n
  "
  if config.env is 'production'
    manifest_str += "
      index.html\n
      client_app.js\n
      templates.js\n
      lib/*.js\n
      stylesheets/*.css\n
      img/*.*\n
      img/*/*.*
    "
  fs.writeFileSync config.app_dir+'/public/appcache.mf', manifest_str, 'utf8', (err)-> if err then throw err
  