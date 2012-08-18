require 'sinatra'
require 'haml'

# --

ENV['PATH']   = "#{ENV['HOME']}/tmp/__nap/nap/bin:#{ENV['PATH']}"
ENV['NAPRC']  = "#{ENV['HOME']}/tmp/__nap/cfg/naprc"

# --

# AUTH_USER = '...'
# AUTH_PASS = '...'
# AUTH_INFO = '...'

# use Rack::Auth::Basic, AUTH_INFO do |user, pass|
#   user == USER && pass == PASS
# end

# --

BRAND       = 'naps'
ROUTE       = {}

LAYOUT_CSS  = %w[ css/bootstrap.css ]
LAYOUT_JS   = %w[]

# --

helpers do
  def naps
    %x[ naps list ].split.map do |x|
      { name: x, stat: %x[ nap status #{x} -s ], colour: '...' }
    end
  end
end

# --

get '/' do
  @title  = 'nap status'
  @naps   = naps
  haml :status
end

# --
