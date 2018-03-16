

chan red = [0] of { byte };
chan green = [0] of { byte };
chan off = [0] of { byte };

chan unblocked = [0] of {byte};
chan blocked = [0] of {byte};

chan start = [0] of {byte}

init {

	
	byte value = 'o';
	run light(value);
	red!'r';
	green!'g';
	off!value

	run door('b');
	unblocked!'u';
	blocked!'b';

}


proctype light(byte state)
{
	

	if
	::red?state;
		printf("light:state %c\n" ,state);
		run light(state)
	::green?state;
		printf("light:state %c\n" ,state);
		run light(state)
	::off?state;
		printf("light:state %c\n" ,state);
		run light(state)
	fi

	
}

proctype door(byte state)
{
	if
	::unblocked?state;
		printf("door:state %c\n" ,state);
		run door(state)
	::blocked?state;
		printf("door:state %c\n" ,state);
		run door(state)
	fi

}

inline wait(x)
{
	int a = 0;
	do
		::a!=x->a=a+1
}
