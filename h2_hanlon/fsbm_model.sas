
*This program creates standardized financial statements;

options errorabend;

libname home '.';

%include '/home/oregonstate/tblackb/mymacros/compustatutilities.sas';
%include '/home/oregonstate/tblackb/mymacros/generalutilities.sas';

/*(where=(gvkey in('184996','005073','004839','019113','017828','019661','005691','015172','100737')))*/

%getcompfunda(dsetout=compdata,startyear=1995,endyear=2019);

%let bsvars=ch ivst rectr txr recco invt aco act ppegt dpact ivaeq ivao intan ao at dlc ap txp lco lct dltt txdb itcb lo lt reuna acominc seqo re cstk caps tstk pstk seq lt seq pstkr pstkn
			mib mibn lse che recd ppent txditc ceq cstk caps re tstk tlcf recd rect;

%let isvars=sale cogs xsga dp oiadp oibdp xint nopi spi pi txt mii ib ibc xido cibegni cicurr cidergl cisecgl ciother cipen cimii dvp dvc cstke xrd gp xopr txc txdi txo txs txfed 
			xad dvp dvsco dvc dvt;

%let balance_sheet=	cash_and_equivalents trade_receivables inventory other_current_assets current_assets current_asset_flag ppe_gross acc_depreciation ppe_net intangible_assets
					other_assets total_assets asset_flag current_debt accounts_payable taxes_payable other_current_liabilities current_liabilities long_term_debt deferred_taxes
					other_liabilities total_liabilities	liability_flag retained_earnings common_equity preferred_equity shareholder_equity equity_flag minority_equity total_equity 
					liab_equity_flag1 liab_equity_flag2;

%let income_statement=revenue cost_of_sales gross_margin sales_general_admin research_and_development depreciation ebitda operating_income interest_expense
						non_operating_income special_items pre_tax_income tax_expense minority_interest net_income common_dividends preferred_dividends;

%let cashflows=net_income_c depreciation_c sale_of_ppe change_receivables change_inventory change_payables change_tax_payable change_other_assets_liabilities
				other_changes operating_cash_flows investing_cash_flows change_investments capital_expenditures sale_of_ppe_i acquisitions other_investing_activities
				sale_of_stock stock_option_tax_benefit stock_purchases cash_dividends long_term_debt_issuance debt_retirement changes_in_current_debt other_financing_activities
				exchange_rate_adjustment cash_interest_paid;

%let csvars= dpc xidoc txdc esubc sppiv fopo recch invch apalch txach aoloch oancf ivncf ivch siv ivstch capx sppe aqc ivaco fincf sstk txbcof prstkc dv dltis dltr dlcch fiao exre
				chech intpn capxv;



%missingtozero(inset_missing=compdata(keep=gvkey conm fyear fyr sic datadate &bsvars &isvars &csvars),mvars=&bsvars &isvars &csvars,outset=mdb);

data mdb;
	set mdb;
	aoci_a=acominc+seqo;
	stkn_a=cstk+caps-tstk+pstk;
	mibt_a=mib+mibn;
	pstk_a=pstkr+pstkn;
	oci_a=cicurr+cidergl+cisecgl+ciother+cipen;
	ch_m=ch;
	if ch=ivst=0 and che>0 then ch_m=che;
	ibc_m=ibc;
		if fyear<2009 then ibc_m=ibc+mii;
		if fyear>2008 and (pi-txt)~=ibc then ibc_m=ibc+mii;
run;

