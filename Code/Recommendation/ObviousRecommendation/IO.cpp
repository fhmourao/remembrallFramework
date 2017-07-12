/************************************************************************
                            IO.cpp
************************************************************************/

#include "IO.h"

bool comparisonFunction(const myPair &a,const myPair &b) {
    return ((a.score) > (b.score));
}

short getArguments(char **trainFile, char **testFile, char **outputFile, float &percentageOfHistory, int &contextSize, int argc, char **argv){
	int opt; 
	
	//initialize parameters
	*outputFile = NULL;
	*testFile = NULL;
	*trainFile = NULL;
	percentageOfHistory = 0.1;
	contextSize = -1;

	while( (opt = getopt(argc, argv, "ho:t:e:r:c:")) != -1 ) {
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
			case 'e':
				*testFile = optarg;
				break;
			case 'r':
				percentageOfHistory = atof(optarg);
				break;
			case 'c':
				contextSize = atoi(optarg);
				break;
			default:{
				printUsage();
				return 0;
			}
		}
	}

	if( *outputFile == NULL || *testFile == NULL || *trainFile == NULL || percentageOfHistory < 0.0 || contextSize < 0){
		printUsage();
		return 0;
	}
	
	return 1;
}

void loadTraingData(char *inputFileName, HashOfHashes &trainingData){
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

		// split the line based on the ' ' and '\t' delimiter
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		
		
		userId = atoi(vetor[0].c_str());
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
	
	inputFile.close();

}

void printRecommendations(User currentUser, long int testMoment, vector<myPair> &forgottenItems, int recommendationSize, std::ofstream &outputFile){
	
	int numItems = (int) forgottenItems.size();
		
	sort(forgottenItems.begin(), forgottenItems.begin()+numItems, comparisonFunction);
	outputFile << currentUser.getUserId() << "\t" << testMoment;
	for(int i=0; (i < recommendationSize && i < numItems); i++) {
		outputFile << "\t" << forgottenItems[i].item << ":" << forgottenItems[i].score;
	}
	outputFile << "\n";
	
}

void printUsage(){
	string args = "\nIn order to run this algorithm, please inform:\n";
	args += "\t -o <output file name>\n";
	args += "\t -t <train file name>\n";
	args += "\t -e <test file name>\n";
	args += "\t -r <recommendation size>\n";
	args += "\t -c <temporal context size>\n";
	args += "\t [-h] <for showing this message>\n\n";
	cout << args;
}
