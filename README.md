# whosonfirst-external-foursquare-venue-us

Who's On First ancestry data (parent ID and hierarchy) for Foursquare venues in United States.

## Description

This repository contains CSV files mapping individual records in the [Foursquare Open Places](https://opensource.foursquare.com/os-places/) dataset, located in the United States, to their Who's On First "parent" and "ancestor" (hierarchy) records.

This data was compiled using the [whosonfirst/go-whosonfirst-external](https://github.com/whosonfirst/go-whosonfirst-external?tab=readme-ov-file#assign-ancestors) package to "reverse geocode" each record using the [whosonfirst/go-whosonfirst-spatial-pmtiles](https://github.com/whosonfirst/go-whosonfirst-spatial-pmtiles) package.

Data is encoded as CSV rows with the following headers:

| Header | Notes |
| --- | --- |
| external:geometry | The WKT-encoded geometry for the record. |
| external:id | The unique ID assigned to the record (by Foursqure) |
| external:namespace | "fsq" |
| geohash | The geohash of the centroid associated with the external geometry |
| wof:country | The Who's On First country that the external record belongs to |
| wof:hierarchies | The Who's On First hierarchies associated with the external record, derived by doing a point-in-polygon lookup against the external geometry. |
| wof:parent_id | The Who's On First parent ID associated with the external record, derived by doing a point-in-polygon lookup against the external geometry. |

For example:

```
external:geometry,external:id,external:namespace,geohash,wof:country,wof:hierarchies,wof:parent_id
POINT(-64.7151968000689 18.348638265458188),50c383c3e4b009e3bc124040,4sq,hkmpcdcn,US,"[{""continent_id"":102191575,""country_id"":-1,""dependency_id"":85632169,""empire_id"":136253057,""locality_id"":101734681,""region_id"":85680575}]",101734681
POINT(-64.712322 18.348274),5154a227e4b00667a1c2d8be,4sq,hkmpce2z,US,"[{""continent_id"":102191575,""country_id"":-1,""dependency_id"":85632169,""empire_id"":136253057,""locality_id"":101734681,""region_id"":85680575}]",101734681
... and so on
```

Do these records really need to store the geometry associated with the Foursquare ID since they are already included in the Foursquare exports? Maybe not. Do these records really need to each store their complete Who's On First hierachies rather than referencing a separate file mapping parent IDs to hierarchies? Maybe. Do these files really need to store a geohash? Maybe not. Should there be a "belongs to" column which is the union of all the possible values to make it easier to determine if a venue is contained by a Who's On First ID (easier than querying multiple hierarchy dictionaries)? Maybe.

All of these are valid questions since their inclusion has a meaningful impact on the size of the CSV files and this repository. These details have not been finalized.

## File structure

All files are stored in the `data` directory using the following conventions:

```
+ data
  + {WHOSONFIRST_REGION_ID}
    - us-{WHOSONFIRST_REGION_ID}-{WHOSONFIRST_LOCALITY_ID}.csv.bz2
    - us-{WHOSONFIRST_REGION_ID}-{WHOSONFIRST_LOCALITY_ID}.csv.bz2
```

In the event that either `{WHOSONFIRST_REGION_ID}` or `{WHOSONFIRST_LOCALITY_ID}` are unknown they will be replaced by "xx". For example:

```
+ data
  + {WHOSONFIRST_REGION_ID}
    - us-{WHOSONFIRST_REGION_ID}-xx.csv.bz2
  + xx
    - us-xx-xx.csv.bz2
    - us-xx-{WHOSONFIRST_LOCALITY_ID}.csv.bz2
```

_Note that while it seems counter-intuitive to be able to know a locality ID but not its region ID it reflects data that needs to be corrected in the Who's On First administrative dataset. Life is complicated that way._

## DuckDB

These CSV files are meant to be "useable" from [DuckDB](https://duckdb.org/docs/data/csv/overview.html) or other similar database systems.

```
D DESCRIBE(SELECT * FROM read_csv('us-85680575-101734683.csv'));
┌────────────────────┬─────────────┬─────────┬─────────┬─────────┬─────────┐
│    column_name     │ column_type │  null   │   key   │ default │  extra  │
│      varchar       │   varchar   │ varchar │ varchar │ varchar │ varchar │
├────────────────────┼─────────────┼─────────┼─────────┼─────────┼─────────┤
│ external:geometry  │ VARCHAR     │ YES     │         │         │         │
│ external:id        │ VARCHAR     │ YES     │         │         │         │
│ external:namespace │ VARCHAR     │ YES     │         │         │         │
│ geohash            │ VARCHAR     │ YES     │         │         │         │
│ wof:country        │ VARCHAR     │ YES     │         │         │         │
│ wof:hierarchies    │ VARCHAR     │ YES     │         │         │         │
│ wof:parent_id      │ BIGINT      │ YES     │         │         │         │
└────────────────────┴─────────────┴─────────┴─────────┴─────────┴─────────┘
```

_Note: Unfortunately, DuckDB [does not support reading bz2-compressed CSV files yet](https://github.com/duckdb/duckdb/discussions/12232) which means you will need to decompress the files in this repository before using them. This is not ideal but because the uncompressed CSV data is so big it is a recognized "trade-off"._

For example:

```
D SELECT "external:id"  FROM read_csv(['us-85680575-101734683.csv', 'us-85681227-101734613.csv']) WHERE JSON("wof:hierarchies")[0]."locality_id" = 101734683 LIMIT 10;
┌──────────────────────────┐
│       external:id        │
│         varchar          │
├──────────────────────────┤
│ 56d89ea2cd107fd76b7835d4 │
│ 4bc71cd78b7c9c7464c935cf │
│ 4b8f012bf964a520e44333e3 │
│ 554918fa498ebde87bb273d4 │
│ 4cc18d5622ce46883a223e47 │
│ 4c49de921b430f47b42821c4 │
│ 4bdef0a3fe0e62b57c110606 │
│ 4dd3c5557d8b6704c7ac9c11 │
│ 4be61bb9cf200f471d3f143c │
│ 4b4f5927f964a5207a0227e3 │
├──────────────────────────┤
│         10 rows          │
└──────────────────────────┘
```

And to be something which can be used in conjunction with the source Foursquare data. For example here are 10 Foursquare places that are in the locality of [Cruz Bay](https://spelunker.whosonfirst.org/id/101734683) in the Virgin Islands:

```
D SELECT w."external:id", f.name  FROM read_csv(['us-85680575-101734683.csv', 'us-85681227-101734613.csv']) w, read_parquet('/usr/local/data/foursquare/parquet/*.parquet') f  WHERE f.fsq_place_id = w."external:id" AND JSON("wof:hierarchies")[0]."locality_id" = 101734683 LIMIT 10;
┌──────────────────────────┬─────────────────────────┐
│       external:id        │          name           │
│         varchar          │         varchar         │
├──────────────────────────┼─────────────────────────┤
│ 53f4d120498e975d53c8c0df │ Yogurt in love          │
│ 5689a639498e55b3af28e427 │ The Bowery              │
│ 4ed0f08ef790d0703911f770 │ Lone Star Taquería      │
│ 5af1ffde364d97002cfa1eeb │ On the Sea Charters     │
│ 4c311d323896e21eda94e690 │ Margarita Phil's        │
│ 4c47242419fde21ef25f0776 │ Kaleidoscope Video      │
│ 512f973345b0fa9f2372a111 │ ilanality Boat Charters │
│ 55156c2b498efa5147e50cf0 │ Jack's                  │
│ 4dda98ad7d8b3226643a167b │ Villa Hibiscus          │
│ 5512dc52498ef72936416f89 │ Sip & Chill             │
├──────────────────────────┴─────────────────────────┤
│ 10 rows                                  2 columns │
└────────────────────────────────────────────────────┘
```

## See also

* https://opensource.foursquare.com/os-places/
* https://github.com/whosonfirst/go-whosonfirst-external