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
            # Check for previous uploads (to prevent repeated downloads = cost)
            if [ $(sqlite3 MegaQC_Uploads.sqlite "SELECT EXISTS(SELECT 1 FROM megaQC_jsons WHERE DNAnexus_fileID=$fileID LIMIT 1);") -eq 0 ]; then 
                mkdir -p $JSONPATH/$2/$projectName/$dirName; dx download $fileID -o $JSONPATH/$2/$projectName/$dirName
                json=$(ls $JSONPATH/$2/$projectName/$dirName) #THIS WON'T WORK IF MULTIPLE!! JUST A PLACEHOLDER
                # Check JSON to see if it's a proper run (i.e. more than 5 samples - threshold set by policy)
                if [ $(jq ''[.[]]'[2][0] | length' $json) -gt 5 ]; then
                    sqlite3 MegaQC_Uploads.sqlite "INSERT INTO megaQC_jsons (Runfolder, DNAnexus_fileID, Uploaded) VALUES ($projectName, $fileID, '0');"
                fi
            fi
        done
    done
}


# download myeloid files (project name suffix is MYE)
download_files 002_*_MYE_* MYELOID

# download FH files (project name suffix is FHC)
download_files 002_*_FHC_* FH

# download WES files (project name suffix is TWE)
download_files 002_*_TWE_* WES

# download WES files (project name has no suffix)
download_files 002_*_clinicalgenetics TSOE
