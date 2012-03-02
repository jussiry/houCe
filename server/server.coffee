
# SERVER SETUP:

express = require 'express'


app = express.createServer() # server_options


app.configure ->
  app.use express.logger format: ':method :url'
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session
            key:    "#{config.app_name}.sid"
            secret: 'dfSDFdflkj43kl54j35klj3lGrefjgq' #some_secret
            httpOnly: false
            cookie: { maxAge: 10 * 24*60*60*1000 } # 10 days
  app.use app.router
  app.use express.static config.app_dir + '/public'
  app.use express.errorHandler
            dumpExceptions: true
            showStack: true


console.info "-- Starting application in port #{config.port} --"
app.listen config.port

module.exports = app




#
# CONTROLLERS:
#


{exec}       = require 'child_process'
fs           = require 'fs'
restler      = require 'restler'


index_str = null

build_client = (callback)->
  index_file = fs.readFileSync config.app_dir+"/public/index.html"
  index_str = index_file.toString().replace '##client_config_from_server##', "
    window.client_config_from_server = {
      app_name: '#{config.app_name}',
      env: '#{config.env}'
    };
  "
  exec "cd #{config.app_dir} && cake 'build_client'", (err, stdout, stderr)->
    log stdout
    if err
      err_msg = (stdout + stderr).replace /\n/g, "<br/>"
      style = "<style>body{
        padding: 1em 2em;
        font-family: Verdana;
        font-size: 0.8em;
        line-height: 1.4em;
        color: #333;
      }</style>"
      callback? style+err_msg
    else callback?()



build_client() if config.env is 'production'


# Routes:

if config.env is 'production'
  app.get '*', (req,res,next)->
    # Cache control:
    res.header 'Cache-Control', "public, max-age=#{1.day()}"
    # Heroku way of redirecting to from http to https:
    # if req.headers['x-forwarded-proto'] isnt 'https'
    #   res.redirect "https://#{req.headers['host']}#{req.url}" # TODO: change or better check when in m.getkapsa.com
    # else
    #   next() # Continue to other routes if we're not redirecting

  

# MAIN PAGE / APPLICATION LOAD:

send_index = (res)->
  if config.env is 'development'
    # in development mode, always rebuild client on load:
    log "app get",index_str
    build_client (err)->
      res.send if err then err else index_str
  else
    res.send index_str


app.get '/', (req,res)->
  send_index res

#### Not used currently
# Backup for storing auth app (fb or google) in the url if browser don't support localStorage
app.get '/auth/*', (req,res)->
  send_index res




# # TEMPLATE FOR API PROXY

# # API GET
# app.get '/api/*', (req,res)->
#   console.info "starting api get to: #{req.url}"

#   restler.get( "#{config.api_url}#{req.url}" )
#     .on 'complete', (data)->
#       res.send data
#     .on 'error', (err)->
#       log "-----ERROR-----"
#       log err

# # API POST
# app.post '/api/*', (req,res)->
#   console.info "atarting api post to: #{req.url} with params:"
#   console.info req.body
  
#   options = data: req.body #, log: true
  
#   restler.post( "#{config.api_url}#{req.url}", options )
#     .on 'complete', (data)->
#       res.send data
#     .on 'error', (err)->
#       log "-----ERROR-----"
#       log err


