worker = null

# jmarine's AI for 8x8 games.
# Could use as base later.

stopEnginePlayer = () ->
    if worker?
        worker.terminate()
        worker = null

runEnginePlayer = (level, gameString, onFinishThinking) ->
    args = {alg: 'negascout', level, game: gameString} 
 
    if not worker?
        worker = new Worker('jmarine/ai-worker.js')

        worker.onmessage = (event) ->
            moveStr = event.data
            console.log "AI returned #{moveStr}."
            onFinishThinking(moveStr)

    worker.postMessage(args)

module.exports = {stopEnginePlayer, runEnginePlayer}
