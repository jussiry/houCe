
doctype 5

html_attrs = if @env is 'production' then manifest:'appcache.mf' else {}

html html_attrs, ->

  head ->
    meta charset: 'utf-8'
    title ''
    link href:"/stylesheets/less_styles.css", media:"screen", rel:"stylesheet", type:"text/css"
    link href:"/stylesheets/ccss_styles.css", media:"screen", rel:"stylesheet", type:"text/css"

  body ->
    
    div '#header', ->
      # Insert content you want to show up on every page here
      a '.connect_status .fb     .offline', href:'#', 'Facebook'
      a '.connect_status .google .offline', href:'#', 'Google'
      span '.connect_status', "API's"
      a '#docs_link', href:'/docs', 'Documentation'
    div '#page_content', ''
    div '#overflows', ''
    
    div '#scripts', ->
      script ->
        #window.client_config_from_server = JSON.stringify @config
        "window.client_config_from_server = #{JSON.stringify @config};"
      srcs = [
        '/preload.js'
        '/lib/modernizr.custom.js'
        '/lib/jquery-1.7.1.min.js'
        '/lib/jquery.animate-enhanced.min.js'
        '/lib/sugar-1.2.1.min.js'
        '/lib/coffeekup.js'
        '/templates.js'
        '/client_app.js'
      ]
      for src in srcs
        script src:src, type:'text/javascript'
    