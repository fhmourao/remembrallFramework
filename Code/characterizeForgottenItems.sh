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

### Verify Number of parameters received as input
if [[ $# -ne 5 ]];then
    echo -e "\n\t\t***ERROR: Number of input parameters different from the required! \n \t\t   Please read the README.txt file in order to get more information. \n\n";
    exit;
fi

### Create output directory
mkdir -p ${OUTPUT_DIR}/Characterization/${DATASET};
mkdir -p ${OUTPUT_DIR}/Gnuplot/${DATASET};
mkdir -p ${OUTPUT_DIR}/Graphic/${DATASET};


###############################################################
### Declaration of internal variables
###############################################################
source ${SCRIPT_PATH}/../global.config

##################################################################################################
### Step 1 - Generate distribution of memories in terms of their estimated need probabilities.
##################################################################################################

	echo -e "\t Generating distribution of memories w.r.t the estimated need probabilities ... ";

		### Mean individual distribution
		perl ${SCRIPT_PATH}/Characterization/generateIndividualMemoryDistribution.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/individualMemoryDistribution.txt  

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/individualMemoryDistribution.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/individualMemoryDistribution.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/individualMemoryDistribution.gp ${OUTPUT_DIR}/Graphic/${DATASET}/individualMemoryDistribution.eps "Rank" "Need Odds"
		fi
			
		### Global single distribution
		perl ${SCRIPT_PATH}/Characterization/generateGlobalMemoryDistribution.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/globalMemoryDistribution.txt

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/globalMemoryDistribution.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/globalMemoryDistribution.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/globalMemoryDistribution.gp ${OUTPUT_DIR}/Graphic/${DATASET}/globalMemoryDistribution.eps "Rank" "Need Odds"
		fi

	echo -e "\t Done! ";
	
##################################################################################################
### Step 2 - Show that forgotten items represent a subset of the long tail items
##################################################################################################

	echo -e "\t Evaluate popularity of forgotten items ... ";

		perl ${SCRIPT_PATH}/Characterization/getItemsPopularity.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/itemsPopularity.txt;

		perl ${SCRIPT_PATH}/Characterization/getPopularityPerRank.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/itemsPopularity.txt ${OUTPUT_DIR}/Characterization/${DATASET}/popularityPerRank.txt  

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/popularityPerRank.txt ]]; then 
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/popularityPerRank.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/popularityPerRank.gp ${OUTPUT_DIR}/Graphic/${DATASET}/popularityPerRank.eps "Rank" "Popularity"
		fi

	echo -e "\t Done! ";

##################################################################################################
### Step 3 - 
##################################################################################################

	echo -e "\t Evaluate aging of forgotten items ... ";

		perl ${SCRIPT_PATH}/Characterization/getItemsAging.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/itemsAging.txt;

		perl ${SCRIPT_PATH}/Characterization/getAgePerRank.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/itemsAging.txt ${OUTPUT_DIR}/Characterization/${DATASET}/agePerRank.txt  
		
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/agePerRank.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/agePerRank.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/agePerRank.gp ${OUTPUT_DIR}/Graphic/${DATASET}/agePerRank.eps "Rank" "Age"
		fi

	echo -e "\t done! ";

##################################################################################################
### Step 4 - Evaluate Retention Function
##################################################################################################

	echo -e "\t Evaluate Retention Function ... ";

		perl ${SCRIPT_PATH}/Characterization/generateIndividualRetentionFunction.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/individualRetentionFunction.txt ${TrainingPercentage}

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/individualRetentionFunction.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/individualRetentionFunction.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/individualRetentionFunction.gp ${OUTPUT_DIR}/Graphic/${DATASET}/individualRetentionFunction.eps "Last Occurrence" "Need Odds"
		fi
		
		perl ${SCRIPT_PATH}/Characterization/generateGlobalRetentionFunction.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/globalRetentionFunction.txt ${TrainingPercentage}

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/globalRetentionFunction.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/globalRetentionFunction.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/globalRetentionFunction.gp ${OUTPUT_DIR}/Graphic/${DATASET}/globalRetentionFunction.eps "Last Occurrence" "Need Odds"
		fi

	echo -e "\t Done! ";

