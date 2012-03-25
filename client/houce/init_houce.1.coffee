
# If application is directed only for newer browsers that implement
# Object.defineProperty you can use Object prototype functions for nicer syntaxt.
# http://sugarjs.com/objects#object_extend
Object.extend() if Object.defineProperty?


### Main modules: ###

# Namespace for houCe functions
global.Houce  = {}
# Namespace for models
global.Models = {}
# Namespace for page controllers
global.Pages  = {}
# Namespace for utility libraries
global.Utils  = {}



# Setup houCe. Called from setup.coffee

Houce.init_houce = (args)->

  global.Data ?= {}
  
  defaults =
    main_page: null
    before_open_page: ->
    after_open_page:  ->
    data_structure: {}
    data_version: 1
    config:
      # TOOD: use insted Zepto or some other library for mobile stuff?
      is_mobile: navigator.userAgent.has /iPhone|Android|Nokia/
      storage_on: true
    init_app:  ->
    error_logging: false

  args = merge defaults, args

  PageHandler.main_page        = args.main_page
  PageHandler.before_open_page = args.before_open_page
  PageHandler.after_open_page  = args.after_open_page
  Houce.init_data.defaults         = args.data_structure
  Houce.init_data.defaults.version = args.data_version


  ### Error logging to server ###
  # requires (Redis) data storage; currently not implemented on server

  if args.error_logging
    window.onerror = (a,b)->
      log "Error arguments", arguments
      console.info "----- Error in #{a} #{b} -----"
      
      Houce.render 'flash_notice', error:true, msg: dict 'error_notice'
        
      # Send to sever
      $.post '/err_logs',
        ua:        navigator.userAgent
        err_msg:   err.message
        err_stack: err.stack
        non_err_err:  JSON.stringify err
        err_title:    str
        timestamp:    Date.now()
        path_history: JSON.stringify PageHandler.path_history  


  ### Config ###

  # Config from server:
  global.Config = client_config_from_server
  # Client config from setup.coffee
  merge Config, args.config
  # Test local storage:
  try
    # In iphone/ipad private mode this will fail
    localStorage  .storage_test = 'works'
    sessionStorage.storage_test = 'works'
  catch err then Config.storage_on = false

  ### Init pages ###
  Houce.init_pages()  

  ### Namespacing to store all modules under single application object ###
  global[Config.app_name] =
    Config: Config
    Houce:  Houce
    Models: Models
    Pages:  Pages
    Utils:  Utils
    Templates: Templates


  ### Data setup ###

  Houce.init_data false
  
  if Config.storage_on
    # Dismiss cache if Data structure changed since last cache
    if Data.version is 'no_cache' or Data.version > localStorage.getItem 'DataVersion'
      Houce.init_data true
    else
      # Load from cache:
      data_str = localStorage.getItem 'Data'
      merge Data, Houce.objectify data_str if data_str?
    
    # Bind caching operations to store 
    $(window).bind 'unload', Houce.cache_data
    # as backup for dirty closing, store cache in intervals:
    setInterval Houce.cache_data, 5.minutes()


  ### Init application ###

  # check if is auth redirect
  Houce.oauth2.check_for_access_token()
  # execute app specific init
  args.init_app()
  # start PageHandler
  PageHandler.start_url_checking()
    