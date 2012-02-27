
# Utils related to API's of other services

Utils.FB =
  connect: ->
    l = window.location
    redirect_uri = "#{l.protocol}//#{l.host}/" # "#localocalhost:3003/#!/fb_login"
    redirect_uri += "?path=#{l.hash[3..-1]}" if l.hash.lenght > 3
    console.info 'FB redirect_uri', redirect_uri
    auth_url = "https://www.facebook.com/dialog/oauth?client_id=#{Config.fb_app_id}&redirect_uri=#{redirect_uri}&response_type=token"
    auth_url += "&scope=#{Config.fb_permissions}" if Config.fb_permissions
    location.href = auth_url
  access_token_received: ->
    # hash params (access_token end expires_in):
    fb_params = location.hash[1..-1].split '&'
    expires_in_sec = fb_params[1].split('=')[1].toNumber()
    Data.apis.merge
      fb_access_token: fb_params[0].split('=')[1]
      fb_expires: if expires_in_sec == 0 then 'never' else Date.create().addSeconds(expires_in_sec)
    # path param:
    path = decodeURIComponent( location.search.split('path=')[1] ? '' )
    location.hash = "#!/#{path}"
  get: (what, callback) =>
    Utils.FB.connect() unless Data.apis.fb_access_token?
    url = "https://graph.facebook.com/#{what}?access_token=#{Data.apis.fb_access_token}"
    $.get url, callback



Utils.get_geolocation = (recalculate=false, cb)->
  Utils.try 'get_geolocation', =>

    cb = recalculate if recalculate.constructor is Function

    coord = Data.state.coord
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
  s = Data.state
  if s.coord.latitude then merge params,
    latitude:  s.coord.latitude
    longitude: s.coord.longitude
  if s.connection.connected_to_api then merge params,
    fb_user_id:    Data.user.fb.id
    fb_auth_token: s.connection.fb_access_token
  params

