#!/bin/bash

[[ -d gh ]] || mkdir gh
[[ -d sources ]] || mkdir sources
./gh-scrape.sh
./gh-get-meta.sh
./gh-one-liner.sh
./gh-db-insert.sh
