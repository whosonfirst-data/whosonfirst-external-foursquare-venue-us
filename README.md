# whosonfirst-external-foursquare-venue-us

Who's On First ancestry data (parent ID and hierarchy) for Foursquare venues in United States.

## Description

This repository contains CSV files mapping individual records in the Foursquare Open Places release, located in the United States, to their Who's On First "parent" and "ancestor" (hierarchy) records. This data was compiled using the [whosonfirst/go-whosonfirst-external](https://github.com/whosonfirst/go-whosonfirst-external?tab=readme-ov-file#assign-ancestors) package to "reverse geocode" each record using the [whosonfirst/go-whosonfirst-spatial-pmtiles](https://github.com/whosonfirst/go-whosonfirst-spatial-pmtiles) package.

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

Do these records really need to store the geometry associated with the Foursquare ID since they are already included in the Foursquare exports? Maybe not. Do these records really need to each store their complete Who's On First hierachies rather than referencing a separate file mapping parent IDs to hierarchies? Maybe. Do these files really need to store a geohash? Maybe not.

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

## See also

* https://opensource.foursquare.com/os-places/
* https://github.com/whosonfirst/go-whosonfirst-external