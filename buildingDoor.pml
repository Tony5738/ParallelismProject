

chan red = [0] of { byte };
chan green = [0] of { byte };
chan off = [0] of { byte };

init {

	
	byte initState = 'o';
	run light(initState);
	red!'r';
	green!'g';
	off!'o'
}


proctype light(byte state)
{
	

	if
	::red?state;
		printf("state %c\n" ,state);
		run light(state)
	::green?state;
		printf("state %c\n" ,state);
		run light(state)
	::off?state;
		printf("state %c\n" ,state);
		run light(state)
	fi

	
}
