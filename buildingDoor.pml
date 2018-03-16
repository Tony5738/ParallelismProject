#define noValue 0


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


init {

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

}

inline wait(x)
{
	int a = 0;
	do
		::a!=x->a++;
		::a==x->break
	od
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
