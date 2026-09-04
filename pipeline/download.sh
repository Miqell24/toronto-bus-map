#!/usr/bin/env bash
# Downloads input data: the TTC GTFS, the OSM extract (Geofabrik), MapLibre GL.
# Everything is cached — re-running only fetches what is missing.
#
# Toronto: the TTC publishes ONE feed for every mode it runs — the "Merged
# GTFS" on the City of Toronto open data portal
# (open.toronto.ca/dataset/merged-gtfs-ttc-routes-and-schedules), refreshed
# with every board period. The download link is the CKAN resource; the
# package id is stable, the resource url is read from the API so a new upload
# keeps working.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p data/osm/tiles web/vendor

# pyosmium does the cutting; it is the one dependency outside Node here.
need_osmium () {
  python3 -c "import osmium" 2>/dev/null && return 0
  echo "brak pakietu osmium — zainstaluj: pip3 install --user osmium" >&2
  return 1
}

# 1) GTFS — the resource url from the CKAN package (falls back to the 2026-07 one)
if [ ! -f data/gtfs/routes.txt ]; then
  echo "== TTC Merged GTFS =="
  URL=$(curl -s "https://ckan0.cf.opendata.inter.prod-toronto.ca/api/3/action/package_show?id=merged-gtfs-ttc-routes-and-schedules" \
    | python3 -c "import json,sys; r=[x for x in json.load(sys.stdin)['result']['resources'] if x['format'].upper()=='ZIP']; print(r[0]['url'])" 2>/dev/null \
    || echo "https://ckan0.cf.opendata.inter.prod-toronto.ca/dataset/b811ead4-6eaf-4adb-8408-d389fb5a069c/resource/c920e221-7a1c-488b-8c5b-6d8cd4e85eaf/download/completegtfs.zip")
  curl -fL --retry 3 --max-time 900 -o data/ttc-gtfs.zip "$URL"
  mkdir -p data/gtfs
  unzip -q -o data/ttc-gtfs.zip -d data/gtfs
fi

# 2) OSM — from the Geofabrik extract, not Overpass. Geofabrik has no Toronto
#    extract, so the whole of Ontario comes down (~1.1 GB) and
#    pipeline/pbf-tiles.py cuts the 5 × 5 road grid and the rail file out of
#    it in one pass, writing exactly the JSON shape Overpass would have
#    returned (ways with tags, NODE IDS and geometry — buildGraph silently
#    drops ways without el.nodes).
if [ ! -f data/osm/tiles/t25.json ] || [ ! -f data/osm/toronto-rail.json ]; then
  need_osmium
  if [ ! -f data/ontario-latest.osm.pbf ]; then
    echo "== Geofabrik ontario-latest.osm.pbf =="
    curl -fL --retry 5 --retry-delay 5 -C - --max-time 3600 -o data/ontario-latest.osm.pbf \
      "https://download.geofabrik.de/north-america/canada/ontario-latest.osm.pbf"
  fi
  echo "== cutting OSM tiles out of the extract =="
  python3 pipeline/pbf-tiles.py
fi

# 3) MapLibre GL (vendored, no CDN at runtime)
if [ ! -f web/vendor/maplibre-gl.js ]; then
  echo "== MapLibre GL =="
  curl -fL --retry 3 -o web/vendor/maplibre-gl.js  https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js
  curl -fL --retry 3 -o web/vendor/maplibre-gl.css https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css
fi

echo "OK — data ready:"
du -sh data/gtfs data/osm 2>/dev/null || true
