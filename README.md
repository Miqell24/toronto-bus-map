# Toronto Public Transport — interactive map

Interactive, poster-grade map of the **TTC** network: 204 bus routes, the ten
streetcar routes and their six Blue Night siblings, the three subway lines and
the two light rail lines 5 Eglinton and 6 Finch West — drawn along the real
street and track geometry.

## Live

**https://miqell24.github.io/toronto-bus-map/** — GitHub Pages serves
`main:/docs`; local build on port 8181 (`npm run serve`).

Everything comes from ONE feed — the TTC's own **Merged GTFS** on the City of
Toronto open data portal
(<https://open.toronto.ca/dataset/merged-gtfs-ttc-routes-and-schedules/>),
refreshed with every board period. The TTC is the whole map: the City of
Toronto plus the few routes that cross into Mississauga, Vaughan and Markham,
44 × 50 km, so no scope rule is needed.

| mode | route_type | scope | graph |
|---|---|---|---|
| buses | 3 | all 204 routes — local 7–189, Blue Night 300–399, express 900–996 | OSM roadways |
| streetcars | 0 | 501–512 and the Blue Night 301–312, family red | `railway=tram` |
| rapid transit | 1 (+ 0 for lines 5 and 6) | lines 1, 2, 4, 5, 6 in the TTC's own colours | `railway=subway` + `light_rail` |

**Colours.** The rapid transit colours come from the feed itself — the TTC
fills `route_color` on every route, and on lines 1–6 they are the line colours
of its own map: yellow 1 Yonge–University, green 2 Bloor–Danforth, purple 4
Sheppard, orange 5 Eglinton, grey 6 Finch West. The feed also paints the
expresses green and the Blue Night routes blue; those stay in the family's
navy, because colour means the *mode* on these maps. Lines 5 and 6 are coded
as streetcars (route_type 0) in the feed but numbered, coloured and signed as
rapid transit by the TTC, so they ride the rapid transit cfg.

**Line 5 ships no shapes.** Its trips carry no `shape_id`, so the station
sequence is the matching observation (pseudo-matching on the light-rail graph,
as Olsztyn and Istanbul's buses do).

**Headsigns** carry the whole announcement — "East - 10 Van Horne towards
Victoria Park", "Yonge-University Line towards Finch Station" — and the panel
prints them as directions, so everything up to "towards" is dropped; the
short-turn signs without a "towards" stay as they are.

Line keys need nothing invented: the TTC's numbers are unique across every
mode — rapid transit 1–6, buses 7–189, 300–399 and 900–996, streetcars 501–512
and 301–312 — so every key is the number the street signs show.

## Pipeline

`npm run download` fetches the feed (the resource url is read from the CKAN
API) and cuts the OSM extracts. **The OSM data comes from Geofabrik, not
Overpass**: Geofabrik has no Toronto extract, so `ontario-latest.osm.pbf`
comes down once and `pipeline/pbf-tiles.py` (needs `pip3 install --user
osmium`) cuts a 5 × 5 road grid and the rail file out of it in one pass,
writing exactly the JSON shape Overpass would have returned, node ids
included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graphs) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view;
`npm run audit` checks the drawn result. `npm run serve` hosts the map at
<http://localhost:8181>.

Data: TTC (Merged GTFS, City of Toronto Open Data) ·
base map © OpenFreeMap / OpenMapTiles / OpenStreetMap contributors.
