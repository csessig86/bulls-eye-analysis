#!/bin/bash

# We can use parameters to skip certain tasks within this script
# Example:
# sh process.sh --skip=convert

# Pull out parameters and make them an array
# Called params_array
params=$1
prefix="--skip="
param=${params#$prefix}
IFS=', ' read -r -a params_array <<< ${param}


YEARS=( 15 13 12 11 10 00 )

if [[ " ${params_array[*]} " != *" merge "* ]]; then
  cd raw_data/census_tracts

  for year in "${YEARS[@]}";
  do
    echo "Current year: ${year}"
    EDIT_ONE="edit_a_tracts_pop_${year}"

    if [[ " ${year} " == *" 00 "* ]]; then
      RAW_TRACTS_1="tr48_d${year}"
      RAW_TRACTS="tr48_d${year}_concat"
      RAW_POP="DEC_${year}_SF1_P001"

      ogr2ogr -dialect sqlite -sql "select COUNTY, STATE || COUNTY || CASE WHEN length(TRACT) = 4 THEN TRACT || '00' ELSE TRACT END as GEOID, geometry FROM $RAW_TRACTS_1" $RAW_TRACTS.shp $RAW_TRACTS_1.shp -progress
    elif [[ " ${year} " == *" 10 "* ]]; then
      RAW_TRACTS="tl_20${year}_48_tract10"
      RAW_POP="DEC_${year}_SF1_P1"
    else
      RAW_TRACTS="tl_20${year}_48_tract"
      RAW_POP="ACS_${year}_5YR_B01003"
    fi

    # 2010 data has different GEO ID, of course
    if [[ " ${year} " == *" 10 "* ]]; then
      YR_ADD="10"
    else
      YR_ADD=""
    fi

    # Rename columns in population csv
    sed -i '1s/GEO.id/GEO_id/' $RAW_POP.csv
    sed -i '1s/GEO.id2/GEO_id2/' $RAW_POP.csv
    sed -i '1s/GEO.display-label/GEO_display_label/' $RAW_POP.csv

    echo "Merge tracts, population csv"
    ogr2ogr -sql "select $RAW_TRACTS.*, $RAW_POP.* from $RAW_TRACTS left join '$RAW_POP.csv'.$RAW_POP on $RAW_TRACTS.GEOID$YR_ADD = $RAW_POP.GEO_id2" $EDIT_ONE.shp $RAW_TRACTS.shp -progress
  done

  # Move newly created files to correct directory
  mv edit_* ../../edits
  cd ../../
fi


if [[ " ${params_array[*]} " != *" filter "* ]]; then
  cd edits/

  for year in "${YEARS[@]}";
  do
    echo "Current year: ${year}"
    EDIT_ONE="edit_a_tracts_pop_${year}"
    EDIT_TWO="edit_b_tracts_pop_format_${year}"

    echo "Select columns, convert some to integers"
    if [[ " ${year} " == *" 00 "* ]]; then
      ogr2ogr -sql "SELECT DEC_${year}_SF1 as geo_id, DEC_${year}_S_1 as geo_id_two, DEC_${year}_S_2 as geo_label, tr48_d${year}_c as county_fps, cast(DEC_${year}_S_3 as float(10,0)) as total_pop FROM $EDIT_ONE" $EDIT_TWO.shp $EDIT_ONE.shp -progress
    elif [[ " ${year} " == *" 10 "* ]] ; then
      ogr2ogr -sql "SELECT DEC_${year}_SF1 as geo_id, DEC_${year}_S_1 as geo_id_two, DEC_${year}_S_2 as geo_label, tl_20${year}__1 as county_fps, cast(DEC_${year}_S_3 as float(10,0)) as total_pop FROM $EDIT_ONE" $EDIT_TWO.shp $EDIT_ONE.shp -progress
    else
      ogr2ogr -sql "SELECT ACS_${year}_5YR as geo_id, ACS_${year}_5_1 as geo_id_two, ACS_${year}_5_2 as geo_label, tl_20${year}__1 as county_fps, cast(ACS_${year}_5_3 as float(10,0)) as total_pop, cast(ACS_${year}_5_4 as float(10,0)) as moe FROM $EDIT_ONE" $EDIT_TWO.shp $EDIT_ONE.shp -progress
    fi
  done

  cd ../../
fi