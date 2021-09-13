#!/usr/bin/env bash

# housekeeping - ensure we're in the correct directory OR add option so user can command script
# to download to specific place

# This script collects all new multiqc jsons from DNAnexus, for upload to MegaQC. You'll need to be logged into DNAnexus.


# Standardise default separator.
IFS=$'\n'

# Directory to save downloaded JSON files into. Change according to policy.
JSONPATH=/home/chris/Dev/MegaQC-jsons

touch /home/chris/megaUp.log
echo $(date) >> /home/chris/megaUp.log

# Function to do the work since we're doing basically the same thing for each assay.
download_files () {
    # Find all 002 projects with appropriate suffix. '$1' and '$2' refer to arguments given when this function is called below.
    for i in $(dx find projects --name $1); do
    echo --------
    projectID=$(printf $i | awk -F " " '{print $1}')
    projectName=$(printf $i | awk -F " " '{print $3}')
    echo ProjectID - $projectID
    echo ProjectName - $projectName
        # Find all multiqc json files within each project. 'dirName' is the 'single' runfolder.
        for j in $(dx find data --name "multiqc_data.json" --project $projectID); do
            if [ $2 = MYELOID ]; then
                echo Myeloid data found
                dirName=$(printf $j | awk -F " " '{print $6}' | awk -F "/" '{print $5}')
            else
                echo $2 data found
                dirName=$(printf $j | awk -F " " '{print $6}' | awk -F "/" '{print $6}')
            fi
            echo Runfolder - $dirName
            fileID=$(printf $j | awk -F " " '{print $7}' | tr -d '()')
            echo FileID - $fileID
            # Check for previous uploads (to prevent repeated downloads = cost)
            if [ $(sqlite3 MegaQC_Uploads.sqlite "SELECT EXISTS(SELECT 1 FROM megaQC_jsons WHERE DNAnexus_fileID=\"$fileID\" LIMIT 1);") -eq 0 ]; then 
                echo $fileID ' not in upload database... Downloading...'
                mkdir -p $JSONPATH/$2/$projectName/$dirName;
                dx download $fileID -o $JSONPATH/$2/$projectName/$dirName -f
                json=$JSONPATH/$2/$projectName/$dirName/multiqc_data.json # Works as long as there's only one json per 'single' runfolder
                echo File saved to $json
                # Check JSON to see if it's a proper run (i.e. more than 5 samples - threshold set by policy). Indexing the json by keyname didn't work.
                # This just counts the number of entries (samples) in the first section of 'report_general_stats_data'. Insert into DB if acceptable.
                if [ $(jq ''[.[]]'[2][0] | length' $json) -gt 5 ]; then
                    echo 'JSON is of sufficient size (>5 samples)... Recording in upload database...'
                    sqlite3 MegaQC_Uploads.sqlite "INSERT INTO megaQC_jsons (Runfolder, DNAnexus_fileID, Uploaded) VALUES ($dirName, $fileID, '0');"
                fi
            fi
        done
    echo --------
    echo --------
    done
}


# download myeloid files (project name suffix is MYE)              BUG FIXED: DIRECTORY STRUCTURE IS DIFFERENT
download_files 002_*_MYE MYELOID

# download FH files (project name suffix is FHC)
download_files 002_*_FHC FH

# download WES files (project name suffix is TWE)
download_files 002_*_TWE WES

# download WES files (project name has no suffix)
download_files 002_*_clinicalgenetics TSOE

echo 'FILE ADDED \n' >> /home/chris/megaUp.log
