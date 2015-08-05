// Some functional stuff to get back expressiveness lost from CoffeeScript.
// Will this be slower than CoffeeScript? Depends. Sometimes CoffeeScript 
// created anonymous functions for scoping purposes, anyway.

// Based on TypeScript/compiler/core.ts, by Microsoft, released under Apache License 2.0

interface Promisify<T> {
    (callback): (any, T) => Promise<T>;
}

export declare var require : (string) => any;

// Monkey-patch babel-runtime:
require("babel-runtime/helpers/interop-require-wildcard")["default"] = function(obj) {
    if (obj.__esModule == null) {
        obj.__esModule = true;
        obj["default"] = obj;
    }
    // Return now-patched module:
    return obj;
}

var _promisify = require("es6-promisify");
export function promisify<T>(callback: (any, T) => T): Promise<T> {
    return _promisify(callback);
};

export const enum Comparison {
    LessThan    = -1,
    EqualTo     = 0,
    GreaterThan = 1
}

export function toCapitalized(str:string): string {
    return (str.charAt(0).toUpperCase()) + (str.slice(1));
};

export function arrayWithValueNTimes<T>(value: T, n: number): T[] {
    var array:T[] = [];
    for (var i = 0; i < n; i++) {
        array.push(value);
    }
    return array;
}

export function gridWithValueNByMTimes<T>(value: T, n: number, m: number): T[][] {
    var array:T[][] = [];
    for (var x = 0; x < n; x++) {
        array.push([]);
        for (var y = 0; y < n; y++) {
            array[array.length - 1].push(value);
        }
    }
    return array;
}

export function forEach<T, U>(array: T[], callback: (element: T) => U): U {
    if (array) {
        for (var i = 0, len = array.length; i < len; i++) {
            var result = callback(array[i]);
            if (result) {
                return result;
            }
        }
    }
    return undefined;
}

export function contains<T>(array: T[], value: T): boolean {
    if (array) {
        for (var i = 0, len = array.length; i < len; i++) {
            if (array[i] === value) {
                return true;
            }
        }
    }
    return false;
}

export function indexOf<T>(array: T[], value: T): number {
    if (array) {
        for (var i = 0, len = array.length; i < len; i++) {
            if (array[i] === value) {
                return i;
            }
        }
    }
    return -1;
}

export function countWhere<T>(array: T[], predicate: (x: T) => boolean): number {
    var count = 0;
    if (array) {
        for (var i = 0, len = array.length; i < len; i++) {
            if (predicate(array[i])) {
                count++;
            }
        }
    }
    return count;
}

export function filter<T>(array: T[], f: (x: T) => boolean): T[] {
    if (array) {
        var result: T[] = [];
        for (var i = 0, len = array.length; i < len; i++) {
            var item = array[i];
            if (f(item)) {
                result.push(item);
            }
        }
    }
    return result;
}

export function map<T, U>(array: T[], f: (x: T) => U): U[] {
    if (array) {
        var result: U[] = [];
        for (var i = 0, len = array.length; i < len; i++) {
            result.push(f(array[i]));
        }
    }
    return result;
}

export function concatenate<T>(array1: T[], array2: T[]): T[] {
    if (!array2 || !array2.length) return array1;
    if (!array1 || !array1.length) return array2;

    return array1.concat(array2);
}

export function deduplicate<T>(array: T[]): T[] {
    if (array) {
        var result: T[] = [];
        for (var i = 0, len = array.length; i < len; i++) {
            var item = array[i];
            if (!contains(result, item)) result.push(item);
        }
    }
    return result;
}

export function sum(array: any[], prop: string): number {
    var result = 0;
    for (var i = 0; i < array.length; i++) {
        result += array[i][prop];
    }
    return result;
}

/**
 * Returns the last element of an array if non-empty, undefined otherwise.
 */
export function lastOrUndefined<T>(array: T[]): T {
    if (array.length === 0) {
        return undefined;
    }

    return array[array.length - 1];
}

export function binarySearch(array: number[], value: number): number {
    var low = 0;
    var high = array.length - 1;

    while (low <= high) {
        var middle = low + ((high - low) >> 1);
        var midValue = array[middle];

        if (midValue === value) {
            return middle;
        }
        else if (midValue > value) {
            high = middle - 1;
        }
        else {
            low = middle + 1;
        }
    }

    return ~low;
}

var hasOwnProperty = Object.prototype.hasOwnProperty;

export function hasProperty<T>(map: any, key: string): boolean {
    return hasOwnProperty.call(map, key);
}

export function getProperty<T>(map: any, key: string): T {
    return hasOwnProperty.call(map, key) ? map[key] : undefined;
}

export function isEmpty<T>(map: any) {
    for (var id in map) {
        if (hasProperty(map, id)) {
            return false;
        }
    }
    return true;
}

export function clone<T>(object: T): T {
    var result: any = {};
    for (var id in object) {
        result[id] = (<any>object)[id];
    }
    return <T>result;
}

export function forEachValue<T, U>(map: any, callback: (value: T) => U): U {
    var result: U;
    for (var id in map) {
        if (result = callback(map[id])) break;
    }
    return result;
}

export function forEachKey<T, U>(map: any, callback: (key: string) => U): U {
    var result: U;
    for (var id in map) {
        if (result = callback(id)) break;
    }
    return result;
}

export function lookUp<T>(map: any, key: string): T {
    return hasProperty(map, key) ? map[key] : undefined;
}

export function mapToArray<T>(map: any): T[] {
    var result: T[] = [];

    for (var id in map) {
        result.push(map[id]);
    }

    return result;
}

/**
 * Creates a map from the elements of an array.
 *
 * @param array the array of input elements.
 * @param makeKey a function that produces a key for a given element.
 *
 * This function makes no effort to avoid collisions; if any two elements produce
 * the same key with the given 'makeKey' function, then the element with the higher
 * index in the array will be the one associated with the produced key.
 */
export function arrayToMap<T>(array: T[], makeKey: (value: T) => string): any {
    var result: any = {};

    forEach(array, value => {
        result[makeKey(value)] = value;
    });

    return result;
}
