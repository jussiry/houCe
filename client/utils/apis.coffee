

Utils.set_up_new_api = (args)->
  # TODO:
  # instead of adding stuff to Config, Data and api utils
  # use this function to populate API data (FB, google, etc.)
  # args: name, id, permissions, auth_url, get_url


Utils.oauth2 = do ->
  ss = sessionStorage
  me =
  clean_ss: ->
    return unless Config.storage_on
    ss.removeItem.bind(ss).repeat \
      'auth_redirect',
      'auth_path',
      'auth_app'
  
  connect: (app)->
    l    = window.location
    path = location.hash.from 3
    if Config.storage_on
      me.clean_ss() # remove bofore setting: iPhone / iPad bug?
      Utils.try 'sessionStorage for authentication', ->
        ss.auth_redirect = true
        ss.auth_path = path
        ss.auth_app  = app
      redirect_uri = "#{l.protocol}//#{l.host}/" # "#localocalhost:3003/#!/fb_login"
    else
      # store path and app in redirect url
      redirect_uri = "#{l.protocol}//#{l.host}/#app=#{app}&path=#{path}"
    location.href = "#{Config.apis[app].auth_url}?response_type=token&client_id=#{Config.apis[app].app_id}&scope=#{Config.apis[app].permissions}&redirect_uri=#{encodeURIComponent redirect_uri}"
  
  check_for_access_token: ->
    params = {}
    for pa in (location.hash[1..-1].split('&').map (p)-> p.split '=')
      params[pa[0]] = pa[1]
    if Config.storage_on
      return unless ss.auth_redirect
      path = ss.auth_path
      app  = ss.auth_app
    else # auth params strored in URL
      return unless location.hash[0...5] is '#app='
      path = params.path
      app  = params.app
      delete params.path
      delete params.app
    
    console.info 'access_token_received'
    
    api_data = Data.apis[app]
    merge api_data, params
    
    if api_data.expires_in? and api_data.expires_in isnt '0' # 0 is offline_access
      api_data.expires_in = Date.now() + api_data.expires_in.toNumber().seconds()
    
    location.hash = "#!/#{path}"
    # init redirect from session:
    me.clean_ss()

  disconnect: (app)->
    delete Data.apis[app].access_token
    delete Data.apis[app].expires_in
    

Utils.apis = do ->
  me =
  get: (app, what, callback, jsonp)->
    unless me.is_connected app
      Utils.oauth2.connect app
      return 
    console.info "apis GET started", app, what
    url = "#{Config.apis[app].get_url}/#{what}?access_token=#{Data.apis[app].access_token}"
    if jsonp then $.ajax url, dataType: 'jsonp', success: callback \
             else $.get url, callback  
  fb_get:     (what, callback)-> Utils.apis.get 'fb',     what, callback
  google_get: (what, callback)-> Utils.apis.get 'google', what, callback, true
  is_connected: (app)->
    state = Data.apis[app]
    return true if state.connected
    return state.access_token? and state.expires_in? and
           (state.expires_in > Date.now() or state.expires_in is '0')



Utils.get_geolocation = (recalculate=false, cb)->
  Utils.try 'get_geolocation', =>

    cb = recalculate if recalculate.constructor is Function

    coord = Data.misc.coord
    if Utils.cache_valid 'coordinates' # coord.updated? and Date.now() - coord.updated < 20.minutes() and not recalculate
      cb coord
    else
      geo_success = (gp)->
        coord.latitude  = gp.coords.latitude
        coord.longitude = gp.coords.longitude
        Data.cache_updated.coordinates = Date.now()
        cb coord
      geo_failed = (err)->
        alert 'Failed to retrieve geolocation'
        cb null
      geo_args = timeout: Config.get_geo_timeout
      if navigator.geolocation?.getCurrentPosition?
        navigator.geolocation.getCurrentPosition geo_success, geo_failed, geo_args
      else
        geo_failed code: -1



### TODO: remove function below; update Kapsa api calls ###

# Define Config.api_url to use api_get and api_post functions

Utils.api_get = (path, params={}, cb=(->), post)->
  log "API started to: #{path}"
  if params.constructor is Function
    cb     = params
    params = Utils.def_ajax_params()
  else
    merge params, Utils.def_ajax_params()
  
  req = (if post then $.post else $.get) "#{Config.api_url}/#{path}", params, (res)->
    unless res.success
      err = message: "fetching #{path} (#{ifs post,'post','get'})" ,\
            stack:   res
      return Utils.fail "Utils.api_get", err 
    cb res

Utils.api_post = (path, params={}, cb)->
  Utils.api_get path, params, cb, true


Utils.def_ajax_params = ->
  params = merge {}, Config.api_def_params
  m = Data.misc
  if m.coord.latitude then merge params,
    latitude:  m.coord.latitude
    longitude: m.coord.longitude
  if m.connection.connected_to_api then merge params,
    fb_user_id:    Data.user.fb.id
    fb_auth_token: m.connection.fb_access_token
  params

