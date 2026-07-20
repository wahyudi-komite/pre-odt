import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import vm from "node:vm";

const html = await readFile(new URL("../index.html", import.meta.url), "utf8");
const css = await readFile(new URL("../css/public.css", import.meta.url), "utf8");

test("public page module script has valid JavaScript syntax", () => {
    const startMarker = '<script type="module">';
    const start = html.indexOf(startMarker);
    const end = html.indexOf("</script>", start);
    const moduleScript = start >= 0 && end > start
        ? html.slice(start + startMarker.length, end)
        : "";

    assert.notEqual(moduleScript, "");
    assert.doesNotThrow(() => new vm.SourceTextModule(moduleScript));
});

test("public page integrates explicit fullscreen selection persistence", () => {
    assert.match(html, /from "\.\/js\/fullscreen-area-state\.js"/);
    assert.match(html, /saveFullscreenArea\(localStorage,\s*areaId\)/);
    assert.match(html, /clearFullscreenArea\(localStorage\)/);
    assert.match(html, /document\.body\.classList\.add\("area-fullscreen-restored-mode"\)/);
    assert.match(html, /window\.exitAreaFullscreen\s*=\s*async function/);
});

test("fullscreenchange does not clear persisted selection", () => {
    const handler = html.match(/document\.addEventListener\("fullscreenchange",[\s\S]*?\n\s*\}\);/)?.[0] || "";
    assert.doesNotMatch(handler, /clearFullscreenArea|removeItem|setItem/);
    assert.match(handler, /restoreFullscreenArea\(\)/);
});

test("bracket rerenders reapply the persisted fullscreen selection", () => {
    const start = html.indexOf("function renderAllBrackets()");
    const end = html.indexOf("function renderBracketSection", start);
    const renderFunction = start >= 0 && end > start ? html.slice(start, end) : "";
    assert.match(renderFunction, /restoreFullscreenArea\(\)/);
});

test("restored mode fills the viewport and hides unrelated content", () => {
    assert.match(css, /body\.area-fullscreen-restored-mode\s*\{[^}]*height:\s*100dvh;[^}]*overflow:\s*hidden;/s);
    assert.match(css, /\.area-fullscreen-restored-mode\s+\.public-header[^}]*\{[^}]*display:\s*none\s*!important;/s);
    assert.match(css, /\.area-fullscreen-restored-mode\s+\.area-summary-panel[^}]*\{[^}]*display:\s*none\s*!important;/s);
    assert.match(css, /\.area-fullscreen-restored-mode\s+#areas-container\s*\{[^}]*height:\s*100dvh;/s);
    assert.match(css, /\.area-section\.area-fullscreen-restored\s*\{[^}]*height:\s*100dvh;/s);
});
