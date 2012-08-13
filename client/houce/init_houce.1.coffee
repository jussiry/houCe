

# If application is directed only for newer browsers that implement
# Object.defineProperty you can use Object prototype functions for nicer syntaxt.
# http://sugarjs.com/objects#object_extend

#Object.extend() if Object.defineProperty?


### Main modules: ###

# Namespace for houCe functions
global.Houce  = {}
# Namespace for models
global.Models = {}
# Namespace for utility libraries
global.Utils  = {}
# Namespace for configs
global.Config = {}


# Setup houCe. Called from setup.coffee

Houce.init_houce = (args)->
  global.Data ?= {}

  defaults =
    main_page: null
    before_open_page: ->
    after_open_page:  ->
    data_structure: {}
    data_version: 1
    Config:
      # TOOD: use insted Zepto or some other library for mobile stuff?
      is_mobile: navigator.userAgent.has /iPhone|Android|Nokia/
      storage_on: true
    init_app:  ->
    error_logging: false

  args = merge defaults, args

  Pager.main_page        = args.main_page
  Pager.before_open_page = args.before_open_page
  Pager.after_open_page  = args.after_open_page
  Houce.init_data.app_defaults = args.data_structure
  Houce.init_data.version      = args.data_version


  ### Error logging to server ###

  Houce.error.logging_on = args.error_logging
  if Utils.device.is_mobile() or Config.env is 'production'
    window.onerror = Houce.error

  #if Utils.devise.is_mobile() or Config.env is 'production'


  ### Config ###

  # Client config from setup.coffee
  merge Config, args.Config
  # Config from server:
  merge Config, client_config_from_server
  # ---Kapsa specific---
  # Merge host specific config to main config

  # if (host_conf = Config.by_host[location.host])?
  #   Object.merge Config, host_conf, true
  # else if (linked_host = Config.by_host.links[location.host])?
  #   Object.merge Config, Config.by_host[linked_host], true
  # else
  #   alert 'No config found for: '+location.host
  # delete Config.by_host
  # ---/Kapsa specific---

  # Test local storage:
  try
    # In iphone/ipad private mode this will fail
    localStorage  .storage_test = 'works'
    sessionStorage.storage_test = 'works'
  catch err then Config.storage_on = false


  ### Init templates ###
  Houce.init_templates()

  ### Namespacing to store all modules under single application object ###
  global[Config.app_name] =
    Config: Config
    Houce:  Houce
    Models: Models
    Utils:  Utils
    Templates: Templates

  ### Data setup ###
  Houce.init_data false #Config.flush_cache or false

  if Config.storage_on
    # Bind caching operations to store
    $(window).bind 'unload', Houce.cache_data
    # as backup for dirty closing, store cache in intervals:
    setInterval Houce.cache_data, 5.minutes()


  ### Init application ###

  # check if is auth redirect
  path = Houce.oauth2.check_for_access_token()
  # execute app specific init
  args.init_app()
  # start Pager
  Pager.start_url_checking path
