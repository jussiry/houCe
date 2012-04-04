
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




# CONTROLLERS:


index_str  = null
read_index = -> index_str = (fs.readFileSync config.app_dir+"/public/index.html").toString()

if config.env is 'production'
  houce.build_client()
  houce.compile_index()
  read_index()
  

# Routes:

if config.env is 'production'
  app.get '*', (req,res,next)->
    # Cache control:
    res.header 'Cache-Control', "public, max-age=#{1.day()}"
  

# MAIN PAGE / APPLICATION LOAD:

send_index = (res)->
  if config.env is 'development'
    # in development mode, always rebuild client on load:
    houce.build_client res
    houce.compile_index()
    res.send read_index()
  else
    res.send index_str


app.get '/', (req,res)->
  send_index res

#### Not used currently
# Backup for storing auth app (fb or google) in the url if browser don't support localStorage
app.get '/auth/*', (req,res)->
  send_index res

