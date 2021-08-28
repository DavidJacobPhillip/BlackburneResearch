* Hanlon 2005 TAR replication;

options errorabend;

libname home '.';

* First, load in the macros I want to use;

%include '../macros/hanlon_paper/compustatutilities.sas';
%include '../macros/hanlon_paper/Winsorize_Macro.sas';

%getcompfunda(dsetout=compdata(where=(not missing(at))),startyear=1993,endyear=2001);

options mergenoby=nowarn;

data compdata;
	merge 	compdata(keep=gvkey fyear fyr sic at tlcf mii pi txdfed txdfo txdi txt txc oancf xidoc txpd prcc_f csho fic)
			compdata(firstobs=2
					 keep=gvkey fyear fyr pi mii at
					 rename=(gvkey=gvkey_p1 fyear=fyear_p1 fyr=fyr_p1 pi=pi_p1 mii=mii_p1 at=at_p1));
	sic2d=floor(sic/100);/* Done */
	m1=.; 
    	if gvkey=lag(gvkey) and fyear-1=lag(fyear) and fyr=lag(fyr) then m1=1;
	avta=m1*(at+lag(at))/2;/* Done */

	if missing(tlcf) then tlcf=0;	/* Done */

	if not missing(mii) then pti=(pi-mii);
		else pti=pi;
	if avta>0 then ptbi=pti/avta;
	if missing(txdfed) or missing(txdfo) then dtax = txdi;
			else dtax 	= txdfed + txdfo;
	if avta>0 then deftax=(dtax/.35)/avta;
	if avta>0 then curtax=((txt-txdi)/.35)/avta;
	if avta>0 then ptcf=(oancf-xidoc+txpd)/avta;
	at_m1=m1*lag(at);
	ptacc=ptbi-ptcf;
	mve=prcc_f*csho;
	current_tax=(txt-txdi)/.35;
	p1=.;
	if gvkey=gvkey_p1 and fyear+1=fyear_p1 and fyr=fyr_p1 then p1=1;
	if not missing(mii_p1) then pti_p1=p1*(pi_p1-mii_p1);
		else pti_p1=p1*pi_p1;
	avta_p1=p1*(at+at_p1)/2;
	if avta_p1>0 then ptbi_p1=pti_p1/avta_p1;
	txt_alt=.35*pi;
	if pi<0 then txt_alt=0;
run;

*input screens from page 144;

data hanlondata;
	set compdata;
	if 1994<=fyear<=2000;
	if not missing(mve);
	if fic="USA";	
	if not missing(ptbi);
	if not missing(ptbi_p1);
	if not missing(ptcf);
	if not missing(deftax);
	if ptbi>0;
	if curtax>0;
	if tlcf=0;
	if 60 <= sic2d <= 69 then delete;
		else if sic2d = 49 then delete;
	include=1;
run;

data home.hanlondata;
	set hanlondata;
run;


%winsor(dsetin=hanlondata,dsetout=hanlondata,byvar=none,vars=ptbi ptbi_p1 deftax curtax ptcf ptacc,type=winsor,pctl=1 99);

proc rank data=hanlondata out=hanlondata groups=5;
	var deftax;
	ranks defvar_rank;
run;

data hanlondata;
	set hanlondata;
	if defvar_rank=0 then lnbtd=1;
		else lnbtd=0;
	if defvar_rank=4 then lpbtd=1;
		else lpbtd=0;
	
	ln_ptbi=lnbtd*ptbi;
	lp_ptbi=lpbtd*ptbi;
	ln_ptacc=lnbtd*ptacc;
	ln_ptcf=lnbtd*ptcf;
	lp_ptacc=lpbtd*ptacc;
	lp_ptcf=lpbtd*ptcf;
	drop defvar_rank;
run;

data home.hanlondata;
	set hanlondata;
run;

ods html file='Table1PanelB.xls';
proc means data=hanlondata n mean mean std p25 median p75;
	var ptbi_p1 ptbi ptcf ptacc deftax avta curtax;
run;
ods html close;

ods listing close;
proc reg data=hanlondata;
	model ptbi_p1 = lnbtd lpbtd ptbi ln_ptbi lp_ptbi / edf;
ods output ParameterEstimates = regcoeffs;
ods output FitStatistics = fit;
ods output NObs = numobs;
run;
ods listing;

proc transpose data=regcoeffs out=coeftrans;
	id variable;
	var estimate tvalue;
run;

data fit(keep=label2 cvalue2);
	set fit;
	where label2='Adj R-Sq';
run;

data table3panela;
	set coeftrans fit numobs(keep=nobsused); 
	format intercept lnbtd lpbtd ptbi ln_ptbi lp_ptbi 10.3;
run;

ods html file='Table3PanelA.xls';
proc print data=table3panela;
run;
ods html close;


ods listing close;
proc reg data=hanlondata;
	model ptbi_p1 = lnbtd lpbtd ptcf ln_ptcf lp_ptcf ptacc ln_ptacc lp_ptacc / edf;
	ods output ParameterEstimates = regcoeffs;
	ods output FitStatistics = fit;
	ods output NObs = numobs;
run;
ods listing;

proc transpose data=regcoeffs out=coeftrans;
	id variable;
	var estimate tvalue;
run;

data fit(keep=label2 cvalue2);
	set fit;
	where label2='Adj R-Sq';
run;

data table3panelc;
	set coeftrans fit numobs(keep=nobsused); 
	format intercept lnbtd lpbtd ptcf ln_ptcf lp_ptcf ptacc ln_ptacc lp_ptacc 10.3;
run;

ods html file='Table3PanelC.xls';
proc print data=table3panelc;
run;
ods html close;

