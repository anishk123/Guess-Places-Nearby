class App < Sinatra::Base
  set :sessions, true

  get '/' do
    erb :index
  end
  
# Authentication

  get '/auth/foursquare' do
    redirect(client.web_server.
             authorize_url(:redirect_uri => redirect_uri, :scope => 'read-write'))
  end

  get '/auth/foursquare/callback' do
    begin
      response = client.
        web_server.
        get_access_token(params[:code], :redirect_uri => redirect_uri)
      session[:access_token] = response.token
      session[:refresh_token] = response.refresh_token

      if session[:access_token]
        redirect '/'
      else
        "Error retrieving access token."
      end
    rescue OAuth2::HTTPError => e
      e.response.body
    end
  end

  get '/auth/foursquare/refresh' do
    if session[:refresh_token]
      # This doesn't work. Patch oauth2?
      response = client.
        web_server.
        get_access_token(nil, :refresh_token => session[:refresh_token], :type => 'refresh_token')
      session[:access_token] = response.token
      session[:refresh_token] = response.refresh_token
      puts response.refresh_token
    else
      redirect '/auth/foursquare'
    end
  end

  error OAuth2::HTTPError do
    reset
  end
  
  error OAuth2::AccessDenied do
    reset
  end

protected

  def client
    api_key    = ENV['API_KEY'] || 'H1IC5ABMAEYEROFEBOK3KUVYE3OK35OQY0OJKE10CAEOZ3GX'
    api_secret = ENV['API_SECRET'] || 'IJYABNWLT22ZAUWBVK0UGHTXVSKCPH4E53U5MZQBQKQPDPWL'
    oauth_site = ENV['OAUTH_SITE'] || 'https://foursquare.com'
    options = {
      :site => ENV['SITE'] || 'https://api.foursquare.com',
      :authorize_url => oauth_site.dup << '/api/oauth2/authenticate',
      :access_token_url => oauth_site.dup << '/api/oauth2/access_token'
    }
    OAuth2::Client.new(api_key, api_secret, options)
  end
  
  def connection
    OAuth2::AccessToken.new(client, session[:access_token], session[:refresh_token])
  end

  def headers
    {'Accept' => 'application/json'}
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = '/auth/foursquare/callback'
    uri.query = nil
    uri.to_s
  end

  # An error from Gowalla most likely means our token is bad. Delete it
  # and re-authorize.
  def reset
    session.delete(:access_token)
    session.delete(:refresh_token)
    redirect('/auth/foursquare')
  end
end