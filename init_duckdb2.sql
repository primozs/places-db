install spatial;
load spatial;

CREATE SEQUENCE id_places_sequence START 1;

CREATE TABLE places (
	id INTEGER DEFAULT nextval('id_places_sequence'),
	name VARCHAR,
	country_code VARCHAR,
	region_code VARCHAR,
	municipality VARCHAR,
	elev DOUBLE,
	type VARCHAR NOT NULL,
	geom GEOMETRY
);

-- INSERT INTO places SELECT nextval('id_places_sequence'), * FROM ST_Read('tmp/airports.geojson');
-- INSERT INTO places SELECT nextval('id_places_sequence'), * FROM ST_Read('tmp/cities.geojson');

insert into places
select
	nextval('id_places_sequence'),
	name,
	iso_country as country_code, 
	iso_region as region_code,
	municipality as municipality,
	if (elevation_ft = '', 0, elevation_ft::DOUBLE * 0.3048)  as elev,
	'airport' as type,
	ST_Point(longitude_deg::DOUBLE, latitude_deg::DOUBLE) AS geom
from read_json('tmp/airports-data.json');

insert into places
select
	nextval('id_places_sequence'),
	name,
	countryCode as country_code, 
	'' as region_code,
	'' as municipality,
	if (elevation = null, null, elevation)  as elev,
	'cities' as type,
	ST_Point(longitude, latitude) AS geom
from read_json('tmp/cities-data.json');

BEGIN TRANSACTION;
insert into places
SELECT 
  nextval('id_places_sequence'),
	name, 
	'' as country_code, 
	'' as region_code,
	'' as municipality,
	ele as elev,
	'pass' as type,
	ST_Point(lon, lat) AS geom,
	 FROM 
		read_csv('input/mountain-peaks.csv', 
			header = true,
			columns = {
        'name': 'VARCHAR',				
        'lat': 'DOUBLE',
        'lon': 'DOUBLE',					
  			'file': 'VARCHAR',
				'ele': 'DOUBLE'
      }
		);
COMMIT;

insert into places
select
	nextval('id_places_sequence'),
	name,
	''as country_code, 
	'' as region_code,
	'' as municipality,
	null as elev,
	'landing' as type,
	ST_Point(lon, lat) AS geom
from read_json('input/landings.json');

insert into places
select
  nextval('id_places_sequence'),
	name,
	iso2 as country_code,
	'' as region_code,
	'' as municipality,
	alt as elev,
	'takeoff' as type,
	ST_Point(lon, lat) AS geom
from read_json('input/pge-takeoffs.json');

CREATE INDEX geom_places_idx ON places USING RTREE (geom);

insert into places
select 
  nextval('id_places_sequence'),
	name,
	'' as country_code,
	'' as region_code,
	'' as municipality,
	altitude as elev,
	'takeoff' as type,
	geom
from
(select 
	name,
	ST_Point(lon, lat) AS geom,
	altitude,
	(select count() from places p where type == 'takeoff' and ST_Distance_Sphere(ST_Point(lat, lon), p.geom)<=200) as c  
from read_json('input/pgspots-takeoffs.json')
where c == 0);

DROP INDEX IF EXISTS geom_places_idx;
CREATE INDEX geom_places_idx ON places USING RTREE (geom);

insert into places
select 
	nextval('id_places_sequence'),
	name,
	'' as country_code,
	'' as region_code,
	'' as municipality,
	alt as elev,
	'takeoff' as type,
	geom
from
(select 
	name,
	ST_Point(lon, lat) AS geom,
	alt,
	(select count() from places p where type == 'takeoff' and ST_Distance_Sphere(ST_Point(lat, lon), p.geom)<=200) as c  
from read_json('input/dhv-takeoffs.json')
where c == 0);

DROP INDEX IF EXISTS geom_places_idx;
CREATE INDEX geom_places_idx ON places USING RTREE (geom);

insert into places
select 
	nextval('id_places_sequence'),
	name,
	'' as country_code,
	'' as region_code,
	'' as municipality,
	alt as elev,
	'takeoff' as type,
	geom
from
(select 
	name,
	ST_Point(lon, lat) AS geom,
	alt,
	(select count() from places p where type == 'takeoff' and ST_Distance_Sphere(ST_Point(lat, lon), p.geom)<=200) as c  
from read_json('input/flyland-takeoffs.json')
where c == 0);

DROP INDEX IF EXISTS geom_places_idx;
CREATE INDEX geom_places_idx ON places USING RTREE (geom);


UPDATE places p
SET country_code = (
		select 
			country_a2 
		from countries c 
		where ST_Contains(c.geom, p.geom)
	)
where p.country_code = '';

UPDATE places p
set region_code = (
	select if (region_code == null, '', a.region_code) from admin1 a where ST_Contains(a.geom, p.geom)
)
where p.region_code = '';

UPDATE places p
set municipality = (
	select if (name == null, '', a.name) from admin1 a where ST_Contains(a.geom, p.geom)
)
where p.municipality = '';

DROP INDEX IF EXISTS geom_places_idx;
CREATE INDEX geom_places_idx ON places USING RTREE (geom);
