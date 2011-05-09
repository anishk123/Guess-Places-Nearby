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
  key :name, String
  key :type, String
  key :herbs, Integer
  key :materials, Integer
  key :ramen, Integer
  key :upkeep, Integer
  key :max_herbs, Integer
  key :max_materials, Integer
  key :max_ramen, Integer
  key :max_upkeep, Integer
  key :herbs_output, Integer
  key :materials_output, Integer
  key :ramen_output, Integer
  key :upkeep_output, Integer
  key :renewal_time, Time
  key :gold, Integer
  key :heat, Integer
  many :headquarters
end

class Headquarter
  include MongoMapper::Document
  key :name, String
  key :current, Boolean
  many :rooms
  many :clans
  many :staff
  many :incoming_attacks
  many :outgoing_attacks
  many :defended, :class_name => "AttackHistory", :foreign_key => :defender_id
  many :attacked, :class_name => "AttackHistory", :foreign_key => :attacker_id
  belongs_to :user
  belongs_to :spot
end

class Spot
  include MongoMapper::Document
  key :bases, Integer
  key :name, String
  key :url, String
  key :image_url, String
  key :owner, String
  key :category, String
  key :location, Array
ensure_index [[:location, '2d']]
  many :headquarters
end

class IncomingAttack
  include MongoMapper::EmbeddedDocument
  key :attacker_id, ObjectId
  one :attacker, :in => :attacker_id, :class_name => "Headquarter"
  key :attack_time, Time
  key :type, String
  many :attackers
end

class OutgoingAttack
  include MongoMapper::EmbeddedDocument
  key :defender_id, ObjectId
  one :defender, :in => :defender_id, :class_name => "Headquarter"
  key :attack_time, Time
  key :type, String 
  many :attackers
end

class AttackHistory
  include MongoMapper::Document
  key :attacker_id, ObjectId
  one :attacker, :in => :attacker_id, :class_name => "Headquarter"
  key :defender_id, ObjectId
  one :defender, :in => :defender_id, :class_name => "Headquarter"
  key :attack_time, Time
  key :herbs, Integer
  key :materials, Integer
  key :ramen, Integer
  many :attackers
  many :defenders
end

class Attacker
  include MongoMapper::EmbeddedDocument
key :name, String
  key :attack, Integer
  key :defence, Integer
  key :speed, Integer
  key :carry, Integer
  key :trained, Integer
  key :lost, Integer
end

class Defender
  include MongoMapper::EmbeddedDocument
key :name, String
  key :attack, Integer
  key :defence, Integer
  key :speed, Integer
  key :carry, Integer
  key :trained, Integer
  key :lost, Integer
end

class Clan
  include MongoMapper::EmbeddedDocument
  key :name, String
  key :attack, Integer
  key :defence, Integer
  key :herbs, Integer
  key :materials, Integer
  key :ramen, Integer
  key :upkeep, Integer
  key :speed, Integer
  key :carry, Integer
  key :training_time, Integer
  key :trained, Integer
  key :next_trained_time, Time
  key :total_trained_time, Time
end

class Room
  include MongoMapper::EmbeddedDocument
  key :herbs, Integer
  key :materials, Integer
  key :ramen, Integer
  key :upkeep, Integer
  key :level, Integer
  key :upgrade_time, Time
  #one :staff 
end

class Staff
  include MongoMapper::EmbeddedDocument
  key :name, String
  key :herbs, Integer
  key :materials, Integer
  key :ramen, Integer
  key :upkeep, Integer
  key :level, Integer
  key :upgrade_time, Time
end
