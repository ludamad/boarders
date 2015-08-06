import * as anyboard from "../client/anyboard";

import {setupBreakthrough} from "../client/Breakthrough";
import * as boarders from "../client/boarders";

window.onerror = function(message: string, filename: string, lineno: number, colno: number, error:Error) {
    console.log(message);
    console.log(error.message);
    console.log((<any>error).stack);
};

// On load:
$(() => {
    setupBreakthrough($("#board-1"));
});