
# PageHandler watches browsers URL's hash and changes the page when the hash changes.
#
# When page is changes:
#
# * old pages gets `close` event.
# * new page is initialized.
# * new page gets `open` event.

global.PageHandler = do ->
  
  hashbang = '#!/'

  # The paradigm favourided in houCe for making singleton objects is to execute function (do ->)
  # with private variables defined above and public vars defined below by
  # returnin a literal object.
  # Use 'me' inside public methods to refer to self and try to avoid using 'this' (or @).

  me =
  
  path:       [] # current path
  path_stack: []

  start_url_checking: ->
    # init hash checker
    if Modernizr.hashchange # TODO android 2.1 claims to have but don't work: http://caniuse.com/hashchange ?
      window.onhashchange = PageHandler.check_url_hash
      PageHandler.check_url_hash()
    else setInterval PageHandler.check_url_hash, 100

  get_page: -> Pages[me.path[0] or me.main_page]
  
  get_param: (num)->
    return alert "Incorrect param index! (1 is first)" if num < 1
    me.path[num]
  get_params: (num)->
    num ?= -1
    log "WARNING: not enough url parameters." if me.path.length < 1+num
    me.path[1..num]
  
  go_back: ->  
    me.open_page
      new_path: (me.path_stack.pop() or [me.main_page])
    return false
  
  # Gets executed evrytime window.locatio.hash changes.
  # TODO change to History API
  check_url_hash: ->
    # TODO: find out why @ becomes DOMWindow when called from setInterval
    # Works with 'new ->', but not with object literal?
    hash = window.location.hash # shorthands
    if hash[0..2] == hashbang
      new_path = hash[3..-1].split('/')
      # Check if hash path has changed
      unless Object.equal new_path, me.path
        prev_page = if me.path.isEmpty() then null else Pages[ me.path[0] ]
        # Change state
        me.path_stack.push me.path if me.path.first()?
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
      old_page = Pages[me.path[0]]
      me.path = args.new_path
      if old_page?.close? and not args.already_closed
        old_page.close me.open_page.bind me, new_path: args.new_path, already_closed: true
        return

      # check\_url\_hash will be fired but won't do anythign since state already mathches hash
      window.location.hash = hashbang + args.new_path.join '/'
  
    me.before_open_page()
    
    page_name = me.path[0]
    
    if Pages?[page_name]?
      log "UH: '#{page_name}' controller found"
      Pages[page_name].open()
    else
      log "UH: no page found!"
      $('#page_content').html "Page <strong>#{page_name}</strong> not found!"
    
    me.after_open_page()
      