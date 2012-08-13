
houce        = require './houce'


# SERVER SETUP:

express = require 'express'
connect = require 'connect'

# require index.ck just to make server restart on dev mode when it's modified
try require './index.ck'
catch err
  'this will always throw error, do nhtn'

app = express.createServer() # express.logger() # server_options

app.configure ->
  app.use express.logger format: ':method :url'
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session
            key:    "#{config.app_name}.sid"
            secret: 'weoijr897423JFKHDS344KJH4545kbdfkjsdfkjbKJBjjbjb' #some_secret
            httpOnly: false
            cookie: { maxAge: 10 * 24*60*60*1000 } # 10 days
  app.use app.router
  app.use connect.compress()
  app.use express.static config.app_dir + '/public'
  app.use express.errorHandler
            dumpExceptions: true
            showStack: true


log "-- Starting application in port #{config.port} --"
app.listen config.port

# init server:
houce.build_client()
#houce.minify_js()
houce.compile_indexes()
log 'Client built!'




# CONTROLLERS:

# Controller related requires:
{exec}       = require 'child_process'
fs           = require 'fs'
restler      = require 'restler'


get_host_config = (req)->
  host = req.headers.host
  conf = if (cbh=config.by_host)[host]? then cbh[host] \
                                        else cbh[cbh.links[host]]
  return conf if conf?
  req.res.send "The URL you are using to access Kapsa is not allowed!"



app.get '/', (req,res)->

  return unless (host_conf = get_host_config req)?

  index_str = (fs.readFileSync "#{config.app_dir}public/index/#{req.headers.host}.html").toString()

  if host_conf.env is 'development'
    # in development mode, always rebuild client on load:
    log 'ABOUT TO REBUILD CLIENT'
    houce.build_client res
    res.send index_str
  else
    res.send index_str


