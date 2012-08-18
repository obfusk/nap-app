require 'sinatra'

# AUTH_USER = '...'
# AUTH_PASS = '...'
# AUTH_INFO = '...'

# use Rack::Auth::Basic, AUTH_INFO do |user, pass|
#   user == USER && pass == PASS
# end

# --

get '/' do
  erb :status
end

# --
