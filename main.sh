#! /bin/bash                                 #
# Azahara Maria Fuentes Trillo               #
# Unidad de Genomica y Diagnostico Genetico  #
# Valencia                                   #
##############################################

## PARSE ARGUMENTS

while getopts hp: option
do
    case "${option}"
    in
        h) help=${OPTARG}

        echo "                                                                     "
        echo "-USE"
        echo "  bash main.sh -d 161207 -r RUNXXX"
        echo "                                                                     "
        echo "This script performs an initial QC analysis for raw fastqs"
        echo "and trimmed fastqs sequenced with Illumina Miseq. The input required is: "
        echo "                                                                     "
        echo "Options:"
        echo "  -h: display this help message"
        echo "  -p: working dir (absolut path without final slash)"
        echo "*********************************************************************\
***************************************************************************************"
        echo "*********************************************************************\
***************************************************************************************"
        echo "GOOD LUCK"
        exit 1
        ;;
        p) wd=${OPTARG}
        ;;
    esac
done

## Run date must be inserted in format YYMMDD RUNXXX
WORKING_DIR="$wd"

## PATH FOR FASTQS
FOLDER_FASTQS="$WORKING_DIR/fastqs/"

## FOLDER TRIMMED FASTQS
FOLDER_TRIMMED="$WORKING_DIR/trimmed/"

## PATH FOR QC OUTPUT
FOLDER_QC="$WORKING_DIR/QC/"

## PATH FOR FASTQC
FOLDER_FASTQC="$WORKING_DIR/QC/fastqc/"

## PATH FOR FASTQC PREPROCESSED
FOLDER_PREPROCESSED="$WORKING_DIR/QC/fastqc/preprocessed/"

## PATH FOR FASTQC POSTPROCESSED
FOLDER_POSTPROCESSED="$WORKING_DIR/QC/fastqc/postprocessed/"

## PATH FOR QC SCRIPTS
SCRIPT_TABLE="/srv/dev/QC/fastQC_table.py"

## Echoes

echo "WORKING DIRECTORY: $WORKING_DIR"
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
fastqc --version

cmd="CMD_preprocessed.cmd"
log="LOG_preprocessed.log"

for i in $FOLDER_FASTQS*fastq.gz; do

    fastq_name=$(basename $i)
    
    echo "fastqc $i -o $FOLDER_PREPROCESSED"

done > $FOLDER_PREPROCESSED$cmd

cat $FOLDER_PREPROCESSED$cmd | parallel --joblog $FOLDER_PREPROCESSED$log -j10

### EXTRACTING FOLDERS
for i in $FOLDER_PREPROCESSED*.zip; do

    echo "$i: unzipping folder"
    unzip $i -d $FOLDER_PREPROCESSED

done

rm $FOLDER_PREPROCESSED*.zip 

### FASTQC DATA SUMMARY
fastq_stats="fastqs_stats.txt"

for i in $(find $FOLDER_PREPROCESSED -name fastqc_data.txt); do

    head -n11 $i >> $FOLDER_PREPROCESSED$fastq_stats

done

### FASTQC DATA SUMMARY
summary="summary.txt"
resume="resume.txt"
FAIL_BSQ="FAILED_per-base-sequence-quality.txt"
FAIL_SQS="FAILED_per-sequence-queality.txt"
FAIL_BS="FAILED_basic-statistics.txt"
FAIL_GC="FAILED_GC-content.txt"
FAIL_BNC="FAILED_per-base-N-content.txt"
FAIL_SLD="FAILED_sequence-length-distribution.txt"
FAIL_AC="FAILED_adapter-content.txt"

for i in $(find $FOLDER_PREPROCESSED -name summary.txt); do

    cat $i >> $FOLDER_PREPROCESSED$summary
done

cat $FOLDER_PREPROCESSED$summary | cut -f1,2 | sort | uniq -c > $FOLDER_PREPROCESSED$resume
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Per base sequence quality" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_BSQ
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Per sequence quality scores" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_SQS
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Basic Statistics" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_BS
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Per sequence GC content" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_GC
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Per base N content" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_BNC
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Sequence Length Distribution" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_SLD
cat $FOLDER_PREPROCESSED$summary | grep "FAIL" | grep "Adapter Content" | cut -f3 > $FOLDER_PREPROCESSED$FAIL_AC


## FASTQC POSTPROCESSED

echo "Using FASTQC:  "
fastqc --version

cmd="CMD_postprocessed.cmd"
log="LOG_postprocessed.log"

for i in $FOLDER_TRIMMED*fastq.gz; do

    fastq_name=$(basename $i)

    echo "fastqc $i -o $FOLDER_POSTPROCESSED"

done > $FOLDER_POSTPROCESSED$cmd

cat $FOLDER_POSTPROCESSED$cmd | parallel --joblog $FOLDER_POSTPROCESSED$log -j10


### EXTRACTING FOLDERS
for i in $FOLDER_POSTPROCESSED*.zip; do

    echo "$i: unzipping folder"
    unzip $i -d $FOLDER_POSTPROCESSED

done

rm $FOLDER_POSTPROCESSED*.zip

### FASTQC DATA SUMMARY
fastq_stats="fastqs_stats.txt"

for i in $(find $FOLDER_POSTPROCESSED -name fastqc_data.txt); do

    head -n11 $i >> $FOLDER_POSTPROCESSED$fastq_stats

done

### FASTQC DATA SUMMARY
summary="summary.txt"
resume="resume.txt"
FAIL_BSQ="FAILED_per-base-sequence-quality.txt"
FAIL_SQS="FAILED_per-sequence-queality.txt"
FAIL_BS="FAILED_basic-statistics.txt"
FAIL_GC="FAILED_GC-content.txt"
FAIL_BNC="FAILED_per-base-N-content.txt"
FAIL_SLD="FAILED_sequence-length-distribution.txt"
FAIL_AC="FAILED_adapter-content.txt"

for i in $(find $FOLDER_POSTPROCESSED -name summary.txt); do

    cat $i >> $FOLDER_POSTPROCESSED$summary

done

cat $FOLDER_POSTPROCESSED$summary | cut -f1,2 | sort | uniq -c > $FOLDER_POSTPROCESSED$resume
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Per base sequence quality" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_BSQ
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Per sequence quality scores" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_SQS
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Basic Statistics" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_BS
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Per sequence GC content" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_GC
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Per base N content" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_BNC
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Sequence Length Distribution" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_SLD
cat $FOLDER_POSTPROCESSED$summary | grep "FAIL" | grep "Adapter Content" | cut -f3 > $FOLDER_POSTPROCESSED$FAIL_AC

## TABLE GENERATION
python $SCRIPT_TABLE $FOLDER_PREPROCESSED$fastq_stats $FOLDER_POSTPROCESSED$fastq_stats $FOLDER_QC
