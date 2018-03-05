typedef Log
{
	int id[9999];
	int arrivalDay[9999];
	int arrivalTime[9999];
	int departureDay[9999];
	int departureTime[9999];
	int current;
};

Log logbook;
chan register = [0] of {int, int, int};



//////////////////////////////////////////

init
{
	logbook.current = 0;

	run journal();
}

inline addEntry(_id, _day, _time)
{
	logbook.id[logbook.current] = _id;
	logbook.arrivalDay[logbook.current] = _day;
	logbook.arrivalTime[logbook.current] = _time;
	logbook.current++;
}

inline completeEntry(_id, _day, _time)
{
	int i=0;

	do
	:: logbook.id[i] != _id && logbook.departureDay[i] == 0 ->
		i++
	:: else ->
		break
	od

	if
	:: (i > logbook.current) ->
		printf("This person did not enter the building")
	:: else ->
		logbook.departureDay[i] = _day;
		logbook.departureTime[i] = _time;
	fi
	
}

inline checkIsInside(_id)
{
	int i=0;
	do
	:: i < logbook.current && logbook.id[i] != _id || (logbook.id[i] == _id && logbook.departureDay[i] != 0) ->
		i++
	:: else ->
		break
	od

	if
	:: i < logbook.current ->
		printf("%d is inside the building\n", _id)
	:: else ->
		printf("%d is not inside the building\n", _id)
	fi	
}

inline displayLogbook()
{
	int i=0;
	printf("----------\nEntries: \n");

	do
	:: i<logbook.current ->
		printf("%d: %d %d, %d %d\n", logbook.id[i], logbook.arrivalDay[i], logbook.arrivalTime[i], logbook.departureDay[i], logbook.departureTime[i])
		i++
	:: else ->
		break
	od

	printf("----------\n");
}

proctype journal()
{atomic{
	printf("Journal\n");

	displayLogbook();
	checkIsInside(123); // is not

	addEntry(123, 01012018, 1010);
	displayLogbook();
	checkIsInside(123); // is

	addEntry(456, 01012018, 1111);
	displayLogbook();
	checkIsInside(123); // is

	completeEntry(123, 01012018, 1212);
	displayLogbook();
	checkIsInside(123); // is not

	atomic{ displayLogbook(); };}
}

proctype displayTest()
{
	printf("TEST\n");
}