boarders = require './boarders'

# Exemplify 'raw' boarders usage?
# Well, we'll be as lazy as possible with making abstractions.

setupBreakthrough = (elem) ->
    rules = new boarders.Rules()
    rules.grid('board-1', 8, 8) 
    playArea = rules.getHtmlComponent('board-container')
    v = ''
    for k in Object.keys playArea.boards[0]
        v += k + ': ' + playArea.boards[0][k].toString() + '\n'
    alert v
    playArea.setup()

module.exports = {setupBreakthrough}
