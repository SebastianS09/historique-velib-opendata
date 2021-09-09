#!/usr/bin/env bash
set -e
set -o pipefail

if [ -z "$GITHUB_TOKEN" ]
then
  echo "Missing \$GITHUB_TOKEN"
  exit 1
fi

zip -r stations.zip historique_stations.csv

GAPI=https://api.github.com/repos/SebastianS09/historique-velib-opendata
AUTH="-HAuthorization: token $GITHUB_TOKEN"

LAST_RELEASE_JSON=$(mktemp)

echo "Downloading last release information"
curl -sS "$AUTH" "$GAPI/releases/latest" > "$LAST_RELEASE_JSON"

UPLOAD_URL=$(
    < "$LAST_RELEASE_JSON" \
    jq -r '.upload_url' |
    sed 's/{.*}//'
)

echo "Uploading new version"
NEW_ASSET_ID=$(
  curl -sS --fail "$AUTH" \
    --retry 7 --retry-delay 0 \
    -H "Content-Type: application/zip" \
    "$UPLOAD_URL?name=stations-$(date -u +"%Y-%m-%dT%H%MZ").zip" \
    --data-binary "@stations.zip" |
  jq -r '.id'
)

echo "Removing old release asset"
curl -sS -XDELETE "$AUTH" \
  "$GAPI/releases/assets/$(
      <"$LAST_RELEASE_JSON" \
      jq -r '.assets[]|select(.name == "stations.zip")|.id'
  )"

echo "Renaming asset file"
curl -sS --fail --retry 7 --retry-delay 0 -XPATCH "$AUTH" \
  "$GAPI/releases/assets/$NEW_ASSET_ID" \
  --data-binary "{\"name\":\"stations.zip\",\"label\":\"Latest data per station as of $(date)\"}"
