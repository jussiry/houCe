
# Page handler watche browsers URL hash and changes the page when the URL changes.
#
# When page is changes:
#
# * old pages gets `close` event.
# * new page is initialized.
# * new page gets `open` event.

global.PageHandler = do ->
  
  hashbang = '#!/'
  main_page = 'main'
  

  # The paradigm favourided in houCe for making singleton objects is to execute function (do ->)
  # with private variables defined above and public vars defined below by
  # returnin a literal object.
  # Use 'me' inside public methods to refer to self and try to avoid using 'this' (or @).

  me =
  
  get_page: -> Data.state.path[0] or main_page
  
  get_param: (num)->
    return alert "Incorrect param index! (1 == first)" if num < 1
    Data.state.path[num]
  get_params: (num)->
    num ?= -1
    log "WARNING: not enough url parameters." if Data.state.path.length < 1+num
    Data.state.path[1..num]
  

  # Gets executed evrytime window.locatio.hash changes.
  # TODO change to History API
  check_url_hash: ->
    Utils.try 'check_url_hash', =>
      # TODO: find out why @ becomes DOMWindow when called from setInterval
      # Works with 'new ->', but not with object literal?
      hash = window.location.hash # shorthands
      s    = Data.state
      if hash[0..2] == hashbang
        new_path = hash[3..-1].split('/')
        # Check if hash path has changed
        unless Object.equal new_path, s.path
          prev_page = if s.path.isEmpty() then null else Pages[ me.get_page() ]
          # Change state
          s.path = new_path
          # Close page event or directly open new page:
          if prev_page?.close?
            cb = me.open_page.bind me
            prev_page.close cb
          else
            me.open_page()
      else
        # url has no hasbang, set it and direct to main page:
        window.location.hash = hashbang + main_page

  open_page: (args)->
    Utils.try 'UH: open_page', =>
      
      # close old page if event exists:
      if args?.new_path
        # close event for old page not yet fired; do it here if exists
        old_page = Pages[Data.state.path?[0]]
        Data.state.path = args.new_path
        if old_page?.close? and not args.already_closed
          old_page.close me.open_page.bind me, new_path: args.new_path, already_closed: true
          return

        # check\_url\_hash will be fired but won't do anythign since state already mathches hash
        window.location.hash = hashbang + args.new_path.join '/'
    
      me.init_page()
      
      page_name = me.get_page()
      
      if Pages?[page_name]?
        Utils.try 'UH: open controller', =>
          log "UH: '#{page_name}' controller found"
          Pages[page_name].open()
      else
        log "UH: no page found!"
        $('#page_content').html "Page <strong>#{page_name}</strong> not found!"
      
      # Fade in page content after it has been rendered
      reqAnimFrame -> $('#page_content').animate opacity: 1
  
  init_page: ->
    Utils.try 'init_page', =>
      pc = $('#page_content')
      pc.css
        opacity: 0
        left: 0
      pc.attr class: @get_page()
      $('body').scrollTop 0
      