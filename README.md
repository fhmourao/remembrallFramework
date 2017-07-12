**** Description

	This framework aims to evaluate original personalized strategies to uncover subsets 
	of known items useful for recommendation presently. We hypothesize that not only 
	recently consumed items are candidates for reconsumption, but also subsets of items 
	that were consumed long ago by the user could be candidates. We implemented four 
	distinct recommendation heuristics based on time-related, context-related, relevance-
	related information, as well as a combination of these three types of information 
	(i.e., mixed heuristic).


*** How to setup the environment:

In order to install all dependencies, you need to execute the following command line in a linux shell console:

	bash install.sh


*** Dependencies:

- bash
- g++
- make
- perl
- gnuplot


*** How to run:

In order to run the framework, you need to execute the following command line in a linux shell console:

	bash runFramework <INPUT_DATA_DIR> <DATASET_NAME> <INPUT_DATA_FORMAT> <REC_METHOD> <OUTPUT_DIR>
Where:
	- INPUT_DATA_DIR: valid directory path where the input dataset is stored.
	- DATASET_NAME: Name of the input dataset.
	- INPUT_DATA_FORMAT: format of the input data set (TG -> MovieLens Tags format;ML -> MovieLens format; LF -> LastFm format; NF -> NetFlix format)
	- REC_METHOD: Name of the recommendation method used to recommend unexpected known items (LFA -> relevance related heuristic; LRA -> time-related heuristic; LCCC -> context-related heuritic;ACT-R -> mixed heuristic)
	- OUTPUT_DIR: valid directory path where framework's all results will be stored.


*** Running example:

	bash runFramework.sh /usr/local/remembrallFramework/Examples movieDomainSample ML ACT-R /usr/local/remembrallFramework/Outputs


*** Input Data Formats:

The current version of this framework allows four distinct data formats:

- TG [MovieLens Tags]
	USER_ID \t ITEM_ID \t FREQ_OCCURRENCE \t TIME_MOMENT
	USER_ID \t ITEM_ID \t FREQ_OCCURRENCE \t TIME_MOMENT
	USER_ID \t ITEM_ID \t FREQ_OCCURRENCE \t TIME_MOMENT
	
- ML [MovieLens]
	USER_ID \t ITEM_ID \t RATING \t TIME_MOMENT
	USER_ID \t ITEM_ID \t RATING \t TIME_MOMENT
	USER_ID \t ITEM_ID \t RATING \t TIME_MOMENT
	
- LF [LastFm]
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE \t ITEM_ID:FREQ_OCCURRENCE
	
- NF [NetFlix]
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING
	USER_ID \t START_TIME \t END_TIME \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING \t ITEM_ID:RATING


