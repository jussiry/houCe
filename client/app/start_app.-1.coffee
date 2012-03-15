
# Starts the app by initializing PageHandler. Also handles initialization of Data.

# -1 in start_app.-1.coffee means that this file will be the last one in client_app.js

Utils.try 'start_app.coffee', =>  

  # Init app:
  delay start_app = ->
    
    data_setup()
    
    # check if is auth redirect:
    Utils.oauth2.check_for_access_token()
    
    # Set app title
    $('head title').text Config.app_name

    # init hash checker
    if Modernizr.hashchange # TODO android 2.1 claims to have but don't work: http://caniuse.com/hashchange ?
      window.onhashchange = PageHandler.check_url_hash
      PageHandler.check_url_hash()
    else setInterval PageHandler.check_url_hash, 100

  
  data_setup = ->
    Utils.init_data false
    return unless Config.storage_on
    
    # Dismiss cache if Data structure changed since last cache
    if Data.version is 'no_cache' or Data.version > localStorage.getItem 'DataVersion'
      Utils.init_data true
    else
      # Load from cache:
      data_str = localStorage.getItem 'Data'
      merge Data, Utils.objectify data_str if data_str?
    
    # Bind caching operations to store 
    $(window).bind 'unload', Utils.cache_data
    # as backup for dirty closing, store cache in intervals:
    setInterval Utils.cache_data, 5.minutes()
    