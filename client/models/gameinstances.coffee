attr = DS.attr

Boarders.Player = DS.Model.extend({
    name: attr('string')
});

Boarders.Ruleset = DS.Model.extend({
    name: attr('string')
    rules: attr('string')
});

Boarders.GameInstance = DS.Model.extend({
    players: DS.hasMany('player', async: true)
    public: attr('boolean')
    ruleset: DS.belongsTo('ruleset', async: true)
    tags: attr('string')
});

Boarders.OpenGame = DS.Model.extend({
    games: DS.hasMany('game-instance', async: true)
    })

# Fixtures
Boarders.Player.FIXTURES = [{
        id: 1,
        name: 'ludamad'
    },{
        id: 2,
        name: 'putterson'
    },{
        id: 3,
        name: 'AI'
}];

Boarders.Ruleset.FIXTURES = [{
    id: 1,
    name: 'Breakthrough'
    ruleset: 'Breakthrough'
}];

Boarders.GameInstance.FIXTURES = [{
    id: 1,
    players: [ 1, 3 ]
    ruleset: 1
    public: true
    tags: 'hello world'
}];

Boarders.OpenGame.FIXTURES = [{
    id: 1,
    games: [ 1 ]
}];