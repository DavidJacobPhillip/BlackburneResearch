/********************************************************************************************************************************	
*	Program Name:	compustatutilities.sas																						*
*	What it does: 	This program contains useful macros for general compustat tasks												*
*																																*
*																																*
*					getcompfunda		downloads the funda database and adds 4 - digit SIC codes, firm age, headquarters		*
*										location, and IPO date																	*
*																																*
*					getcompfunq			downloads the fundq database and adds 4 - digit SIC codes, firm age, headquarters		*
*										location, and IPO date																	*
*																																*
*					getshortinterest	calculates the short interest from the Compustat sec_shortint dataset and merges with 	*
*										the input dataset																		*
*																																*
*					getsegmentdata		downloads segment data from compustat													*
*																																*
*	Instructions:	getcompfunda		dsetout		= name of output dataset													*
*										startyear	= first year of data														*
*										endyear		= last year of data															*
*																																*
*					getcompfundq		dsetout		= name of output dataset													*
*										startyear	= first year of data														*
*										endyear		= last year of data															*																									*
*																																*
*					getshortinterest	dsetin		= name of the output dataset												*	
*										dsetout		= name of the output dataset												*
*										dateleft	= date prior to which short interest data is desired						*
*										idvars		= unique company identifiers												*
*																																*
*					getsegmentdata		outdset		= name of the output dataset												*
*										segmatch	= takes the value "old" or "new", use "old" if you want the segments that 	*
*													  were used at the time of the initial financial report, "new" for the most	*
*													  recent segments															*
*																																*
*	Written by:		Terrence Blackburne																							*
*	Date written:	May 17, 2018																								*
* 	Date modified:	getsegmentdata added on June 3, 2020																		*	
********************************************************************************************************************************/

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

%macro getcompfundq(dsetout=,startyear=,endyear=);

proc sort data=comp.fundq out=fundq nodupkey;
	where &startyear<=fyearq<=&endyear and (indfmt="INDL") and (datafmt="STD") and (popsrc="D")
	and (consol="C") and (curcdq="USD");
	by gvkey fyearq fqtr;
run;

proc sort data=comp.names(keep=gvkey sic year1) out=names nodupkey;
	by gvkey;
run;

proc sort data=comp.company out=company nodupkey;
	by gvkey;
run;

data &dsetout;
	merge fundq names company(keep=gvkey addzip state loc ipodate);
	by gvkey;
	if missing(fyearq) then delete;
	fyearqtr=fyearq*10 + fqtr;
	firm_age=1+fyearq-year1;
	drop year1;
run;

%mend getcompfundq;

%macro getshortinterest(dsetin=, dsetout= ,dateleft= ,idvars=);

data foo1;
	set &dsetin (keep=gvkey &dateleft &idvars);
run;

proc sql;
	create table foo as
	select	a.*,
			b.datadate as _settledate,
			intck('day',b.datadate,a.datadate) as difftime,
			b.shortint/(a.csho*1000000) as short_ratio
	from &dsetin as a left join comp.sec_shortint as b
	on		a.gvkey = b.gvkey
		and intnx('year',a.&dateleft,-1,'same')<=b.datadate<=a.&dateleft;
quit;

data foo;
	set foo;
	if short_ratio<=1;
run;

proc sort data=foo;
	by gvkey &idvars &dateleft difftime ;
run;

proc sort data=foo nodupkey;
	by gvkey &idvars &dateleft ;
run;

proc sort data=&dsetin nodupkey;
	by gvkey &idvars &dateleft ;
run;

data &dsetout;
	merge &dsetin foo(keep=gvkey &dateleft &idvars short_ratio);
	by gvkey &idvars &dateleft;
run;

%mend getshortinterest;

%macro getsegmentdata(outdset=,segmatch=);

proc sort data=comp.wrds_segmerged nodupkey out=compsegs;
where stype in('BUSSEG','GEOSEG','OPSEG') and sid~=99;
by gvkey datadate stype srcdate sid;
run;

data compsegs;
	set compsegs;
	ssic1=input(sics1,8.);
	ssicb1=input(sics2,8.);
	snaics1=input(naicss1,8.);
	sgeotp=input(geotp,8.);
	fyear=year(datadate);
		if month(datadate)<6 then fyear=year(datadate)-1;
run;

%if &segmatch = old %then %do;

	proc means data=compsegs noprint;
		by gvkey datadate stype;
		var srcdate;
		output out=match_srcdate(drop =_freq_ _type_) min= match_srcdate;
	run;
%end;

%else %do;
	
	proc means data=compsegs noprint;
		by gvkey datadate stype;
		var srcdate;
		output out=match_srcdate(drop =_freq_ _type_) max= match_srcdate;
	run;
%end;

data &outdset;
	merge compsegs(in=inmakeseg) match_srcdate;
	by gvkey datadate stype;
	if inmakeseg;
	if srcdate = match_srcdate ;
	if ssicb1 ne . then sic=ssicb1; else sic=ssic1; /*getting sic codes*/
	sic2d=floor(sic/100); 
	drop inmakeseg;
run;
%mend getsegmentdata;
