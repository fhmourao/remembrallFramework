/************************************************************************
                            relevanceDistribution.cpp
************************************************************************/

#include "relevanceDistribution.h"

/* construtor */
relevanceDistribution::relevanceDistribution() {
	this->fallPoint = -1.0;
	this->lapsePoint = -1.0;
}


/* destrutor */
relevanceDistribution::~relevanceDistribution() {
	
	this->fallPoint = -1.0;
	this->lapsePoint = -1.0;

// 	delete[] &this->distribution;
}


/**** Get functions ****/
float relevanceDistribution::getFallPoint(){
	return this->fallPoint;
}

float relevanceDistribution::getLapsePoint(){
	return this->lapsePoint;
}

void relevanceDistribution::printDistribution(){
	std::multiset<float, eq>::iterator itr;
	
// 	std::cout << "Number of items : " << (int)  this->distribution.size() << "\n\t";
	for(itr=this->distribution.begin(); itr!=this->distribution.end(); itr++)
		std::cout << " " << *itr;
	std::cout << "\n\n";
}

/**** Set functions ****/
void relevanceDistribution::setDistribution(std::vector<snapshot> &history){
	std::vector<snapshot>::iterator itr;
	float probability;
	int sumOfFrequencies;
	
	std::vector<int>::iterator itr1;
	std::vector<int> currentFrequencies;

	//for each snapshot
	for(itr=history.begin(); itr!=history.end(); itr++){
		snapshot currentSnapshot = *itr;
		sumOfFrequencies = currentSnapshot.getSumOfFrequencies();
		
		currentFrequencies = currentSnapshot.getConsumptionFrequencies();
		for( itr1=currentFrequencies.begin(); itr1!=currentFrequencies.end(); itr1++ ){
			probability = ((float)  *itr1)/((float) sumOfFrequencies);
			this->distribution.insert(probability);
		}
	}

	//define critical points related to the distribution
	setCriticalPoints();
	
}

/********** Private Functions **************/

// Implement the Newton DIvied Differences in order to find the second derivative, which is defined as the fall point.
// The lapse point is defined ad the point at each the first derivative is equal to zero
void relevanceDistribution::setCriticalPoints(){
	
	this->fallPoint = dividedDifferencesMethod();
	this->lapsePoint = finiteDifferencesMethod();
	
}
	
float relevanceDistribution::dividedDifferencesMethod(){	
	int numItems = this->distribution.size();
	int rank;
	float secondNorm;
	float minDifference;
	float binSize;
	
// 	std::map<int, int> pointer = binMap;
	std::vector<float> sigma;
	std::multiset<float, eq>::iterator itr1;
	std::vector<float>::iterator itr;
	std::vector<float> sigmaNorm;
	std::vector<float> secondDerivative;
	int quotient;
	
	//copying distribution for a temporary vector
	for(itr1= this->distribution.begin(); itr1!=this->distribution.end(); itr1++)
			sigma.push_back(*itr1);
	
	//initializing second derivatives
	secondNorm = sigma[1];
	for(itr=sigma.begin(); itr!=sigma.end(); itr++){
		sigmaNorm.push_back(*itr / secondNorm);
		secondDerivative.push_back(0.0);
	}

	//curve approximating the second derivative 
	minDifference = 1.0;
	for(int i=1; i<(numItems-1); i++){
		secondDerivative[i] = fabs(sigmaNorm[i-1] - 2*sigmaNorm[i] + sigmaNorm[i+1]);
		std::cout << secondDerivative[i] << "\n";
		
		//identify the smallest divided difference
		if( secondDerivative[i] < minDifference ){
			minDifference = secondDerivative[i];
		}
	}

	//search rank
	rank = numItems - 1;
	while (rank > 1){ 
		rank = rank - 1;
		if ( secondDerivative[rank] >= MIN_PRECISION ){
			break;
		}
	} 

	std::cout << "Rank: " << rank << "\t Prob: " << sigma[rank] << "\n";
	return sigma[rank];
}

//TODO
float relevanceDistribution::finiteDifferencesMethod(){
	float result = 0.0;
	
	return result;
}

float relevanceDistribution::simpsonMethod(float upperBound, float lowerBound, std::vector<float> &samples){
	float h;
	float sum;
	int numSamples = (int) samples.size();

	h = (lowerBound - upperBound) / (float) numSamples;
	sum = sample[0];

	//even numbers
	for(int i=2; i<(numSamples-1); i+=2){
		sum += 2*sample[i];
	}

	//odd numbers
	for(int i=1; i<(numSamples-1); i+=2){
		sum += 4*sample[i];
	}

	sum += sample[numSample-1];

	sum = sum * h/3;

	return sum;
}

