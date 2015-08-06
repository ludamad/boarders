import * as anyboard from "../client/anyboard";

import {setupBreakthrough} from "../client/Breakthrough";
import * as boarders from "../client/boarders";

// On load:
$(() => {
    setupBreakthrough($("#board-1"));
});