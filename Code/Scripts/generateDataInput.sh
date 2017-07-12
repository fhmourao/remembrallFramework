#!/bin/bash
set -e
export LC_ALL=C
export LANG=C

###############################################################
### Get input parameters
##############################################################
SCRIPT_PATH=$1;
DATA_PATH=$2;
DATASET=$3;
OUTPUT_DIR=$4;
INPUT_FORMAT=$5;
TRAINING_PERCENTAGE=$6;

###############################################################
### Verify Number of parameters received as input
###############################################################
if [[ $# -ne 6 ]];then
    echo -e "\n\t\t***ERROR: Number of input parameters different from the required! Please open the README.txt file for more information.\n\n";
    exit;
fi

###############################################################
### Declaration of internal variables
###############################################################
source ${SCRIPT_PATH}/../../global.config

###############################################################
### Generate train and test data
###############################################################

# create output directories	
mkdir -p ${OUTPUT_DIR}/${DATASET}/

TRAIN_FILE=${OUTPUT_DIR}/${DATASET}/Train.txt;
TEST_FILE=${OUTPUT_DIR}/${DATASET}/Test.txt;

if [[ ${INPUT_FORMAT} == "TG" ]] ; then
	sort -nk 1 -nk 4 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstTime=`cut -f 4 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstTime} ${Time_interval} ${TRAINING_PERCENTAGE} ${TRAIN_FILE} ${TEST_FILE};	
elif [[ ${INPUT_FORMAT} == "ML" ]] ; then
	if  [[ $extendProfile = true ]]; then
		cd ${SCRIPT_PATH}/ExtendProfile/;
		make clean;
		make;
		./userKNN -t ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -p ${NUmThreads} -k ${NumNeighbors}
		cat ${OUTPUT_DIR}/${DATASET}/temporaryData.txt.* > ${OUTPUT_DIR}/${DATASET}/temporaryData.txt;
		rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.txt.*
		
		sort -nk 1 -nk 4 ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	else 
		sort -nk 1 -nk 4 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	fi 
	firstTime=`cut -f 4 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstTime} ${Time_interval} ${TRAINING_PERCENTAGE} ${TRAIN_FILE} ${TEST_FILE};	
elif [[ ${INPUT_FORMAT} == "LF" ]]; then
	sort -nk 1 -nk 2 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstTime=`cut -f 2 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/changeLFInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstTime} ${Time_interval} ${TRAINING_PERCENTAGE} ${TRAIN_FILE} ${TEST_FILE};
elif [[ ${INPUT_FORMAT} == "NF" ]]; then
	if  [[ $extendProfile = true ]]; then
		cd ${SCRIPT_PATH}/ExtendProfile/;
		make clean;
		make;
		perl ${SCRIPT_PATH}/changeNFInputDataFormat.pl ${DATA_PATH}/${DATASET} ${OUTPUT_DIR}/${DATASET}/temporaryData.txt
		./userKNN -t ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -o ${OUTPUT_DIR}/${DATASET}/temporaryData.out -p ${NUmThreads} -k ${NumNeighbors}
		cat ${OUTPUT_DIR}/${DATASET}/temporaryData.out.* > ${OUTPUT_DIR}/${DATASET}/temporaryData.out 
		rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.out.*
		
		sort -nk 1 -nk 4 ${OUTPUT_DIR}/${DATASET}/temporaryData.out -o ${OUTPUT_DIR}/${DATASET}/temporaryData.out -T ${OUTPUT_DIR}/${DATASET}/
	else
		sort -nk 1 -nk 2 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	fi
	firstTime=`cut -f 4 ${OUTPUT_DIR}/${DATASET}/temporaryData.out | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.out ${firstTime} 1 ${TRAINING_PERCENTAGE} ${TRAIN_FILE} ${TEST_FILE};
else 
	echo -e "\n\t\t***ERROR: Not valid data format! Please open the README.txt file for more information.\n\n";
fi;

rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.txt
rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.out;
