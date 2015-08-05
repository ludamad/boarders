"use strict"

###############################################################################
# Includes
###############################################################################

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
      autoConnect: true
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

# Controller = (route) -> (definition) ->
#     Boarders["#{route.toCapitalized()}Controller"] = Ember.Controller.extend(definition)

# ObjectController = (route) -> (definition) ->
#     Boarders["#{route.toCapitalized()}Controller"] = Ember.ObjectController.extend(definition)

# View = (route) -> (definition) ->
#     Boarders["#{route.toCapitalized()}View"] = Ember.View.extend(definition)

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

###############################################################################
# Controllers:
###############################################################################

# Magically applies to 'index' template
Boarders.IndexController = Ember.Controller.extend {
    'mock_data': [1,2,3]

    sockets: {
        'mock_data': 'mock_data'
    }
}

###############################################################################
# Views:
###############################################################################

# Applies to 'index' template
Boarders.IndexView = Ember.View.extend {
    didInsertElement: () ->
        $(".Breakthrough-container").each () ->
            setupBreakthrough($(@))
}

models = require "./models/models"
   
