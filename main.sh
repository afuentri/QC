#! /bin/bash                                 #
# Azahara Maria Fuentes Trillo               #
# Unidad de Genomica y Diagnostico Genetico  #
# Valencia                                   #
##############################################

## PARSE ARGUMENTS

genome=false
alignment=false
repository=false

while getopts hd:r:s:gm: option
do
    case "${option}"
    in
        h) help=${OPTARG}

        echo "                                                                     "
        echo "-USE"
        echo "  bash main.sh -d 161207 -r RUNXXX"
        echo "                                                                     "
        echo "This script performs an IGH analysis from raw fastqs"
        echo "sequenced with Illumina Miseq. The input required is: "
        echo "                                                                     "
        echo "Options:"
        echo "  -h: display this help message"
        echo "  -d: Run date in format YYMMDD"
        echo "  -r: RUN ID in format RUNXXX"
        echo "*********************************************************************\
***************************************************************************************"
        echo "Before executing this script, miseq_historico must be mounted on the machine." 
        echo "*********************************************************************\
***************************************************************************************"
        echo "GOOD LUCK"
        exit 1
        ;;
        d) dat=${OPTARG}
        ;;
        r) run=${OPTARG}
        ;;
    esac
done

## Run date must be inserted in format YYMMDD RUNXXX
WORKING_DIR="/storage/ethernus_ugdg_HPC_data2/IgHs/projects/$dat"_"$run"

## PATH FOR ALL THE projects
PROJECTS_DIR="/storage/ethernus_ugdg_HPC_data2/IgHs/projects"

## PATH FOR FASTQS
FOLDER_FASTQS="$WORKING_DIR/fastqs/"

## FOLDER TRIMMED FASTQS
FOLDER_TRIMMED="$WORKING_DIR/trimmed/"

## PATH FOR QC OUTPUT
FOLDER_QC="$WORKING_DIR/QC"

## PATH FOR FASTQC
FOLDER_FASTQC="$WORKING_DIR/QC/fastqc"

## PATH FOR FASTQC PREPROCESSED
FOLDER_PREPROCESSED="$WORKING_DIR/QC/fastqc/preprocessed"

## PATH FOR FASTQC POSTPROCESSED
FOLDER_POSTPROCESSED="$WORKING_DIR/QC/fastqc/postprocessed"

## PATH FOR QC SCRIPTS
SCRIPT_TABLE="/srv/dev/QC/fastQC_table.py"

## Echoes

echo "WORKING DIRECTORY: $WORKING_DIR"
echo "FOLDER PROJECTS: $PROJECTS_DIR"
echo "FOLDER FASTQS: $FOLDER_FASTQS"
echo "FOLDER TRIMMED: $FOLDER_TRIMMED"
echo "FOLDER QC: $FOLDER_QC"
echo "FOLDER FASTQC: $FOLDER_FASTQC"
echo "FOLDER PREPROCESSED: $FOLDER_PREPROCESSED"
echo "FOLDER POSTPROCESSED: $FOLDER_POSTPROCESSED"
echo "SCRIPT TABLE: $SCRIPT_TABLE"


# Creating folders
mkdir $FOLDER_QC
mkdir $FOLDER_FASTQC
mkdir $FOLDER_PREPROCESSED
mkdir $FOLDER_POSTPROCESSED

# Read counts

pre_counts="pre-triming_counts.txt"

for i in $FOLDER_FASTQS*fastq.gz; do
    
    echo $i
    zcat $i | echo $((`wc -l`/4))
    
done >> $FOLDER_QC$pre_counts

post_counts="post-triming_counts.txt"

for i in $FOLDER_TRIMMED*fastq.gz; do

    echo $i
    zcat $i | echo $((`wc -l`/4))

done >> $FOLDER_QC$post_counts

## FASTQC PREPROCESSED
echo "Using FASTQC:  "
fastqc

for i in $FOLDER_FASTQS*fastq.gz; do

    fastq_name=$(basename $i)
    echo "$fastq_name : Starting pretrimming quality control analysis"
    fastqc $i -o $FOLDER_PREPROCESSED

done

### EXTRACTING FOLDERS
for i in $FOLDER_PREPROCESSED*.zip; do

    echo "$i: unzipping folder"
    unzip $i
    rm $FOLDER_PREPROCESSED*.zip
done

### FASTQC DATA SUMMARY
fastq_stats="fastqs_stats.txt"

for i in $(find $FOLDER_PREPROCESSED -name fastqc_data.txt); do

    head -n11 $i >> $FOLDER_PREPROCESSED$fastq_stats

done

### FASTQC DATA SUMMARY
summary="summary.txt"
resume="resume.txt"
for i in $(find $FOLDER_PREPROCESSED -name summary.txt); do

    cat $i >> $FOLDER_PREPROCESSED$summary
done

cat $FOLDER_PREPROCESSED$summary | cut -f1,2 | sort | uniq -c > $FOLDER_PREPROCESSED$resume


## FASTQC POSTPROCESSED

for i in $FOLDER_TRIMMED*fastq.gz; do

    fastq_name=$(basename $i)
    echo "$fastq_name : Starting postrimming quality control analysis"
    fastqc $i -o $FOLDER_POSTPROCESSED

done


### EXTRACTING FOLDERS
for i in $FOLDER_POSTPROCESSED*.zip; do

    echo "$i: unzipping folder"
    unzip $i
    rm $FOLDER_POSTPROCESSED*.zip
done

### FASTQC DATA SUMMARY
fastq_stats="fastqs_stats.txt"

for i in $(find $FOLDER_POSTPROCESSED -name fastqc_data.txt); do

    head -n11 $i >> $FOLDER_POSTPROCESSED$fastq_stats

done

### FASTQC DATA SUMMARY
summary="summary.txt"
resume="resume.txt"
for i in $(find $FOLDER_POSTPROCESSED -name summary.txt); do

    cat $i >> $FOLDER_POSTPROCESSED$summary
done

cat $FOLDER_POSTPROCESSED$summary | cut -f1,2 | sort | uniq -c > $FOLDER_POSTPROCESSED$resume

## TABLE GENERATION

python $SCRIPT_TABLE $FOLDER_PREPROCESSED$fastq_stats $FOLDER_POSTPROCESSED$fastq_stats
