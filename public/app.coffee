###############################################################################
# Generic utilities
###############################################################################

String::toCapitalized = () -> "#{@charAt(0).toUpperCase()}#{@slice(1)}"

###############################################################################
# Handlebars callbacks:
###############################################################################

showdown = new Showdown.converter()
Ember.Handlebars.helper 'format-markdown', (input) ->
    return new Handlebars.SafeString(showdown.makeHtml(input))

Ember.Handlebars.helper 'format-date', (date) ->
    return moment(date).fromNow() 

###############################################################################
# Ember JS wrapping utilities:
###############################################################################

App = Ember.Application.create({})

routes = []
subRoutes = {}
routeHandlers = {}
subRouteHandlers = {}

Route = (route, handler) ->
    routes.push(route)
    if handler?
        App["#{route.toCapitalized()}Route"] = Ember.Route.extend {model: handler}
        routeHandlers[route] = App["#{route.toCapitalized()}Route"]
    subRoutes[route] = []
    subRouteHandlers[route] = {}

Controller = (route) -> (definition) ->
    App["#{route.toCapitalized()}Controller"] = Ember.Controller.extend(definition)

ObjectController = (route) -> (definition) ->
    App["#{route.toCapitalized()}Controller"] = Ember.ObjectController.extend(definition)

SubRoute = (str) ->
    [parent, route] = str.split("/")
    subRoutes[parent].push(route)
    if handler?
        App["#{route.toCapitalized()}Route"] = Ember.Route.extend {model: handler}
    subRouteHandlers[parent][route] = App["#{route.toCapitalized()}Route"]

installRoutes = () ->
    App.Router.map () ->
        for route in routes
            @resource route, () ->
                for subRoute in subRoutes[route]
                    @resource subRoute, {path: ":path_id"}

###############################################################################
# Routes:
###############################################################################

Route("lobby") # Handler is TODO

games = null

Route "games", () -> 
    return $.getJSON("/games").then (obj) ->
        games = obj 
        return obj

SubRoute("games/game", ({path_id}) -> return games.findBy('id', path_id))

Route "posts", () ->
    return @store.find 'post'

installRoutes()

###############################################################################
# Controllers:
###############################################################################

ObjectController("game") {
    isPlaying: false
    actions: {
        play: () ->
            @set('isPlaying', true)
        resign: () ->
            @set('isPlaying', false)
            @set('body', 'You lose.')
    }
}

