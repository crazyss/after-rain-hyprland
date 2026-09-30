import QtQuick
import QtTest
import "../../config/quickshell/after-rain/Core/RainPolicy.js" as Policy

TestCase {
    name: "RainPolicy"
    function test_modes() {
        verify(Policy.validMode("off"));
        verify(!Policy.validMode("invalid"));
        compare(Policy.budgets([3440 * 1440], "normal"), [20]);
        compare(Policy.budgets([3440 * 1440], "off"), [0]);
        compare(Policy.budgets([], "heavy"), []);
    }
    function test_hardCaps() {
        for (const mode of ["light", "normal", "heavy"]) {
            for (let screens = 1; screens <= 30; ++screens) {
                const areas = Array.from({length: screens}, (_, i) => (i + 1) * 2000000);
                const result = Policy.budgets(areas, mode);
                compare(result.length, screens);
                verify(result.reduce((a,b) => a+b, 0) <= Policy.preset(mode)[3]);
                verify(result.every(n => n >= 0 && n <= Policy.preset(mode)[2] && n === Math.floor(n)));
            }
        }
    }
    function test_stateValidation() {
        compare(Policy.decode('{"schema":1,"mode":"off","lastActiveMode":"heavy"}').lastActiveMode, "heavy");
        for (const text of ["{", "null", '{"schema":2}', '{"schema":1,"mode":"normal","lastActiveMode":"off"}']) {
            let failed = false;
            try { Policy.decode(text); } catch (_) { failed = true; }
            verify(failed);
        }
    }
}
