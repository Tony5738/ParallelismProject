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

//Boolean to know if he can enter
bool isValid = false;
//Boolean to know if is really inside
bool isInside = false;

int nbPassages = 0;

bool doorOpened = false;

bool isFire = false;

//card id
int ident;


//light
chan red = [0] of { byte };
chan green = [0] of { byte };
chan off = [0] of { byte };

//lightCommand
chan putColor = [1] of { chan };


//door
chan unblocked = [0] of {byte};
chan blocked = [0] of {byte};


//laser
chan detection = [0] of {int};
chan resetLaser = [0] of {int};



//intrusion alert and fire alert
chan alertIntrusion = [0] of {int};
chan alertFire = [0] of {int};
chan detFire = [0] of {int};

//Journal
chan registerArrival = [0] of {int, int, int};
chan registerDeparture = [0] of {int, int, int};

//CardReaders
chan getInfoIn = [0] of {int, int, int};
chan getInfoEx = [0] of {int, int, int};
chan registration = [0] of {int};
chan cancelRegistration = [0] of {int};

//simulation
chan STDIN;
chan in = [0] of {int};
chan out = [0] of {int};






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
	

	run simulation();
	run lightCommand();
	run light('o');

	run door();
	run laser();
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

		printf("---------\n");
	};
}

proctype light(byte state)
{
	

	if
		::red?_;
			state= 'r';
			printf("red light\n");
			
			run light(state)
		::green?_;
			state= 'g';
			printf("green light\n");
			run light(state)
		::off?_;
			state= 'o';
			printf("light is off\n");
			run light(state)
	fi

	
}

proctype lightCommand()
{
	chan myChan;

	putColor?myChan;
	myChan!noValue;
	wait(50000);//5s
	off!noValue;
	run lightCommand()

}

proctype door()
{

	if
		::unblocked?_;
			
			printf("door opened\n");
			doorOpened = true;
			wait(300000); // 30s
			
			run door()
		::blocked?_;
			
			printf("door closed\n");
			
			if

				::nbPassages == 0->cancelRegistration!noValue;
				::else->;
			fi
			doorOpened = false;
			run door()
	fi

}


proctype laser()
{
	do 
		::detection?_;
			nbPassages ++;
			printf("Passage detected\n");
			if
				::!isFire&&nbPassages > 1 -> alertIntrusion!noValue;
				::!isFire&&nbPassages == 1 -> registration!noValue;
				::isFire->;
				
			fi;
		::resetLaser?_;
			printf("reset laser\n");
			nbPassages = 0;
	od;


	
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
	isFire = true;
	printf("Fire alert!\n");
	printf("building is burning!\n");
	run fireAlarm();
}

proctype fireSensor()
{
	detFire?_;
	alertFire!noValue;
	unblocked!noValue;
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

			putColor!green;
			if 
				::registration?_;
					registerArrival!id, day, time;
				::cancelRegistration?_;

				
			fi
			
			
			:: else ->
			printf("Cannot enter building\n");
			putColor!red;
			

		fi
	};
	run externalCardReader();
}

proctype internalCardReader()
{
	int id, day, time;
	

	atomic
	{
		getInfoIn?id, day, time;
	
		checkIsInside(id);
		if
			:: isInside == true ->
			
				putColor!green;
				if 
					::registration?_;
						registerDeparture!id, day, time;
					::cancelRegistration?_;
					
				fi
			
			:: else ->
				printf("Cannot leave building\n");
				putColor!red;
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

proctype simulation()
{
	printf("\nSimulation start\n");
	printf("-i someone is using the internal card reader\n");
	printf("-o someone is using the external card reader\n");
	printf("-d the laser detects someone passing though the door\n");
	printf("-f fire sensors detect fire\n");
	printf("-p to be used after a fire detection\n");
	
	int c1, c2;
	do

		::STDIN?c1->
			printf("%c\n",c1 );
			if
				::c1=='i'-> 
					printf("Who is inside? (1: 123, 2: 456, 3: 7890)\n");
					STDIN?c2;
					if
						::c2==49 -> ident = 123; // 1
						::c2==50 -> ident = 456; // 2
						::c2==51 -> ident = 7890; // 3, id not allowed in the building
					fi
					in!noValue;//somebody going out

				::c1=='o'-> 
					printf("Who is outside? (1: 123, 2: 456, 3: 7890)\n");
					STDIN?c2;
					if
						::c2==49 -> ident = 123; // 1
						::c2==50 -> ident = 456; // 2
						::c2==51 -> ident = 7890; // 3, id not allowed in the building
					fi
					out!noValue;//somebody going in

				::c1=='d'-> detection!noValue;
				::c1=='f'-> detFire!noValue;/*break;*/
				::c1=='p'-> isFire = false;
							resetLaser!noValue;
							printf("firemen fighted the fire or some heavy rain has falled or a big wet piece of fabric has falled from the sky and exstinguished the fire.\n");
				::else;
			fi
	od;


}

proctype command()
{

	
	atomic {

		int i;
		if
		

			::
				out?_->getInfoEx!ident,30032018,1120;
				if
					::
						isValid;
						unblocked!noValue;
						doorOpened;
						blocked!noValue;
						!doorOpened;
						resetLaser!noValue;
						
					::else->;
				fi
			::
				in?_->getInfoIn!ident,30032018,1130;
				if
					::
						isInside;
						unblocked!noValue;
						doorOpened;
						blocked!noValue;
						!doorOpened;
						resetLaser!noValue;
					::else->;
				fi
		fi
		
		
	}
	
	
	

	atomic
	{
		printf("\n- The logbook currently:\n");
		displayLogbook();
	}

	run command();


}