/************************************************************************
                            IO.cpp
************************************************************************/

#include "IO.h"

bool comparisonFunction(float a,float b) {
    return (a < b);
}

short getArguments(char **trainFile, char **recommendationFile, char **outputFile, int &temporalDistance, float &talValue, int argc, char **argv){
	int opt; 
	
	//initialize parameters
	*outputFile = NULL;
	*recommendationFile = NULL;
	*trainFile = NULL;
	talValue = 0;
	temporalDistance = 100;

	while( (opt = getopt(argc, argv, "ho:t:d:a:r:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 'o':
				*outputFile = optarg;
				break;
			case 't':
				*trainFile = optarg;
				break;
			case 'd':
				temporalDistance = atoi(optarg);
				break;
			case 'a':
				talValue = atof(optarg);
				break;
			case 'r':
				*recommendationFile = optarg;
				break;

			default:{
				printUsage();
				return 0;
			}
		}
	}

	if( *outputFile == NULL || *recommendationFile == NULL || *trainFile == NULL || temporalDistance < 0 || talValue > 10 ){
		printUsage();
		return 0;
	}
	
	return 1;
}

void loadRecommendations(char *inputFileName, HashOfHashes &recommendationsPerUser){
	std::ifstream inputFile;
	std::string itemId;
	std::string line;
	std::string rating;
	int userId;
	int vectorSize;
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
			vectorSize = (int) vetor.size();

			for(int i=1; i<vectorSize; i++){
				std::stringstream ssBuffer(vetor[i]);
				getline(ssBuffer, itemId, ':');
				getline(ssBuffer, rating, ':');
			
				recommendationsPerUser[userId][atoi(itemId.c_str())] = atof(rating.c_str());
			}
		}
	}
	
	inputFile.close();
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
	vector<float>::iterator itr;
	
	int numItems = (int) retrievalProbability.size();
	int medianPosition = numItems/2;

	sort(retrievalProbability.begin(), retrievalProbability.end(), comparisonFunction);
	float medianValue = retrievalProbability[medianPosition];
	
	outputFile << 1.0 - medianValue;	
}

void printUsage(){
	string args = "\nIn order to run this algorithm, please inform:\n";
	args += "\t -o <output file name>\n";
	args += "\t -t <train file name>\n";
	args += "\t -r <recommendation file name>\n";
	args += "\t -a <tal value>\n";
	args += "\t -d <Minimum temporal distance for old items -- positive integer>\n";
	args += "\t [-h] <for showing this message>\n\n";
	cout << args;
}
