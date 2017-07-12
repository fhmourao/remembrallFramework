CC = g++
LIBS = -lm 
#CFLAGS = -Wall -c -fPIC -O3 -fomit-frame-pointer -ffast-math -DREENTRANT
CFLAGS = -Wall -c -g -DDEBUG -fPIC -std=c++0x
# PROGFLAGS = $(LIBS) -fPIC -O3 -fomit-frame-pointer -ffast-math -DREENTRANT
PROGFLAGS = $(LIBS) -fPIC -DREENTRANT

EXE = sampleTrainingItems
OBJ = snapshot.o User.o recommendation.o IO.o sampleTrainingItems.o

all: $(OBJ)
	$(CC) $(PROGFLAGS) $(OBJ) -o $(EXE)

snapshot.o: snapshot.h snapshot.cpp
	$(CC) $(CFLAGS) snapshot.cpp -o snapshot.o
	
User.o: User.h User.cpp
	$(CC) $(CFLAGS) User.cpp -o User.o

recommendation.o: recommendation.h recommendation.cpp
	$(CC) $(CFLAGS) recommendation.cpp -o recommendation.o

IO.o: IO.h IO.cpp
	$(CC) $(CFLAGS) IO.cpp -o IO.o

sampleTrainingItems.o: sampleTrainingItems.h sampleTrainingItems.cpp
	$(CC) $(CFLAGS) sampleTrainingItems.cpp -o sampleTrainingItems.o

clean:
	rm -f .*.swp *~ $(OBJ) $(EXE)

backup:
	tar -cvzf backups/`date +%Y-%m-%d-%H.%M`.tar.gz *.h *.cpp Makefile 
