#!/usr/bin/env bash

# script to upload to megaqc
# duplicate uploads should not be present if download script is working
# but megaqc will ignore attempts with identical config creation dates (or some other metadata)


# pass instrument to script at command line
INSTRUMENT=$1


# Directory where JSONS are saved (policy)
JSONPATH=/MegaQC-jsons


# need upload block for each assay and each instrument (to allow for different upload user & filtering in megaqc dashboards)


for report in $(find $JSONPATH/* -name '_$INSTRUMENT_*/*.json'); do 
    megaqc upload $report
done

# add name/ID to upload database