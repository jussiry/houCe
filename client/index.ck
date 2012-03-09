
doctype 5

html ->

  head ->
    meta charset: 'utf-8'
    title ''
    meta name:'HandheldFriendly', content:'True'
    meta name:'apple-mobile-web-app-capable', content:'yes'
    meta name:'HandheldFriendly', content:'True'
    meta name:'HandheldFriendly', content:'True'
    link href:"/stylesheets/stylesheets.css", media:"screen", rel:"stylesheet", type:"text/css"

  body ->
    
    div '#header', ''
    div '#page_content', ''
    div '#overflows', ''
    
    div '#scripts', ->
      script ->
        '##client_config_from_server##'
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
    