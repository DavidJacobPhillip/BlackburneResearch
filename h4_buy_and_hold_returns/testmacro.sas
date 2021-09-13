options errorabend;

libname home '.';

%include '../macros/BuyNHoldAbnormRets.sas';

%Daily_BHAR(dsetout=BHARD, permno=(12369 92203), startdate=MDY(01,01,2016), enddate=MDY(12,31,2016));
%Monthly_BHAR(dsetout=BHARM, permno=(12369 92203), startdate=MDY(01,01,2016), enddate=MDY(12,31,2016));

proc print data=BHARD;
    title "Daily Data";
run;
proc print data=BHARM;
    title "Monthly Data";
run;