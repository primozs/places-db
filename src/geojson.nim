# https://macwright.com/2015/03/23/geojson-second-bite
# https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/geojson/index.d.ts
# https://github.com/Turfjs/turf/blob/master/packages/turf-helpers/index.ts
{.push raises: [].}

import std/options
import std/json

# Position is an array of coordinates.
# https://tools.ietf.org/html/rfc7946#section-3.1.1
# Array should contain between two and three elements.
# The previous GeoJSON specification allowed more elements (e.g., which could be used to represent M values),
# but the current specification only allows X, Y, and (optionally) Z to be defined.
type Position* = seq[float]

# Bounding box
# https://tools.ietf.org/html/rfc7946#section-5

# Bounding box of the coordinate range of the object's Geometries, Features, or Feature Collections.
# The value of the bbox member is an array of length 2*n where n is the number of dimensions
# represented in the contained geometries, with all axes of the most southwesterly point
# followed by all axes of the more northeasterly point.
# The axes order of a bbox follows the axes order of geometries.
# https://tools.ietf.org/html/rfc7946#section-5
type BBox* = seq[float]

# type GeometryType* = enum
#   GeometryPoint = "Point"
#   GeometryMultiPoint = "MultiPoint"
#   GeometryLineString = "LineString"
#   GeometryMultiLineString = "MultiLineString"
#   GeometryPolygon = "Polygon"
#   GeometryMultiPolygon = "MultiPolygon"

type
  GeometryType* = enum
    Point, MultiPoint, LineString, MultiLineString, Polygon, MultiPolygon, GeometryCollection

  Geometry* = object
    `type`*: GeometryType
    coordinates*: JsonNode
    geometries*: seq[Geometry]
    bbox*: Option[BBox]

  Feature* = object
    geometry*: Geometry
    properties*: JsonNode
    id*: Option[JsonNode]
    bbox*: Option[BBox]

  FeatureCollection* = object
    features*: seq[Feature]
    bbox*: Option[BBox]

proc `%`*(g: Geometry): JsonNode =
  var res = newJObject()
  res["type"] = newJString($g.type)
  res["coordinates"] = g.coordinates
  # if g.geometries.len > 0:
  #   res["geometries"] = newJArray()
  #   for geom in g.geometries:
  #     try:
  #       res["geometries"].add(% geom)
  #     except:
  #       echo getCurrentExceptionMsg()
  if g.bbox.isSome:
    res["bbox"] = %* g.bbox
  return res

proc `%`*(f: Feature): JsonNode {.raises: [].} =
  var res = newJObject()
  res["type"] = newJString("Feature")
  res["geometry"] = % f.geometry
  res["properties"] = f.properties
  if f.id.isSome:
    res["id"] = % f.id
  if f.bbox.isSome:
    res["bbox"] = %* f.bbox
  return res

proc `%`*(fc: FeatureCollection): JsonNode {.raises: [].} =
  var res = newJObject()
  res["type"] = newJString("FeatureCollection")
  res["features"] = newJArray()
  for feature in fc.features:
    try:
      res["features"].add( % feature)
    except:
      echo getCurrentExceptionMsg()
  if fc.bbox.isSome:
    res["bbox"] = %* fc.bbox
  return res


proc initPoint*(coordinates: Position): Geometry =
  result = Geometry(
    type: Point,
    coordinates: %* coordinates,
    geometries: @[],
    bbox: none(BBox)
  )

proc initMultiPoint*(coordinates: seq[Position]): Geometry =
  result = Geometry(
    type: MultiPoint,
    coordinates: %* coordinates,
    geometries: @[],
    bbox: none(BBox)
  )

proc initLineString*(coordinates: seq[Position]): Geometry =
  result = Geometry(
    type: LineString,
    coordinates: %* coordinates,
    geometries: @[],
    bbox: none(BBox)
  )

proc initMultiLineString*(coordinates: seq[seq[Position]]): Geometry =
  result = Geometry(
    type: MultiLineString,
    coordinates: %* coordinates,
    geometries: @[],
    bbox: none(BBox)
  )

proc initPolygon*(coordinates: seq[seq[Position]]): Geometry =
  result = Geometry(
    type: Polygon,
    coordinates: %* coordinates,
    geometries: @[],
    bbox: none(BBox)
  )

proc initMultiPolygon*(coordinates: seq[seq[seq[Position]]]): Geometry =
  result = Geometry(
    type: MultiPolygon,
    coordinates: %* coordinates,
    geometries: @[],
    bbox: none(BBox)
  )

proc getCoord*(g: Geometry): Option[Position] =
  if g.type == Point:
    try:
      let pos = g.coordinates.to(Position)
      return some(pos)
    except:
      return none(Position)
  else:
    return none(Position)


proc getCoord*(f: Feature): Option[Position] =
  let g = f.geometry
  if g.type == Point:
    try:
      let pos = g.coordinates.to(Position)
      return some(pos)
    except:
      return none(Position)
  else:
    return none(Position)

proc getCoord*(p: Position): Option[Position] =
  return some(p)
