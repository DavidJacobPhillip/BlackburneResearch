/********************************************************************************************************************
*   Description: identifying abnormal returns (value-weighted returns minus S&P 500 returns)                        *
*	Written by:		Santosh Ramesh & Methum Kasthuriarachchi											   			*
*	Date written:	September 11, 2021   																			*
* 	Date modified:	September 11, 2021 																				*	
********************************************************************************************************************/

options errorabend;

libname home '.';

* Get the daily data;
data logRet;
    set CRSP.dsf(where=(PERMNO in (12369 92203) and MDY(01,01,2016)<=DATE<=MDY(12,31,2016)));
    LOG_RET = log10(1+RET);
    keep PERMNO DATE RET LOG_RET
run;

* sum the logrets;
proc sql;
    create table logRetSum as 
    select PERMNO, SUM(LOG_RET) as SUM_LOG_RET
    from logRet
    group by PERMNO;
quit;

* remove the log from returns;
data CompoundDaily;
    set logRetSum;
    STOCK_RET = 10**SUM_LOG_RET;
    keep PERMNO STOCK_RET
run;


* get EW and VW market returns;
data marketRet;
    set crsp.dsi(where=(MDY(01,01,2016)<=DATE<=MDY(12,31,2016)));
    EW_LOG_RET = log10(1+ewretd);
    VW_LOG_RET = log10(1+vwretd);
    keep DATE EW_LOG_RET ewretd VW_LOG_RET vwretd
run;

* sum the logs;
proc sql;
    create table marketRetSum as
    select SUM(EW_LOG_RET) as SUM_EW, SUM(VW_LOG_RET) as SUM_VW
    from marketRet
quit;

* remove logs from returns;
data CalcBHAR;
    set marketRetSum;
    EWR = 10**SUM_EW;
    VWR = 10**SUM_VW;
run;


* merge stock return and market return;
proc sql;
    create table BHAR_DAILY as 
    select s.*, m.*
    from CalcBHAR as m, CompoundDaily as s;
quit;

* calculate the buy and hold return;
data CALC_BHAR;
    set BHAR_DAILY;
    EW_BHAR = STOCK_RET - EWR;
    VW_BHAR = STOCK_RET - VWR;
run;

proc print data=CALC_BHAR;
run;




