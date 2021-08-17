options errorabend;

libname home '.';

%include '../macros/hanlon_paper/compustatutilities.sas';
%include '../macros/hanlon_paper/Winsorize_Macro.sas';


* get the comp data from 1993 to 2001;
%getcompfunda(dsetout=compdata(where=(not missing(at))),startyear=1993,endyear=2001);

* determining first and last years and average_at and ptbi a year ahead;
data all_data;
    set compdata;
    by gvkey;

    lag_at = lag(at);
    lag_fyear = lag(fyear);  
    lag_fyr = lag(fyr);   
    lag_gvkey = lag(gvkey);   

    if gvkey=lag_gvkey and fyr = lag_fyr and fyear-1=lag_fyear then avg_at = (lag_at + at)/2;
    else avg_at=.;

    * calculate lead values for PI (PTBI);
    if eof1=0 then
        set compdata (firstobs=2 keep=PI MII fyear rename=(PI=ptbi_lead MII=mii_lead fyear=next_year)) end=eof1;
    if last.gvkey then next_year=.;
    if last.gvkey or next_year-1 ~= fyear then ptbi_lead=.; 
    if last.gvkey or next_year-1 ~= fyear then mii_lead=.;

    if mii=. then mii=0;
    if mii_lead=. then mii_lead=0;

    * sales in current year;
    SALES = DIVIDE(SALE, avg_at);

    * Net operating assets in current year;
    NOA = RECT + INVT + ACO + PPENT + INTAN + AO - AP - LCO - LO;
run;

* calculating sales growth and NOA (net operating assets) growth;
data all_vars;
    set all_data;
    by gvkey;

    PREV_SALES = lag(SALES);
    PREV_NOA = lag(NOA);

    * determining growth in sales from previous year;
    if prev_year+1 = fyear then
        /* SALESGROW = (SALES - PREV_SALES)/PREV_SALES; */
        SALESGROW = DIVIDE((SALES - PREV_SALES), PREV_SALES);
    else
        SALESGROW =.;

    * determining growth of net operating assets from previous year;
    if prev_year+1 = fyear then
        /* NOAGROW = NOA/PREV_NOA; */
        NOWAGROW = DIVIDE(NOA, PREV_NOA);
    else
        NOAGROW = .;

    * lead avg_at;
    if eof1=0 then
        set all_data (firstobs=2 keep=avg_at rename=(avg_at=avg_at_lead)) end=eof1;
    if last.gvkey then avg_at_lead=.; 
run; 


* calculate the other ratios;
data scaled_values;
    set all_vars;

    * pre-tax book income;
    if avg_at>0 then PTBI = DIVIDE((pi - MII), avg_at);

    * year ahead pre-tax book income;
    if avg_at_lead>0 then PTBI_AHEAD = DIVIDE((ptbi_lead - mii_lead), avg_at_lead);

    * pre-tax cash flow;
    if avg_at>0 then PTCF = DIVIDE((OANCF + TXPD - XIDOC), avg_at);

    *current tax;
    current_tax = (txt-txdi)/0.35;
    if avg_at>0 then CURTAX = DIVIDE(current_tax, avg_at);

    * deferred tax expense;
    def_tax_expense = TXDFED+TXDFO;
    if def_tax_expense=. then 
        def_tax_expense = TXDI;

    if avg_at>0 then DTE = DIVIDE(((def_tax_expense)/0.35), avg_at);

    * pre-tax accruals;
    PTACC = PTBI - PTCF;

    * earnings/avg shareholder's equity;
    ROE = DIVIDE(IB, SEQ);

    * market value of equity;
    MVE = prcc_f * csho;

    * book value to market value of equity ratio;
    BM = DIVIDE(CEQ, MVE);

    * effective tax rate;
    ETR = DIVIDE(TXT, PI);

    * current effective tax rate;
    CETR = DIVIDE((TXT - TXDI), PI);

    * deb-to-equity ratio;
    LEVERAGE = DIVIDE((DLC + DLTT), SEQ);

    * special items;
    SPECITEMS = DIVIDE(SPI, avg_at);

run;


