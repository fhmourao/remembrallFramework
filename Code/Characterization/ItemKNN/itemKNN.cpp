#include "itemKNN.h"

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char **argv) {
	char *trainFileName;
	char *outFileName;
	int numThreads;
	
	HashOfHashes itemRatings;
	HashOfHashes userRatings;

	// checa a validade dos parâmetros de entrada passados pela linha de comando
	if(!getArgs(argc, argv, &trainFileName, &outFileName, &numThreads)) {
		return 1;
	}

	std::cout << "loading training data...\n" << flush;
	loadTrainData(trainFileName, itemRatings, userRatings);
	
	std::cout << "Starting recommendation process...\n" << flush;
	
	/* start threads */
	pthread_t *threads;
	pthread_param *params;

	threads = (pthread_t *) malloc(sizeof(pthread_t)*numThreads);
	params = (pthread_param *) malloc(sizeof(pthread_param)*numThreads);

	/* inicializa as threads */
	for (int i = 0; i < numThreads; i++) {
		params[i].threadId = i;
		params[i].numThreads = numThreads;
		params[i].itemRatings = &itemRatings;
		params[i].userRatings = &userRatings;
		params[i].outFileName = outFileName;

		pthread_create(&threads[i], NULL, &performRecommendation, params+i);
	}

	/* sincroniza finalizacao// das threads */
	for (int i = 0; i < numThreads; i++) {
		pthread_join(threads[i], NULL);
	}

	free(threads);

	return 0;
}

/****************************************************************************************
                             Main Thread Function
*****************************************************************************************/

void *performRecommendation(void *arg){
	int currentPosition;
	int modulus;
	HashOfHashes::iterator itr;
	
	// get thread parameters
	pthread_param *param = (pthread_param *) arg;
	
	//open output file name
	std::ofstream outputFile;
        std::stringstream outputFileName;
        outputFileName << param->outFileName << "." << param->threadId;

        outputFile.open(outputFileName.str().c_str());
        if(!outputFile.is_open()) {
                cout << "Erro ao abrir o arquivo de saída da thread " << param->threadId << "!" << endl;
                exit(-1);
        }

        // for each test user
	currentPosition = 0;
	for ( itr = (*param->userRatings).begin(); itr != (*param->userRatings).end(); itr++) {
		modulus = (currentPosition - (param->threadId + 1)) % param->numThreads;
		if( modulus == 0 ){
			recommendItems(itr->first, (*param->userRatings), (*param->itemRatings), outputFile);
		}
		currentPosition++;
		
	}
	
	// close thread output file
        outputFile.close();
	
	return NULL;
}

/****************************************************************************************
                             Recommendation Functions
*****************************************************************************************/
float calculateCosineSimilarity(int firstItem, int secondItem, HashOfHashes &itemRatings){
	float cosine = 0.0;
	float dotProduct = 0.0;
	float norm1 = 0.0;
	float norm2 = 0.0;
	
	HashOfHashes::iterator itr1;
	HashOfHashes::iterator itr2;

	Hash::iterator itr3;
	Hash::iterator itr4;
	
	//verify whether both item exist in the training set
	itr1 = itemRatings.find(firstItem);
	itr2 = itemRatings.find(secondItem);
	
	if( itr1 == itemRatings.end() || itr2 == itemRatings.end() )
		return cosine;
	
	for( itr3=itemRatings[firstItem].begin(); itr3!=itemRatings[firstItem].end(); itr3++ ){
		itr4 = itemRatings[secondItem].find(itr3->first);
		if( itr4 != itemRatings[secondItem].end() ){
			dotProduct += itr3->second * itr4->second;
		}
		
		norm1 += (itr3->second*itr3->second);
	}
	norm1 = sqrt(norm1);
	
	for( itr4=itemRatings[secondItem].begin(); itr4!=itemRatings[secondItem].end(); itr4++ )
		norm2 += itr4->second*itr4->second;
	norm2 = sqrt(norm2);
	
	if( (norm1 > 0.0) && (norm2 > 0.0) )
		cosine = dotProduct/(norm1*norm2);
	
	return cosine;
}

bool comparisonFunctionAsc(const myPair &a,const myPair &b) {
    return ((a.score) > (b.score));
}

bool comparisonFunctionDesc(const myPair &a,const myPair &b) {
    return ((a.score) < (b.score));
}

