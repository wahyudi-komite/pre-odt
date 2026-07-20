import test from "node:test";
import assert from "node:assert/strict";
import {
    FULLSCREEN_AREA_STORAGE_KEY,
    readFullscreenArea,
    saveFullscreenArea,
    clearFullscreenArea,
    resolveFullscreenArea
} from "../js/fullscreen-area-state.js";

function memoryStorage(initial = {}) {
    const values = new Map(Object.entries(initial));
    return {
        getItem(key) {
            return values.has(key) ? values.get(key) : null;
        },
        setItem(key, value) {
            values.set(key, String(value));
        },
        removeItem(key) {
            values.delete(key);
        }
    };
}

test("saves and reads the selected fullscreen area", () => {
    const storage = memoryStorage();
    assert.equal(saveFullscreenArea(storage, "area-1"), true);
    assert.equal(readFullscreenArea(storage), "area-1");
});

test("clears selection only when explicitly requested", () => {
    const storage = memoryStorage({ [FULLSCREEN_AREA_STORAGE_KEY]: "area-2" });
    assert.equal(readFullscreenArea(storage), "area-2");
    assert.equal(clearFullscreenArea(storage), true);
    assert.equal(readFullscreenArea(storage), null);
});

test("rejects missing or unknown saved areas", () => {
    assert.equal(resolveFullscreenArea(null, ["area-1"]), null);
    assert.equal(resolveFullscreenArea("", ["area-1"]), null);
    assert.equal(resolveFullscreenArea("missing", ["area-1"]), null);
    assert.equal(resolveFullscreenArea("area-1", ["area-1", "area-2"]), "area-1");
});

test("storage failures do not escape to the page", () => {
    const brokenStorage = {
        getItem() { throw new Error("blocked"); },
        setItem() { throw new Error("blocked"); },
        removeItem() { throw new Error("blocked"); }
    };
    assert.equal(readFullscreenArea(brokenStorage), null);
    assert.equal(saveFullscreenArea(brokenStorage, "area-1"), false);
    assert.equal(clearFullscreenArea(brokenStorage), false);
});
