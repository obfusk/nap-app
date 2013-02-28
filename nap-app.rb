# --                                                            ; {{{1
#
# File        : nap-app.rb
# Maintainer  : Felix C. Stegerman <flx@obfusk.net>
# Date        : 2013-02-28
#
# Copyright   : Copyright (C) 2013  Felix C. Stegerman
# Licence     : GPLv2
#
# --                                                            ; }}}1

# NB: BE VERY CAREFUL WITH cmd/%x/exec/sys !!!
# NB: MAKE SURE TO PROPERLY VALIDATE ALL ROUTE PARAMETERS !!!

require 'coffee-script'
require 'haml'
require 'json'
require 'sinatra/base'

module Obfusk; module Nap; class App < Sinatra::Base

  NAPRC = [ENV['NAP_APP_RC'], ENV['HOME'] + '/.nap-app-rc']
            .reject { |x| x.nil? or x.empty? } .first
  load NAPRC

  if NAP_APP_AUTH
    use Rack::Auth::Basic, NAP_APP_AUTH[:info] do |user, pass|
      user == NAP_APP_AUTH[:user] && pass == NAP_APP_AUTH[:pass]
    end
  end

  # --

  CONFIG = {                                                    # {{{1
    hist:       5,
    tail:       20,

    brand:      'nap',
    brand_url:  'http://obfusk.github.com/nap/',

    layout_css: %w{
      /bootstrap-2.3.0/css/bootstrap.min.css
      /css/layout.css
    },

    layout_js: [],

    naps_js: %w{
      http://code.jquery.com/jquery-1.9.1.min.js
      /__coffee__/apps.js
    },
  }                                                             # }}}1

  LINES = ->(x) { x.lines.map(&:chomp) }

  COMMANDS = {                                                  # {{{1
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
  }                                                             # }}}1

  ROUTES = {                                                    # {{{1
    apps:   ->()                      { '/apps'               },
    app:    ->(x)                     { "/app/#{x}"           },
    hist:   ->(x, n=CONFIG[:hist])    { "/hist/#{x}/#{n}"     },
    log:    ->(x, l, n=CONFIG[:tail]) { "/log/#{x}/#{l}/#{n}" },
    start:  ->(x)                     { "/start/#{x}"         },
    stop:   ->(x)                     { "/stop/#{x}"          },
    st_all: ->()                      { "/start-all"          },
  }                                                             # }}}1

  # --

  def self.sys (x)                                              # {{{1
    pid = fork do
      Process.setsid  # will kill server otherwise
      exec x          # CAREFUL !!!
    end
    Process.waitpid pid
  end                                                           # }}}1

  def cmd (x, *args)                                            # {{{1
    args.all? { |x| x =~ %r[^([a-z0-9A-Z@.:/_-]+)$] } \
      or raise 'invalid argument'

    r = Bundler.with_clean_env { COMMANDS[x][*args] }
    $?.exitstatus == 0 or raise 'command returned non-zero'
    r
  end                                                           # }}}1

  # --

  def r (what, *more)
    to ROUTES[what][*more]
  end

  def page (view, locals = {})
    haml view, locals: locals
  end

  def activate (x)
    @active = x
  end

  def act (x)
    @active == x ? 'active' : ''
  end

  def layout_css (*xs)
    @layout_css += xs
  end

  def layout_js (*xs)
    @layout_js += xs
  end

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
    return unless NAP_APP_MODIFY

    act, ing, icon = case stat
      when 'dead', 'stopped'; [:start, 'Starting', 'play']
      when 'running'        ; [:stop , 'Stopping', 'stop']
    end

    { link: r(act, app), icon: icon, act: ing }
  end                                                           # }}}1

  # --

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

  def app_log (app, log, n)
    logs  = Hash[cmd(:log_as, app).map { |x| x.split ' ', 2 }]
    file  = logs[log] or raise 'log not found'
    cmd :log, file, n
  end

  # --

  get '/__coffee__/:name.js' do |name|
    content_type 'text/javascript'
    coffee :"coffee/#{name}"
  end

  before do
    @layout_css = CONFIG[:layout_css]
    @layout_js  = CONFIG[:layout_js]
  end

  # --

  get '/' do
    redirect r(:apps)
  end

  get '/apps' do                                                # {{{1
    ns = naps

    activate :apps
    layout_js *CONFIG[:naps_js] if NAP_APP_MODIFY && !ns.empty?

    page :apps,
      naps:   ns,
      dead:   ns.count { |x| x[:stat] == 'dead'    },
      stop:   ns.count { |x| x[:stat] == 'stopped' },
      title:  'apps'
  end                                                           # }}}1

  get %r[^/app/([a-z0-9_-]+)$] do |app|
    page :app, app: app_info(app), title: app
  end

  get %r[^/hist/([a-z0-9_-]+)/([0-9]+)$] do |app, n|
    page :hist,
      app:   { name: app, n: n },
      hist:  app_hist(app, n),
      title: "#{app} :: history"
  end

  get %r[^/log/([a-z0-9_-]+)/(@?[a-z0-9_-]+)/([0-9]+)$] \
  do |app, log, n|
    page :log,
      app:   { name: app, log: log, n: n },
      log:   app_log(app, log, n),
      title: "#{app} :: log :: #{log}"
  end

  # --

  if NAP_APP_MODIFY
    post %r[^/start/([a-z0-9_-]+)$] do |app|
      content_type :json
      cmd :start, app
      { cmd: :start, app: app }.to_json
    end

    post %r[^/stop/([a-z0-9_-]+)$] do |app|
      content_type :json
      cmd :stop, app
      { cmd: :stop, app: app }.to_json
    end

    post '/start-all' do
      content_type :json
      cmd :st_all
      { cmd: 'start-all' }.to_json
    end
  end

end; end; end

# vim: set tw=70 sw=2 sts=2 et fdm=marker :
