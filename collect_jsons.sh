#!/usr/bin/env bash

# housekeeping - ensure we're in the correct directory OR add option so user can command script
# to download to specific place


IFS=$'\n'

# need database (flatfile for simplicity - sqlite?)
# database to hold filenames or checksums(?) of reports already uploaded to megaqc

# each assay has different project name convention (or subtitle?) so needs separate 'find' block
# save to assay-specific directory for ease later


# Directory to save downloaded JSON files into. Change according to policy.
JSONPATH=/MegaQC-jsons


download_files () {
    for i in $(dx find projects --name "002_*_$1_*"); do
    projectID=$(printf $i | awk -F " " '{print $1}')
    projectName=$(printf $i | awk -F " " '{print $3}')
        for j in $(dx find data --name "multiqc_data.json" --project $projectID); do
            dirName=$(printf $j | awk -F " " '{print $6}' | awk -F "/" '{print $6}')
            fileID=$(printf $j | awk -F " " '{print $7}' | tr -d '()')
            # INSERT CHECK for previous uploads (to prevent repeated downloads = cost)
            mkdir -p $JSONPATH/$1/$projectName/$dirName; dx download $fileID -o $JSONPATH/$1/$projectName/$dirName
            sqlite3 MegaQC_Uploads.sqlite "INSERT INTO megaQC_jsons VALUES ($projectName, $fileID, '0');"

        done
    done
}


# block for myeloid (project name suffix is MYE)
download_files MYE

# block for FH (project name suffix is FHC)
download_files FHC

# block for WES (project name suffix is TWE)
download_files TWE

# this block downloads gemini/TSOE reports (and hopefully nothing else) - follows different pattern so function above not used.
for i in $(dx find projects --name "002_*_clinicalgenetics"); do
    projectID=$(printf $i | awk -F " " '{print $1}')
    projectName=$(printf $i | awk -F " " '{print $3}')
    for j in $(dx find data --name "multiqc_data.json" --project $projectID); do
        dirName=$(printf $j | awk -F " " '{print $6}' | awk -F "/" '{print $6}')
        fileID=$(printf $j | awk -F " " '{print $7}' | tr -d '()')
        # INSERT CHECK for previous uploads (to prevent repeated downloads = cost)
        mkdir -p $JSONPATH/TSOE/$projectName/$dirName; dx download $fileID -o $JSONPATH/TSOE/$projectName/$dirName
        sqlite3 MegaQC_Uploads.sqlite "INSERT INTO megaQC_jsons VALUES ($projectName, $fileID, '0');"

    done
done
