# Bull's Eye analysis

The files used to run the analysis for our Bull's Eye story.

The processing tasks are inside:

  process.sh

The first task merges Texas census tract shapefiles with population csvs. The raw data is in the raw_data directory. The shapefiles are made available by the [U.S. Census](https://www.census.gov/cgi-bin/geo/shapefiles/index.php). The population counts can be found on the [American FactFinder](https://factfinder.census.gov/faces/nav/jsf/pages/index.xhtml).

The second task filters out just the columns we want. We run these tasks for 2000, 2010, 2011, 2012, 2013 and 2015.

All the merged data is put into the edits directory.

We've also included QGIS file with a choropleth map made out of some of the shapefiles. That's within the qgis directory.