YUI().use 'aui-ace-editor', (Y) ->
    new Y.AceEditor(boundingBox: '#yamlEditor', mode: 'yaml',  value: '\r\n#################################################################\r\n# >> analysis:\r\n#\r\n# Attributes for controlling the duration and type of analysis.\r\n#  initial_entities:\r\n#    The initial entity amount to create.\r\n#  max_entities: \r\n#    The maximum amount of entities for which to allocate. Once the network\r\n#    has grown to this amount, the entity add rate will artifically drop to 0.\r\n#  max_time:\r\n#    The maximum simulation-time for the simulation. Once it has elapsed, the simulation halts.\r\n#    Interacting with the simulation does not alter the simulation-time.\r\n#    In seconds.\r\n#  max_real_time:\r\n#    The maximum real-time for the simulation. Once it has elapsed, the simulation halts.\r\n#    Note that interacting with the simulation DOES detract from this time.\r\n#    In seconds.\r\n#  enable_interactive_mode:\r\n#    Whether interactive mode should be triggered by Ctrl+C or .\/scripts\/stop.sh (triggers SIGUSR1).\r\n#  enable_lua_hooks:\r\n#    Whether to use runtime Lua functions that can react to events. **Slow!**\r\n#    Hooks are availble for running on every tweet, retweet, follow, etc.\r\n#  lua_script:\r\n#    Script to use to define the behaviour of interactive mode as well as lua hooks.\r\n#  use_barabasi: \r\n#    If true, the global follow rate is ignored. Follow thresholds not needed.\r\n#  use_random_time_increment: \r\n#    Increments by 1\/sum(rates) on average\r\n#  use_flawed_followback: \r\n#    Whether to follow-back by a fixed 40%.\r\n#  follow_model: \r\n#    Accepted models: \'random\', \'twitter_preferential\', \'entity\', \'preferential_entity\', \'hashtag\', \'twitter\'\r\n#  stage1_unfollow: \r\n#    Whether to have an unfollow model assuming constant \'chattiness\', compares the chatiness of an entity wrt to the following set.\r\n#  unfollow_tweet_rate: \r\n#    Tweets per minute. Chattiness for which to be considered for unfollow.\r\n#################################################################\r\n\r\nanalysis:\r\n  initial_entities:\r\n    10000  # start out from something small, could be when only the developers were online.\r\n  max_entities: \r\n    10000     # 1 million max users\r\n  max_time: \r\n    100000\r\n  max_analysis_steps: \r\n    unlimited\r\n  max_real_time: \r\n    240*hour*5        # 10 days         \r\n  enable_interactive_mode:\r\n    false\r\n  enable_lua_hooks: # Defined in same file as interactive_mode. Can slow down simulation considerably.\r\n    false\r\n  lua_script: # Defines behaviour of interactive mode & lua hooks\r\n    INTERACT.lua\r\n  use_barabasi: \r\n    false \r\n  barabasi_connections: # number of connections we want to make when use_barabasi == true\r\n    100\r\n  barabasi_exponent:\r\n    1\r\n  use_random_time_increment: \r\n    true\r\n  use_followback: \r\n    false        # followback turned on, from literature it makes sense for a realistic system\r\n  follow_model: # See notes above\r\n    random\r\n  # model weights ONLY necessary for follow method \'twitter\'  \r\n  # educated guesses for the follow models  \r\n  model_weights: {random: 0.0, twitter_preferential: 1.0, entity: 0.0, preferential_entity: 0.0, hashtag: 0.0}\r\n  \r\n  stage1_unfollow: \r\n    false\r\n  unfollow_tweet_rate: \r\n    100\r\n  use_hashtag_probability:\r\n    0.5    # 50 % chance of using a hashtag\r\n\r\n#################################################################\r\n# >> rates:\r\n#\r\n# The rate function for adding entities to the network.\r\n#################################################################\r\n\r\nrates:\r\n  add: {function: constant, value: 0.0}  # found from experiment\r\n\r\n#################################################################\r\n# >> output:\r\n#\r\n# Various options for the output of the simulation, both while it\r\n# runs and for post-analysis.\r\n#################################################################\r\n\r\noutput:\r\n  save_network_on_timeout: \r\n    true\r\n  load_network_on_startup:\r\n    true\r\n  ignore_load_config_check: # Whether to allow loading configuration with mismatching configuration (generally OK)    \r\n    true\r\n  save_file: # File to save to, and load from\r\n    network_state.sav\r\n  stdout_basic: \r\n    true\r\n  stdout_summary: \r\n    true\r\n  summary_output_rate: \r\n    100\r\n  visualize: \r\n    true\r\n  entity_stats: \r\n    true\r\n  degree_distributions: \r\n    true            # set this to true, will print after simulation has finished\r\n  tweet_analysis: \r\n    true\r\n  retweet_visualization:\r\n    true\r\n  main_statistics:\r\n    true\r\n\r\n#################################################################\r\n# >> *_ranks:\r\n# Options for the categorization based on various attributes.\r\n#################################################################\r\n\r\ntweet_ranks: \r\n  thresholds: {bin_spacing: linear, min: 10, max: 300, increment: 10}\r\nretweet_ranks:\r\n  thresholds: {bin_spacing: linear, min: 10, max: 300, increment: 10}\r\nfollow_ranks:\r\n  thresholds: {bin_spacing: linear, min: 0, max: 540000, increment: 1}    # for preferential following\r\n  weights:    {bin_spacing: linear, min: 1, max: 540001, increment: 1}\r\n\r\n#################################################################\r\n# >> tweet_observation: \r\n#\r\n# An observation probability density function that gives \r\n# the probability that a tweet is observed at a certain time by an \'ideal observer\'. \r\n# An \'ideal observer\' is one which always sees a tweet, eventually.\'\r\n# The observation PDF is used for both retweeting and follow-from-tweet.\r\n# We combine this with a relevance factor, r, where 0 <= r <= 1.0, we in turn\r\n# determines the probability that a given entity will act on a given tweet, with enough time.\r\n#\r\n#  density_function:\r\n#    Probability \'density\' function to sample logarithmatically.\r\n#    Provided as if a Python function of \'x\'. It is integrated using the scipy.integrate module. \r\n#    Note technically not a true PDF because one does NOT need to have an integral range that sums to 1.0.\r\n#    The function, after integration, _will_ be normalized for you.\r\n#\r\n#  x_start:\r\n#    In arbitrary units. The beginning x-value to integrate from.\r\n#  x_end:\r\n#    In arbitrary units. The end x-value to integrate to.\r\n#\r\n#  initial_resolution:\r\n#    In arbitrary units. The initial binning resolution. \r\n#    That is, the x-step with which to begin binning. The binning resolution is decreased from there on.\r\n#  resolution_growth_factor:\r\n#    How quickly the resolution grows from one bin to the next. \r\n#    Quicker is more efficient, but with less precise rates in later bins.\r\n#  time_span:\r\n#    In minutes. The time over which the function is defined.\r\n#    After this, tweets will \'disappear\'.\r\n#################################################################\r\n\r\ntweet_observation: # \'Omega\'\r\n   density_function: \r\n       2.45 \/ (x)**1.1 \r\n   x_start: \r\n       5\r\n   x_end: \r\n       600\r\n   initial_resolution: \r\n       1.0\r\n   resolution_growth_factor: \r\n       1.05\r\n       # this is now obsolete, the x_start and x_ends are in minutes\r\n   time_span: \r\n       8*hour\r\n\r\n#################################################################\r\n# >> ideologies: \r\n# Abstract categorizations of similar beliefs.\r\n# The amount of ideologies MUST match N_BIN_IDEOLOGIES in \r\n# config_static.h!\r\n#################################################################\r\n\r\nideologies:\r\n  - name: Red\r\n  - name: Blue\r\n  - name: Green\r\n  - name: Orange\r\n\r\n#################################################################\r\n# >> regions: \r\n#\r\n# Locations, such as countries, can be represented abstractly. \r\n# Note that the number of regions must exactly match N_BIN_REGIONS in config_static.h!\r\n# Additionally, it is required that every region have exactly N_BIN_SUBREGIONS subregions.\r\n#\r\n# add_weight:\r\n#   Required for each region. The weight with which \r\n#   this region is chosen.\r\n#\r\n# The following are definable for each subregion.\r\n# If specified in the region, it will be an inherited default.\r\n#  languages_weights:\r\n#    Weights with which English, French, French-and-English are chosen.\r\n#  idealogy_weights:\r\n#    Weights with which an entity is a of a given \'idealogy\'\r\n\r\n#################################################################\r\n\r\nregions:\r\n  - name: Ontario\r\n    add_weight: 5\r\n\r\n    preference_class_weights: {StandardPref: 100}\r\n    ideology_weights: {Red: 100, Blue: 100, Green: 100, Orange: 100}\r\n    language_weights: {English: 60, French: 0, Spanish: 0, French+English: 0}\r\n\r\n  - name: Quebec\r\n    add_weight: 5\r\n\r\n    preference_class_weights: {StandardPref: 100}\r\n    ideology_weights: {Red: 100, Blue: 100, Green: 100, Orange: 100}\r\n    language_weights: {English: 0, French: 40, Spanish: 0, French+English: 0}\r\n    \r\n  - name: Mexico\r\n    add_weight: 0\r\n\r\n    preference_class_weights: {StandardPref: 100}\r\n    ideology_weights: {Red: 100, Blue: 100, Green: 100, Orange: 100}\r\n    language_weights: {English: 0, French: 0, Spanish: 100, French+English: 0}\r\n\r\n#################################################################\r\n# >> config_static: \r\n# Manually duplicated values from config_static.h. \r\n# These values MUST match config_static.h!\r\n#################################################################\r\n\r\nconfig_static:\r\n    # These values should match your C++ config_static.h limits!!\r\n    humour_bins: 2 # Amount of discrete bins for humour\r\n\r\n#################################################################\r\n# >> preference_classes: \r\n# The different preference stereotypes that users in the network can have.\r\n#\r\n# tweet_transmission:\r\n#   The transmission probability for a person of a certain preference class towards\r\n#   a tweet of a given origin & content.\r\n#   Effectively, this determines the proportion (on average) of a follower type\r\n#   that will, eventually (according to the tweet observation PDF), retweet a tweet.\r\n#\r\n#   Can be provided for an entity type, or the keys \'else\' or \'all\'. \r\n#   Both \'else\' and \'all\' have the functionality of defining the transmission probability\r\n#   function for all otherwise unspecified entity types.\r\n#\r\n#   Transmission probability functions are automatically converted into the necessary tables\r\n#   using Python. The strings provided can be any valid Python.\r\n#################################################################\r\n\r\npreference_classes:\r\n - name: StandardPref\r\n \r\n  # Determines the probability that a tweet is reacted to by this \r\n  # preference class:\r\n   tweet_transmission: \r\n      plain: # Also applies to musical tweets\r\n        Standard: 0.001\r\n        Celebrity: 0.001\r\n        else: 0.001\r\n      different_ideology:   # no retweeting for different ideologies\r\n        Standard: 0.00\r\n        Celebrity: 0.00\r\n        else: 0.00\r\n      same_ideology:\r\n        Standard: 0.001\r\n        Celebrity: 0.001\r\n        else: 0.001\r\n      humourous:\r\n        Standard: 0.002\r\n        Celebrity: 0.002\r\n        else: 0.002\r\n   # Probability that we will follow as a reaction.\r\n   # Only applies to 2nd generation retweets, otherwise\r\n   # the entity would already be a follower.\r\n   follow_reaction_prob:\r\n      0.1\r\n\r\n - name: NoRetweetPref\r\n   tweet_transmission: \r\n      plain: # Also applies to musical tweets\r\n        Standard: 0.0\r\n        Celebrity: 0\r\n        else: 0\r\n      different_ideology:\r\n        Standard: 0\r\n        Celebrity: 0\r\n        else: 0\r\n      same_ideology:\r\n        Standard: 0\r\n        Celebrity: 0\r\n        else: 0\r\n      humourous:\r\n        Standard: 0\r\n        Celebrity: 0\r\n        else: 0\r\n   # Probability that we will follow as a reaction.\r\n   # Only applies to 2nd generation retweets, otherwise\r\n   # the entity would already be a follower.\r\n   follow_reaction_prob:\r\n      0.0\r\n\r\n#################################################################\r\n# >> entities: \r\n#\r\n# The different types of entities in the network, and their \r\n# associated rates.\r\n#################################################################\r\n\r\nentities:\r\n  - name: Standard\r\n    weights:\r\n      # Weight with which this entity is created\r\n      add: 100.0\r\n      # Weight with which this entity is followed in entity follow\r\n      follow: 5\r\n      tweet_type:\r\n        ideological: 1.0\r\n        plain: 1.0\r\n        musical: 1.0\r\n        humourous: 1.0 # Can be considered the humourousness of the entity type\r\n    # Probability that following this entity results in a follow-back\r\n    followback_probability: .44\r\n    hashtag_follow_options:\r\n      care_about_region: true # does the entity care about where the entity they will follow is from?\r\n      care_about_ideology: false # does the entiy care about which ideology the entity has?\r\n    rates: \r\n        # Rate for follows from this entity:\r\n        follow: {function: constant, value: 0.001}\r\n        # Rate for tweets from this entity:\r\n        tweet: {function: constant, value: 0.0}   #0.000256944444444 0.37 per day\r\n').render()
