# --                                                            # {{{1
#
# File        : src/app.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2012-08-31
#
# Copyright   : Copyright (C) 2012  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            # }}}1

# NB: BE VERY CAREFUL WITH cmd/%x/exec/sys !!!
# NB: MAKE SURE TO PROPERLY VALIDATE ALL ROUTE PARAMETERS !!!

# --

require 'haml'

# --

NAPRC       = [ENV['NAP_APP_RC'], ENV['HOME'] + '/.nap-app-rc']
              .reject { |x| x.nil? or x.empty? } .first
load NAPRC

# --

HIST        = 5
TAIL        = 10

# --

BRAND       = 'nap'
BRAND_URL   = 'http://obfusk.github.com/nap/'

LAYOUT_CSS  = %w[ /css/bootstrap.css /css/layout.css ]
LAYOUT_JS   = []

NAPS_JS     = %w[
  https://ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js
  /js/apps.js
]

# --

if AUTH                                                         # {{{1
  use Rack::Auth::Basic, AUTH[:info] do |user, pass|
    user == AUTH[:user] && pass == AUTH[:pass]
  end
end                                                             # }}}1

# --

LINES = ->(x) { x.lines.map(&:chomp) }

COMMANDS = {                                                    # {{{1
  list:   ->()      { %x[ naps list ].split                       },
  stat:   ->(x)     { %x[ nap status #{x} -s ].strip.split ' ', 2 },
  info:   ->(x)     { LINES[%x[ nap info #{x} -q ]]               },
  hist:   ->(x, n)  { LINES[%x[ nap log #{x} hist #{n} -v ]]      },
  logs:   ->(x)     { %x[ nap log #{x} list ].split               },
  log_as: ->(x)     { LINES[%x[ nap log #{x} assoc ]]             },
  log:    ->(l, n)  { LINES[%x[ tail -n #{n} -- #{l} ]]           },
  start:  ->(x)     { sys "nap start #{x}"                        },
  stop:   ->(x)     { %x[ nap stop #{x} ]                         },
  st_all: ->()      { sys 'naps pstart'                           },
}                                                               # }}}1

helpers do

  def r (what, *more) to ROUTES[what][*more] end

  def cmd (x, *args)                                            # {{{1
    args.all? { |x| x =~ %r[^([a-z0-9A-Z@.:/_-]+)$] } \
      or raise 'invalid argument'

    r = COMMANDS[x][*args]
    $?.exitstatus == 0 or raise 'command returned non-zero'
    r
  end                                                           # }}}1

  def sys (x)                                                   # {{{1
    pid = fork do
      Process.setsid  # will kill server otherwise
      exec x          # CAREFUL !!!
    end
    Process.waitpid pid
  end                                                           # }}}1

  def act (x) @active == x ? 'active' : '' end

  def icon (stat)                                               # {{{1
    case stat
      when 'dead'   ; 'exclamation-sign'
      when 'stopped'; 'off'
      when 'running'; 'ok'
    end
  end                                                           # }}}1

  def label (stat)                                              # {{{1
    case stat
      when 'dead'   ; 'label-important'
      when 'stopped'; 'label-info'
      when 'running'; 'label-success'
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
    cmd(:list).map do |app|
      s, t = cmd(:stat, app)
      { name: app, stat: s, time: t, icon: icon(s), mod: mod(app, s),
        lbl: label(s) }
    end
  end                                                           # }}}1

  def app_info (app)                                            # {{{1
    s, t  = cmd :stat, app
    info  = cmd(:info, app).map { |x| x.split (/\s*: /), 2 }
    logs  = cmd :logs, app

    { name: app, stat: s, time: t, icon: icon(s), lbl: label(s),
      info: info, logs: logs }
  end                                                           # }}}1

  def app_hist (app, n)
    h = cmd :hist, app, n
    { cmd: h[0], lines: h[1..-1] }
  end

  def app_log (app, log, n)                                     # {{{1
    logs  = Hash[cmd(:log_as, app).map { |x| x.split ' ', 2 }]
    file  = logs[log] or raise 'log not found'
    cmd :log, file, n
  end                                                           # }}}1

end

# --

ROUTES = {                                                      # {{{1
  apps:   ->()              { '/apps'               },
  app:    ->(x)             { "/app/#{x}"           },
  hist:   ->(x, n=HIST)     { "/hist/#{x}/#{n}"     },
  log:    ->(x, l, n=TAIL)  { "/log/#{x}/#{l}/#{n}" },
  start:  ->(x)             { "/start/#{x}"         },
  stop:   ->(x)             { "/stop/#{x}"          },
  st_all: ->()              { "/start-all"          },
}                                                               # }}}1

# --

before do
  @layout_css = @layout_js  = []
  @active                   = nil
end

get '/' do redirect r(:apps) end

get '/apps' do                                                  # {{{1
  @naps       = naps
  @dead       = @naps.count { |x| x[:stat] == 'dead'    }
  @stop       = @naps.count { |x| x[:stat] == 'stopped' }

  @layout_js  = NAPS_JS if MODIFY and not @naps.empty?
  @active     = :apps
  @title      = 'apps'

  haml :apps
end                                                             # }}}1

get %r[^/app/([a-z0-9_-]+)$] do |app|                           # {{{1
  @app    = app_info app
  @title  = app

  haml :app
end                                                             # }}}1

get %r[^/hist/([a-z0-9_-]+)/([0-9]+)$] do |app, n|              # {{{1
  @app    = { name: app, n: n }
  @hist   = app_hist app, n
  @title  = "#{app} :: history"

  haml :hist
end                                                             # }}}1

get %r[^/log/([a-z0-9_-]+)/(@?[a-z0-9_-]+)/([0-9]+)$] do        # {{{1
|app, log, n|
  @app    = { name: app, log: log, n: n }
  @log    = app_log app, log, n
  @title  = "#{app} :: log :: #{log}"

  haml :log
end                                                             # }}}1

if MODIFY
  post %r[^/start/([a-z0-9_-]+)$]   do |app|  cmd :start, app end
  post %r[^/stop/([a-z0-9_-]+)$]    do |app|  cmd :stop , app end
  post '/start-all'                 do        cmd :st_all     end
end

# --

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
