# --                                                            # {{{1
#
# File        : src/app.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2012-08-18
#
# Copyright   : Copyright (C) 2012  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            # }}}1

require 'haml'

require './cfg'

BRAND       = 'nap'
LAYOUT_CSS  = %w[ /css/bootstrap.css /css/layout.css ]
LAYOUT_JS   = %w[]

# --

if AUTH                                                         # {{{1
  use Rack::Auth::Basic, AUTH[:info] do |user, pass|
    user == AUTH[:user] && pass == AUTH[:pass]
  end
end                                                             # }}}1

# --

helpers do
  def r (what, *more)
    to(R[what][*more])
  end

  def icon (s)                                                  # {{{1
    case s
      when 'dead'   ; 'warning-sign'
      when 'stopped'; 'off'
      when 'running'; 'ok'
      else raise '...'                                          # TODO
    end
  end                                                           # }}}1

  def naps                                                      # {{{1
    # TODO: check return value etc.

    %x[ naps list ].split.map do |x|
      s, t  = %x[ nap status #{x} -s ].strip.split ' ', 2
      { name: x, stat: s, time: t, icon: icon(s) }
    end
  end                                                           # }}}1

  def nap_info (x)
    # TODO
  end
end

# --

R = {
  naps: ->()  { '/naps'     },
  app:  ->(x) { "/app/#{x}" },
}

# --

before do                                                       # {{{1
  @layout_css = []
  @layout_js  = []

  @title = @naps = @info = nil
end                                                             # }}}1

get '/' do
  redirect r(:naps)
end

get '/naps' do                                                  # {{{1
  @title  = 'naps'
  @naps   = naps
  haml :naps
end                                                             # }}}1

get %r[^/app/([a-z_-]+)$] do |app|                              # {{{1
  @title  = "nap info #{app}"
  @info   = nap_info app
  haml :app
end                                                             # }}}1

# --

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