data balance_sheet;
	set mdb;
	cash_and_equivalents=ch_m+ivst;
	trade_receivables=rectr;
	inventory=invt;
	other_current_assets=txr+recco+aco;
	current_assets=sum(cash_and_equivalents,trade_receivables,inventory,other_current_assets);
	current_asset_flag=0;
		if abs(current_assets-act)>.0001 then current_asset_flag=1;
	ppe_gross=ppegt;
	acc_depreciation=dpact;
	ppe_net=ppe_gross-acc_depreciation;
	intangible_assets=intan;
	other_assets=ivaeq+ivao+ao;
	total_assets=sum(current_assets,ppe_net,intangible_assets,other_assets);
	asset_flag=0;
		if abs(total_assets-at)>.0001 then asset_flag=1;
	current_debt=dlc;
	accounts_payable=ap;
	taxes_payable=txp;
	other_current_liabilities=lco;
	current_liabilities=sum(current_debt,accounts_payable,taxes_payable,other_current_liabilities);
	long_term_debt=dltt;
	deferred_taxes=txdb+itcb;
	other_liabilities=lo;
	total_liabilities=sum(current_liabilities,long_term_debt,deferred_taxes,other_liabilities);
	liability_flag=0;
		if abs(total_liabilities-lt)>.0001 then liability_flag=1;
	retained_earnings=reuna+aoci_a;
	common_equity=cstk+caps-tstk;
	preferred_equity=pstk_a;
	shareholder_equity=sum(retained_earnings,common_equity,preferred_equity);
	equity_flag=0;
		if abs(shareholder_equity-seq)>.0001 then equity_flag=1;
	minority_equity=mibt_a;
	total_equity=shareholder_equity+minority_equity;
	liab_equity_flag1=0;
		if abs(sum(total_equity,total_liabilities)-lse)>.0001 then liab_equity_flag1=1;
	liab_equity_flag2=0;
		if lse~=at then liab_equity_flag2=1;
	keep gvkey conm fyear fyr &balance_sheet;
run;

data home.balance_sheet;
	set balance_sheet;
	drop current_asset_flag asset_flag liability_flag equity_flag minority_equity total_equity;
run;

data home.income_statement;
	set mdb;
	revenue=sale;
	cost_of_sales=cogs;
	gross_margin=sale-cogs;
	margin_flag=0;
		if abs(gross_margin-gp)>.0001 then margin_flag=1;
	sales_general_admin=xsga-xrd;
	research_and_development=xrd;
	depreciation=dp;
	ebitda=sum(sale,-1*cogs,-1*xsga);
	ebitda_flag=0;
		if abs(ebitda-oibdp)>.0001 then ebitda_flag=1;
	operating_income=sum(ebitda,-1*dp);
	operating_income_flag=0;
		if abs(operating_income-oiadp)>.0001 then operating_income_flag=1;
	interest_expense=xint;
	non_operating_income=nopi;
	special_items=spi;
	pre_tax_income=sum(operating_income,-1*interest_expense,nopi,spi);
	pre_tax_flag=0;
		if abs(pre_tax_income-pi)>.0001 then pre_tax_flag=1;
	tax_expense=txt;
	minority_interest=mii;
	net_income=sum(pre_tax_income,-1*tax_expense,-1*minority_interest);
	income_flag=0;
	if abs(ib-net_income)>.0001 then income_flag=1;
	common_dividends=dvc;
	preferred_dividends=dvp;
	keep gvkey fyear &income_statement;
run;

*Cash Flow Statement;

data cash_flows;
	set mdb;
	net_income_c=ibc;
	depreciation_c=dpc;
	sale_of_ppe=sppiv;
	change_receivables=recch;
	change_inventory=invch;
	change_payables=apalch;
	change_tax_payable=txdc+txach;
	change_other_assets_liabilities=aoloch;
	other_changes=xidoc+esubc+fopo;
	operating_cash_flows=sum(net_income_c,depreciation_c,sale_of_ppe,change_receivables,change_inventory,change_payables,change_tax_payable,
							change_other_assets_liabilities,other_changes, operating_cash_flows);
	cfo_flag=0;
		if abs(operating_cash_flows-oancf)>.0001 then cfo_flag=1;
	change_investments=siv-ivch+ivstch;
	capital_expenditures=capx;
	sale_of_ppe_i=sppe;
	acquisitions=aqc;
	other_investing_activities=ivaco;
	investing_cash_flows=change_investments-capital_expenditures+sale_of_ppe_i-acquisitions+other_investing_activities;
	cfi_flag=0;
		if abs(investing_cash_flows-ivncf)>.0001 then cfi_flag=1;
	sale_of_stock=sstk;
	stock_option_tax_benefit=txbcof;
	stock_purchases=prstkc;
	cash_dividends=dv;
	long_term_debt_issuance=dltis;
	debt_retirement=dltr;
	changes_in_current_debt=dlcch;
	other_financing_activities=fiao;
	financing_cash_flows=sum(sale_of_stock,stock_option_tax_benefit,stock_purchases,cash_dividends,long_term_debt_issuance,
							debt_retirement,changes_in_current_debt,other_financing_activities);
	cff_flag=0;
		if abs(financing_cash_flows-fincf)>.0001 then cff_flag=1;
	net_cash_flows=operating_cash_flows+investing_cash_flows+financing_cash_flows;
	cash_flow_flag=0;
		if abs(net_cash_flows-oancf-ivncf-fincf)>.0001  then cash_flow_flag=1;
	exchange_rate_adjustment=exre;
	cf_flag1=0;
		if abs(sum(oancf,ivncf,fincf,exre)-chech)>.0001 then cf_flag1=1;
	cf_flag2=0;
		if abs(dif(ch_m)-chech)>.0001 then cf_flag2=1;
	cash_interest_paid=intpn;
	keep gvkey fyear &cashflows cfo_flag cfi_flag cff_flag cash_flow_flag cf_flag1 cf_flag2;
