# Toronto Public Transport — interactive map

Interactive, poster-grade map of public transport in **Toronto and York
Region**: the TTC's 204 bus routes, the ten streetcar routes and their six
Blue Night siblings, the three subway lines and the two light rail lines 5
Eglinton and 6 Finch West; York Region Transit whole, Viva rapidways
included; the GO buses of the frame; and the seven GO train lines with UP
Express drawn to their real ends — along the real street and track geometry.

## Live

**https://agcghub.github.io/toronto-bus-map/** — GitHub Pages serves
`main:/docs`; local build on port 8181 (`npm run serve`).

Four feeds, one network. The TTC's own **Merged GTFS** on the City of
Toronto open data portal
(<https://open.toronto.ca/dataset/merged-gtfs-ttc-routes-and-schedules/>),
refreshed with every board period; **York Region Transit** from yrt.ca;
**GO Transit** and **UP Express** from Metrolinx's open data (each with its
MobilityDatabase mirror as the fallback). Since 17.09.2026 the frame is
94 × 58 km — the city, York Region up to Georgina and Barrie, Brampton and
Bolton — and the rail file reaches as far as the GO trains do.

| feed | route_type | scope | graph |
|---|---|---|---|
| TTC buses | 3 | all 204 routes — local 7–189, Blue Night 300–399, express 900–996 | OSM roadways |
| York Region Transit | 3 | all 125 routes — the Viva rapidways, 1–522, the 300s expresses | OSM roadways |
| GO Transit buses | 3 | the 12 routes whose every stop lies inside the frame (`pipeline/scope.mjs`) | OSM roadways |
| TTC streetcars | 0 | 501–512 and the Blue Night 301–312, family red | `railway=tram` |
| TTC rapid transit | 1 (+ 0 for lines 5 and 6) | lines 1, 2, 4, 5, 6 in the TTC's own colours | `railway=subway` + `light_rail` |
| GO trains, UP Express | 2 | Lakeshore West and East, Milton, Kitchener, Barrie, Richmond Hill, Stouffville, UP — in Metrolinx's colours | `railway=rail` |

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

Line keys need nothing invented for the TTC: its numbers are unique across
every mode — rapid transit 1–6, buses 7–189, 300–399 and 900–996, streetcars
501–512 and 301–312 — so every TTC key is the number the street signs show.
York Region and GO reuse those numbers (a YRT 12, a GO 19 against the
TTC's), so their keys carry `Y` and `GO` and print the bare number; the Viva
lines print as the region brands them ("Viva Blue"), the GO trains by line
name, the airport train as "UP". Lists run TTC, then York Region (Viva
first), then GO. York Region shouts its poles ("HWY 7 / MARTIN GROVE");
`usName` brings them to title case with the flags' abbreviations kept (Av,
Rd, Blvd, Cres…); the YRT headsigns drop their compass tag ("- NB"), the GO
headsigns their route prefix ("LW - "), the GO stations their " GO".

## Pipeline

`npm run download` fetches the four feeds (the TTC resource url is read
from the CKAN API), computes the GO bus scope and cuts the OSM extracts.
**The OSM data comes from Geofabrik, not Overpass**: Geofabrik has no
Toronto extract, so `ontario-latest.osm.pbf` comes down once and
`pipeline/pbf-tiles.py` (needs `pip3 install --user osmium`) cuts a 6 × 9
road grid and the rail file (Kitchener to Niagara Falls, Barrie to Oshawa)
out of it in one pass, writing exactly the JSON shape Overpass would have
returned, node ids included.

`npm run build` map-matches every line (HMM/Viterbi on the OSM graphs) and
writes GeoJSON to `data/out/`; `npm run lines` adds the line-by-line view;
`npm run audit` checks the drawn result. `npm run serve` hosts the map at
<http://localhost:8181>.

Data: TTC (Merged GTFS, City of Toronto Open Data) · York Region Transit ·
GO Transit and UP Express (Metrolinx) · base map © OpenFreeMap /
OpenMapTiles / OpenStreetMap contributors.

## 17.09.2026 — requested fixes

- **The region north of Steeles.** The map was cut off at the city line; now York Region Transit rides whole (125 routes, Viva included, out to Newmarket and Georgina), the GO buses that stay inside the frame (12 routes, `pipeline/scope.mjs` — a GO bus is on the map when every stop it serves lies inside the frame) and the GO trains with UP Express, drawn to Kitchener, Niagara Falls, Barrie and Oshawa in Metrolinx's colours with the trunk treatment. The road grid grew from 5 × 5 to 6 × 9 tiles (43.55–44.40 / −79.80–−79.07), the rail file to 160 × 145 km.
- **GO train branches.** `allVariants` with `foldSubsets`: every maximal stop pattern is a rep, and an express working that only skips stations folds into the all-stops pattern — what survives are the real ends (Aldershot, West Harbour, Niagara Falls on Lakeshore West).
- **Keys.** York Region `Y…`, GO buses `GO…`, both printed bare; lists run TTC → York Region (Viva first) → GO; the Blue Night rank is tested on the TTC key, so York Region's 300s expresses stay day lines.
