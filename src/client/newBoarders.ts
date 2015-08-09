// Game rules object.


////////////////////////////////////////////////////////////////////////////////
// Helpers to assign objects sequential integers:
////////////////////////////////////////////////////////////////////////////////

// A hack to get more expressive-looking types, without changing anything really.
type ResourceId<T> = number;

export class HasResourceId {
    // Backpointer to allow for setting data in the UI info object.
    rules:Rules;
    resourceId:ResourceId<any>;
}

class Enumerator<T extends HasResourceId> {
    nextResourceId:ResourceId<T> = 0;
    resources:T[] = [];
    enumerate(t:T) {
        t.resourceId = this.nextResourceId++;
        this.resources.push(t);
    }
}

class Enumerators {
    Player        = new Enumerator<Player>();
    Direction     = new Enumerator<Direction>();
    GraphNode     = new Enumerator<GraphNode>();
    GraphPlayArea = new Enumerator<GraphPlayArea>();
}

////////////////////////////////////////////////////////////////////////////////
// Helpers to assign objects sequential integers:
////////////////////////////////////////////////////////////////////////////////

export class Direction extends HasResourceId {
    previous: ResourceId<Direction>[];
    next:     ResourceId<Direction>[];
}

export class Player extends HasResourceId {
    name: string;
}

export class GraphNode extends HasResourceId {
}

export class GraphPlayArea extends HasResourceId {
    
}

export class Rules {
    uiInfo:UiInfo = new UiInfo();
    enums:Enumerators = new Enumerators();
    finalized:boolean = false;
    finalizeBoardShape() {
        
    }
}

export class GameState {
    private playAreas:GraphPlayArea[];
    private rules:Rules;
    // Store _everything_ in a single array.
    // We treat it as arbitrary memory allocation.
    private state:number[];
}

////////////////////////////////////////////////////////////////////////////////
// Everything related to UI.
////////////////////////////////////////////////////////////////////////////////

export class UiInfo {
    // any[];
}