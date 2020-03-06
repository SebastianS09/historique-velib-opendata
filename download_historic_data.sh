#!/usr/bin/env bash

set -e

wget -O stations.zip 'https://github.com/lovasoa/historique-velib-opendata/releases/download/latest/stations.zip'

unzip -q -o stations.zip -d stations

rm stations.zip