run;

data home.cash_flows;
	set cash_flows;
	keep gvkey fyear &cashflows;
run;

data fsdata;
	merge home.balance_sheet home.income_statement home.cash_flows;
	by gvkey fyear;
run;

data free_cash_flow;
	set fsdata;
	m1=.;
		if lag(gvkey)=gvkey and lag(fyear)=fyear-1 and lag(fyr)=fyr then m1=1;
	taxrate=.35;
	if fyear>2017 then taxrate=.21;
	tax_fcfu=taxrate*operating_income;
		if operating_income<0 then tax_fcfu=0;
	unlevered_earnings=operating_income-tax_fcfu;
	non_cash_expenses=depreciation_c;
	non_cash_revenues=sale_of_ppe;
	ch_operating_working_capital=change_receivables+change_inventory+change_payables+change_tax_payable+change_other_assets_liabilities+other_changes;
	unlevered_cash_from_operations=unlevered_earnings+non_cash_expenses-non_cash_revenues+ch_operating_working_capital;
	net_capital_expenditures=capital_expenditures-sale_of_ppe_i+acquisitions;
	unlevered_free_cash_flow=unlevered_cash_from_operations-net_capital_expenditures;
	interest_tax_shield=taxrate*cash_interest_paid;
		if operating_income<0 then interest_tax_shield=0;
	change_debt=long_term_debt_issuance-debt_retirement;
	change_preferred_stock=m1*preferred_equity;
	equity_free_cash_flow=unlevered_free_cash_flow-cash_interest_paid+interest_tax_shield-preferred_dividends+change_debt-change_preferred_stock;
	cf_fcf=operating_cash_flows+cash_interest_paid-interest_tax_shield-net_capital_expenditures;
	cf_efcf=operating_cash_flows-net_capital_expenditures-preferred_dividends+change_debt-change_preferred_stock;
run;

%let free_cash=operating_income tax_fcfu unlevered_earnings non_cash_expenses non_cash_revenues ch_operating_working_capital unlevered_cash_from_operations net_capital_expenditures
				unlevered_free_cash_flow interest_tax_shield change_debt change_preferred_stock equity_free_cash_flow cf_fcf cf_efcf;

data home.free_cash_flows;
	set free_cash_flow;
	keep gvkey conm fyear &free_cash;
run;

%let incomestatement = sale cogs gp xsga dp xint spi nopi pi txt mii ib xopr oibdp oiadp txc txdi txo txs txfed dvp xrd xad dvp dvsco dvc dvt;
%let balancesheet = at act ppent ivaeq ivao intan ao che aco invt rect ppegt ppent dpact lt lct txditc lo dltt ap lco dlc txp seq ceq pstk cstk caps re tstk tlcf recd;
%let cashflow = oancf capxv sppe;

* No adjustments for "excess" assets;

