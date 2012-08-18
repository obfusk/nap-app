require 'haml'

# --

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

helpers do                                                      # {{{1
  def r (what, *more)
    to(R[what][*more])
  end

  def icon (s)
    case s
      when 'dead'   ; 'warning-sign'
      when 'stopped'; 'off'
      when 'running'; 'ok'
      else raise '...'                                          # TODO
    end
  end

  def naps
    # TODO: check return value etc.

    %x[ naps list ].split.map do |x|
      s, t  = %x[ nap status #{x} -s ].strip.split ' ', 2
      { name: x, stat: s, time: t, icon: icon(s) }
    end
  end

  def nap_info (x)
    # TODO
  end
end                                                             # }}}1

# --

R = {
  naps: ->()  { '/naps'     },
  app:  ->(x) { "/app/#{x}" },
}

# -- [routes] --                                                # {{{1

before do
  @layout_css = []
  @layout_js  = []

  @title = @naps = @info = nil
end

get '/' do
  redirect r(:naps)
end

get '/naps' do
  @title  = 'naps'
  @naps   = naps
  haml :naps
end

get %r[/app/([a-z_-]+)] do |app|
  @title  = "nap info #{app}"
  @info   = nap_info app
  haml :app
end

# --                                                            # }}}1
