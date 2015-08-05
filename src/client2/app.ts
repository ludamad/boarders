/// <reference path="../DefinitelyTyped/ember/ember.d.ts"/>
/// <reference path="../DefinitelyTyped/showdown/showdown.d.ts"/>
/// <reference path="../DefinitelyTyped/moment/moment.d.ts"/>
/// <reference path="./ember-data.d.ts"/>

"use strict";
// Includes

import * as anyboard from "./anyboard"
import {setupBreakthrough} from "./Breakthrough";

declare var EmberSockets; // No DefinitelyTyped for ember-sockets, it seems.

// Generic utilities

// Handlebars callbacks:

var showdown = new Showdown.converter();
Ember.Handlebars.helper("format-markdown", (input) => new Handlebars.SafeString(showdown.makeHtml(input)));

Ember.Handlebars.helper("format-date", (date) => moment(date).fromNow());
// Ember JS wrapping utilities:

interface Boarders {
    ApplicationAdapter: any;
    ApplicationAdapter: any;
}

// Cast window so TypeScript lets us extend it
var Boarders = Ember.Application.create<Boarders>({
    LOG_TRANSITIONS: true,
    Socket: EmberSockets.extend({
        controllers: ["index"],
        autoConnect: true
    })
});

(<any>window).Boarders = Boarders;

Boarders.ApplicationAdapter = DS.FixtureAdapter.extend();
// 
// var routes = [];
// var subRoutes = {};
// var routeHandlers = {};
// var subRouteHandlers = {};
// 
// function Route(route, handler) {
//     routes.push(route);
//     if (handler != null) {
//         Boarders[(route.toCapitalized()) + "Route"] = Ember.Route.extend({
//             model: handler
//         });
//         routeHandlers[route] = Boarders[(route.toCapitalized()) + "Route"];
//     }
//     subRoutes[route] = [];
//     return subRouteHandlers[route] = {};
// }
// 
// // Controller = (route) -> (definition) ->
// //     Boarders["#{route.toCapitalized()}Controller"] = Ember.Controller.extend(definition)
// 
// // ObjectController = (route) -> (definition) ->
// //     Boarders["#{route.toCapitalized()}Controller"] = Ember.ObjectController.extend(definition)
// 
// // View = (route) -> (definition) ->
// //     Boarders["#{route.toCapitalized()}View"] = Ember.View.extend(definition)
// 
// function SubRoute(str) {
//     var parent, route, _ref;
//     _ref = str.split("/"), parent = _ref[0], route = _ref[1];
//     subRoutes[parent].push(route);
//     if (typeof handler !== "undefined" && handler !== null) {
//         Boarders[(route.toCapitalized()) + "Route"] = Ember.Route.extend({
//             model: handler
//         });
//     }
//     return subRouteHandlers[parent][route] = Boarders[(route.toCapitalized()) + "Route"];
// }
// 
// function installRoutes() {
//     return Boarders.Router.map(() => routes.map((route) => this.resource(route, () => subRoutes[route].map((subRoute) => this.resource(subRoute, {
//                         path: ":path_id"
//                     })))));
// }
// Routes:
// Controllers:

// Magically applies to 'index' template
Boarders.IndexController = Ember.Controller.extend({
    "mock_data": [1, 2, 3],
    sockets: {
        "mock_data": "mock_data"
    }
});
// Views:

// Applies to 'index' template
Boarders.IndexView = Ember.View.extend({
    didInsertElement: () => $(".Breakthrough-container").each(function() {
            return setupBreakthrough($(this));
        })
});

models = require("./models/models");
