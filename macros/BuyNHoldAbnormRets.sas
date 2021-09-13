/********************************************************************************************************************************  
*   Program Name:   BuyHoldAbnormRets.sas                                                                                       *
*   What it does:   This program calculates the buy and hold abnormal returns for stocks                                        *
*                                                                                                                               *
*                                                                                                                               *
*                   Daily_BHAR          looks at the daily stock values for various PERMNOs in the CRSP dataset and             *
*                                       calculates the BHAR based on equal & value-weighted stock returns of the market         *
*                                                                                                                               *
*                   Monthly_BHAR        looks at the monthly stock values for various PERMNOs in the CRSP dataset and           *
*                                       calculates the BHAR based on equal & value-weighted stock returns of the market         *
*                                                                                                                               *
*   Instructions:   Daily_BHAR          dsetout     = name of output dataset                                                    *
*                                       permno      = companies to calculate BHAR for                                           *
*                                       startdate   = first date of data                                                        *
*                                       enddate     = last date of data                                                         *
*                                                                                                                               *
*                   Monthly_BHAR        dsetout     = name of output dataset                                                    *
*                                       permno      = companies to calculate BHAR for                                           *
*                                       startdate   = first date of data                                                        *
*                                       enddate     = last date of data                                                         *
*                                                                                                                               *
*   Written by:     Santosh Ramesh & Methum Kasthuriarachchi                                                                    *
*   Date written:   September 12, 2020                                                                                          *
*   Date modified:  September 12, 2020                                                                                          *  
********************************************************************************************************************************/

* gets daily buy and hold annual return;
%macro Daily_BHAR(dsetout=, permno=, startdate=, enddate=);

/*     format &startDate yymmddn8.;
    format &endDate yymmddn8.; */

* Get the stock daily data;
data logRet;
    set CRSP.dsf(where=(PERMNO in &permno and &startDate<=DATE<=&endDate));
    LOG_RET = log10(1+RET);
    keep PERMNO LOG_RET
run;

* sum the logrets;
proc sql;
    create table logRetSum as 
    select PERMNO, SUM(LOG_RET) as SUM_LOG_RET
    from logRet
    group by PERMNO;
quit;

* remove the log from returns;
data CompoundStock;
    set logRetSum;
    STOCK_RET = 10**SUM_LOG_RET;
    keep PERMNO STOCK_RET
run;

*====================================;
*====================================;

* get EW and VW market returns;
data marketRet;
    set crsp.dsi(where=(&startdate<=DATE<=&enddate));
    EW_LOG_RET = log10(1+ewretd);
    VW_LOG_RET = log10(1+vwretd);
    keep EW_LOG_RET ewretd VW_LOG_RET vwretd
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
    from CalcBHAR as m, CompoundStock as s;
quit;

* calculate the buy and hold return;
data &dsetout;
    set BHAR_DAILY;
    EW_BHAR = STOCK_RET - EWR;
    VW_BHAR = STOCK_RET - VWR;
    keep PERMNO STOCK_RET EWR VWR EW_BHAR VW_BHAR
run;

%mend Daily_BHAR;


* gets monthly buy and hold annual return;
%macro Monthly_BHAR(dsetout=, permno=, startdate=, enddate=);

* Get the stock monthly data;
data logRet;
    set CRSP.msf(where=(PERMNO in &permno and &startDate<=DATE<=&endDate));
    LOG_RET = log10(1+RET);
    keep PERMNO LOG_RET
run;

* sum the logrets;
proc sql;
    create table logRetSum as 
    select PERMNO, SUM(LOG_RET) as SUM_LOG_RET
    from logRet
    group by PERMNO;
quit;

* remove the log from returns;
data CompoundStock;
    set logRetSum;
    STOCK_RET = 10**SUM_LOG_RET;
    keep PERMNO STOCK_RET
run;

*====================================;
*====================================;

* get EW and VW market returns;
data marketRet;
    set crsp.msi(where=(&startdate<=DATE<=&enddate));
    EW_LOG_RET = log10(1+ewretd);
    VW_LOG_RET = log10(1+vwretd);
    keep EW_LOG_RET ewretd VW_LOG_RET vwretd
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
    create table BHAR_MONTHLY as 
    select s.*, m.*
    from CalcBHAR as m, CompoundStock as s;
quit;

* calculate the buy and hold return;
data &dsetout;
    set BHAR_MONTHLY;
    EW_BHAR = STOCK_RET - EWR;
    VW_BHAR = STOCK_RET - VWR;
    keep PERMNO STOCK_RET EWR VWR EW_BHAR VW_BHAR
run;

%mend Monthly_BHAR;

