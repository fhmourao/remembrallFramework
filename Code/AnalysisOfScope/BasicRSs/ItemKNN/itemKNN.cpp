#include "itemKNN.h"

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;

int main(int argc, char **argv) {
	char *trainFileName;
	char *testFileName;
	char *outFileName;
	int K;
	int TOP_N;
	int numThreads;
	int numTestUsers;
	float globalAverage;
	
	std::set<int> testUsers;
	Hash userBias;
	Hash itemBias;
	HashOfHashes itemRatings;
	HashOfHashes userRatings;
	HashOfHashes itemSimilarities;

	// checa a validade dos parâmetros de entrada passados pela linha de comando
	if(!getArgs(argc, argv, &trainFileName, &testFileName, &outFileName, &numThreads, &K, &TOP_N)) {
		return 1;
	}

	std::cout << "loading training data...\n" << flush;
	loadTrainData(trainFileName, itemRatings, userRatings, globalAverage);
	
	std::cout << "loading test data...\n" << flush;
	loadTestData(testFileName, testUsers);
	
	defineIndividualBias(userRatings, userBias, itemRatings, itemBias, globalAverage);
	
	// verifica se ah registros a serem avaliados
	numTestUsers = (int) testUsers.size();
	if(numTestUsers == 0)
		return 0;
	
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
		params[i].K = K;
		params[i].TOP_N = TOP_N;
		params[i].globalAverage = globalAverage;
		params[i].itemBias = &itemBias;
		params[i].userBias = &userBias;
		params[i].testUsers = &testUsers;
		params[i].itemRatings = &itemRatings;
		params[i].userRatings = &userRatings;
		params[i].itemSimilarities = &itemSimilarities;
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
	std::set<int>::iterator itr;
	
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
	for ( itr = (*param->testUsers).begin(); itr != (*param->testUsers).end(); itr++) {
		modulus = (currentPosition - (param->threadId + 1)) % param->numThreads;
		if( modulus == 0 ){
			recommendItems(*itr, (*param->userRatings), (*param->itemRatings), (*param->itemSimilarities),  (*param->userBias), (*param->itemBias), param->K, param->TOP_N, param->globalAverage, outputFile);
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

void calculateItemBiases(HashOfHashes &itemRatings, Hash &itemBias, Hash &userBias, float globalAverage){
	int itemId;
	int userId;
	float rating;
	int numRatings;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	
	for(itr1 = itemRatings.begin(); itr1 != itemRatings.end(); itr1++){
		itemId = itr1->first;
		
		numRatings = 0;
		itemBias[itemId] = 0.0;
		for(itr2 = itemRatings[itemId].begin(); itr2 != itemRatings[itemId].end(); itr2++ ){
			userId = itr2->first;
			rating = itr2->second;
			itemBias[itemId] += rating - globalAverage - userBias[userId];
			numRatings++;
		}
		
		itemBias[itemId] = itemBias[itemId] / ((float) (ITEM_REGULARIZATION + numRatings));
	}
}

void calculateUserBiases(HashOfHashes &userRatings, Hash &userBias, Hash &itemBias, float globalAverage){
	int itemId;
	int userId;
	float rating;
	int numRatings;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	
	for(itr1 = userRatings.begin(); itr1 != userRatings.end(); itr1++){
		userId = itr1->first;
		
		numRatings = 0;
		userBias[userId] = 0.0;
		for(itr2 = userRatings[userId].begin(); itr2 != userRatings[userId].end(); itr2++ ){
			itemId = itr2->first;
			rating = itr2->second;
			userBias[userId] += rating - globalAverage - itemBias[itemId];
			numRatings++;
		}
		
		userBias[userId] = userBias[userId] / ((float) (USER_REGULARIZATION + numRatings));
	}
}

void defineIndividualBias(HashOfHashes &userRatings, Hash &userBias, HashOfHashes &itemRatings, Hash &itemBias, float globalAverage){
	
	for(int i=0; i< NUM_ITERACTIONS; i++){
		calculateUserBiases(userRatings, userBias, itemBias, globalAverage);
		calculateItemBiases(itemRatings, itemBias, userBias, globalAverage);
	}
	
}

void getKNNItems(int itemId, int K, HashOfHashes &itemRatings, HashOfHashes &itemSimilarities, multiset<myPair,eq> &candidateSet){
	myPair auxilary;
	int numNeighbors;
	float similarity = 0.0;
	
	HashOfHashes::iterator itr1;
	Hash::iterator itr2;
	HashOfHashes::iterator itr3;
	multiset<myPair,eq>::iterator itr4;
	
	// verify whether the KNN have been completely calculated for itemId
	itr1 = itemSimilarities.find(itemId);
	if( itr1 != itemSimilarities.end() ){
		itr2 = itemSimilarities[itemId].find(INVALID_VALUE);
		if( itr2 == itemSimilarities[itemId].end() )
			itr1 = itemSimilarities.end();
	}
	
	// If not, calculate now
	if( itr1 == itemSimilarities.end() ){
		// for each distinct item
		for(itr1= itemRatings.begin(); itr1!= itemRatings.end(); itr1++){
			if( itr1->first != itemId){
				similarity = INVALID_VALUE;
				
				//retrieve already calculated similarity
				itr3 = itemSimilarities.find(itr1->first);
				if( itr3 != itemSimilarities.end() ){
					
					similarity = 0.0;
					itr2 = itemSimilarities[itr1->first].find(itemId);
					if( itr2 != itemSimilarities[itr1->first].end() ){
						
						similarity = itemSimilarities[itr1->first][itemId];
					}
				}
				
				//calculate and store similarity
				if( similarity == INVALID_VALUE )
					similarity = calculateCosineSimilarity(itemId, itr1->first, itemRatings);
				
				if( (similarity < 0.0) || (similarity > 0.0) ){
					pthread_mutex_lock( &mutex );
						itemSimilarities[itemId][itr1->first] = similarity;
					pthread_mutex_unlock( &mutex );
				}
			}
		}
		
		// create a sign informing that have finished with this item
		pthread_mutex_lock( &mutex );
			itemSimilarities[itemId][INVALID_VALUE] = 1;
		pthread_mutex_unlock( &mutex );

	}

	// retrieve neighbors
	numNeighbors = 0;
	for(itr2 = itemSimilarities[itemId].begin(); itr2 != itemSimilarities[itemId].end(); itr2++){
		auxilary.item = itr2->first;
		auxilary.score = itr2->second;
				
		candidateSet.insert(auxilary);
		numNeighbors++;
	}
	
        // remove neighbors less similar
        if( numNeighbors > K ){
                pthread_mutex_lock( &mutex );
                        numNeighbors = 0;
                        for(itr4= candidateSet.begin(); itr4 != candidateSet.end(); itr4++){
                                numNeighbors++;
                                auxilary = *itr4;
                                if( (numNeighbors > K) || !(auxilary.score > 0.0) )
                                        itemSimilarities[itemId].erase(auxilary.item);
                        }
                        itemSimilarities[itemId][INVALID_VALUE] = -1;
                pthread_mutex_unlock( &mutex );
        }
}

inline float getValidScore(float score){
	if( score < MIN_SCORE )
		score = MIN_SCORE;
	if( score > MAX_SCORE )
		score = MAX_SCORE;
	
	return score;
}

void recommendItems(int userId, HashOfHashes &userRatings, HashOfHashes &itemRatings, HashOfHashes &itemSimilarities, Hash &userBias, Hash &itemBias, int K, int TOP_N, float globalAverage, std::ofstream &outputFile) {
	myPair auxilary;
	
	float baseline;
	int candidate;
	int counter1;
	int counter2;
	float finalScore;
	int itemId;
	float rating;
	float similarity;
	
	multiset<myPair,eq> candidateSet;
	Hash itemScore;
	Hash itemWeight;
	multiset<myPair,eq> resultSet;
	
	Hash::iterator itr;
	multiset<myPair,eq>::iterator itr1;
	Hash::iterator itr2;
	
	//for each item consumed by userId in the training identify the KNN items
	for(itr= userRatings[userId].begin(); itr!= userRatings[userId].end(); itr++){
			itemId = itr->first;
			rating = itr->second;
			baseline = getValidScore(globalAverage + userBias[userId] + itemBias[itemId]);
			
			// retrieve candidate set
			getKNNItems(itemId, K, itemRatings, itemSimilarities, candidateSet);
			
			//for each candidate item
			counter1 = 0;
			for(itr1= candidateSet.begin(); itr1 != candidateSet.end(); itr1++){
				auxilary = *itr1;
				candidate = auxilary.item;
				similarity = auxilary.score;
				
				// verify whether it have been consumed by userId
				itr2 = userRatings[userId].find(candidate);
				if( itr2 != userRatings[userId].end() )
					continue;
			
				itr2 = itemScore.find(candidate);
				if( itr2 != itemScore.end() ){
					itemScore[candidate] += similarity * (rating - baseline);
					itemWeight[candidate] += similarity;
				}
				else{
					itemScore[candidate] = similarity * (rating - baseline);
					itemWeight[candidate] = similarity;
				}
				
				counter1++;
			}
		
			candidateSet.clear();
	}
	
	// copy item from hash to ordered multiset structure
	counter2 = 0;
	for(itr2 = itemScore.begin(); (itr2 != itemScore.end() && counter2 < TOP_N); itr2++){
		finalScore = itr2->second/itemWeight[itr2->first];
		auxilary.item = itr2->first;
		auxilary.score = getValidScore(finalScore + globalAverage + userBias[userId] + itemBias[auxilary.item]);

		resultSet.insert(auxilary);
		counter2++;
	}
	itemScore.clear();
	itemWeight.clear();
		
	// print the user recommendations
	outputFile << userId;
	for(itr1= resultSet.begin(); itr1 != resultSet.end(); itr1++){
		auxilary = *itr1;
		outputFile << " " << auxilary.item << ":" << auxilary.score;
	}
	outputFile << std::endl;
	
	resultSet.clear();
}


/****************************************************************************************
                             Load Functions
*****************************************************************************************/

void loadTestData(char *testFile, std::set<int> &testUsers) {
	std::ifstream file;
	std::string line;
	std::vector<std::string> vetor;
	int userId;

	file.open(testFile);

	if(!file.is_open()) {
		std::cout << "\nError opening file!" << endl;
		std::exit(-1);
	}

	while(!file.eof()) {
		getline(file, line);

		// separa a linha através do delimitador " " e salva o resultado em um vetor
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		userId = atoi(vetor[0].c_str());
		testUsers.insert(userId);
	}

	file.close();
}

void loadTrainData(char *trainFile, HashOfHashes &itemRatings, HashOfHashes &userRatings, float &globalAverage) {
	std::ifstream file;
	std::string line;
	int itemId;
	float rating;
	std::vector<std::string> vetor;
	int userId;
	int numRatings = 0;

	file.open(trainFile);

	if(!file.is_open()) {
		std::cout << "\nError opening file!" << endl;
		std::exit(-1);
	}

	globalAverage = 0.0;
	while(!file.eof()) {
		getline(file, line);

		// separa a linha através do delimitador " " e salva o resultado em um vetor
		vetor.clear();
		string_tokenize(line, vetor, " \t");
		userId = atoi(vetor[0].c_str());
		itemId = atoi(vetor[1].c_str());
		rating = atof(vetor[2].c_str());

		if(rating > MAX_SCORE)
			MAX_SCORE = rating;
		
		if(MIN_SCORE > rating)
			MIN_SCORE = rating;

		itemRatings[itemId][userId] = rating;
		userRatings[userId][itemId] = rating;
		
		globalAverage += rating;
		numRatings++;

	}
	
	globalAverage = globalAverage/((float) numRatings);

	file.close();
}

/****************************************************************************************
                             Get Functions
*****************************************************************************************/

int getArgs(int argc, char **argv, char **trainFileName, char **testFileName, char **outFileName, int *numThreads, int *K, int *TOP_N) {
	int opt;
	*trainFileName = NULL;
	*outFileName = NULL;
	*testFileName = NULL;
	*numThreads = 1;
	*K = 80;
	*TOP_N = -1;

	while( (opt = getopt(argc, argv, "ht:e:o:n:k:p:")) != -1 ) {
		switch(opt) {
			case 'h':
				printUsage();
				return 0;
				break;
			case 't':
				*trainFileName = optarg;
				break;
			case 'e':
				*testFileName = optarg;
				break;
			case 'o':
				*outFileName = optarg;
				break;
			case 'p':
				*numThreads = atoi(optarg);
				break;
			case 'k':
				*K = atoi(optarg);
				break;
			case 'n':
				*TOP_N = atoi(optarg);
				break;
			default: {
				printUsage();
				return 0;
			}
		}
	}

	if( *trainFileName == NULL || *testFileName == NULL || 
	    *outFileName == NULL || *numThreads <= 0 || *numThreads > 100 || *K < 0 || *TOP_N == -1) {
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
	args += "\n    -e <testFile> ";
	args += "\n    -p <numThreads> ";
	args += "\n    -n <number of item to recommend> ";
	args += "\n    [-k] <number of neighbors -- default: 80> ";
	args += "\n    [-h]\n\n";
	std::cout << "\n  Argumentos corretos:\n" << args;
}
