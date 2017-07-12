#!/bin/bash
set -e
export LC_ALL=C
export LANG=C

##################################################################################################
### Obtain input parameters
##################################################################################################

INPUT_DATA_DIR=$1;
DATASET_NAME=$2;
INPUT_DATA_FORMAT=$3;
REC_METHOD=$4;
OUTPUT_DIR=$5;

##################################################################################################
### Check parameter values
##################################################################################################

echo "Checking parameter values ..."

	if [[ ! -d "$INPUT_DATA_DIR" ]]; then
		echo -e "\n\t*** ERROR: Input data directory $INPUT_DATA_DIR does not exist!\n"
		exit 1
	fi
	if [[ ! -f "${INPUT_DATA_DIR}/${DATASET_NAME}" ]]; then
		echo -e "\n\t*** ERROR: Input dataset ${INPUT_DATA_DIR}/${DATASET_NAME} does not exist!\n"
		exit 1
	fi
	if [[ ! "$INPUT_DATA_FORMAT" =~ ^(TG|ML|LF|NF)$ ]]; then
		echo -e "\n\t*** ERROR: Input data format $INPUT_DATA_FORMAT is not valid!\n"
		exit 1
	fi	
	if [[ ! "$REC_METHOD" =~ ^(LFA|LRA|LCCC|ACT-R)$ ]]; then
		echo -e "\n\t*** ERROR: Input recommender method $REC_METHOD is not valid!\n"
		exit 1
	fi	

echo -e "Done!\n"

##################################################################################################
### Execute framework
##################################################################################################

echo "Running framework ..."

	echo -e " *** Identifying unexpected known items (a.k.a. forgotten items) ...\n"
	bash ${PWD}/Code/identifyForgottenItems.sh ${PWD}/Code/ ${INPUT_DATA_DIR}/ ${DATASET_NAME} ${OUTPUT_DIR}/ ${INPUT_DATA_FORMAT}

	echo -e "\n *** Recommendding unexpected known items ...\n"
	bash ${PWD}/Code/recommendForgottenItems.sh ${PWD}/Code/ ${INPUT_DATA_DIR}/ ${DATASET_NAME} ${OUTPUT_DIR}/ ${INPUT_DATA_FORMAT} ${REC_METHOD}
	
	echo -e "\n *** Characterizing unexpected known items ...\n"
	bash ${PWD}/Code/characterizeForgottenItems.sh ${PWD}/Code/ ${INPUT_DATA_DIR}/ ${DATASET_NAME} ${OUTPUT_DIR}/ ${INPUT_DATA_FORMAT} 

echo -e  "Done!\n"