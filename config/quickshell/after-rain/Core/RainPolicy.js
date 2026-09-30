.pragma library

function validMode(mode) {
    return ["off", "light", "normal", "heavy"].indexOf(mode) !== -1;
}

function preset(mode) {
    return ({light: [2, 3, 12, 24], normal: [4, 6, 24, 48],
             heavy: [7, 9, 42, 84]})[mode] || [0, 0, 0, 0];
}

// Largest-remainder allocation: deterministic, integer, never exceeds global cap.
function budgets(areas, mode) {
    const p = preset(mode);
    const targets = areas.map(a => Math.min(p[2], Math.max(p[1], Math.round(a * p[0] / 1000000))));
    const total = targets.reduce((a, b) => a + b, 0);
    if (total <= p[3]) return targets;
    const scaled = targets.map(t => t * p[3] / total);
    const result = scaled.map(Math.floor);
    let remaining = p[3] - result.reduce((a, b) => a + b, 0);
    const order = scaled.map((v, i) => i).sort((a, b) =>
        (scaled[b] - result[b]) - (scaled[a] - result[a]) || a - b);
    for (let i = 0; i < remaining; ++i) result[order[i]]++;
    return result;
}

function decode(text) {
    const value = JSON.parse(text);
    if (!value || value.schema !== 1 || !validMode(value.mode)
            || !validMode(value.lastActiveMode) || value.lastActiveMode === "off")
        throw new Error("Invalid rain state schema or mode");
    return value;
}
