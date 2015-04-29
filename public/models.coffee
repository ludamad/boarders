{attr, hasMany, belongsTo, Model} = DS

# Simple sugar over EmberJS

Model = (name) -> attrs) ->
	App[name] = DS.Model.extend(attrs)

App.BlogPost = DS.Model.extend {
  title: attr()
  createdAt: attr('date')
  comments: hasMany('comment')
}

Model("User") {
	name: attr()
	isGuest: attr()
	is_guest: attr()
}

Model("ActiveGame") {
  users: hasMany('user')
}
import Model from require "lapis.db.model"
import create_table, create_index, types, drop_table from require "lapis.db.schema"

M = {} -- module

Model.dbDrop = () =>
  drop_table(@table_name())
Model.dbInit = () =>
  create_table(@table_name(), @schema)

class M.Users extends Model
  @schema: {
    "id serial not null"
    "name text"
    "password_hash text"
    -- Guest accounts are accessible only using a session (although for arbitrarily long), unless they register
    "is_guest bool" 
    "primary key(id)"
  }

class M.GameRules extends Model
  @schema: {  
    "id serial not null"
    "name text"
    "short_description text"
    "description text"
    "times text"
    "primary key(id)"
  }

class M.ActiveGames extends Model
  @schema: {  
    "id serial not null"
    "name text"
    "short_description text"
    "description text"
    "times text"
    "gamestate bytea"
    "primary key(id)"
  }
class M.ActiveGameParticipants extends Model
  @schema: {
    "active_game_id integer"
    "active_game_player integer" -- -1 for spectator?
  }

class M.ChatChannels extends Model
  @schema: {  
  }

class M.Sessions extends Model
  @schema: {
    "user_id integer references users(id)"
    "auth_key text NOT NULL default md5(random()::text)"
    "last_action_time timestamp default now()"
    "primary key(user_id, auth_key)"
  }

M.dbInit = () ->
  M.Metadata\dbDrop()
  M.Sessions\dbDrop()
  M.Users\dbDrop()
  M.GameRules\dbDrop()
  M.ActiveGames\dbDrop()

  M.Metadata\dbInit()
  M.Metadata\create {
    password_salt: "Supersecretsalt"
    lua_engine_files: ""
  }
  M.Users\dbInit()
  M.Sessions\dbInit()
  create_index(M.Users\table_name(), "name")
  M.GameRules\dbInit()
  create_index(M.GameRules\table_name(), "name")
  M.ActiveGames\dbInit()

return M
