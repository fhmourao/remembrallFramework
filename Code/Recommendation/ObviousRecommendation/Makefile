CC = g++
LIBS = -lm 
#CFLAGS = -Wall -c -fPIC -O3 -fomit-frame-pointer -ffast-math -DREENTRANT
CFLAGS = -Wall -c -g -DDEBUG -fPIC -std=c++0x
# PROGFLAGS = $(LIBS) -fPIC -O3 -fomit-frame-pointer -ffast-math -DREENTRANT
PROGFLAGS = $(LIBS) -fPIC -DREENTRANT

EXE = retriveObviousItems
OBJ = snapshot.o User.o recommendation.o IO.o retriveObviousItems.o

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

retriveObviousItems.o: retriveObviousItems.h retriveObviousItems.cpp
	$(CC) $(CFLAGS) retriveObviousItems.cpp -o retriveObviousItems.o

clean:
	rm -f .*.swp *~ $(OBJ) $(EXE)

backup:
	tar -cvzf backups/`date +%Y-%m-%d-%H.%M`.tar.gz *.h *.cpp Makefile 
