# attr = DS.attr

# Boarders.Session = DS.Model.extend {
#     id: attr('number')
#     timestamp: attr('string')
#     uuid: attr('string')
#     user_id: attr('number')
# }

# Boarders.User = DS.Model.extend {
#     name: attr('string')
# }

# Boarders.Ruleset = DS.Model.extend {
#     name: attr('string')
#     n_players: attr('number')
# }

# Boarders.GameInstance = DS.Model.extend {
#     players: DS.hasMany('player', async: true)
#     players: DS.hasMany('player', async: true)
#     public: attr('boolean')
#     ruleset: DS.belongsTo('ruleset', async: true)
#     tags: attr('string')
# }

# Boarders.OpenGame = DS.Model.extend {
#     games: DS.hasMany('game-instance', async: true)
# }

# # For now, do everything in socketio
# class DataSyncer
#     constructor: (@socket) ->
#         @socket.on ''

