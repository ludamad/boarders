boarders = require './boarders'

# Exemplify 'raw' boarders usage?
# Well, we'll be as lazy as possible with making abstractions.

breakthroughMoveLogic = () ->
    # Used for move generation logic:
    directions = [
        {white: 'forward-left', black: 'backward-left', canCapture: true} 
        {white: 'forward', black: 'backward', canCapture: false} 
        {white: 'forward-right', black: 'backward-right', canCapture: true} 
    ]

setupBreakthrough = (elem) ->
    rules = new boarders.Rules()
    rules.player "white"
    rules.player "black"
    rules.grid('board-1', 8, 8) 
    
    pawn = rules.piece "pawn"
    pawn.image "white", 'images/Chess/wpawn_45x45.svg' 
    pawn.image "black", 'images/Chess/bpawn_45x45.svg' 

    rules.finalizeBoardShape()

    rules.boardSetup "pawn", "white", 'a1 b1 c1 d1 e1 f1 g1 h1'.split(' ')
    rules.boardSetup "pawn", "white", 'a2 b2 c2 d2 e2 f2 g2 h2'.split(' ')
    rules.boardSetup "pawn", "black", 'a7 b7 c7 d7 e7 f7 g7 h7'.split(' ')
    rules.boardSetup "pawn", "black", 'a8 b8 c8 d8 e8 f8 g8 h8'.split(' ')

    gamestate = new boarders.GameState(rules)
    playArea = gamestate.setupHtml('board-container')

module.exports = {setupBreakthrough}
