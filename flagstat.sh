#! /bin/bash                                 #
# Azahara Maria Fuentes Trillo               #
# Unidad de Genomica y Diagnostico Genetico  #
# Valencia                                   #
##############################################

## PARSE ARGUMENTS

while getopts hb: option
do

    case "${option}"
    in
	h) help=${OPTARG}

	echo "                                                                     "
        echo "-USE"
	echo "  bash flagstat.sh -b working_dir"
	echo "                                                                     "
	echo "This script performs an initial analysis of mapping statistics"
	echo "The input required is: "
	echo "                                                                     "
	echo "Options:"
	echo "  -h: display this help message"
	echo "  -b: folder with bam files"
        echo "*********************************************************************\            
****************************************************************************************"
	echo "*********************************************************************\  
***************************************************************************************"
	echo "GOOD LUCK"
	exit 1
	;;
	b) wd=${OPTARG}
	;;
    esac
done

## WORKING DIR
BAMS_DIR="$wd"

## FOLDER FLAGSTAT
FOLDER_FLAGSTAT="$BAMS_DIR/flagstat/"

## SCRIPTS REPO
QC="$scripts_repo/QC/"

## Echoes
echo "WORKING DIRECTORY: $BAMS_DIR"
echo "FOLDER MAPPING STATISTICS: $FOLDER_FLAGSTAT"

# Creating folders
mkdir $FOLDER_FLAGSTAT

## SAMTOOLS FLAGSTAT

echo "Performing samtools flagstat: BAM files mapping statistics"

cmd="CMD_flagstat.cmd"
log="LOG_flagstat.log"

for i in $BAMS_DIR/*sorted.bam; do

    echo "echo $i"
    name_bam=$(basename $i)
    stats_out="$FOLDER_FLAGSTAT${name_bam%-sorted.bam}-stats.txt"
    echo "samtools flagstat $i > $stats_out"

done > $FOLDER_FLAGSTAT$cmd

cat $FOLDER_FLAGSTAT$cmd | parallel --joblog $FOLDER_FLAGSTAT$log -j10

## TABLE

echo "Mapping statistics to tabular format..."

out_table="$FOLDER_FLAGSTATresume.csv"
echo "file_name,count_reads_mapped,percent_reads_mapped" > $out_table

for i in $FOLDER_FLAGSTAT*-stats.txt; do

    l=$(cat $i | grep "mapped (")
    reads=$(echo $l | cut -f1 -d"+")
    perc=$(echo $l | cut -f2 -d"(" | cut -f1 -d":")

    echo $(basename ${i%-stats.txt}),$reads,$perc | sed 's/ //g' >> $out_table

done

## plots mapping statistics
python ${QC}mapstats.py $out_table