data ratios;
	set mdb(keep=gvkey conm sic datadate fyear fyr &incomestatement &balancesheet &cashflow);
	if fyear<2017 then taxrate=.35;
		else taxrate=.21;
	credit_sales=sale;
	m1=.;
	if gvkey=lag(gvkey) and fyear=lag(fyear)+1 and fyr=lag(fyr) then m1=1;
	avg_at=m1*(at+lag(at))/2;
	avg_ppegt=m1*(ppegt+lag(ppegt))/2;
	avg_ppent=m1*(ppent+lag(ppent))/2;
	avg_payables=m1*(ap+lag(ap))/2;
	avg_inventory=m1*(invt+lag(invt))/2;
	avg_receivables=m1*(rect+lag(rect))/2;

	*accounting rates of return;

	if not missing(avg_at) then roa_unlevered=(ib+(1-taxrate)*xint)/avg_at;
	investment=dlc+dltt+pstk+ceq;
	pos_inv=.;
	if investment>0 then pos_inv=1;
	avg_investment=m1*(pos_inv*investment+lag(pos_inv)*lag(investment))/2;
	if not missing(avg_investment) then roi=(ib+(1-taxrate)*xint)/avg_investment;
	pos_common=.;
	if ceq>0 then pos_common=1;
	avg_common=m1*(pos_common*ceq+lag(pos_common)*lag(ceq))/2;
	if not missing(avg_common) then roe=(ib-dvp)/avg_common;

	* disaggregating roa;

	if sale>0 then unlevered_profit_margin = (ib+(1-taxrate)*xint)/sale;
	if avg_at>0 then asset_utilization = sale/avg_at;

	if not missing(avg_at) then roa=ib/avg_at;
	if not missing(sale) then profit_margin=ib/sale;


	* cost structure (expense ratio);

	cogs_expense_ratio = cogs/sale;
	sga_expense_ratio = xsga/sale;
	depreciation_amort_ratio = dp/sale;
	advert_ratio = xad/sale;
	r_and_d_ratio = xrd/sale;

	* ability to pay;

	current_ratio=act/lct;
	acid_ratio=(che+rect)/lct;
	cfo_current_liabilities=oancf/lct;

	* turnover ratios;

	if avg_ppegt>0 then ppe_gross_turnover = sale/avg_ppegt;
	if avg_ppent>0 then ppe_net_turnover = sale/avg_ppent;
	if avg_payables>0 then payable_turnover = m1*(cogs+invt-lag(invt))/avg_payables;
	if avg_payables>0 then payable_turnover_alt=m1*(lag(ap)+(cogs+invt-lag(invt))-ap)/avg_payables;
	if avg_inventory>0 then inventory_turnover = m1*cogs/avg_inventory;
	if avg_receivables>0 then receivables_turnover = credit_sales/avg_receivables;
	if avg_receivables>0 then receivables_turnover_alt = m1*(lag(rect)+credit_sales-rect)/avg_receivables;

	pct_uncollectible=recd/rect;
 
	* trade cash cycle;

	days_payable=365/payable_turnover;
	days_payable_alt=365/payable_turnover_alt;
	days_inventory=365/inventory_turnover;
	receivable_collection=365/receivables_turnover;
	receivable_collection_alt=365/receivables_turnover_alt;
	trade_cash_cycle=sum(0,-1*days_payable,days_inventory,receivable_collection);
	trade_cash_cycle_alt=sum(0,-1*days_payable_alt,days_inventory,receivable_collection_alt);

	* depreciable life;

	if dp>0 then depreciable_life_gross=m1*avg_ppegt/dp;
	if dp>0 then depreciable_life_net=m1*avg_ppent/dp;

	* capital expenditures;

	capex_revenue=sum(capxv,-1*sppe,0)/sale;
	if oibdp>0 then capex_ebitda=sum(capxv,-1*sppe,0)/oibdp;
	if dp>0 then capex_depreciation=sum(capxv,-1*sppe,0)/dp;

	* financial leverage;

	debt_to_assets=sum(0,dlc,dltt)/at;
	liabilities_to_assets=lt/at;
	if ceq>0 then debt_to_equity=sum(0,dlc,dltt)/ceq;

	* coverage ratios;

	ebit_coverage=oiadp/sum(xint,dvp/(1-taxrate));
	ebitda_coverage=oibdp/sum(xint,dvp/(1-taxrate));

	* disaggregating roe;
	levered_profit_margin=sum(ib,-1*dvp)/sale;
	if avg_equity>0 then financial_leverage_factor=at/avg_common;

run;

%let ratios = roa_unlevered roi roe unlevered_profit_margin asset_utilization cogs_expense_ratio sga_expense_ratio depreciation_amort_ratio advert_ratio r_and_d_ratio current_ratio acid_ratio
			  cfo_current_liabilities ppe_gross_turnover ppe_net_turnover payable_turnover inventory_turnover receivables_turnover pct_uncollectible days_payable days_inventory receivable_collection
			  trade_cash_cycle depreciable_life_gross depreciable_life_net capex_revenue capex_ebitda capex_depreciation debt_to_assets liabilities_to_assets debt_to_equity ebit_coverage
			  ebitda_coverage levered_profit_margin financial_leverage_factor roa profit_margin;

data home.ratios;
	set ratios;
	keep gvkey conm fyear datadate &ratios;
run;
*/
