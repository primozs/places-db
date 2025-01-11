import os, strformat, json, strutils
import ./geojson

type AirportData = object
  id: string
  ident: string
  `type`: string
  name: string
  latitude_deg: string
  longitude_deg: string
  elevation_ft: string
  continent: string
  iso_country: string
  iso_region: string
  municipality: string
  scheduled_service: string
  gps_code: string
  iata_code: string
  local_code: string
  home_link: string
  wikipedia_link: string
  keywords: string

proc toSql() =
  let dir = "input" / "regions"
  var sqlStr = ""
  for k, p in walkDir(dir):
    sqlStr.add &"INSERT INTO regions SELECT * FROM ST_Read('{p}');\n"

  var f = open("tmp" / "csql.sql", fmWrite)
  f.write(sqlStr)

proc toDigitFloat(str: string): float =
  if str == "": return 0.0
  var e: string
  for c in str.strip():
    if c.isDigit():
      e.add c
  return e.parseFloat()

proc processAirports() =
  let airportsFile = "tmp" / "airports-data.json"
  let output = "tmp" / "airports.geojson"
  let f = open(airportsFile, fmRead)
  let text = f.readAll()
  let txtJson = text.parseJson()
  let airports: seq[AirportData] = txtJson.to(seq[AirportData])

  var features: seq[Feature] = @[]
  for airport in airports:
    let lat = airport.latitude_deg.parseFloat()
    let lon = airport.longitude_deg.parseFloat()
    # echo airport.name, " ", airport.elevation_ft
    let elev = airport.elevation_ft.toDigitFloat() * 0.3048
    let name = airport.name
    let country_code = airport.iso_country
    let region_code = airport.iso_region
    let municipality = airport.municipality

    let point = initPoint(@[lon, lat, elev])
    let properties: JsonNode = %*{
      "name": name,
      "country_code": country_code,
      "region_code": region_code,
      "municipality": municipality,
      "elev": elev,
      "type": "airport"
    }
    let feature = Feature(geometry: point, properties: properties)
    features.add feature

  let fc = FeatureCollection(features: features)
  let fo = open(output, fmWrite)
  fo.write( %* fc)


type CityData = object
  geoNameId: string
  name: string
  asciiName: string
  alternateNames: string
  latitude: float
  longitude: float
  featureClass: string
  featureCode: string
  countryCode: string
  cc2: string
  admin1Code: string
  admin2Code: string
  admin3Code: string
  admin4Code: string
  population: string
  elevation: string
  dem: string
  timezone: string
  modificationDate: string


proc processCities() =
  let inputFile = "tmp" / "cities-data.json"
  let outputFile = "tmp" / "cities.geojson"
  let f = open(inputFile, fmRead)
  let text = f.readAll()
  let txtJson = text.parseJson()
  let items: seq[CityData] = txtJson.to(seq[CityData])

  var features: seq[Feature] = @[]
  for item in items:
    let lat = item.latitude
    let lon = item.longitude
    # echo airport.name, " ", airport.elevation_ft
    let elev = item.elevation.toDigitFloat
    let name = item.name
    let country_code = item.countryCode
    let region_code = ""
    let municipality = ""

    let point = initPoint(@[lon, lat, elev])
    let properties: JsonNode = %*{
      "name": name,
      "country_code": country_code,
      "region_code": region_code,
      "municipality": municipality,
      "elev": elev,
      "type": "cities"
    }
    let feature = Feature(geometry: point, properties: properties)
    features.add feature

  let fc = FeatureCollection(features: features)
  let fo = open(outputFile, fmWrite)
  fo.write( %* fc)


when isMainModule:
  processAirports()
  processCities()
