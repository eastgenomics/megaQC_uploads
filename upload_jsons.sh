#!/usr/bin/env bash

# script to upload to megaqc
# duplicate uploads should not be present if download script is working
# but megaqc will ignore attempts with identical config creation dates (or some other metadata)

# Each sequencer (instrument) will be associated with a unique megaqc user. Each of these users will run this script, giving the sequencer ID as an argument.
# pass instrument to script at command line
INSTRUMENT=$1


# Directory where JSONS are saved (policy)
#JSONPATH=/MegaQC-jsons
JSONPATH=/home/chris/Dev/MegaQC-jsons


# need upload block for each assay and each instrument (to allow for different upload user & filtering in megaqc dashboards)
INSTRUMENT_FOLDERS=$JSONPATH/*/*_${INSTRUMENT}_*/*/

# look in separate area so only complete downloads are used
for runfolder in $INSTRUMENT_FOLDERS; do
    for report in $(find $runfolder -name '*.json'); do
        dir=$(basename $report)
        echo Runfolder - $dir
        # Upload report to MegaQC
        echo 'Uploading to MegaQC'
        megaqc upload $report
        # Update upload database to show file as uploaded.
        echo 'Updating upload database'
        sqlite3 MegaQC_Uploads.sqlite "UPDATE megaQC_jsons SET Uploaded=1 WHERE Runfolder=\"$dir\";"
    done
done

