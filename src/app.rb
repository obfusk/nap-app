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

# require 'sinatra/json'
require 'haml'

require './cfg'

BRAND       = 'nap'
LAYOUT_CSS  = %w[ /css/bootstrap.css /css/layout.css ]
LAYOUT_JS   = %w[
  https://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js
]

NAPS_JS     = %w[ /js/naps.js ]

# --

if AUTH                                                         # {{{1
  use Rack::Auth::Basic, AUTH[:info] do |user, pass|
    user == AUTH[:user] && pass == AUTH[:pass]
  end
end                                                             # }}}1

# --

# NB: BE VERY CAREFUL WITH %x/sys !!!

helpers do
  def sys (x)                                                   # {{{1
    pid = fork do
      Process.setsid
      %x[ #{x} ]
    end
    Process.waitpid pid
    nil
  end                                                           # }}}1

  def r (what, *more)
    to(R[what][*more])
  end

  def icon (stat)                                               # {{{1
    case stat
      when 'dead'   ; 'warning-sign'
      when 'stopped'; 'off'
      when 'running'; 'ok'
    end
  end                                                           # }}}1

  def mod (app, stat)                                           # {{{1
    return unless MODIFY

    act, ing, icon = case stat
      when 'dead', 'stopped'; [:start, 'Starting', 'play']
      when 'running'        ; [:stop , 'Stopping', 'stop']
    end

    { link: r(act, app), icon: icon, act: ing }
  end                                                           # }}}1

  def naps                                                      # {{{1
    # TODO: check return value etc.

    %x[ naps list ].split.map do |app|
      s, t  = %x[ nap status #{app} -s ].strip.split ' ', 2
      { name: app, stat: s, time: t, icon: icon(s), mod: mod(app, s) }
    end
  end                                                           # }}}1

  def nap_info (app)
    # TODO
  end
end

# --

R = {
  naps:       ->()  { '/naps'       },
  app:        ->(x) { "/app/#{x}"   },
  start:      ->(x) { "/start/#{x}" },
  stop:       ->(x) { "/stop/#{x}"  },
  start_all:  ->()  { "/start-all"  },
  stop_all:   ->()  { "/stop-all"   },
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
  @layout_js  = NAPS_JS
  @title      = 'naps'
  @naps       = naps
  haml :naps
end                                                             # }}}1

# get %r[^/app/([a-z0-9_-]+)$] do |app|                         # {{{1
#   @title  = "nap info #{app}"
#   @info   = nap_info app
#   haml :app
# end                                                           # }}}1

if MODIFY
  post %r[^/start/([a-z0-9_-]+)$] do |app|
    sys "nap start #{app}"
  end

  post %r[^/stop/([a-z0-9_-]+)$] do |app|
    sys "nap stop #{app}"
  end

  post '/start-all' do
    sys 'naps sap'
  end

  post '/stop-all' do
    sys 'naps stop'
  end
end

# --

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
