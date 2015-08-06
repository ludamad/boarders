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

export function runEnginePlayer(level:number, gameString:string, onFinishThinking: (string) => void) {
    let args = {
        alg: "negascout",
        level: level,
        game: gameString
    };

    if (worker == null) {
        console.log("Spawning ai-worker");
        worker = new Worker("jmarine/ai-worker.js");

        worker.onmessage = (event) => {
            if (event.data == "spawned") {
                console.log("AI worker confirms that it has been spawned");
                return;
            }
            let moveStr = event.data;
            console.log("AI returned " + moveStr + ".");
            onFinishThinking(moveStr);
        };
    }
    console.log("Telling ai-worker to think");
    return worker.postMessage(args);
}
