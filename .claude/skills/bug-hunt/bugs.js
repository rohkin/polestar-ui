// node bugs.js <!BugGrabber.lua> [filter=Polestar_UI] [localsMatch]
// Prints each BugGrabberDB.errors entry whose message+stack contains `filter`, newest info first line.
const fs = require("fs");
const [file, filter = "Polestar_UI", showLocals] = process.argv.slice(2);
if (!file) { console.error("usage: node bugs.js <!BugGrabber.lua> [filter] [localsMatch]"); process.exit(1); }
const entries = fs.readFileSync(file, "utf8").split(/\r?\n\{\r?\n/).slice(1);
const get = (e, k) => { const m = e.match(new RegExp('\\["' + k + '"\\] = ("(?:[^"\\\\]|\\\\.)*"|\\d+)')); return m ? m[1] : ""; };
let maxSession = 0;
const out = [];
for (const e of entries) {
  const s = +get(e, "session") || 0; maxSession = Math.max(maxSession, s);
  const msg = get(e, "message"), st = get(e, "stack");
  if (!(msg + st).includes(filter)) continue;
  let o = "== s" + s + " x" + get(e, "counter") + " t" + get(e, "time") + " " + msg + "\n" +
    st.replace(/\\n/g, "\n").replace(/Interface\/AddOns\//g, "").split("\n")
      .filter(l => l && !/BugGrabber/.test(l) && l !== '""').map(l => "   " + l).join("\n");
  if (showLocals && msg.includes(showLocals)) o += "\n" + get(e, "locals").replace(/\\n/g, "\n").slice(0, 2500);
  out.push(o);
}
console.log(entries.length + " entries, latest session " + maxSession + ", " + out.length + " match '" + filter + "'");
console.log(out.join("\n"));
