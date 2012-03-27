
# Controller related requires:
{exec}       = require 'child_process'
fs           = require 'fs'
restler      = require 'restler'
houce        = require './houce'


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


# build_client = (callback)->
#   exec "cd #{config.app_dir} && cake 'build_client'", (err, stdout, stderr)->
#     log stdout
#     if err
      
#     else
#       index_str = (fs.readFileSync config.app_dir+"/public/index.html").toString()
#       callback?()

index_str  = null
read_index = -> index_str = (fs.readFileSync config.app_dir+"/public/index.html").toString()

if config.env is 'production'
  houce.build_client()
  read_index()
  


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
    houce.build_client res
    res.send read_index()
    #build_client (err)->
    #  res.send if err then err else index_str
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


