volatile int * const outreg = (int*)0x02000000;

int main()
{
	*outreg = 42;
	return 0;
}
