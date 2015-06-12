anyboard = require "./anyboard"
{setupBreakthrough} = require "./Breakthrough"


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

window.Boarders = Ember.Application.create {
    LOG_TRANSITIONS: true
    Socket: EmberSockets.extend {
      controllers: ['index'],
      autoConnect: false
    }
}

Boarders.ApplicationAdapter = DS.FixtureAdapter.extend();

routes = []
subRoutes = {}
routeHandlers = {}
subRouteHandlers = {}

Route = (route, handler) ->
    routes.push(route)
    if handler?
        Boarders["#{route.toCapitalized()}Route"] = Ember.Route.extend {model: handler}
        routeHandlers[route] = Boarders["#{route.toCapitalized()}Route"]
    subRoutes[route] = []
    subRouteHandlers[route] = {}

Controller = (route) -> (definition) ->
    Boarders["#{route.toCapitalized()}Controller"] = Ember.Controller.extend(definition)

ObjectController = (route) -> (definition) ->
    Boarders["#{route.toCapitalized()}Controller"] = Ember.ObjectController.extend(definition)

View = (route) -> (definition) ->
    Boarders["#{route.toCapitalized()}View"] = Ember.View.extend(definition)

SubRoute = (str) ->
    [parent, route] = str.split("/")
    subRoutes[parent].push(route)
    if handler?
        Boarders["#{route.toCapitalized()}Route"] = Ember.Route.extend {model: handler}
    subRouteHandlers[parent][route] = Boarders["#{route.toCapitalized()}Route"]

installRoutes = () ->
    Boarders.Router.map () ->
        for route in routes
            @resource route, () ->
                for subRoute in subRoutes[route]
                    @resource subRoute, {path: ":path_id"}

###############################################################################
# Routes:
###############################################################################

games = null

window.RENDER_DATA = {
    game_instances: [
        {rules: {name: 'Breakthrough', n_players: 2}, is_active: true, players: }
    ]
}

GAMES = []

# Route "games", () ->
#     return this.store.find('game-instance')

# SubRoute("games/game", ({path_id}) -> return games.findBy('id', path_id))

Route "library", () ->
    return @store.find 'game-instance'

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

###############################################################################
# Views:
###############################################################################

View("index") {
    didInsertElement: () ->
        $(".Breakthrough-container").each () ->
            setupBreakthrough($(@))
}

models = require "./models/models"
   