$('#textarea').html("Some text!")

Controller("main") {
    loginFailed: false
    isProcessing: false
    timeout: null
    username: ""

    init: () ->
        @_super()
        @set("username", $.cookie("session-user-name") or '')
        @set("loggedIn", $.cookie("session-auth-key")?)
        @set("alerts", [])
        # HACK
        $(window).on 'popstate', () => 
            @set("alerts", [])

    _login: (request) ->
        @setProperties {
            loginFailed: false
            isProcessing: true
        }
        request.then(@success.bind(@), @failure.bind(@))

    actions: {
        guestLogin: () ->
            @_login $.post("/login/guest")

        login: () ->
            @_login $.post("/login/#{@get("username")}", @getProperties("password"))
    }

    success: (props) ->
        @reset()
        @setProperties {
            loggedIn: true
            loggedInRecent: true
            username: props.session.userName
            alerts: [{message: props.message}]
        } 
        $.cookie("session-user-id", props.session.userId)
        $.cookie("session-user-name", props.session.userName)
        $.cookie("session-auth-key", props.session.authKey)

    failure: () ->
        @reset()
        @set("loginFailed", true)

    reset: () ->
        clearTimeout(@get("timeout"))
        @setProperties {
            isProcessing: false,
            alert: null,
            isSlowConnection: false
            loggedInRecent: false
        }
}
