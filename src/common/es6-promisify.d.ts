
declare module "es6-promisify" {
    type NodeStyleCB<T> = (error:Error, val?:T) => void;
    export default function promisify<T>( 
        toTransform: (done:NodeStyleCB<T>) => any
    ): () => Promise<T>;
    export default function promisify<T, A1>( 
        toTransform: (a1:A1, done:NodeStyleCB<T>) => any
    ): (a1:A1) => Promise<T>;
    export default function promisify<T, A1, A2>( 
        toTransform: (a1:A1, a2:A2, done:NodeStyleCB<T>) => any
    ): (a1:A1, a2:A2) => Promise<T>;
    export default function promisify<T, A1, A2, A3>( 
        toTransform: (a1:A1, a2:A2, a3:A3, done:NodeStyleCB<T>) => any
    ): (a1:A1, a2:A2, a3:A3) => Promise<T>;
    export default function promisify<T, A1, A2, A3, A4>( 
        toTransform: (a1:A1, a2:A2, a3:A3, a4:A4, done:NodeStyleCB<T>) => any
    ): (a1:A1, a2:A2, a3:A3, a4:A4) => Promise<T>;
    export default function promisify<T, A1, A2, A3, A4, A5>( 
        toTransform: (a1:A1, a2:A2, a3:A3, a4:A4, a5:A5, done:NodeStyleCB<T>) => any
    ): (a1:A1, a2:A2, a3:A3, a4:A4, a5:A5) => Promise<T>;
    export default function promisify<T>(callback:any): any;
}
