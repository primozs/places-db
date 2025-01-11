#!/bin/sh

mkdir -p output
rm -rf tmp
mkdir -p tmp

unzip ./input/airports-data.zip -d ./tmp
unzip ./input/cities-data.zip -d ./tmp

# nim c -r src/places_db.nim

rm -rf output/places.duckdb
duckdb output/places.duckdb < ./init_duckdb.sql
duckdb output/places.duckdb < ./init_duckdb2.sql
