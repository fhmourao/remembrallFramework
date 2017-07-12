#!/bin/bash
set -e
export LC_ALL=C
export LANG=C

##################################################################################################
### Obtain input parameters
##################################################################################################

SCRIPT_PATH=$1;
DATA_PATH=$2;
DATASET=$3;
OUTPUT_DIR=$4;
INPUT_FORMAT=$5;

### Verify Number of parameters received as input
if [[ $# -ne 5 ]];then
    echo -e "\n\t\t***ERROR: Number of input parameters different from the required! \n \t\t   Please read the README.txt file in order to get more information. \n\n";
    exit;
fi

### Create output directory
mkdir -p ${OUTPUT_DIR}/Data/${DATASET};
mkdir -p ${OUTPUT_DIR}/Gnuplot/${DATASET};
mkdir -p ${OUTPUT_DIR}/Graphic/${DATASET};
mkdir -p ${OUTPUT_DIR}/Characterization/${DATASET};

###############################################################
### Declaration of internal variables
###############################################################
source ${SCRIPT_PATH}/../global.config

##################################################################################################
### Step 1 - Generate input data
##################################################################################################

	echo -e "\t Generating input data ... \n";
	
	bash ${SCRIPT_PATH}/Scripts/generateDataInput.sh ${SCRIPT_PATH}/Scripts/ ${DATA_PATH} ${DATASET} ${OUTPUT_DIR}/Data/ ${INPUT_FORMAT} ${TrainingPercentage};

	echo -e "\n\t Done!\n ";

##################################################################################################
### Step 2 - Identify Forgotten Itens
##################################################################################################

	echo -e "\t Identifying Forgotten Itens ... ";
	
	for method in ${methods}; do
		echo -e "\t\t Executing method $method ... \n";

		cd ${SCRIPT_PATH}/Scripts/${method};
		make clean;
		make;
		./remembrall -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -o ${OUTPUT_DIR}/Data/${DATASET}/forgotten${method}_${contextSize}.txt -r 0 -c ${contextSize}
		
	done;
	
	echo -e "\n\t Done!\n ";

##################################################################################################
### Step 3 - Evaluate Forgotten Items
##################################################################################################

	echo -e "\t Evaluating forgotten items ... ";

	perl ${SCRIPT_PATH}/Scripts/projectTestSet.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Data/${DATASET}/Test.txt ${OUTPUT_DIR}/Data/${DATASET}/reconsumptions.txt

	for method in ${methods}; do
		echo -e "\t\t Evaluating method $method ... ";
		
		perl ${SCRIPT_PATH}/Scripts/getMeanRatingPerScore.pl ${OUTPUT_DIR}/Data/${DATASET}/forgotten${method}_${contextSize}.txt ${OUTPUT_DIR}/Characterization/${DATASET}/meanRatingPerScore${method}_${contextSize}.txt ${OUTPUT_DIR}/Data/${DATASET}/reconsumptions.txt
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/meanRatingPerScore${method}_${contextSize}.txt ]]; then
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/meanRatingPerScore${method}_${contextSize}.txt" > ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/meanRatingPerScore${method}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/meanRatingPerScore${method}_${contextSize}.eps "${method} Score" "Mean rating";
		fi

		perl ${SCRIPT_PATH}/Scripts/getOverallRankDifference.pl ${OUTPUT_DIR}/Data/${DATASET}/forgotten${method}_${contextSize}.txt ${OUTPUT_DIR}/Data/${DATASET}/reconsumptions.txt ${OUTPUT_DIR}/Characterization/${DATASET}/overallRankDifference${method}_${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/overallRankDifference${method}_${contextSize}.txt ]]; then 
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/overallRankDifference${method}_${contextSize}.txt" > ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/overallRankDifference${method}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/overallRankDifference${method}_${contextSize}.eps "Rank Difference" "Probability of Occurrence";
		fi

		perl ${SCRIPT_PATH}/Scripts/getRankDifferencePerScore.pl ${OUTPUT_DIR}/Data/${DATASET}/forgotten${method}_${contextSize}.txt ${OUTPUT_DIR}/Data/${DATASET}/reconsumptions.txt ${OUTPUT_DIR}/Characterization/${DATASET}/rankDifferencePerScore${method}_${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/rankDifferencePerScore${method}_${contextSize}.txt ]]; then
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/rankDifferencePerScore${method}_${contextSize}.txt" > ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/rankDifferencePerScore${method}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/rankDifferencePerScore${method}_${contextSize}.eps "${method} Score" "Mean Rank Difference";
		fi

		perl ${SCRIPT_PATH}/Scripts/generateRankScorePairs.pl ${OUTPUT_DIR}/Data/${DATASET}/forgotten${method}_${contextSize}.txt ${OUTPUT_DIR}/Data/${DATASET}/reconsumptions.txt ${OUTPUT_DIR}/Data/${DATASET}/inputCorrelations.txt
		if [[ -s ${OUTPUT_DIR}/Data/${DATASET}/inputCorrelations.txt ]]; then
			perl ${SCRIPT_PATH}/Scripts/correlation.pl -i ${OUTPUT_DIR}/Data/${DATASET}/inputCorrelations.txt > ${OUTPUT_DIR}/Data/${DATASET}/correlationRankScore_${method}_${contextSize}.txt
		fi

	done;

	rm -rf ${OUTPUT_DIR}/Characterization/${DATASET}/inputGraphic.txt;
	rm -rf ${OUTPUT_DIR}/Data/${DATASET}/inputCorrelations.txt;
	rm -rf ${OUTPUT_DIR}/Data/${DATASET}/reconsumptions.txt;

	echo -e "\t Done!\n ";