data filter_ratios;
    set scaled_values;

    * remove observations in 1993 and 2001;
    if fyear = 1993 or fyear = 2001 then delete;

    if mve =. then delete;

    * get firms from the USA;
    if fic ~= "USA" then delete;

    if ptbi =. then delete;
 
    if ptbi_ahead =. then delete;

    if ptcf =. then delete;

    if dte =. then delete;

    * filter out pre-tax income (financial loss);
    if ptbi <= 0 then delete;

    * filter out negative current tax expense;
    if curtax <=0 then delete;

    * filter out positive tax loss carry forward;
    if tlcf =. then tlcf = 0;
    if tlcf ~=0 then delete;

    * filter out financial services and utilities;
    industry_code = FLOOR(sic/100);
    if (60 <= industry_code <= 69 or industry_code = 49) then delete;
run; 


* winsorize the ratios;
 %winsor(dsetin=filter_ratios, dsetout=ratios_winsorized, byvar=none, vars=ptbi_ahead ptbi dte ptcf ptacc curtax, type=winsor, pctl=1 99);




*==============================================;
* Table 1
*==============================================;
* Panel A: Descriptive statistics;
proc means data=ratios_winsorized mean stddev q1 median q3;
    var ptbi_ahead ptbi ptcf ptacc dte avg_at curtax;
run;

* Panel B: Pearsona and Spearman Correlations;
proc corr data=ratios_winsorized Pearson Spearman;
    var ptbi_ahead ptbi ptcf ptacc dte;
    with ptbi_ahead ptbi ptcf ptacc dte;
run; 



* determine the quintiles to calculate LPBTD, LNBTD, smallbtd;
proc rank data=ratios_winsorized out=grouped_values groups=5;
    var dte;
    ranks quintile;
run;

data LNBTD;
    set grouped_values;
    * keep bottom quintile;
    if quintile > 0 then delete;
run;

data LPBTD;
    set grouped_values;
    * keep top quintile;
    if quintile < 4 then delete;
run;

data SmallBTD;
    set grouped_values;
    * keep middle quintiles;
    if quintile = 0 or quintile = 4 then delete;
run;



*==============================================;
* Printing Statistics for Table 2 Groups
*==============================================;
data LNBTD_TITLE;
    * create a descriptor variable;
    LENGTH descriptor $ 20;
    descriptor = 'LNBTD';
run;
proc print data=LNBTD_TITLE;
run;
proc means data=LNBTD mean stddev q1 median q3;
    var ptbi_ahead ptbi ptcf ptacc avg_at dte roe mve bm etr cetr leverage specitems sales salesgrow noa noagrow;
run;


data SmallBTD_TITLE;
    * create a descriptor variable;
    LENGTH descriptor $ 20;
    descriptor = 'SmallBTD';
run;
proc print data=SmallBTD_TITLE;
run;
proc means data=SmallBTD mean stddev q1 median q3;
    var ptbi_ahead ptbi ptcf ptacc avg_at dte roe mve bm etr cetr leverage specitems sales salesgrow noa noagrow;
run;


data LPBTD_TITLE;
    * create a descriptor variable;
    LENGTH descriptor $ 20;
    descriptor = 'LPBTD';
run;
proc print data=LPBTD_TITLE;
run;
proc means data=LPBTD mean stddev q1 median q3;
    var ptbi_ahead ptbi ptcf ptacc avg_at dte roe mve bm etr cetr leverage specitems sales salesgrow noa noagrow;
run;




*==============================================;
* Table 3
*==============================================;
* panel A;
proc reg data=ratios_winsorized;
    model PTBI_AHEAD = PTBI;
run;


* panel B;
data table3_panelB;
    set grouped_values;

    IS_LPBTD = 0;
    IS_LNBTD = 0;
    if quintile = 0 then IS_LNBTD = 1;
    else if quintile = 4 then IS_LPBTD = 1;

    LN_PTBI = IS_LNBTD*PTBI;
    LP_PTBI = IS_LPBTD*PTBI;
run;
proc reg data=table3_panelB;
    model PTBI_AHEAD =  IS_LNBTD IS_LPBTD PTBI LN_PTBI LP_PTBI;
run;



*==============================================;
* Table 4
*==============================================;
* panel A;
proc reg data=ratios_winsorized;
    model PTBI_AHEAD = PTCF PTACC;
run;

* panel B;
data table4_panelB;
    set table3_panelB;

    LN_PTCF = IS_LNBTD*PTCF;
    LP_PTCF = IS_LPBTD*PTCF;

    LN_PTACC = IS_LNBTD*PTACC;
    LP_PTACC = IS_LPBTD*PTACC;
run;
proc reg data=table4_panelB;
    model PTBI_AHEAD = IS_LNBTD IS_LPBTD PTCF LN_PTCF LP_PTCF PTACC LN_PTACC LP_PTACC;
run;

