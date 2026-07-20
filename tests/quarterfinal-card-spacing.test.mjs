import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";

const css = await readFile(new URL("../css/public.css", import.meta.url), "utf8");
const desktopStart = css.indexOf("@media (min-width: 769px) {");
const desktopEnd = css.indexOf(
    "@media (min-width: 1600px) and (min-height: 850px)",
    desktopStart
);
const desktopCss = desktopStart >= 0 && desktopEnd > desktopStart
    ? css.slice(desktopStart, desktopEnd)
    : "";

test("desktop quarterfinal cards use dedicated vertical spacing", () => {
    assert.notEqual(desktopCss, "");
    assert.match(
        desktopCss,
        /\.round-quarter\s*\{[^}]*justify-content:\s*space-between;[^}]*gap:\s*clamp\(4px,\s*0\.45vh,\s*6px\);[^}]*\}/s
    );
    assert.match(
        desktopCss,
        /\.round-quarter\s+\.match-wrapper\s*\{[^}]*padding:\s*0;[^}]*\}/s
    );
});

test("other desktop rounds retain the compact wrapper spacing", () => {
    assert.match(
        desktopCss,
        /\.match-wrapper\s*\{\s*min-height:\s*0;\s*padding:\s*1px 0;\s*\}/
    );
});
