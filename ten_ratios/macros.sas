%macro getcompfunda(dsetout=,startyear=,endyear=);

proc sort data=comp.funda out=funda nodupkey;
      where &startyear<=fyear<=&endyear and (indfmt="INDL") and (datafmt="STD") and (popsrc="D")
      and (consol="C") and (curcd="USD");
      by gvkey fyear;
run;

proc sort data=comp.names(keep=gvkey sic year1) out=names nodupkey;
      by gvkey;
run;

proc sort data=comp.company out=company nodupkey;
      by gvkey;
run;
 
data &dsetout;
      merge funda names(rename=(sic=sic_char)) company(keep=gvkey addzip state loc ipodate);
      by gvkey;
      sic_num=input(sic_char,8.);
      sic=sich;
      if missing(sich) then sic=sic_num;
      if missing(fyear) then delete;
      firm_age=1+fyear-year1;
      drop sic_char sic_num year1;
run;

%mend getcompfunda;