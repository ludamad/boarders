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
    IndexController: any;
    IndexView: any;
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

// Magically applies to 'index' template
Boarders.IndexController = Ember.Controller.extend(<CoreObjectArguments> {
    "mock_data": [1, 2, 3],
    sockets: {
        "mock_data": "mock_data"
    }
});
// Views:

// Applies to 'index' template
Boarders.IndexView = Ember.View.extend(<CoreObjectArguments>{
    didInsertElement: () => {
        $(".Breakthrough-container").each(function() {
            return setupBreakthrough($(this));
        })
    }
});

// models = require("./models/models");