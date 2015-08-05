var worker;

worker = null;

// jmarine's AI for 8x8 games.
// Could use as base later.

export function stopEnginePlayer() {
    if (worker != null) {
        worker.terminate();
        return worker = null;
    }
}

export function runEnginePlayer(level, gameString, onFinishThinking) {
    var args;
    args = {
        alg: "negascout",
        level: level,
        game: gameString
    };

    if (worker == null) {
        worker = new Worker("jmarine/ai-worker.js");

        worker.onmessage = (event) => {
            var moveStr;
            moveStr = event.data;
            console.log("AI returned " + moveStr + ".");
            return onFinishThinking(moveStr);
        };
    }

    return worker.postMessage(args);
}
