/********************************************************************************************************************	
*	Program Name:	generalutilities.sas																			*
*	What it does: 	This program contains useful macros for general purposes										*
*																													*
*																													*
*					num_tokens			counts the number of words in a text string	and outputs the number 			*
*																													*
*					add_string			takes a string and adds a prefix or suffix to each word in it, outputs a 	*
*										new string with the prefixes/suffixes in it									*
*																													*
*					sum_mean_by			takes a list of variables and calculates means and totals by specified		*
*										sorting variables															*
*																													*
*					demean				takes a list of variables and calculates values demeaned by specified		*
*										sorting variables (merges the demeaned variables with the original dataset	*
*																													*
*					herfindahl			calculates a herfindahl concentration measure for a given set of variables	*
*										and by groups, then creates an output dataset with those variables (they 	*
*										will have the suffix "_herf"												*
*																													*
*	Instructions:	num_tokens			typically used inside other macros (see add_string for an example)			*
*																													*																													*
*					add_string			typically used inside other macros (see sum_mean_by for an example)			*
*																													*
*					sum_mean_by			indata		= input dataset													*
*										sortvars	= variables to sort on											*
*										varsto		= variables to get means/totals of								*
*										meansuffix	= suffix to add to variables for means							*
*										sumsuffix   = suffix for sums												*
*										outdata		= output dataset name											*   																								*
*																													*
*					demean				indata		= input dataset													*
*										sortvars	= variables to sort on											*
*										varsto		= variables to demean											*
*										dmsuffix	= suffix for demeaned variables									*
*										outdata		= output dataset containing the demeaned variables				*
*																													*
*					herfindahl			indata		= input dataset													*
*										sortvars	= variables to sort on											*
*										varsto		= variables to get herfindahl index for							*
*										outdata		= output dataset name											*   
*																													*
*	Written by:		Terrence Blackburne																				*
*	Date written:	December 5, 2018																				*
* 	Date modified:	June 2, 2020																					*	
********************************************************************************************************************/

%macro num_tokens(words, delim=%str( ));
	%local counter;

	%* Loop through the words list, incrementing a counter for each word found. ;
	%let counter = 1;
	%do %while (%length(%scan(&words, &counter, &delim)) > 0);
		%let counter = %eval(&counter + 1);
	%end;

	%* Our loop above pushes the counter past the number of words by 1. ;
	%let counter = %eval(&counter - 1);

	%* Output the count of the number of words. ;
	&counter
%mend num_tokens;

%macro add_string(words, str, delim=%str( ), location=suffix);
	%local outstr i word num_words;

	%* Verify macro arguments. ;
	%if (%length(&words) eq 0) %then %do;
		%put ***ERROR(add_string): Required argument 'words' is missing.;
		%goto exit;
	%end;
	%if (%length(&str) eq 0) %then %do;
	%put ***ERROR(add_string): Required argument 'str' is missing.;
	%goto exit;
	%end;
	%if (%upcase(&location) ne SUFFIX and %upcase(&location) ne PREFIX) %then %do;
	%put ***ERROR(add_string): Optional argument 'location' must be;
	%put *** set to SUFFIX or PREFIX.;
	%goto exit;
	%end;

	%* Build the outstr by looping through the words list and adding the
	* requested string onto each word. ;
	%let outstr = ;
	%let num_words = %num_tokens(&words, delim=&delim);
	%do i=1 %to &num_words;
		%let word = %scan(&words, &i, &delim);
		%if (&i eq 1) %then %do;
			%if (%upcase(&location) eq PREFIX) %then %do;
				%let outstr = &str&word;
			%end;
			%else %do;
			%let outstr = &word&str;
			%end;
		%end;
		%else %do;
			%if (%upcase(&location) eq PREFIX) %then %do;
				%let outstr = &outstr&delim&str&word;
			%end;
			%else %do;
				%let outstr = &outstr&delim&word&str;
			%end;
		%end;
	%end;

	%* Output the new list of words. ;
	&outstr
	%exit:
%mend add_string;


%macro sum_mean_by(indata=,sortvars=,varsto=,meansuffix=,sumsuffix=,outdata=);

proc sort data=&indata out=xff;
	by &sortvars;
run;

proc means data=xff noprint;
	by &sortvars;
	var &varsto;
	output out=&outdata(drop=_FREQ_ _TYPE_) sum = %add_string(&varsto, &sumsuffix, location=suffix) mean = %add_string(&varsto, &meansuffix, location=suffix);
run;

%mend sum_mean_by;


%macro demean(indata=,sortvars=,varsto=,dmsuffix=,outdata=);

proc sort data=&indata;
	by &sortvars;
run;

proc means data=&indata noprint;
	by &sortvars;
	var &varsto;
	output out=_foo2 mean = %add_string(&varsto, _mean, location=suffix);
run;

data &outdata;
	merge &indata _foo2(keep = &sortvars %add_string(&varsto, _mean, location=suffix));
	by &sortvars;
	array dvars[*] &varsto;
	array mvars[*] %add_string(&varsto, _mean, location=suffix);
	array dmvars[*] %add_string(&varsto, &dmsuffix, location=suffix);
	do i=1 to dim(dvars);
		dmvars[i]=dvars[i]-mvars[i];
	end;
	drop i %add_string(&varsto, _mean, location=suffix);
run;

%mend demean;


%macro herfindahl(indata=,sortvars=,varsto=,outdata=);
proc sort data=&indata out=xfoo;
	by &sortvars;
run;

proc means data=xfoo noprint;
	by &sortvars;
	var &varsto;
	output out=foototaldata(drop=_FREQ_ _TYPE_) sum = %add_string(&varsto, _sum, location=suffix);
run;

data xb1;
	merge xfoo foototaldata;
	by &sortvars;
	array ratiovars	{*} %add_string(&varsto, _rtemp, location=suffix);
	array varstoratio {*} &varsto;
	array totalvars {*} %add_string(&varsto, _sum, location=suffix);
	do foo4 = 1 to dim(ratiovars);
		 ratiovars[foo4] = (varstoratio[foo4]/ totalvars[foo4])**2;
	end;
run;

proc means data=xb1 noprint;
	by &sortvars;
	var %add_string(&varsto, _rtemp, location=suffix);
	output out=&outdata(drop=_FREQ_ _TYPE_) sum=%add_string(&varsto, _herf, location=suffix);
run;
%mend herfindahl;


%macro missingtozero(inset_missing=,mvars=,outset=);
data &outset;
	set &inset_missing;
	array misvars[*] &mvars;
		do i=1 to dim(misvars);
			if missing(misvars[i]) then misvars[i]=0;
		end;
	drop i;
run;
%mend missingtozero;
