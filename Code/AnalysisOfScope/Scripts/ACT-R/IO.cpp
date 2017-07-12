/************************************************************************
                            IO.cpp
************************************************************************/

#include "IO.h"

bool comparisonFunction(float a,float b) {
    return (a < b);
}

short getArguments(char **trainFile, char **outputFile, char **outputFile1, int &temporalDistance, int argc, char **argv){
	int opt; 
	
	//initialize parameters
	*outputFile = NULL;
	*outputFile1 = NULL;
	*trainFile = NULL;
	temporalDistance = 0;

	while( (opt = getopt(argc, argv, "ho:t:d:a:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 'o':
				*outputFile = optarg;
				break;
			case 'a':
				*outputFile1 = optarg;
				break;
			case 't':
				*trainFile = optarg;
				break;
			case 'd':
				temporalDistance = atoi(optarg);
				break;
			default:{
				printUsage();
				return 0;
			}
		}
	}

	if( *outputFile == NULL || *outputFile1 == NULL || *trainFile == NULL || temporalDistance < 0 ){
		printUsage();
		return 0;
	}
	
	return 1;
}

void loadTraingData(char *inputFileName, vector<int> &domainUsers, HashOfHashes &trainingData){
	std::ifstream inputFile;
	std::string itemId;
	std::string line;
	std::string rating;
	int userId;
	int vectorSize;
	int numTimeUnits;
	std::vector<std::string> vetor;
	
	//open input file
	inputFile.open(inputFileName);
	if( !(inputFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << inputFileName << "\n\n";
		exit(-1);
	}
	
	while(!inputFile.eof()) {
		getline(inputFile, line);

		if( line.length() > 0){
			// split the line based on the ' ' and '\t' delimiter
			vetor.clear();
			string_tokenize(line, vetor, " \t");
			
			
			userId = atoi(vetor[0].c_str());
			domainUsers.push_back(userId);
			numTimeUnits = atoi(vetor[1].c_str());

			for(int k=0; k<numTimeUnits; k++){
				getline(inputFile, line);
				
				vetor.clear();
				string_tokenize(line, vetor, " \t");		
				vectorSize = (int) vetor.size();
				
				for(int i=3; i<vectorSize; i++){
					std::stringstream ssBuffer(vetor[i]);
					getline(ssBuffer, itemId, ':');
					getline(ssBuffer, rating, ':');
				
					trainingData[atoi(itemId.c_str())][userId] = atof(rating.c_str());
				}
			}
		}
	}
	
	inputFile.close();

}

void printMedianProbability(vector<float> &retrievalProbability, std::ofstream &outputFile){
	
	int numItems = (int) retrievalProbability.size();
	int medianPosition = numItems/2;
		
	sort(retrievalProbability.begin(), retrievalProbability.end(), comparisonFunction);
	float medianValue = retrievalProbability[medianPosition];
	
	outputFile << 1.0 - medianValue;
	
}

void printUsage(){
	string args = "\nIn order to run this algorithm, please inform:\n";
	args += "\t -o <output file name>\n";
	args += "\t -a <output file name to print the tal value>\n";
	args += "\t -t <train file name>\n";
	args += "\t -d <Minimum temporal distance for old items -- positive integer>\n";
	args += "\t [-h] <for showing this message>\n\n";
	cout << args;
}
