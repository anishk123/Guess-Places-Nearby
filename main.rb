class App < Sinatra::Base
  set :sessions, true

  get '/' do
    erb :index
  end
  
  get '/login' do
    @uuid = params[:uuid].to_s
    user = User.where(:uuid => @uuid).first
    if user.nil?
      puts "creating user"
      user = User.create(:uuid => @uuid, :score => 0) 
    end
    content_type :json
    {:user_id => user._id, :score => user.score}.to_json
  end
  
  get '/venues' do
    @lat = params[:lat].to_f
    @lng = params[:lng].to_f
    @user = User.find(params[:user_id])
    while @venue_groups.nil?
      @venue_groups = JSON.parse(open("https://api.foursquare.com/v2/venues/search.json?ll=#{@lat},#{@lng}&client_id=#{api_key}&client_secret=#{api_secret}").read)["response"]["groups"]
    end
    
    @venue = nil
    @venue_groups.each do |venue_group|
      venue_set = venue_group["items"]
      venue_set.each do |venue|
      existing_venue = Venue.where(:name => venue["name"], :location => {'$near' => [venue["location"]["lat"].to_f, venue["location"]["lng"].to_f] }).first
      if existing_venue.nil?
        new_venue = Venue.create(:name => venue["name"], :location => [venue["location"]["lat"].to_f, venue["location"]["lng"].to_f], :address => venue["location"]["address"], :city => venue["location"]["city"], :cross_street => venue["location"]["crossStreet"])
        new_venue.categories = []
        venue["categories"].each do |category|
          new_venue.categories += [category["name"]]     
        end
        new_venue.save!
        @venue = new_venue
      else
        @venue = existing_venue if @user.venues.length <= 0
        puts @user.venues.inspect
        puts existing_venue.inspect
        @venue = existing_venue if !@user.venues.include?(existing_venue) && @user.venues.length > 0
      end
      break if !@venue.nil?
      end
    end
    erb :venues
  end
  
  post '/venues' do
    @answer = params[:answer]    
    @venue = Venue.find(params[:venue_id])
    @user = User.find(params[:user_id])
    @user.venues << @venue
    
    @user.score = 0 if @user.score.nil?
    if @answer.to_s.downcase == @venue.name.to_s.downcase
      @user.score += 100
      score_result = "CONGRATS, you are correct, You earned 100 points, Your total Score is #{@user.score}"  
    else
      score_result = "Sorry, that is incorrect. The name of the place is #{@venue.name}. You total Score remains at #{@user.score}"    
    end
    @user.save!
    
    content_type :json
    {:score_result => score_result}.to_json
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
    api_key    = ENV['API_KEY'] || api_key
    api_secret = ENV['API_SECRET'] || api_secret
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