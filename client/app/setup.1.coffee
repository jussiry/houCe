
# Setup.coffee includes: Config, Namespacing, Page controller setup,
# Object.extend and requestAnimationFrame init.

# 1 in setup.1.coffee means that this file will be first in client_app.js (after common_utils.coffee)

# The reason for putting everything in try-catch loopt (or usin Utils.try after it has been initialized)
# is mobile debugging, where you can't access the console of the device.
try

  #
  # Client config
  #
  global.Config =
    apis:
      fb:
        app_id: 278442548891895
        permissions: 'user_likes'
        auth_url: 'https://www.facebook.com/dialog/oauth'
        get_url: 'https://graph.facebook.com' # TODO: change get_url to url (same as Kovalo config)
      google:
        app_id: '679211380191.apps.googleusercontent.com'
        permissions: encodeURIComponent 'https://www.googleapis.com/auth/plus.me'
        auth_url: "https://accounts.google.com/o/oauth2/auth"
        get_url: 'https://www.googleapis.com/plus/v1' # TODO: change get_url to url (same as Kovalo config)
    api_url: '/api' #if widget? then 'https://dealium-staging.heroku.com/api' else '/api'
    is_mobile: navigator.userAgent.has /iPhone|Android|Nokia/
  
    # Define api_url to use Utils.api_get function
    api_url: null
    api_def_params: {}
    cache_data: localStorage?
    # If you use Facebook API, change this to your fb_app_id; otherwise you can remove it.
    is_mobile: navigator.userAgent.has /iPhone|Android|Nokia/
    # cache_update_after:
    #   coordinates: '10 minutes ago'
    #   deals_near:  '10 minutes ago'
    #   coupons:     '40 minutes ago'
    #page_titles:
    #  plaa: 'daa'

  # Config from server:
  merge Config, client_config_from_server

  # Test local storage:
  if Config.cache_data
    try
      # In iPhone S4 using localStorage fails when trying to store any data
      localStorage.setItem 'storage_test', 'works'
    catch err
      Config.cache_data = false


  #
  # Main modules:
  #

  # Namespace for models
  global.Models = {}
  # Namespace for page controllers
  global.Pages  = {}
  # Namespace for utility libraries
  global.Utils  = {}
  

  #
  # Namespacing to store all modules under single application object
  #

  global[Config.app_name] =
    Models: Models
    Pages:  Pages
    Utils:  Utils
    Config: Config
    Templates: Templates


  # Init PAGES from templates:
  # (Tempaltes[...].page -> Pages[...])
  for name, obj of Templates
    switch typeof obj.page
      when 'object'   then Pages[name] = obj.page 
      when 'function' then Pages[name] = obj.page()  


  #
  # If application is directed only for newer browsers that implement
  # Object.defineProperty you can use Object prototype functions for nicer syntaxt.
  # http://sugarjs.com/objects#object_extend
  #

  Object.extend() if Object.defineProperty?


  #
  # HTML5 backups:
  #

  # TODO: use some library instead?
  window.reqAnimFrame = window.requestAnimationFrame or
                        window.webkitRequestAnimationFrame or
                        window.mozRequestAnimationFrame or
                        window.oRequestAnimationFrame or
                        window.msRequestAnimationFrame or
                        (callback)-> window.setTimeout(callback, 1000 / 60)

catch err
  alert "Error in setup.coffee: #{err.message}"
