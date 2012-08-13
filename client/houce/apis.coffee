

Houce.set_up_new_api = (args)->
  # TODO:
  # instead of adding stuff to Config, Data and api utils
  # use this function to populate API data (FB, google, etc.)
  # args: name, id, permissions, auth_url, get_url


Houce.oauth2 = do ->
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
    path = Pager.path() #get_path_form_page_and_params() #path.join '/'
    if Config.storage_on
      me.clean_ss() # remove bofore setting: iPhone / iPad bug?
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
      return false unless ss.auth_redirect
      path = ss.auth_path
      app  = ss.auth_app
    else # auth params strored in URL
      return false unless location.hash[0...5] is '#app='
      path = params.path
      app  = params.app
      delete params.path
      delete params.app
    
    
    api_data = Data.apis[app]
    merge api_data, params

    if api_data.expires_in? and api_data.expires_in isnt '0' # 0 is offline_access
      api_data.expires_in = Date.now() + api_data.expires_in.toNumber().seconds()
    
    # init redirect from session:
    me.clean_ss()
    
    unless api_data.access_token?
      alert "Failed to retrieve access_token!"
      Pager.main_page
    else
      #alert 'access_token received! '+path
      #location.hash = "!/#{path}"
      path
      
    
    
    

  disconnect: (app)->
    delete Data.apis[app].access_token
    delete Data.apis[app].expires_in
    

Houce.apis = do ->
  me =
  get: (app, what, callback, jsonp)->
    unless me.is_connected app
      Houce.oauth2.connect app
      return 
    log "apis GET started", app, what
    #$.support.cors = true
    url = "#{Config.apis[app].get_url}/#{what}?access_token=#{encodeURIComponent Data.apis[app].access_token}"
    # if XDomainRequest?
    #   alert 'XDomReg '+url
    #   xdr = new XDomainRequest
    #   xdr.open 'GET', url
    #   xdr.onload = ->
    #     alert 'req succesful!'
    #     alert ': '+xhr.responseText
    #     callback xhr.responseText
    #   xdr.onerror = ->
    #     alert 'req failed! '+xhr.responseText
    #   xdr.send()
      
    if jsonp
      $.ajax url, (dataType: 'jsonp', success: callback)
    else
      #alert 'get starts to '+url
      $.get url, callback
  fb_get:     (what, callback)->
    if Utils.device.browser isnt 'IE'
      Houce.apis.get 'fb',     what, callback
    else
      return Houce.oauth2.connect 'fb' unless me.is_connected 'fb'
      url = "/fb_proxy/#{what}?access_token=#{encodeURIComponent Data.apis.fb.access_token}"
      $.get url, callback
  google_get: (what, callback)-> Houce.apis.get 'google', what, callback, true
  
  is_connected: (app)->
    state = Data.apis[app]
    if app is 'kovalo'
      return state.connected and Houce.apis.is_connected 'fb'
    return state.access_token? and state.expires_in? and
           (state.expires_in > Date.now() or state.expires_in is '0')
