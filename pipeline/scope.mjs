// Which GO Transit BUS routes belong on the Toronto map (17.09.2026). The GO
// feed covers the whole Greater Golden Horseshoe — 38 bus routes from Niagara
// Falls and Brantford to Peterborough — while the map's road frame ends at
// Barrie in the north, Bolton and Brampton in the west and Pickering in the
// east (pipeline/pbf-tiles.py). A GO bus is on the map when EVERY stop it
// serves lies inside that frame: the engine draws a line whole or not at all,
// and a route with one stop past the frame would run into empty ground. The
// GO trains are not scoped here — the rail file reaches as far as they do.
//
// Result: data/scope.json → { go: [route_id…] }. Run by download.sh after the
// feeds; build.mjs refuses to guess and requires the file.
import { writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { iterCsv, readCsv } from './lib/csv.mjs';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const GD = join(ROOT, 'data/gtfs-go');

// must match pipeline/pbf-tiles.py
const S = 43.55, N = 44.40, W = -79.80, E = -79.07;

const t0 = Date.now();
const log = (m) => console.log(`[scope ${((Date.now() - t0) / 1000).toFixed(0)}s] ${m}`);

const candidates = new Map();
for (const r of await readCsv(join(GD, 'routes.txt'))) {
  if ((r.route_type || '').trim() === '3') candidates.set(r.route_id, (r.route_short_name || '').trim());
}
log(`kandydatów: ${candidates.size} linii autobusowych GO`);

const inside = new Map();
for await (const s of iterCsv(join(GD, 'stops.txt'))) {
  const lat = Number(s.stop_lat), lon = Number(s.stop_lon);
  if (Number.isFinite(lat) && Number.isFinite(lon)) inside.set(s.stop_id, lat >= S && lat <= N && lon >= W && lon <= E);
}
const t2r = new Map();
for await (const t of iterCsv(join(GD, 'trips.txt'))) {
  if (candidates.has(t.route_id)) t2r.set(t.trip_id, t.route_id);
}
const rStops = new Map();
for await (const st of iterCsv(join(GD, 'stop_times.txt'))) {
  const rid = t2r.get(st.trip_id);
  if (!rid) continue;
  let s = rStops.get(rid);
  if (!s) rStops.set(rid, (s = new Set()));
  s.add(st.stop_id);
}

const go = [], out = [];
for (const [rid, stops] of rStops) {
  let n = 0, ins = 0;
  for (const sid of stops) { if (inside.get(sid) === undefined) continue; n++; if (inside.get(sid)) ins++; }
  if (n && ins === n) go.push(rid); else out.push(`${candidates.get(rid)} (${Math.round(100 * ins / n)}%)`);
}
go.sort();
log(`wybrano: ${go.length} linii GO: ${go.map((id) => candidates.get(id)).sort((a, b) => a - b).join(', ')}`);
log(`poza kadrem: ${out.length}: ${out.sort().join(', ')}`);
writeFileSync(join(ROOT, 'data/scope.json'), JSON.stringify({ go }, null, 0));
log('zapisano data/scope.json');
