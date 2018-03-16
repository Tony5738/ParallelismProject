#define nbEntries 20
#define noValue 0

typedef Log
{
	int current;
	int id[nbEntries];
	int arrivalDay[nbEntries];
	int arrivalTime[nbEntries];
	int departureDay[nbEntries];
	int departureTime[nbEntries];
};

Log logbook;

chan red = [0] of { byte };
chan green = [0] of { byte };
chan off = [0] of { byte };

chan unblocked = [0] of {byte};
chan blocked = [0] of {byte};

chan start = [0] of {byte};

chan alertIntrusion = [0] of {int};
chan alertFire = [0] of {int};
chan detFire = [0] of {int};

chan registerArrival = [0] of {int, int, int};
chan registerDeparture = [0] of {int, int, int};



//////////////////////////////////////////

init
{
	logbook.current = 0;
	
	run light('o');
	red!'r';
	green!'g';
	off!'o';

	run door('b');
	unblocked!'u';
	blocked!'b';

	/*run journal();
	registerArrival!123,1010,01012018;
	registerArrival!456,1010,02022018;
	registerDeparture!123,1010,01012018;*/

	run intrusionAlarm();
	alertIntrusion!noValue;

	run fireAlarm();
	run fireSensor();
	detFire!noValue;
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
		i++;
	:: else ->
		break;
	od

	if
	:: (i > logbook.current) ->
		printf("This person did not enter the building");
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
		i++;
	:: else ->
		break;
	od

	if
	:: i < logbook.current ->
		printf("%d is inside the building\n", _id);
	:: else ->
		printf("%d is not inside the building\n", _id);
	fi	
}

inline displayLogbook()
{
	atomic
	{
		int i=0;
		printf("----------\nEntries: \n");

		do
		:: i<logbook.current ->
			printf("%d: %d %d, %d %d\n", logbook.id[i], logbook.arrivalDay[i], logbook.arrivalTime[i], logbook.departureDay[i], logbook.departureTime[i]);
			i++;
		:: else ->
			break;
		od

		printf("----------\n");
	};
}

proctype light(byte state)
{
	

	if
	::red?state;
		printf("light:state %c\n" ,state);
		run light(state);
	::green?state;
		printf("light:state %c\n" ,state);
		run light(state);
	::off?state;
		printf("light:state %c\n" ,state);
		run light(state);
	fi

	
}

proctype door(byte state)
{
	if
	::unblocked?state;
		printf("door:state %c\n" ,state);
		run door(state);
	::blocked?state;
		printf("door:state %c\n" ,state);
		run door(state);
	fi

}

proctype intrusionAlarm()
{
	alertIntrusion?_;
	printf("Alerte intrusion !\n");
}

proctype fireAlarm()
{
	alertFire?_;
	printf("Alerte incendie !\n");
}

proctype fireSensor()
{
	detFire?_;
	alertFire!noValue;
	unblocked!'u';
	atomic {
		printf("People in the building:\n");
		displayLogbook();	
	};
}

proctype journal()
{
	int id, day, time;
	if
	::registerArrival?id, day, time;
		addEntry(id, day, time);
	::registerDeparture?id, day, time;
		completeEntry(id, day, time);
	fi
}