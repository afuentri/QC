#! /bin/bash                                 #
# Azahara Maria Fuentes Trillo               #
# Unidad de Genomica y Diagnostico Genetico  #
# Valencia                                   #
##############################################

## PARSE ARGUMENTS
primers=false

while getopts hp:f:t:b:: option
do
    case "${option}"
    in
        h) help=${OPTARG}

        echo "                                                                     "
        echo "-USE"
        echo "  bash main.sh -p output_dir -f fastqs_rawfolder -t fastqs_trimmedfolder [-b primers]"
        echo "                                                                     "
        echo "This script performs an initial QC analysis for raw fastqs"
        echo "and trimmed fastqs sequenced with Illumina. The input required is: "
        echo "                                                                     "
        echo "Options:"
        echo "  -h: display this help message"
        echo "  -p: output dir (absolute path)"
	echo "  -f: Folder with RAW FASTQ files inside"
	echo "  -t: Folder with trimmed FASTQ files inside"
	echo "  -b: (optional) evaluate trimming of primers (folder with FASTA files with primer sequences to evaluate)"
	echo "  Evaluation of Nextera and Truseq ADAPTER sequences will be performed always"
	echo "  FASTA files in folder must be named and separated in the following way:"
	echo "   - primers_5.fasta --> primer sequences removed on left end of reads"
	echo "   - primers_3.fasta --> primer sequences removed on right end of reads"
        echo "*********************************************************************************************************"
        echo "*********************************************************************************************************"
        echo "GOOD LUCK"
        exit 1
        ;;
        p) wd=${OPTARG}
        ;;
	f) ff=${OPTARG}
	;;
	t) ft=${OPTARG}
	;;
	b) primers=${OPTARG}
        ;;
       
    esac
done

## OUTPUT DIR and DATA DIRS
WORKING_DIR="$wd"
FOLDER_FASTQS="$ff"
FOLDER_TRIMMED="$ft"
echo $FOLDER_FASTQS
scripts_repo=$(dirname "$0")
## we will have to include the following code in the specific
## pipelines scripts to autodetect which folders to use as we did before
## but it is a bit difficult to run it in pipeline-independent mode that way
## PATH FOR FASTQS
#FOLDER_MERGEDBC="$WORKING_DIR/merged_withoutbarcodes/"
FOLDER_MERGED="$WORKING_DIR/merged/"
## we will have to include the following code 
#if [ -d $FOLDER_MERGED ]; then
#    FOLDER_FASTQS="$WORKING_DIR/merged/"
#else
#    FOLDER_FASTQS="$WORKING_DIR/fastqs/"
#fi

### FOLDER TRIMMED FASTQS
#FOLDER_TRIMMED="$WORKING_DIR/trimmed/"

## PATH FOR QC OUTPUTselect 
FOLDER_QC="$WORKING_DIR/QC/"

## PATH FOR FASTQC
FOLDER_FASTQC="$WORKING_DIR/QC/fastqc/"

## PATH FOR FASTQC PREPROCESSED
FOLDER_PREPROCESSED="$WORKING_DIR/QC/fastqc/preprocessed/"

## PATH FOR FASTQC POSTPROCESSED
FOLDER_POSTPROCESSED="$WORKING_DIR/QC/fastqc/postprocessed/"

## OUT_PRIMERS
OUT_PRIMERS="$WORKING_DIR/QC/primers/"

## PATH FOR QC SCRIPTS
## changed to relative paths
SCRIPT_TABLE="$scripts_repo/fastQC_table.py"
PRIMERS="$scripts_repo/primer_QC.py"
BARCODEPLOT="$scripts_repo/barcodeplot.py"
PRIMERPLOT="$scripts_repo/primersplot.py"
REPORT="$scripts_repo/report.py"
PLOTRESUME="$scripts_repo/resumeplot.py"
plotquality="$scripts_repo/basequality.py"
## adapter sequences including truseq and nextera universal sequences
adaptersRight="$scripts_repo/adapter_sequences/adapters.fa"

## BARCODES
if [ -f $adaptersRight ]; then
    
    adapter=$adaptersRight
else
    echo "Fatal error, can not find adapter files"
fi

## PRIMERS
if [ $primers==true ]; then
    primers5="$primers/primers_5.fasta"
    primers3="$primers/primers_3.fasta"
   
fi

## Echoes
echo "WORKING DIRECTORY: $WORKING_DIR"
echo "FOLDER FASTQS: $FOLDER_FASTQS"
#echo "FOLDER MERGED: $FOLDER_MERGED"
echo "FOLDER TRIMMED: $FOLDER_TRIMMED"
echo "FOLDER QC: $FOLDER_QC"
echo "FOLDER FASTQC: $FOLDER_FASTQC"
echo "FOLDER PREPROCESSED: $FOLDER_PREPROCESSED"
echo "FOLDER POSTPROCESSED: $FOLDER_POSTPROCESSED"
echo "SCRIPT TABLE: $SCRIPT_TABLE"
echo "PRIMERS QC: $primers"
echo "BARCODES QC: $adapter"

# Creating folders
mkdir $FOLDER_QC
mkdir $FOLDER_FASTQC
mkdir $FOLDER_PREPROCESSED
mkdir $FOLDER_POSTPROCESSED
mkdir $OUT_PRIMERS

# Read counts

pre_counts="pre-triming_counts.txt"

