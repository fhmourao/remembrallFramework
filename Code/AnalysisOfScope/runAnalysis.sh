#!/bin/bash
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
MODE=$6

### Verify Number of parameters received as input
if [[ $# -ne 6 ]];then
    echo -e "\n\t\t***ERROR: Number of input parameters different from the required! \n \t\t   Please read the README.txt file in order to get more information. \n\n";
    exit;
fi

### Create output directory
mkdir -p ${OUTPUT_DIR}/AnalysisOfScope/${DATASET};
mkdir -p ${OUTPUT_DIR}/Gnuplot/${DATASET}/AnalysisOfScope;
mkdir -p ${OUTPUT_DIR}/Graphic/${DATASET}/AnalysisOfScope;

NumThreads=4;
TOP_N=100;

##################################################################################################
### Step 1 - Generate input data
##################################################################################################

	echo " Generating input data ... ";
	
 		bash ${SCRIPT_PATH}/Scripts/generateDataInput.sh ${SCRIPT_PATH}/ ${DATA_PATH} ${DATASET} ${OUTPUT_DIR}/Data/ ${INPUT_FORMAT};

		if [[ $MODE -eq 1 ]]; then
			cp ${OUTPUT_DIR}/Data/${DATASET}/extendedTrain.txt ${OUTPUT_DIR}/Data/${DATASET}/train.txt
		fi

	echo -e " done!\n ";

##################################################################################################
### Step 2 - Generate the distribution of consumption over time
##################################################################################################

	echo " Generating distribution of consumption over time ... ";

		# Get the distribution
		perl ${SCRIPT_PATH}/Scripts/getConsumptionOverTime.pl ${OUTPUT_DIR}/Data/${DATASET}/train.txt ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/consumptionOverTime.txt

		# Plot the distribution
		echo -e "notitle\t${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/consumptionOverTime.txt" > ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/inputGraphic.txt

		perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/AnalysisOfScope/consumptionOverTime.gp ${OUTPUT_DIR}/Graphic/${DATASET}/AnalysisOfScope/consumptionOverTime.eps "Item's age (weeks)" "% Users who consume an item" 

		rm -rf ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/inputGraphic.txt
		
	echo -e " done!\n ";

##################################################################################################
### Step 3 - Generate the popularity decay over time
##################################################################################################

	echo " Generating popularity decay over time ... ";
	
		#Generate the distribution
		perl ${SCRIPT_PATH}/Scripts/getPopularityDecay.pl ${OUTPUT_DIR}/Data/${DATASET}/train.txt ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/popularityDecay.txt

		# Plot the distribution
		echo -e "notitle\t${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/popularityDecay.txt" > ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/inputGraphic.txt
		perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/AnalysisOfScope/popularityDecay.gp ${OUTPUT_DIR}/Graphic/${DATASET}/AnalysisOfScope/popularityDecay.eps "Item's age (weeks)" "Percentage of Users (Median)" 

		rm -rf ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/inputGraphic.txt

	echo -e " done!\n ";

##################################################################################################
### Step 4 - Determine the minimum temporal distance to distinguish old items
##################################################################################################

	echo " Determining minimum temporal distance to distinguish old items ... ";

		#Mean individual distribution
		perl ${SCRIPT_PATH}/Scripts/getMinimumTDistance.pl ${OUTPUT_DIR}/Data/${DATASET}/train.txt ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/minimumTemporalDistance.txt

	echo -e " done!\n ";

##################################################################################################
### Step 5 - Determine the probability of an old item be remembered
##################################################################################################

	echo " Determining the probability of an old item be retrieved ... ";

		cd ${SCRIPT_PATH}/Scripts/ACT-R/
		make clean;
		make

		temporalDistance=`cat ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/minimumTemporalDistance.txt`
	
		${SCRIPT_PATH}/Scripts/ACT-R/remembrall -t ${OUTPUT_DIR}/Data/${DATASET}/train.txt -o ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/oblivionProbability.txt -d ${temporalDistance} -a ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/talValue.txt

	echo -e " done!\n ";

##################################################################################################
### Step 6 - Determine the probability of a recommended item be old
##################################################################################################

	echo " Determining the probability of a recommended item be old ... ";
	
		#compile the method
		cd ${SCRIPT_PATH}/BasicRSs/UserKNN/;
		make clean;
		make;
		
		#create a temporary test file
		grep -v ":" ${OUTPUT_DIR}/Data/${DATASET}/train.txt | cut -f 1 | sort -nk 1 > ${OUTPUT_DIR}/Data/${DATASET}/test.txt
		
		# run the method
		./userKNN -t ${OUTPUT_DIR}/Data/${DATASET}/train.txt -e ${OUTPUT_DIR}/Data/${DATASET}/test.txt -o ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out -n ${TOP_N} -p ${NumThreads}
		cat ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out.* > ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out
		rm -f ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out.*
		sort -t " " -nk 1 ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out -o ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out -T ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/;
 
		cd ${SCRIPT_PATH}/Scripts/POI/
		make clean;
		make

		talValue=`cat ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/talValue.txt`;
		
		${SCRIPT_PATH}/Scripts/POI/remembrall -t ${OUTPUT_DIR}/Data/${DATASET}/train.txt -o ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/userKNNProbabilityOfOldItems.txt -r ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out -d ${temporalDistance} -a ${talValue};

		# remove temporary files
		rm -f ${OUTPUT_DIR}/Data/${DATASET}/test.txt
		rm -f ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/predictions_UserKNN_top-${TOP_N}.out 

	echo -e " done!\n ";

##################################################################################################
### Step 5 - Determine the probability of old items be re-consumable
##################################################################################################

	echo " Determine the probability of old items be re-consumable ... ";

		perl ${SCRIPT_PATH}/Scripts/getProbabilityOfReconsumable2.pl ${OUTPUT_DIR}/Data/${DATASET}/train.txt ${OUTPUT_DIR}/AnalysisOfScope/${DATASET}/probabilityOfReconsumption.txt ${TOP_N} ${temporalDistance};

	echo -e " done!\n ";
