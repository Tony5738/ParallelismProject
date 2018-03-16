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

bool isValid = false;

//light
chan red = [0] of { byte };
chan green = [0] of { byte };
chan off = [0] of { byte };
//door
chan unblocked = [0] of {byte};
chan blocked = [0] of {byte};
//laser

chan deactivate = [0] of {byte};
chan detection = [0] of {byte};
chan activate = [0] of {byte};

chan alertIntrusion = [0] of {int};
chan alertFire = [0] of {int};
chan detFire = [0] of {int};

chan registerArrival = [0] of {int, int, int};
chan registerDeparture = [0] of {int, int, int};

chan getInfo = [0] of {int, int, int};



//////////////////////////////////////////

init
{
	logbook.current = 0;
	
	run light('o');
	red!noValue;
	green!noValue;
	off!noValue;

	run door('b');
	unblocked!noValue;
	blocked!noValue

	run laser('d',0);
	activate!noValue;
	deactivate!noValue;

	run journal();
	registerArrival!123,1010,01012018;
	registerArrival!456,1010,02022018;
	registerDeparture!123,1010,01012018;

	run externalCardReader();
	getInfo!789, 2222, 16032018;

	run intrusionAlarm();
	alertIntrusion!noValue;

	run fireAlarm();
	run fireSensor();
	detFire!noValue;
}

inline wait(x)
{
	int a = 0;
	do
		::a!=x->a++;
		::a==x->break
	od
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

inline checkIsValid(_id)
{
	if
	:: _id < 1000 ->
		isValid = true;;
	fi	
}

inline displayLogbook()
{
	atomic
	{
		int i=0;
		printf("--------- \n");

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
		::red?_;
			state= 'r';
			printf("light:state %c\n" ,state);
			//wait(5000000);//5s
			run light(state)
		::green?_;
			state= 'g';
			printf("light:state %c\n" ,state);
			//wait(5000000);//5s
			run light(state)
		::off?_;
			state= 'o';
			printf("light:state %c\n" ,state);
			run light(state)
	fi

	
}

proctype door(byte state)
{
	if
	::unblocked?_;
		state= 'u';
		printf("door:state %c\n" ,state);
		//wait(30000000);//30s
		run door(state)
	::blocked?_;
		state= 'b';
		printf("door:state %c\n" ,state);
		run door(state)
	fi

}


proctype laser(byte state; int passageCounter)
{
	
	if
		::activate?_;
			state = 'a'; 
			printf("laser:active %c\n", state);
			run laser(state, passageCounter)
		::deactivate?_;
			state = 'd';
			printf("laser:deactive %c\n", state);
			passageCounter=0;
			run laser(state, passageCounter)
		::detection?_;
			passageCounter++;
			if
				::passageCounter >1;
					alertIntrusion!noValue
			fi;
			run laser(state, passageCounter)
	fi
}

proctype intrusionAlarm()
{
	alertIntrusion?_;
	printf("Intrusion alert!\n");
	run intrusionAlarm();
}

proctype fireAlarm()
{
	alertFire?_;
	printf("Fire alert!\n");
	run fireAlarm();
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
	run fireSensor();
}

proctype externalCardReader()
{
	int id, day, time;

	getInfo?id, day, time;
	atomic
	{
		checkIsValid(id);
		if
		:: isValid == true ->
			green!noValue;
			registerArrival!id, day, time;
			unblocked!noValue;
			isValid = false;
		:: else ->
			red!noValue;
			blocked!noValue;
		fi
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
	run journal();
}