##################################################################################################
### Step 5 - Evaluate Practice Function
##################################################################################################

	echo -e "\t Evaluate Practice Function ... ";

		perl ${SCRIPT_PATH}/Characterization/generateIndividualPracticeFunction.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/individualPracticeFunction.txt ${TrainingPercentage}

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/individualPracticeFunction.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/individualPracticeFunction.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/individualPracticeFunction.gp ${OUTPUT_DIR}/Graphic/${DATASET}/individualPracticeFunction.eps "Frequency Occurrence" "Need Odds"
		fi

		perl ${SCRIPT_PATH}/Characterization/generateGlobalPracticeFunction.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/globalPracticeFunction.txt ${TrainingPercentage}

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/globalPracticeFunction.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/globalPracticeFunction.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/globalPracticeFunction.gp ${OUTPUT_DIR}/Graphic/${DATASET}/globalPracticeFunction.eps "Frequency Occurrence" "Need Odds"
		fi

	echo -e "\t Done! ";

##################################################################################################
### Step 6 - Evaluate Spacing Effect
##################################################################################################

	echo -e "\t Evaluate Spacing Effect ... ";

		perl ${SCRIPT_PATH}/Characterization/evaluateSpaceEffect.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/spaceEffect.txt ${TrainingPercentage}
		
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/spaceEffect.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/spaceEffect.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Characterization/plotHeatMap.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/spaceEffect.gp ${OUTPUT_DIR}/Graphic/${DATASET}/spaceEffect.eps "Last Interval" "Mean Interval" "Need Odds"
		fi	

	echo -e "\t Done! ";


##################################################################################################
### Step 7 - Distribution of reconsumption probability
##################################################################################################

	echo -e "\t Evaluate Reconsumption per Training Size ... ";
		
		perl ${SCRIPT_PATH}/Characterization/getReconsumptionProbPerSize.pl ${OUTPUT_DIR}/Data/${DATASET}/Train.txt ${OUTPUT_DIR}/Characterization/${DATASET}/reconsumptionPerSize.txt ${TrainingPercentage}

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/reconsumptionPerSize.txt ]]; then
			# Plot the distribution
			echo -e "notitle\t${OUTPUT_DIR}/Characterization/${DATASET}/reconsumptionPerSize.txt" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/reconsumptionPerSize.gp ${OUTPUT_DIR}/Graphic/${DATASET}/reconsumptionPerSize.eps "Training Size" "Need Odds"
		fi

	echo -e "\t Done! ";

##################################################################################################
### Step 8 - Existence of 'stable' and 'instable' tastes
##################################################################################################

	echo -e "\t Evaluate Existence of 'stable' and 'instable' tastes ... ";
		rm -f ${OUTPUT_DIR}/Characterization/inputGraphic.txt
		cd ${SCRIPT_PATH}/Characterization/ItemKNN;
		make clean;
		make;
		./itemKNN -t ${OUTPUT_DIR}/Data/${DATASET}/Train.txt -o ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt -p ${NUmThreads}
		cat ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt.* > ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt;
		rm -f ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt.*;

		perl ${SCRIPT_PATH}/Characterization/generateSimilarityDistribution.pl ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisFQ.cdf 0
		perl ${SCRIPT_PATH}/Characterization/generateSimilarityDistribution.pl ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisLQ.cdf 1
		perl ${SCRIPT_PATH}/Characterization/generateSimilarityDistribution.pl ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysis.txt ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisFL.cdf 2

		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisFQ.cdf ]]; then
			echo -e "Long Taste\t${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisFQ.cdf" > ${OUTPUT_DIR}/Characterization/inputGraphic.txt
		fi 
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisLQ.cdf ]]; then
			echo -e "Short Taste\t${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisLQ.cdf" >> ${OUTPUT_DIR}/Characterization/inputGraphic.txt
		fi
		if [[ -s ${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisFL.cdf ]]; then
			echo -e "Long-short\t${OUTPUT_DIR}/Characterization/${DATASET}/stableInstableTasteAnalysisFL.cdf" >> ${OUTPUT_DIR}/Characterization/inputGraphic.txt
		fi
		if [[ -s ${OUTPUT_DIR}/Characterization/inputGraphic.txt ]]; then
			perl ${SCRIPT_PATH}/Scripts/plotGraphic.pl ${OUTPUT_DIR}/Characterization/inputGraphic.txt ${OUTPUT_DIR}/Gnuplot/${DATASET}/stableInstableTasteAnalysis.gp ${OUTPUT_DIR}/Graphic/${DATASET}/stableInstableTasteAnalysis.eps "Similarity" "CCDF x >= X"
		fi
		
	echo -e "\t Done! ";

rm -rf ${OUTPUT_DIR}/Characterization/inputGraphic.txt