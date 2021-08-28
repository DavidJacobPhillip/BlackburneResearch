/********************************************************************************************************************
*   Description: calculating the annual returns of General Motors & Lululemon based on CRSP monthly & daily data    *
*	Written by:		Santosh Ramesh																        			*
*	Date written:	August 27, 2021   																				*
* 	Date modified:	August 28, 2021																					*	
********************************************************************************************************************/

options errorabend;
libname home ".";

/* GM Calculations */
* Monthly;

data GM_Monthly;
    set CRSP.msf(where=(permno=12369 and MDY(01,01,2016)<=DATE<=MDY(12,31,2016)));

	LOG_RET=log10(1+RET);

    keep PERMNO DATE RET LOG_RET;
run;

proc means data=GM_Monthly sum noprint;
    var LOG_RET;
	output out=GM_Monthly_Sum
	sum = LOG_RET_SUM;
run;

data GM_Monthly_Annual;
	set GM_Monthly_Sum;

	ANNUAL_RETURN=(10**LOG_RET_SUM - 1);
run;

proc print data=GM_Monthly_Annual;
	title 'GM Monthly 01/29/2016 - 12/30/2016';
run;

* Daily;
data GM_Daily;
    set CRSP.dsf(where=(permno=12369 and MDY(01,01,2016)<=DATE<=MDY(12,31,2016)));

	LOG_RET=log10(1+RET);

    keep PERMNO DATE RET LOG_RET;
run;

proc means data=GM_Daily sum noprint;
    var LOG_RET;
	output out=GM_Daily_Sum
	sum = LOG_RET_SUM;
run;

data GM_Daily_Annual;
	set GM_Daily_Sum;

	ANNUAL_RETURN=(10**LOG_RET_SUM - 1);
run;

proc print data=GM_Daily_Annual;
	title 'GM Daily 01/04/2016 - 12/30/2016';
run;

/* LuluLemon Calculations */
* Monthly;

data LULU_Monthly;
    set CRSP.msf(where=(permno=92203 and MDY(01,01,2016)<=DATE<=MDY(12,31,2016)));

	LOG_RET=log10(1+RET);

    keep PERMNO DATE RET LOG_RET;
run;

proc means data=LULU_Monthly sum noprint;
    var LOG_RET;
	output out=LULU_Monthly_Sum
	sum = LOG_RET_SUM;
run;

data LULU_Monthly_Annual;
	set LULU_Monthly_Sum;

	ANNUAL_RETURN=(10**LOG_RET_SUM - 1);
run;

proc print data=LULU_Monthly_Annual;
	title 'LULU Monthly 01/29/2016 - 12/30/2016';
run;

* Daily;
data LULU_Daily;
    set CRSP.dsf(where=(permno=92203 and MDY(01,01,2016)<=DATE<=MDY(12,31,2016)));

	LOG_RET=log10(1+RET);

    keep PERMNO DATE RET LOG_RET;
run;

proc means data=LULU_Daily sum noprint;
    var LOG_RET;
	output out=LULU_Daily_Sum
	sum = LOG_RET_SUM;
run;

data LULU_Daily_Annual;
	set LULU_Daily_Sum;

	ANNUAL_RETURN=(10**LOG_RET_SUM - 1);
run;

proc print data=LULU_Daily_Annual;
	title 'LULU Daily 01/04/2016 - 12/30/2016';
run;
