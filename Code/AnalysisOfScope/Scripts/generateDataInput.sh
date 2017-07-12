#!/bin/bash
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

###############################################################
### Verify Number of parameters received as input
###############################################################
if [[ $# -ne 5 ]];then
    echo -e "\n\t\t***ERROR: Number of input parameters different from the required! Please open the README.txt file for more information.\n\n";
    exit;
fi

###############################################################
### Declaration of internal variables
###############################################################
numThreads=8;
numNeighbors=10;
timeInterval=604800;   #Week size in second

###############################################################
### Generate train data
###############################################################

# create output directories	
mkdir -p ${OUTPUT_DIR}/${DATASET}/


TRAIN_FILE=${OUTPUT_DIR}/${DATASET}/train.txt;
EXTENDED_TRAIN_FILE=${OUTPUT_DIR}/${DATASET}/extendedTrain.txt;

if [[ ${INPUT_FORMAT} == "TG" ]] ; then

	sort -nk 1 -nk 4 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstTime=`cut -f 4 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/Scripts/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstMoment} ${timeInterval} ${TRAIN_FILE};
	
	cp ${TRAIN_FILE} ${EXTENDED_TRAIN_FILE}
	
elif [[ ${INPUT_FORMAT} == "ML" ]] ; then

	sort -nk 1 -nk 4 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstMoment=`cut -f 4 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/Scripts/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstMoment} ${timeInterval} ${TRAIN_FILE};
	
	cd ${SCRIPT_PATH}/Scripts/ExtendProfile/;
	make;
	
	./userKNN -t ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -p ${numThreads} -k ${numNeighbors}
	cat ${OUTPUT_DIR}/${DATASET}/temporaryData.txt.* > ${OUTPUT_DIR}/${DATASET}/temporaryData.txt;
	rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.txt.*

	sort -nk 1 -nk 4 ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstMoment=`cut -f 4 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/Scripts/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstMoment} ${timeInterval} ${EXTENDED_TRAIN_FILE};
	
elif [[ ${INPUT_FORMAT} == "LF" ]]; then

	sort -nk 1 -nk 2 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstMoment=`cut -f 2 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/Scripts/changeLFInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstMoment} ${timeInterval} ${TRAIN_FILE};
	
	cp ${TRAIN_FILE} ${EXTENDED_TRAIN_FILE}
	
elif [[ ${INPUT_FORMAT} == "NF" ]]; then
	perl ${SCRIPT_PATH}/Scripts/changeNFInputDataFormat.pl ${DATA_PATH}/${DATASET} ${OUTPUT_DIR}/${DATASET}/temporaryData.txt
	
	sort -nk 1 -nk 4 ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	firstMoment=`cut -f 2 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/Scripts/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${firstMoment} 1 ${TRAIN_FILE};
	
	cd ${SCRIPT_PATH}/Scripts/ExtendProfile/;
	make;
	
	./userKNN -t ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -o ${OUTPUT_DIR}/${DATASET}/temporaryData.out -p ${numThreads} -k ${numNeighbors}
	cat ${OUTPUT_DIR}/${DATASET}/temporaryData.out.* > ${OUTPUT_DIR}/${DATASET}/temporaryData.out 
	rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.out.*

	sort -nk 1 -nk 4 ${OUTPUT_DIR}/${DATASET}/temporaryData.out -o ${OUTPUT_DIR}/${DATASET}/temporaryData.out -T ${OUTPUT_DIR}/${DATASET}/
	firstMoment=`cut -f 2 ${DATA_PATH}/${DATASET} | sort -nk 1 | head -n 1`;
	perl ${SCRIPT_PATH}/Scripts/changeMLInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.out ${firstMoment} 1 ${EXTENDED_TRAIN_FILE};
	
elif [[ ${INPUT_FORMAT} == "MS" ]]; then

	sort -k 1 ${DATA_PATH}/${DATASET} -o ${OUTPUT_DIR}/${DATASET}/temporaryData.txt -T ${OUTPUT_DIR}/${DATASET}/
	perl ${SCRIPT_PATH}/Scripts/changeMSInputDataFormat.pl ${OUTPUT_DIR}/${DATASET}/temporaryData.txt ${TRAIN_FILE};
	
	cp ${TRAIN_FILE} ${EXTENDED_TRAIN_FILE}
else 
	echo -e "\n\t\t***ERROR: Not valid data format! Please open the README.txt file for more information.\n\n";
fi

rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.out
rm -f ${OUTPUT_DIR}/${DATASET}/temporaryData.txt