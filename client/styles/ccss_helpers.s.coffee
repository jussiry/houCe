
# These helper functions and variables are available to objects
# defined in templates (mainly for @style).
# TODO: store them also in Tempalates.helpers ?
# TODO: make these availabe for @html and @init? Would it slow down rendering?


# COLORS

@font_black = '#333'
@font_gray  = '#555'
@light_gray = '#aaa'



# EXTRA CLASSES

@secondary_font =
  fontFamily: 'Helvetica Neue, Helvetica'
  fontWeight: 'normal'


# FUNCTIONS

@per_padding = (vert_padding, hor_padding, width=100)->
  padding: "#{vert_padding}% #{hor_padding}%"
  width: width - 2*hor_padding + '%'

# Calculate percentage based layout with given margins and paddings
@per_layout = (args={})->
  args.margins  ?= [0,0]
  args.paddings ?= [0,0]
  args.height   ?= 100
  args.width    ?= 100

  margin:  args.margins .join('% ') + '%'
  padding: args.paddings.join('% ') + '%'
  height: args.height - 2*args.margins[0] - 2*args.paddings[0] + '%'
  width:  args.width  - 2*args.margins[1] - 2*args.paddings[1] + '%'


@border_radius = (str)->
  MozBorderRadius:    str
  WebkitBorderRadius: str
  borderRadius:       str

@box_shadow = (str)->
  MozBoxShadow:    str
  WebkitBoxShadow: str
  boxShadow:       str


# @vgradient (from, to)->
#   background: -webkit-gradient(linear, 0 0, 0 100%, from(@from), to(@to));
#   background: -moz-linear-gradient(90deg, @to, @from);


@transition = (str)->
  str = "all #{str} ease-out"
  WebkitTransition: str
  MozTransition:    str
  OTransition:      str
  MSTransition:     str
  transition:       str
