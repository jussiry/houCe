
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
    apis: null # Created in /server/config.coffee
    is_mobile: navigator.userAgent.has /iPhone|Android|Nokia/
    storage_on: true

  # Test local storage:
  try
    # In iphone/ipad private mode this will fail
    localStorage  .storage_test = 'works'
    sessionStorage.storage_test = 'works'
  catch err
    Config.storage_on = false

  # Config from server:
  merge Config, client_config_from_server

  
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
