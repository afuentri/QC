#! /bin/bash                                 #
# Azahara Maria Fuentes Trillo               #
# Unidad de Genomica y Diagnostico Genetico  #
# Valencia                                   #
##############################################

## PARSE ARGUMENTS
bed=false

while getopts hb:l:: option
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
	echo "  -l: BED file with regions"
        echo "*********************************************************************\            
****************************************************************************************"
	echo "*********************************************************************\  
***************************************************************************************"
	echo "GOOD LUCK"
	exit 1
	;;
	b) wd=${OPTARG}
	;;
	l) bed=${OPTARG}
	;;
       
    esac
done

## WORKING DIR
BAMS_DIR="$wd"

## FOLDER FLAGSTAT
FOLDER_FLAGSTAT="$BAMS_DIR/flagstat/"
QC=$(dirname "$0")
## SCRIPTS REPO
REPORT="${QC}/report.py"
MAPPEDCHROMOSOME="${QC}/plotmapped_chr.py"

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

    name_bam=$(basename $i)
    stats_out="$FOLDER_FLAGSTAT${name_bam%-sorted.bam}-stats.txt"
    echo "samtools flagstat $i > $stats_out"

done > $FOLDER_FLAGSTAT$cmd

cat $FOLDER_FLAGSTAT$cmd | parallel --joblog $FOLDER_FLAGSTAT$log -j10

## TABLE

echo "Mapping statistics to tabular format..."

out_table=${FOLDER_FLAGSTAT}resume.csv
echo "file_name,count_reads_mapped,percent_reads_mapped" > $out_table
for i in $(ls $FOLDER_FLAGSTAT*-stats.txt | grep -v "merged"); do

    l=$(cat $i | grep "mapped (")
    reads=$(echo $l | cut -f1 -d"+")
    perc=$(echo $l | cut -f2 -d"(" | cut -f1 -d":" | sed 's/%//g')

    echo $(basename ${i%-stats.txt}),$reads,$perc | sed 's/ //g' >> $out_table

done

## TABLE TARGET REGIONS
if [ -f $bed ]; then
    out_table_reg=${FOLDER_FLAGSTAT}resume_targetregions.csv
    echo "file_name,count_reads_mapped,percent_reads_mapped" > $out_table_reg
    for i in $(ls $BAMS_DIR/*sorted.bam | grep -v "merged"); do

	sname=$(basename ${i%-sorted.bam})
	## view mapped reads in the target regions
	mapped=$(samtools view -F4 -L $bed $i | wc -l)
	total=$(samtools view $i | wc -l)
	echo $sname,$mapped,$(echo "$mapped/$total*100" | bc -l) >> $out_table_reg

    done
    dos2unix $out_table_reg
    python ${QC}/mapstats.py $out_table_reg 'target_regions'
fi
		   
## plots mapping statistics
dos2unix $out_table
python ${QC}/mapstats.py $out_table 'all'

## PDF REPORT
fof_images=${FOLDER_FLAGSTAT}imagesflagstat.fof

ls $FOLDER_FLAGSTAT*.png > $fof_images
python3 $REPORT $fof_images $FOLDER_FLAGSTAT 'mapping_statistics'

## plots mapped per chromosome
for i in $BAMS_DIR/*sorted.bam; do
    t=$(samtools view $i | wc -l)
    samtools view -F4 $i| cut -f3 | sort | uniq -c | sed 's/^ *//g' | sed 's/ /,/g'> ${i%-sorted.bam}-${t}_counts.tsv
    n=$(cat ${i%-sorted.bam}-${t}_counts.tsv | wc -l)
    paste -d"," <(for f in $(seq 1 $n); do l=$(basename "${i%_S*}"); echo "$l,$t" | xargs -n1 ; done) ${i%-sorted.bam}-${t}_counts.tsv

done > $BAMS_DIR/table_counts_mapped.csv

python $MAPPEDCHROMOSOME $BAMS_DIR/table_counts_mapped.csv $FOLDER_FLAGSTAT