for i in $FOLDER_FASTQS/*.f*q*; do
    
    echo $i
    zcat $i | echo $((`wc -l`/4))
    
done >> $FOLDER_QC$pre_counts

post_counts="post-triming_counts.txt"

for i in $FOLDER_TRIMMED/*.f*q*; do

    echo $i
    zcat $i | echo $((`wc -l`/4))

done >> $FOLDER_QC$post_counts

## FASTQC PREPROCESSED
echo "Using FASTQC:  "
fastqc --version

cmd="CMD_preprocessed.cmd"
log="LOG_preprocessed.log"

for i in $FOLDER_FASTQS/*.f*q*; do

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

## PLOT RESUME
python $PLOTRESUME $FOLDER_PREPROCESSED$resume $FOLDER_QC

## FASTQC POSTPROCESSED

echo "Using FASTQC:  "
fastqc --version

cmd="CMD_postprocessed.cmd"
log="LOG_postprocessed.log"

for i in $FOLDER_TRIMMED/*-trimmed.f*q*; do

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

## PLOT RESUME
python $PLOTRESUME $FOLDER_POSTPROCESSED$resume $FOLDER_QC

## TABLE GENERATION
python $SCRIPT_TABLE $FOLDER_PREPROCESSED $FOLDER_POSTPROCESSED $FOLDER_QC $FOLDER_FASTQS

## PLOT BASEQUALITY
find $FOLDER_PREPROCESSED -name "fastqc_data.txt" > "${FOLDER_QC}pretrimming.fof"
find $FOLDER_POSTPROCESSED -name "fastqc_data.txt" > "${FOLDER_QC}posttrimming.fof"
python3 $plotquality "${FOLDER_QC}pretrimming.fof" "${FOLDER_QC}posttrimming.fof" $FOLDER_QC

## BARCODE AND PRIMERS QC
## BARCODES (mandatory)

if [ -f $adapter ]; then

    echo "OK: performing barcode stats"
    for i in $FOLDER_FASTQS/*f*q*; do
	
	python3 $PRIMERS $i $adapter $OUT_PRIMERS

    done

    for i in $FOLDER_TRIMMED/*-trimmed.f*q*; do

	python3 $PRIMERS $i $adapter $OUT_PRIMERS
	
    done
	
    
else
    echo "Can not find adapter sequences: FATAL ERROR"

fi

## PRIMERS (OPTIONAL)
echo $primers
if [ $primers==true ]; then

    if [ -f $primers5 ] && [ -f $primers3 ]; then

	echo "OK: performing primer stats"
	for i in $FOLDER_FASTQS/*f*q*; do
	    
	    python3 $PRIMERS $i $primers5 $OUT_PRIMERS
	    python3 $PRIMERS $i $primers3 $OUT_PRIMERS
	done

	for i in $FOLDER_TRIMMED/*-trimmed.f*q*; do
	    python3 $PRIMERS $i $primers5 $OUT_PRIMERS
	    python3 $PRIMERS $i $primers3 $OUT_PRIMERS
	done
	
    else
	echo "Primers QC option was selected but there are no primer files inside folder indicated"
    fi

fi

## PLOT FOR ADAPTER AND PRIMERS

fof_barcodesraw="${OUT_PRIMERS}barcodesraw.fof"
fof_barcodestrimmed="${OUT_PRIMERS}barcodestrimmed.fof"

ls $OUT_PRIMERS*_adapters.csv | grep -v "trimmed" > $fof_barcodesraw
ls $OUT_PRIMERS*-trimmed_adapters.csv > $fof_barcodestrimmed

python3 $BARCODEPLOT $fof_barcodesraw $FOLDER_QC$pre_counts $OUT_PRIMERS
python3 $BARCODEPLOT $fof_barcodestrimmed $FOLDER_QC$post_counts $OUT_PRIMERS

## FOR PRIMERS
if [ $primers==true ]; then
    if [ -f $primers5 ] && [ -f $primers3 ]; then
	echo "OK: performing primer plots"

	fof_primers5raw="${OUT_PRIMERS}primers5raw.fof"
	fof_primers3raw="${OUT_PRIMERS}primers3raw.fof"
	fof_primers5trimmed="${OUT_PRIMERS}primers5trimmed.fof"
	fof_primers3trimmed="${OUT_PRIMERS}primers3trimmed.fof"

	ls $OUT_PRIMERS*_primers_3.csv | grep -v "trimmed" > $fof_primers3raw
	ls $OUT_PRIMERS*_primers_5.csv | grep -v "trimmed" > $fof_primers5raw
	ls $OUT_PRIMERS*-trimmed_primers_3.csv > $fof_primers3trimmed
	ls $OUT_PRIMERS*-trimmed_primers_5.csv > $fof_primers5trimmed

	python3 $PRIMERPLOT $fof_primers3raw $FOLDER_QC$pre_counts $OUT_PRIMERS
	python3 $PRIMERPLOT $fof_primers5raw $FOLDER_QC$pre_counts $OUT_PRIMERS
	python3 $PRIMERPLOT $fof_primers3trimmed $FOLDER_QC$post_counts $OUT_PRIMERS
	python3 $PRIMERPLOT $fof_primers5trimmed $FOLDER_QC$post_counts $OUT_PRIMERS

    else
	echo "Primers QC option was selected but there are no primer files inside folder indicated"
    fi

fi

## PDF REPORT
fof_images="${OUT_PRIMERS}images.fof"
ls $OUT_PRIMERS*.png > $fof_images
python3 $REPORT $fof_images $OUT_PRIMERS 'barcode-primers_report'
