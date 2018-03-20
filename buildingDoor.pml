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
bool isInside = false;

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

chan getInfoIn = [0] of {int, int, int};
chan getInfoEx = [0] of {int, int, int};



//////////////////////////////////////////

inline wait(x)
{
	int a = 0;
	do
		::a!=x->a++;
		::a==x->break
	od
}

init
{
	logbook.current = 0;
	
	run light('o');

	run door('b');
	run laser(0);
	run journal();
	run externalCardReader();
	run internalCardReader();

	run intrusionAlarm();

	run fireAlarm();
	run fireSensor();
	run command();
}



inline addEntry(_id, _day, _time)
{
	atomic
	{
		logbook.id[logbook.current] = _id;
		logbook.arrivalDay[logbook.current] = _day;
		logbook.arrivalTime[logbook.current] = _time;
		logbook.current++;	
	}
}

inline completeEntry(_id, _day, _time)
{
	int i=0;

	do
	:: logbook.id[i] != _id || (logbook.id[i] == _id && logbook.departureDay[i] != 0) ->
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
		isInside = true;
	:: else ->
		isInside = false;
	fi	
}

inline checkIsValid(_id)
{
	if
	:: _id < 1000 ->
		isValid = true;
	:: else ->
		isValid = false;
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
			activate!noValue;
			//wait(3000);//30s
			run door(state)
		::blocked?_;
			state= 'b';
			printf("door:state %c\n" ,state);
			deactivate!noValue;
			run door(state)
	fi

}


proctype laser(int passageCounter)
{
		
	
	if
		::activate?_;
			printf("laser:active\n");	
			

			do
				::deactivate?_;
					
					
					printf("laser:deactive\n");
					passageCounter=0;
					//run laser(passageCounter);
					break	
					
					
				::detection?_;
						
					atomic{
						passageCounter++;
						printf("laser:detection %d\n",passageCounter);
						if
							::passageCounter > 1 -> alertIntrusion!noValue //TODO see for another better solution
							::else -> printf("Ok\n")
						fi;
					}
					
						
			od;


		::detection?_;
			printf("Not activate\n");
		::deactivate?_;
			printf("Not activate\n");
			

	fi

	run laser(passageCounter)
	
	
	


}

proctype intrusionAlarm()
{
	alertIntrusion?_;
	printf("Intrusion alert!\n");
	run intrusionAlarm()
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
	deactivate!noValue; // TODO: pour éviter les détections d'intrusion en cas d'incendie
	atomic {
		printf("People in the building:\n");
		displayLogbook();	
	};
	run fireSensor();
}

proctype externalCardReader()
{
	int id, day, time;

	getInfoEx?id, day, time;
	atomic
	{
		checkIsValid(id);
		if
		:: isValid == true ->
			green!noValue;
			registerArrival!id, day, time;
			unblocked!noValue;
			wait(3000); // 30s
			blocked!noValue;
			isValid = false;
		:: else ->
			printf("Cannot enter building\n");
			red!noValue;
			blocked!noValue;
		fi
	};
	run externalCardReader();
}

proctype internalCardReader()
{
	int id, day, time;

	getInfoIn?id, day, time;
	atomic
	{
		checkIsInside(id);
		if
		:: isInside == true ->
			green!noValue;
			registerDeparture!id, day, time;
			unblocked!noValue;
			wait(3000); // 30s
			blocked!noValue;
			isInside = false;
		:: else ->
			printf("Cannot leave building\n");
			red!noValue;
			blocked!noValue;
		fi
	};

	run internalCardReader();
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

proctype command()
{
	printf("-------------------\n");
	printf("START OF THE SYSTEM\n");

	printf("\n- Id#123 enters the bulding at 16:00 16/03/2018\n");
	getInfoEx!123,16032018,1600; // they put their cards
	detection!noValue; // they go through the door
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- Id#456 enters the bulding at 16:15 16/03/2018\n");
	getInfoEx!456,16032018,1615; // they put their cards
	detection!noValue; // they go through the door
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- Id#123 leaves the bulding at 16:45 16/03/2018\n");
	getInfoIn!123,16032018,1645; // they put their cards
	detection!noValue; // they go through the door
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- Id#123 leaves the bulding again at 16:46 16/03/2018 (and shouldn't be able to, already outside)\n");
	getInfoIn!123,16032018,1646; // they put their cards
	detection!noValue; // they go through the door
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- Id#789 enters the bulding at 17:00 16/03/2018 (but 3 other people try to enter)\n");
	getInfoEx!789,16032018,1700; // they put their cards
	detection!noValue; // they go through the door
	detection!noValue; // another goes through
	detection!noValue; // and another
	detection!noValue; // and another
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- Id#1230 wants to enter the bulding at 17:15 16/03/2018 (and shouldn't be able to, incorrect id)\n");
	getInfoEx!1230,16032018,1715; // they put their cards
	wait(500);

	printf("\n- Id#123 enters the bulding at 17:30 16/03/2018\n");
	getInfoEx!123,16032018,1730; // they put their cards
	detection!noValue; // they go through the door
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- The logbook currently:\n");
	displayLogbook();
	wait(500);

	printf("\n- A fire is starting\n");
	detFire!noValue;
	detection!noValue; // they go through the door
	detection!noValue; // they go through the door


}