void recommendItems(int userId, HashOfHashes &userRatings, HashOfHashes &itemRatings, std::ofstream &outputFile) {
	int numTrainingItems;
	int quartilSize;
	int numPairs;
	float meanSimilarityFL;
	float meanSimilarityFQ;
	float meanSimilarityLQ;
	float similarity;

	set<int> firstQuartil;
	set<int> lastQuartil;
	set<int>::iterator itr1;
	set<int>::iterator itr2;
	
	myPair auxilary;
	vector<myPair> temporaryVector;
	Hash::iterator itr;
	
	numTrainingItems = (int) userRatings[userId].size();
	quartilSize = numTrainingItems/4;
	if(quartilSize > MAX_SIZE)
		quartilSize = MAX_SIZE;
	
	for(itr=userRatings[userId].begin(); itr!= userRatings[userId].end(); itr++){
		auxilary.item = itr->first;
		auxilary.score = itr->second;
		temporaryVector.push_back(auxilary);
	}
	
	sort(temporaryVector.begin(), temporaryVector.begin()+numTrainingItems, comparisonFunctionDesc);
	for(int i=0;  i < quartilSize; i++) 
		firstQuartil.insert(temporaryVector[i].item);
	
	sort(temporaryVector.begin(), temporaryVector.begin()+numTrainingItems, comparisonFunctionAsc);
	for(int i=0;  i < quartilSize; i++) 
		lastQuartil.insert(temporaryVector[i].item);
	
	numPairs = 0;
	meanSimilarityFQ = 0.0;
	for(itr1=firstQuartil.begin(); itr1!=firstQuartil.end(); itr1++){
		for(itr2=itr1; itr2!=firstQuartil.end(); itr2++){
			if(itr1 != itr2){
				similarity = calculateCosineSimilarity(*itr1, *itr2, itemRatings);
			
				meanSimilarityFQ += similarity;
				numPairs++;
			}
		}
	}
	if(numPairs > 0)
		meanSimilarityFQ = meanSimilarityFQ/numPairs;

	numPairs = 0;
	meanSimilarityLQ = 0.0;
	for(itr1=lastQuartil.begin(); itr1!=lastQuartil.end(); itr1++){
		for(itr2=itr1; itr2!=lastQuartil.end(); itr2++){
			if(itr1 != itr2){
				similarity = calculateCosineSimilarity(*itr1, *itr2, itemRatings);
			
				meanSimilarityLQ += similarity;
				numPairs++;
			}
		}
	}
	if(numPairs > 0)
		meanSimilarityLQ = meanSimilarityLQ/numPairs;

	numPairs = 0;
	meanSimilarityFL = 0.0;
	for(itr1=firstQuartil.begin(); itr1!=firstQuartil.end(); itr1++){
		for(itr2=lastQuartil.begin(); itr2!=lastQuartil.end(); itr2++){
			similarity = calculateCosineSimilarity(*itr1, *itr2, itemRatings);
		
			meanSimilarityFL += similarity;
			numPairs++;
		}
	}
	if(numPairs > 0)
		meanSimilarityFL = meanSimilarityFL/numPairs;

	// print the user recommendations
	outputFile << meanSimilarityFQ << "\t" << meanSimilarityLQ << "\t" << meanSimilarityFL << std::endl;	
}


/****************************************************************************************
                             Load Functions
*****************************************************************************************/
void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings) {
	std::ifstream inputFile;
	std::string line, buffer, itemId, rating;
	std::vector<std::string> vetor;
	int userId;
	int numTimeUnits;
	int vectorSize;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	
	inputFile.open(trainFile);
	if( !(inputFile.is_open()) ) {
		std::cout << "\n\t***Error opening input file: " << trainFile << "\n\n";
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

				if(itr1 == userRatings.end() ){
					userRatings[userId][atoi(itemId.c_str())] = 0;
				}
				else{
					itr2 = userRatings[userId].find(atoi(itemId.c_str()));
					if(itr2 == userRatings[userId].end())
						userRatings[userId][atoi(itemId.c_str())] = 0;
				}
					
				itemRatings[atoi(itemId.c_str())][userId] = 1;
				userRatings[userId][atoi(itemId.c_str())] += 1;
			}
		}
	}
}

/****************************************************************************************
                             Get Functions
*****************************************************************************************/

int getArgs(int argc, char **argv, char **trainFileName, char **outFileName, int *numThreads) {
	int opt;
	*trainFileName = NULL;
	*outFileName = NULL;
	*numThreads = 1;

	while( (opt = getopt(argc, argv, "ht:o:p:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 't':
				*trainFileName = optarg;
				break;
			case 'o':
				*outFileName = optarg;
				break;
			case 'p':
				*numThreads = atoi(optarg);
				break;
			default: {
				printUsage();
				return 0;
			}
		}
	}

	if( *trainFileName == NULL || *outFileName == NULL || *numThreads <= 0 || *numThreads > 100 ) {
		printUsage();
		return 0;
	}

	return 1;
}

void string_tokenize(const std::string &str, std::vector<std::string> &tokens, const std::string &delimiters) {
        std::string::size_type lastPos = str.find_first_not_of(delimiters, 0);
        std::string::size_type pos = str.find_first_of(delimiters, lastPos);
        while (std::string::npos != pos || std::string::npos != lastPos) {
                tokens.push_back(str.substr(lastPos, pos - lastPos));
                lastPos = str.find_first_not_of(delimiters, pos);
                pos = str.find_first_of(delimiters, lastPos);
        }
}

/****************************************************************************************
                             Usage Function
*****************************************************************************************/

void printUsage() {
	std::string args = "";
	args += "\n    -t <trainFilename> ";
	args += "\n    -o <outFile> ";
	args += "\n    -p <numThreads> ";
	args += "\n    [-h]\n\n";
	std::cout << "\n  Argumentos corretos:\n" << args;
}
