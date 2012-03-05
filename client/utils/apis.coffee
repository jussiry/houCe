

Utils.set_up_new_api = (args)->
  # TODO:
  # instead of adding stuff to Config, Data and api utils
  # use this function to populate API data (FB, google, etc.)
  # args: name, id, permissions, auth_url, get_url


Utils.oauth2 =
  connect: (app)->
    Utils.try 'sessionStorage for authentication', ->
      s = sessionStorage
      s.auth_redirect = true
      s.auth_path = location.hash.from 3
      s.auth_app  = app
    l = window.location
    redirect_uri = "#{l.protocol}//#{l.host}/" # "#localocalhost:3003/#!/fb_login"
    log "oauth2 connect url: "+"#{Config.apis[app].auth_url}?response_type=token&client_id=#{Config.apis[app].app_id}&scope=#{Config.apis[app].permissions}&redirect_uri=#{redirect_uri}"
    location.href = "#{Config.apis[app].auth_url}?response_type=token&client_id=#{Config.apis[app].app_id}&scope=#{Config.apis[app].permissions}&redirect_uri=#{redirect_uri}"

  access_token_received: ->
    s = sessionStorage
    api_data = Data.apis[s.auth_app]
    # Set access_token and expires in params received in the URL:
    res_params = location.hash[1..-1].split('&')
    for param_and_val in res_params
      [param, val] = param_and_val.split '='
      api_data[param] = val
    if api_data.expires_in?
      api_data.expires_in = Date.now() + api_data.expires_in.toNumber().seconds()
    
    location.hash = "#!/#{s.auth_path}"
    # init redirect from session:
    s.removeItem.bind(s).repeat \
      'auth_redirect',
      'auth_path',
      'auth_app'


Utils.apis =
  get: (app, what, callback, jsonp)->
    Utils.oauth2.connect app unless Data.apis[app].access_token?
    console.info "apis GET started"
    url = "#{Config.apis[app].get_url}/#{what}?access_token=#{Data.apis[app].access_token}"
    if jsonp then $.ajax url, dataType: 'jsonp', success: callback \
             else $.get url, callback  
  fb_get:     (what, callback)-> Utils.apis.get 'fb',     what, callback
  google_get: (what, callback)-> Utils.apis.get 'google', what, callback, true
    



#### Twitter does not support OAuth 2 (client side authorization)
# Utils.TW =
#   get: (what, callback)->
#     return alert 'twitter access toke required' unless Data.apis.tw_access_token?
#     url = "https://graph.facebook.com/#{what}?access_token=#{Data.apis.fb_access_token}"
#     $.get url, callback


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

