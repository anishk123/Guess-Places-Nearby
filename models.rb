#dbh04.mongolab.com:27047/guess_places_nearby -u <username> -p <password>
mongo_host = 'dbh04.mongolab.com'
mongo_db = 'guess_places_nearby'
mongo_port = '27047'
mongo_user = 'root'
mongo_password = 'dino1967'
MongoMapper.connection = Mongo::Connection.new(mongo_host, mongo_port)
MongoMapper.database = mongo_db
MongoMapper.database.authenticate(mongo_user, mongo_password)

class User
  include MongoMapper::Document
  key :uuid, String
  key :username, String
  key :password, String
  key :score, Integer
  key :venue_ids, Array
  many :venues, :in => :venue_ids
end

class Venue
  include MongoMapper::Document
  key :name, String
  key :categories, Array
  key :address, String
  key :cross_street, String
  key :city, String
  key :location, Array
  ensure_index [[:location, '2d']]
  many :users, :class_name => "User", :foreign_key => :venue_ids
end
