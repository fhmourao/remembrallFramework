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
FORGOTTEN_METHOD=$6;

### Verify Number of parameters received as input
if [[ $# -ne 6 ]];then
    echo -e "\n\t\t***ERROR: Number of input parameters different from the required! \n \t\t   Please read the README.txt file in order to get more information. \n\n";
    exit;
fi

### Create output directory
mkdir -p ${OUTPUT_DIR}/Data/${DATASET};
mkdir -p ${OUTPUT_DIR}/Gnuplot/${DATASET};
mkdir -p ${OUTPUT_DIR}/Graphic/${DATASET};
mkdir -p ${OUTPUT_DIR}/Recommendations/${DATASET};
mkdir -p ${OUTPUT_DIR}/Quality/${DATASET}

###############################################################
### Declaration of internal variables
###############################################################
source ${SCRIPT_PATH}/../global.config

##################################################################################################
### Step 1 - Execute recommendations 
##################################################################################################

	echo -e "\t Recommending Itens ... ";

	for method in ${forgottenRecoveryMethod}; do
		echo -e "\t\t Executing method $method ... \n";

		cd ${SCRIPT_PATH}/Recommendation/${method}/;
		make clean;
		make;
		
		if [[ ${method} == "TradicionalRS" ]]; then
			./userKNN -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/forgotten${FORGOTTEN_METHOD}_${contextSize}.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -p ${NUmThreads} -r ${recommendationPercentage};
			cat ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt.* > ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt
			rm -f ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt.*
			sort -nk 1 -nk 2 ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt
		elif [[ ${method} == "ObviousRecommendation" ]]; then
			./retriveObviousItems -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -c ${contextSize} -r ${recommendationPercentage}
		elif [[ ${method} == "Random" ]]; then
			./sampleTrainingItems -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -r ${recommendationPercentage}
		else
			./remembrall -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -a ${OUTPUT_DIR}/Data/${DATASET}/forgotten${FORGOTTEN_METHOD}_${contextSize}.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -c ${contextSize} -r ${recommendationPercentage}
		fi;

		echo -e "\n\t\t Done!\n ";
		
	done;

	echo -e "\t Done!\n ";

##################################################################################################
### Step 2 - Evaluate Recommendations
##################################################################################################

	echo -e "\t Evaluating recommendations ... ";

	rm -f ${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurves.txt;
	for method in ${forgottenRecoveryMethod}; do
		echo -e "\t\t Evaluating method $method ... \n";

		cd ${SCRIPT_PATH}/Scripts/getQualityMetrics/
		make clean;
		make;
		
		perl ${SCRIPT_PATH}/Scripts/getOverallRecall.pl ${OUTPUT_DIR}/Data/${DATASET}/Test.txt ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}_${recommendationPercentage}_${contextSize}.txt
		

		perl ${SCRIPT_PATH}/Scripts/qualityPerTemporalDistance.pl ${OUTPUT_DIR}/Data/${DATASET}/Test.txt ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTemporalDistance_${recommendationPercentage}_${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTemporalDistance_${recommendationPercentage}_${contextSize}.txt ]]; then 
			echo -e "notitle\t${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTemporalDistance_${recommendationPercentage}_${contextSize}.txt" > ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/recall${method}PerTemporalDistance_${recommendationPercentage}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/recall${method}PerTemporalDistance_${recommendationPercentage}_${contextSize}.eps "Temporal Distance" "Recall (%)";
		fi

		perl ${SCRIPT_PATH}/Scripts/qualityPerTemporalLength.pl ${OUTPUT_DIR}/Data/${DATASET}/Test.txt ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTemporalLength_${recommendationPercentage}_${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTemporalLength_${recommendationPercentage}_${contextSize}.txt ]]; then 
			echo -e "notitle\t${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTemporalLength_${recommendationPercentage}_${contextSize}.txt" > ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/recall${method}PerTemporalLength_${recommendationPercentage}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/recall${method}PerTemporalLength_${recommendationPercentage}_${contextSize}.eps "Temporal Length" "Recall (%)";
		fi
		
		perl ${SCRIPT_PATH}/Scripts/qualityPerTrainingSize.pl ${OUTPUT_DIR}/Data/${DATASET}/Test.txt ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTrainingSize_${recommendationPercentage}_${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTrainingSize_${recommendationPercentage}_${contextSize}.txt ]]; then 
			echo -e "notitle\t${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerTrainingSize_${recommendationPercentage}_${contextSize}.txt" > ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/recall${method}PerTrainingSize_${recommendationPercentage}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/recall${method}PerTrainingSize_${recommendationPercentage}_${contextSize}.eps "Number of Training Items" "Recall (%)";
		fi
		rm -f ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt
		
		cd ${SCRIPT_PATH}/Recommendation/ContextAware/;
		make clean;
		make;
		./remembrall -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -a ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/temporary${recommendationPercentage}_context${contextSize}.txt -c ${contextSize} -r 1.0
		./remembrall -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -a ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -o ${OUTPUT_DIR}/Recommendations/${DATASET}/temporaryTest${recommendationPercentage}_context${contextSize}.txt -c ${contextSize} -r 1.0
		perl ${SCRIPT_PATH}/Scripts/qualityPerContext.pl ${OUTPUT_DIR}/Recommendations/${DATASET}/temporaryTest${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/temporary${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerContextSim_${recommendationPercentage}_${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerContextSim_${recommendationPercentage}_${contextSize}.txt ]]; then 
			echo -e "notitle\t${OUTPUT_DIR}/Quality/${DATASET}/recall${method}PerContextSim_${recommendationPercentage}_${contextSize}.txt" > ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt;
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/recall${method}PerContextSim_${recommendationPercentage}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/recall${method}PerContextSim_${recommendationPercentage}_${contextSize}.eps "Mean Context Similarity" "Recall (%)";
		fi
		rm -f ${OUTPUT_DIR}/Recommendations/${DATASET}/temporary${recommendationPercentage}_context${contextSize}.txt
		rm -f ${OUTPUT_DIR}/Recommendations/${DATASET}/temporaryTest${recommendationPercentage}_context${contextSize}.txt
		rm -f ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt
		
		${SCRIPT_PATH}/Scripts/getQualityMetrics/getMetrics -b ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -l ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -p ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt -t ${NUmThreads} -o ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity${method}_${recommendationPercentage}_context${contextSize}.txt;
		cat ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity${method}_${recommendationPercentage}_context${contextSize}.txt.* > ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity${method}_${recommendationPercentage}_context${contextSize}.txt;
		rm -rf ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity${method}_${recommendationPercentage}_context${contextSize}.txt.*
		
		perl ${SCRIPT_PATH}/Scripts/getMeanValues.pl ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/meanNoveltyDiversity${method}_${recommendationPercentage}_context${contextSize}.txt
		
		perl ${SCRIPT_PATH}/Scripts/generatePrecisionRecallCurve.pl ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Data/${DATASET}/Test.txt ${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurve${method}_${recommendationPercentage}_context${contextSize}.txt
		if [[ -s ${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurve${method}_${recommendationPercentage}_context${contextSize}.txt ]]; then 
			echo -e "${method}\t${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurve${method}_${recommendationPercentage}_context${contextSize}.txt" >> ${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurves.txt;
		fi
		 
		echo -e "\n\t\t Done!\n ";
	done

	${SCRIPT_PATH}/Scripts/getQualityMetrics/getMetrics -b ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -l ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -p ${OUTPUT_DIR}/Data/${DATASET}/Test.txt -t ${NUmThreads} -o ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity_testSet.txt;
	cat ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity_testSet.txt.* > ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity_testSet.txt;
	rm -rf ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity_testSet.txt.*
	
	perl ${SCRIPT_PATH}/Scripts/getMeanValues.pl ${OUTPUT_DIR}/Quality/${DATASET}/noveltyDiversity_testSet.txt ${OUTPUT_DIR}/Quality/${DATASET}/meanNoveltyDiversity_testSet.txt

	bash ${SCRIPT_PATH}/Scripts/generateDataInput.sh ${SCRIPT_PATH}/Scripts/ ${DATA_PATH} ${DATASET} ${OUTPUT_DIR}/Data/ ${INPUT_FORMAT} 1.0
	
	if [[ -s ${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurves.txt ]]; then
		perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Quality/${DATASET}/precisionRecallCurves.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/precisionRecallCurves_${recommendationPercentage}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/precisionRecallCurves_${recommendationPercentage}_${contextSize}.eps "Recall (%)" "Precision (%)";
	fi
	
	for method in ${forgottenRecoveryMethod}; do
	
		perl ${SCRIPT_PATH}/Scripts/getReconsumable.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/reconsumable_${method}_${recommendationPercentage}_${contextSize}.txt
		
		perl ${SCRIPT_PATH}/Scripts/getReconsumablePerTemporalDistance.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/reconsumableTemporalDistance_${method}_${recommendationPercentage}_${contextSize}.txt
		echo -e "notitle\t${OUTPUT_DIR}/Quality/${DATASET}/reconsumableTemporalDistance_${method}_${recommendationPercentage}_${contextSize}.txt" > ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt;
		perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/reconsumableTemporalDistance_${method}_${recommendationPercentage}_${contextSize}.gp ${OUTPUT_DIR}/Graphic/${DATASET}/reconsumableTemporalDistance_${method}_${recommendationPercentage}_${contextSize}.eps "TemporalDistance" "ReRate";
		
		perl ${SCRIPT_PATH}/Scripts/getReconsumablePerPopularity.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Recommendations/${DATASET}/${method}_${recommendationPercentage}_context${contextSize}.txt ${OUTPUT_DIR}/Quality/${DATASET}/reconsumablePopularity_${method}_${recommendationPercentage}_${contextSize}.txt

	done;
	
	rm -f ${OUTPUT_DIR}/Quality/${DATASET}/inputGraphic.txt
	echo -e "\t Done!\n ";
