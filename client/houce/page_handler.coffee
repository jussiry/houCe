
# PageHandler watches browsers URL's hash and changes the page when the hash changes.
#
# When page is changes:
#
# * old page template gets `close` event.
# * new page template is initialized.
# * new page template gets `open` event.

global.PageHandler = do ->
  
  hashbang = '#!/'

  # The paradigm favourided in houCe for making singleton objects is to execute function (do ->)
  # with private variables defined above and public vars defined below by
  # returning a literal object.
  # Use 'me' inside public methods to refer to self and try to avoid using 'this' (or @).
  me =
  
  path:         [] # current path
  path_stack:   []
  path_history: [] # for error logs

  start_url_checking: ->
    # init hash checker
    if Modernizr.hashchange # TODO android 2.1 claims to have but don't work: http://caniuse.com/hashchange ?
      window.onhashchange = PageHandler.check_url_hash
      PageHandler.check_url_hash()
    else setInterval PageHandler.check_url_hash, 100

  get_page: -> Templates[me.path[0] or me.main_page]
  
  get_param: (num)->
    return alert "Incorrect param index! (1 is first)" if num < 1
    if me.path[num].parsesToNumber() then me.path[num].toNumber() \
                                     else me.path[num]
  get_params: (num)->
    num ?= -1
    log "WARNING: not enough url parameters." if me.path.length < 1+num
    me.path[1..num].map (param)->
      if param.parsesToNumber() then param.toNumber() \
                                else param
  
  go_back: (default_prev)->
    if me.path_stack.length > 0
      me.back_path = me.path_stack.pop() or []
      history.back()
    else
      me.open_page new_path: default_prev or [me.main_page]
    return false
  
  # Gets executed evrytime window.locatio.hash changes.
  check_url_hash: ()->
    hash = window.location.hash # shorthands
    if hash[0..2] == hashbang
      new_path = hash[3..-1].split('/')
      return me.go_back() if equal me.path_stack.last(), new_path
      # Check if hash path has changed
      unless Object.equal new_path, me.path
        prev_page = if me.path.isEmpty() then null else Templates[ me.path[0] ]
        if me.back_path?
          # back button pressed: dont push to stack and make sure url hash matches wanted page
          if me.back_path.length
            new_path = me.back_path
            window.location.hash = hashbang + new_path.join('/')
          me.back_path = null  # then me.going_back = false
        else if me.path.first()? and me.path.first() isnt new_path.first()
          # push to stack only when page (first part of path) changes - not just params
          me.path_stack.push me.path 
        me.path = new_path
        # Close page event or directly open new page:
        if prev_page?.close?
          cb = me.open_page.bind me
          prev_page.close cb
        else
          me.open_page()
    else
      # url has no hasbang, set it and direct to main page:
      window.location.hash = hashbang + me.main_page

  open_page: (args)->
    # close old page if event exists:
    if args?.new_path
      # close event for old page not yet fired; do it here if exists
      old_page = Templates[me.path[0]]
      me.path = args.new_path
      if old_page?.close? and not args.already_closed
        old_page.close me.open_page.bind me, new_path: args.new_path, already_closed: true
        return
      # check\_url\_hash will be fired but won't do anythign since state already mathches hash
      window.location.hash = hashbang + args.new_path.join '/'
  
    me.path_history.push me.path

    me.before_open_page()
    
    page_name = me.get_page().name
    templ = Templates[page_name]
    open_start    = Date.now()
    open_rendered = Houce.render.counter
    if templ?
      log "PageHandler: #{page_name}.templ found"
      if templ.open?
        templ.open.apply templ, me.get_params()
      else
        pc = $('#page_content')
        if pc.is_in_dom() then pc.render page_name \
                          else log "PageHandler ERROR: #{page_name}.templ has no @open defined!"
    else
      log "PageHandler: there is no such template: #{page_name}.templ"
      $('#page_content').html "Template <strong>#{page_name}.templ</strong> not found!"
    log "PageHandler: #{page_name}: #{Date.now()-open_start}ms for rendering #{Houce.render.counter-open_rendered} template(s)."
    me.after_open_page()
      