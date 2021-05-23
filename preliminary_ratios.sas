* This homework focuses on retrieving the financial ratios for Dell, Microsoft, and Apple for the past 5 years;

options errorabend;
libname home '.';

* includes the macro file;
%include './macros/get_compa_data.sas';

* Running the macro;

/*
GVKEYS:
    microsoft: 012141
    apple: 001690
    dell: 014489
*/

%getcompfunda(dsetout=compdata(where=(gvkey in('012141', '001690', '014489'))),startyear=2014,endyear=2019);

/*
* exporting getcompfunda into an excell spreadsheet;
proc export data=compdata
    outfile="/home/oregonstate/davjp/2021Research/compdata.csv"
    dbms = csv REPLACE;
run;

proc print data=compdata;
run;
*/

/* CALCULATING RATIOS
---------------------- */
data ratios (keep = fyear tic sale rect at invt ACR_turnover_ratio R_collection_days return_on_assets profit_margin sales_turnover_ratio inv_turnover_ratio);
    set compdata;
    * lagging the required variables;
    rect_lag = lag1(rect);
    at_lag = lag1(at);
    inv_lag = lag1(invt);

    * removing 2014 values from the list;
    if fyear = 2014 then delete;


    * accounts recievable turnover ratio;
    ACR_turnover_ratio = 2 * sale / (rect + rect_lag);

    * recievables collection period;
    R_collection_days = 365 / (2 * sale / (rect + rect_lag));

    * return on assets ratio;
    return_on_assets = 2 * ni / (at + at_lag);

    * profit margin ratio;
    profit_margin = ni / sale;

    * sales turnover ratio;
    sales_turnover_ratio = 2 * sale / (at + at_lag);

    * inventory turnover ratio;
    inv_turnover_ratio = 2 * cogs / (invt + inv_lag);
run;

proc print data=ratios;
run;


/* proc export data=ratios
    outfile = "./Ratios.csv"
    dbms = csv REPLACE;
run; */