lowerBound
upperBound
interval = lowerBound - upperBound;
pieceSize =  interval/NUM_POINTS;

for(int point=0; point<(NUM_POINTS-1); point++){
	firstLowerBound = lowerBound + point*pieceSize;
	firstUpperBound = upperBound + point*pieceSize;

	secondLowerBound = lowerBound + (point+1)*pieceSize;
	secondUpperBound = upperBound + (point+1)*pieceSize;

	firstPiece.clear();
	secondPiece.clear();
	for( itr=differences.begin(); itr!=differences.end(); itr++){
		if( (*itr >= firstLowerBound ) && ( *itr <= firstUpperBound) )
			firstPiece.push_back(*itr);
		
		if( (*itr >= secondLowerBound ) && ( *itr <= secondUpperBound) )
			firstPiece.push_back(*itr);
	}
		
	firstArea = simpsonMethod(firstUpperBound, firstLowerBound, firstPiece);
	secondArea = simpsonMethod(secondUpperBound, secondLowerBound, secondPiece);
	sumOfAreas = firstArea + secondArea;
	
	firstUpperBound = firstUpperBound - firstUpperBound/2;
	secondLowerBound = secondLowerBound - firstUpperBound/2;
	
}

lowerBound
upperBound
interval = lowerBound - upperBound;
pieceSize =  interval/3;

firstPoint = lowerBound + pieceSize;
secondPoint = upperBound - pieceSize;
do {

	shiftDirection = -1;
	hasReducedSumOfAreas = recalculateArea(lowerBound, firsPoint, secondPoint, shiftDirection, distribution);
	
	if( !hasReducedSumOfAreas ){
		shiftDirection = 1;
		hasReducedSumOfAreas = recalculateArea(lowerBound, firsPoint, secondPoint, shiftDirection, distribution);
		
	}
	
	shiftDirection = -1;
	hasReducedSumOfAreas = recalculateArea(firsPoint, secondPoint, upperBound, shiftDirection, distribution);
	
	if( !hasReducedSumOfAreas ){
		shiftDirection = 1;
		hasReducedSumOfAreas = recalculateArea(firsPoint, secondPoint, upperBound, shiftDirection, distribution);
		
	}
	
	
	
} while( (firstPoint != originalFirstPoint) || (secondPoint != originalSecondPoint) );

int inline recalculateArea(lowerBound, middlePoint, upperBound, shiftDirection, distribution){

	area1 = simpsonMethod(lowerBound, middlePoint, distribution);
	area2 = simpsonMethod(middlePoint, upperBound, distribution);
	sumOfArea = area1 + area2;

	hasReducedSumOfAreas = 0;
	
	auxilaryPoint = middlePoint;
	
	for(int numAttempts=0; numAttempts<MAX_ATTEMPTS; numAttempts++){
		auxilaryPoint = auxilaryPoint/2;
		if( shiftDirection < 0 )
			repositioning = middlePoint - auxilaryPoint;
		else
			repositioning = middlePoint + auxilaryPoint;
		
		newArea1 = simpsonMethod(lowerBound, repositioning, distribution);
		newArea2 = simpsonMethod(repositioning, upperBound, distribution);
		sumOfNewArea = newArea1 + newArea2;
		
		if(sumOfNewArea < sumOfArea){
			hasReducedSumOfAreas = 1;
			middlePoint = repositioning;
			sumOfArea = sumOfNewArea;
		}
	}
}
	

/* Descricao do algoritmo:
 * 
 * 
 * objetivo: minimizar a area entre a curva e a reta traçada entre os dois extremos de cada partição da curva
 * algoritmo:
 *          do
 * 		Para cada ponto
 *	 		determina as coordenadas de cada ponto (as particoes iniciais sao equidistantes)
 *      	        para cada ponto calcula-se a soma das areas de suas duas particoes adjacentes
 * 
 * 			tenta-se reduzir a primeira particao do ponto com passos logaritmos enquanto a soma das areas for reduzindo
 * 			ou
 * 			tenta-se aumentar a primeira particao do ponto com passos logaritmos enquanto a soma das areas for reduzindo
 * 
 *         while algum ponto se alterar
 * 
 */
