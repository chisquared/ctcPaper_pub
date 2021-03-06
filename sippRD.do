***Program to set up RDs for SIPP data, for Summer 2015 GSR***


pause on 
cap mkdir "$main/ctcPaper/results"
cd "$main/ctcPaper/results"



***********************************************************
*set parameters (varied to test robustness)
***********************************************************

global graphloc "$main/ctcPaper/results"

global controls "i.year par_depx par_race i.par_educ par_marr par_age par_age2 met  i.tfipsst i.par_obs i.lag_obs" //   lag_par_ctc lag_par_wage_real  
global controls_text "(race, education, max age [quadratic], marriage, metro residence, number of dependents, and indicators for current and lagged months observed)"

global tabnote "\emph{Notes:} @starlegend. Standard errors (clustered by variance strata) in parentheses. Discontinuities are estimated with local linear regressions, uniform kernels, in 6-month windows centered around the December age cutoff."
global tabnote2 "\emph{Notes:} @starlegend. Standard errors (clustered by variance strata) in parentheses."

global inctype "AGI"

global incclass `" "\shortstack{All\\Hhlds}" "\$<\$\\\$20k" "\shortstack{ \\\$20k-\\ \$<\$\\\$30k}" "\\\$30k\$+\$" "'
global inccut "\\\\$20,000"

global min_age "14" 
global prev_age "13.5"	
global win_length "-42" 
global win_years "3"


global estnote "Estimated in window of $prev_age to 17.5 year old children in tax units with prior year $inctype below $inccut."

global controlnote  `"Controls are year and state fixed effects and parental characteristics $controls_text."'


global figControlNote "lagged outcomes, year and state fixed effects, and parental characteristics $controls_text."


* make latex notes 
foreach val in figControlNote min_age prev_age {
file open f using "$graphloc/`val'.tex", write replace 
file write f "$`val'" 
file close f
}



*******************
* DiRD results    *
*******************

estimates clear
set more off
set linesize 100

cd "$main"
use ctcPaper/rd_sample, clear


//output location
cd "$graphloc"


*******
*Main results 
*******
//employment
quietly {
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto dird_main_base
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn if  below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto dird_main_lag
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto dird_main_controls
}

//lfp
quietly {
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto lfp_dird_base
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto lfp_dird_lag
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto lfp_dird_controls
}


esttab dird_main_* using "main_dird.tex", booktabs replace ///
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles ///
	indicate("Lagged DV = lag_hastearn" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "')
//note: imposing same slope for 14-16...

esttab lfp_dird_* using "lfp_dird.tex", booktabs replace ///
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles ///
	indicate("Lagged DV = lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "')
	
#delimit ;
esttab dird_main_* lfp_dird_* using "comb_dird.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles 
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) 
	mgroups("Parent Employed" "Parent in Labor Force", pattern(1 0 0 1 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "') ; 	
	#delimit cr ;
	

	
*******	
*Covariate balance
*******


//main covars
quietly {
foreach var in coll race marr age depx {
reg par_`var' DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto dirdrobust_`var'
estadd ysumm
}
//lagged DV
reg lag_hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto dirdrobust_lagY
estadd ysumm

reg lag_par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto dirdrobust_lagLFP
estadd ysumm

//education (can only compare to age 15+)
foreach var in enroll grade {
reg `var' DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & inrange(agem,-18,5)  & post & samp [aw=wt], cluster(cgroup)
est sto dirdrobust2_`var'
estadd ysumm
}
}

//children's earnings - can only compare to age 15+ (and april+ for earnings to be defined for full year...)
//doesn't work, because children at age 15.5 around age 16 cutoff, so only see half year of earnings
foreach var in childearn {
reg has_`var' DiRD near17 decPlus age_below age_above age_ab17 age_be17  if  below & inrange(agem,-18,5)   & post & samp [aw=wt], cluster(cgroup)
est sto dirdrobust2ce_`var'
estadd ysumm
}


//index for covariates
egen double tot_wt = total(wt) if below==1 & agerange_dird  & post & samp
foreach var in par_coll par_race par_marr par_age par_depx lag_hastearn lag_par_lfp {
egen std_`var' = std(`var' * wt / tot_wt) if below & agerange_dird  & post & samp
}
//switch order so all go towards more earnings
foreach var in par_race par_depx  {
replace std_`var' = 1 - std_`var'
}
egen index = rowmean(std_*)

reg index DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto index
estadd ysumm


*attrition
reg attrit DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto attrit
estadd ysumm

*months observed next period
reg next_months DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto next_months
estadd ysumm

*Sureg (per Lee 2010)
foreach var in coll race marr age depx {
quietly reg par_`var' DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post & samp [aw=wt]
est sto robust_sureg_`var'
}
foreach var in lag_hastearn lag_par_lfp {
quietly reg `var' DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post & samp [aw=wt]
est sto sureg_`var'
}
suest robust_sureg_* sureg_*, cluster(cgroup)
test DiRD
estadd scalar ptest = r(p), replace: index

#delimit ;
esttab dirdrobust_* index using "dird_robust.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) se label 
	mtitles("\shortstack{Educ\\(Coll+)}" "\shortstack{Race (Non-\\White)}" "Married" "\shortstack{Age\\(max)}" "\shortstack{Num\\Dep.}" "\shortstack{Lag\\Emp.}" "\shortstack{Lag\\LFP}" "Index") 
	stats(N N_clust ymean ptest, label("N" "Clusters" "Mean DV" "\$\chi^2\$ \$p\$-value") fmt(%12.0gc %12.0gc 2)) b(3) se(3) modelwidth(12) type 
	coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.") varwidth(14)
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote $estnote 
	Index refers to standardized index of all other columns. \$\chi^2\$ \$p\$-value is for test of first 7 columns being jointly different from zero in seemingly unrelated regression.
	} "') 	;
	#delimit cr ;

#delimit ;
esttab dirdrobust2_* attrit next_months using "dird_child_educ.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) se label 
	mtitles("\shortstack{Enrolled\\in School}" "\shortstack{Highest Grade\\Completed}" "Attrition" "\shortstack{Future\\Months Obs.}") 
	stats(N N_clust ymean, label("N" "Clusters" "Mean DV") fmt(%12.0gc %12.0gc 2)) b(3) se(3) modelwidth(12) type 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote
	$estnote (Except columns 1 and 2 are estimated in window of 15.5 to 17.5 year old children).
	} "') 	;
	#delimit cr ;


	 //exclude dirdrobust2ce_* (label "Has Earnings" ) b/c hard to interpret with age 15.5 not being for full year...

	 
***********************	
*Other income sources
***********************

//presence of income
xtset
foreach var in par_dividends par_otherprop par_pensions par_gssi par_transfers par_ui {
gen byte lag_has_`var' = L.has_`var'
reg has_`var' DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_has_`var' $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto dirdincome_`var'
}

//income amounts
foreach var in par_dividends par_otherprop par_pensions par_gssi par_transfers par_ui {
gen lag_`var' = L.`var'
reg `var' DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_`var' $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto dirdincome2_`var'
}

#delimit ;
esttab dirdincome_* using "dird_income.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) se label 
	coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.")
	mtitles("Dividends" "Property" "Pensions" "Soc. Sec." "Transfers" "UI") 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) b(3) se(3) modelwidth(12) type 
	indicate("Lagged DV = lag_*" "Controls = 2.par_educ", labels(Yes "")) 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote $estnote $controlnote } "') ;
	#delimit cr ;
	
#delimit ;	
esttab dirdincome2_*, keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) se label 
	mtitles("Dividends" "Property" "Pensions" "Soc. Sec." "Transfers" "UI") 	
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) b(3) se(3) modelwidth(12) type 
	indicate("Lagged DV = lag_*" "Controls = 2.par_educ", labels(Yes "")) 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote $estnote $controlnote } "') ;
#delimit cr ;

***********************	
*Robustness
***********************
	
//employment
quietly {
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  par_sing_lths & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto emp_rob_parsing
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below & agerange_dird & post & samp & endage!=17 [aw=wt], cluster(cgroup)
est sto emp_rob_endage
reg par_wrk DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_wrk $controls if  below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto emp_rob_wrk

}

//lfp
quietly {
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  par_sing_lths & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto lfp_rob_parsing
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below & agerange_dird  & post & samp & endage!=17 [aw=wt], cluster(cgroup)
est sto lfp_rob_endage

}


#delimit ;
esttab dird_main_controls emp_rob_* lfp_dird_controls lfp_rob_* using "rob_dird.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label mtitles("Base" "\shortstack{Single\\Low Educ.}" "\shortstack{Leave\\School\\ \$\ne17\$}" "\shortstack{LFP\\Measure}" 
	"Base" "\shortstack{Single\\Low Educ.}" "\shortstack{Leave\\School\\ \$\ne17\$}") 
	indicate("Lagged DV = lag_hastearn lag_par_lfp lag_par_wrk" "Controls = 2.par_educ", labels(Yes "")) 
	mgroups("Parent Employed" "Parent in Labor Force", pattern(1 0 0 0 1 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	modelwidth(20) coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.") varwidth(14)
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "') ; 	
	#delimit cr ;
		
	
	
***********************	
*Results by entry/exit
***********************

quietly {
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17  $controls if lag_hastearn==0 & below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto entry_dird
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17  $controls if lag_hastearn==1 & below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto exit_dird

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17  $controls if lag_par_lfp==0 & below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto entry_lfp_dird
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17  $controls if lag_par_lfp==1 & below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto exit_lfp_dird
}

#delimit ;	
esttab entry_dird exit_dird entry_lfp_dird exit_lfp_dird using "comb_exit_dird.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label mtitles(Entry Exit Entry Exit) 
	indicate( "Controls = 2.par_educ", labels(Yes "")) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	mgroups("Employed" "In Labor Force", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "') ;
	#delimit cr ;


*******	
*Placebos
*******	
//pre period
quietly {
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post==0 & samp [aw=wt], cluster(cgroup)
est sto pre_dird_base
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below & agerange_dird  & post==0 & samp [aw=wt], cluster(cgroup)
est sto pre_dird_con

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post==0 & samp [aw=wt], cluster(cgroup)
est sto pre_lfp_dird_base
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below & agerange_dird  & post==0 & samp [aw=wt], cluster(cgroup)
est sto pre_lfp_dird_con


reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post==0 & year>=1990 & samp [aw=wt], cluster(cgroup)
est sto pre_dird_base90
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below & agerange_dird & year>=1990  & post==0 & samp [aw=wt], cluster(cgroup)
est sto pre_dird_con90

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below & agerange_dird  & post==0 & year>=1990 & samp [aw=wt], cluster(cgroup)
est sto pre_lfp_dird_base90
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below & agerange_dird & year>=1990  & post==0 & samp [aw=wt], cluster(cgroup)
est sto pre_lfp_dird_con90

}

#delimit ;	
esttab pre_dird_base pre_dird_con pre_lfp_dird_base pre_lfp_dird_con pre_dird_base90 pre_dird_con90 pre_lfp_dird_base90 pre_lfp_dird_con90 
	using "comb_pre_dird.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label 
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.")
	mgroups("1984-1999" "1990-1999", pattern(1 0 0 0 1 0 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	mtitles("Emp." "Emp." "LFP" "LFP" "Emp." "Emp." "LFP" "LFP") 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{$tabnote  $estnote  $controlnote  
	Note that full-year data for 2000 is not included in SIPP data. "Emp." is employment, "LFP" is labor force participation.}"')   ;
	#delimit cr ;
	 

quietly {	
//all households (below and above plateau)
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto all_dird_base
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto all_dird_controls

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto all_lfp_dird_base
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto all_lfp_dird_controls
	
//above plateau only
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if below==0 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto above_dird_base
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if below==0 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto above_dird_controls

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if below==0 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto above_lfp_dird_base
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if below==0 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
est sto above_lfp_dird_controls
}

#delimit ;
esttab all_dird_controls dird_main_controls above_dird_controls using "dird_all.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label mtitles("All Households" "Below Plateau" "Plateau or More") 
	indicate("Lagged DV = lag_hastearn" "Controls = 2.par_educ", labels(Yes "")) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  	
	Estimated in window of $prev_age to 17.5 year old children in tax units, split by prior year earnings relative to real value of $endyr CTC plateau. 
	$controlnote } "') ;
	#delimit cr;
	

#delimit ;
esttab all_dird_controls dird_main_controls above_dird_controls all_lfp_dird_controls lfp_dird_controls above_lfp_dird_controls using "comb_dird_all.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label mtitles("\shortstack{All\\Households}" "\shortstack{Below\\Plateau}" "\shortstack{Plateau\\or More}" "\shortstack{All\\Households}" "\shortstack{Below\\Plateau}" "\shortstack{Plateau\\or More}") 
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) 
	mgroups("Parent Employed" "Parent in Labor Force", pattern(1 0 0 1 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.") varwidth(14)
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  
	Estimated in window of $prev_age to 17.5 year old children in tax units, split by prior year earnings relative to real value of $endyr CTC plateau.  
	$controlnote } "') ;
	#delimit cr ;

//shift disc to other ages (one year comparisons)
foreach placebo in 18 16 15 14 {
quietly {

reg hastearn DiRD`placebo' near`placebo' decPlus age_below age_above age_ab`placebo' age_be`placebo' lag_hastearn $controls if below==1 & inrange(agem`placebo',$win_length,5)  & post & samp [aw=wt], cluster(cgroup)
est sto placebo_dird_`placebo'
	
reg par_lfp DiRD`placebo' near`placebo' decPlus age_below age_above age_ab`placebo' age_be`placebo' lag_par_lfp $controls if below==1 & inrange(agem`placebo',$win_length,5)  & post & samp [aw=wt], cluster(cgroup)
est sto placebo_dird_lfp_`placebo'	
}
}

esttab placebo_dird_16 placebo_dird_15 placebo_dird_14  using "results_placebos_dird.tex", booktabs replace ///
		rename(DiRD16 DiRD DiRD15 DiRD DiRD14 DiRD near16 agepost near15 agepost near14 agepost) ///
		coeflabels(agepost "Age \$\geq\$ Cutoff - 0.5 (Post)") ///
		keep(DiRD agepost decPlus) star(* 0.10 ** 0.05 *** 0.01) mtitles("Age 16" "Age 15" "Age 14") se label ///
		stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) b(3) se(3) type ///
		nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  Estimated in window of $win_years years to left and one year to right of placebo cutoff in primary sample.  $controlnote } "') ///
		indicate("Lagged DV = lag_hastearn" "Controls = 2.par_educ", labels(Yes ""))

esttab placebo_dird_lfp_16 placebo_dird_lfp_15 placebo_dird_lfp_14  using "results_placebos_dird_lfp.tex", booktabs replace ///
		rename(DiRD16 DiRD DiRD15 DiRD DiRD14 DiRD near16 agepost near15 agepost near14 agepost) ///
		coeflabels(agepost "Age \$\geq\$ Cutoff - 0.5 (Post)") ///
		keep(DiRD agepost decPlus) star(* 0.10 ** 0.05 *** 0.01) mtitles("Age 16" "Age 15" "Age 14") se label ///
		stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) b(3) se(3) type ///
		nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  Estimated in window of $win_years years to left and one year to right of placebo cutoff in primary sample.  $controlnote } "') ///
		indicate("Lagged DV = lag_par_lfp" "Controls = 2.par_educ", labels(Yes ""))
	

#delimit ;	
esttab placebo_dird_16 placebo_dird_15 placebo_dird_14 placebo_dird_lfp_16 placebo_dird_lfp_15 placebo_dird_lfp_14 using "comb_placebos_dird.tex", booktabs replace 
		rename(DiRD16 DiRD DiRD15 DiRD DiRD14 DiRD near16 agepost near15 agepost near14 agepost) 
		coeflabels(agepost "Age \$\geq\$ Cutoff - 0.5 (Post)") 
		keep(DiRD agepost decPlus) star(* 0.10 ** 0.05 *** 0.01) mtitles("Age 16" "Age 15" "Age 14" "Age 16" "Age 15" "Age 14") se label 
		stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) b(3) se(3) type 
		mgroups("Parent Employed" "Parent in Labor Force", pattern(1 0 0 1 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
		indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) 
		nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote 
		Estimated in age windows of ${win_years}.5 years to left and 0.5 years to right of placebo cutoff, in primary sample. 
		$controlnote } "') ;
		#delimit cr ;

***********************	
*Results for just above plateau
***********************
	
 
quietly { 
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  inc_typ==2 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto justabove_dird_controls

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  inc_typ==2 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto justabove_lfp_dird_controls
	 
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if inc_typ==3 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto moreabove_dird_controls

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  inc_typ==3 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto moreabove_lfp_dird_controls
}	 
	 
#delimit ;	 
esttab all_dird_controls dird_main_controls justabove_dird_controls moreabove_dird_controls all_lfp_dird_controls lfp_dird_controls justabove_lfp_dird_controls moreabove_lfp_dird_controls using "comb_dird_justAbove.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label mtitles($incclass $incclass) 
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) 
	coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.") varwidth(14)
	mgroups("Parent Employed" "Parent in Labor Force", pattern(1 0 0 0 1 0 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  
	Estimated in window of $prev_age to 17.5 year old children in tax units, classified by prior year $inctype.
	$controlnote } "') 	;
	#delimit cr ;




***********************	
*Results by marital status and number kids
***********************

//employment
quietly {

reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if par_marr==0 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto marr_dird_0
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if par_marr==1 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto marr_dird_1
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if par_depx==1 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto kids_dird_1
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if par_depx>1 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto kids_dird_2

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if par_marr==0 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto marr_lfp_0
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if par_marr==1 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto marr_lfp_1
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if par_depx==1 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto kids_lfp_1
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if par_depx>1 & below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
est sto kids_lfp_2

}


#delimit ;
esttab marr_dird_* kids_dird_* marr_lfp_* kids_lfp_* using "dird_marrkids.tex", booktabs replace 
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label 
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) 
	mtitles("Single" "Married" "1 Kid" "2+ Kids" "Single" "Married" "1 Kid" "2+ Kids") 
	coeflabels(near17 "Age 16.5+" decPlus "Dec. Disc.") varwidth(14)
	mgroups("Parent Employed" "Parent in Labor Force", pattern(1 0 0 0 1 0 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) 
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type 
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "') ;
	#delimit cr ;

	//note: results hold even with lag_par_wage_real < 10000 (i.e. getting rid of relationship between income and num kids)
	 
	 
*******
*Functional form and bandwidths
*******

quietly {
reg hastearn DiRD near17 decPlus lag_hastearn $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 0
estadd local kernel "Uni"
estadd scalar bw 6
est sto dirdfunc_0

reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Uni"
estadd scalar bw 6
est sto dirdfunc_1

reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below & agerange_dird & post & samp [aw=kwt_new6], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Tri"
estadd scalar bw 6
est sto dirdfunc_lp

reg hastearn DiRD near17 decPlus c.age_below##c.age_below c.age_above##c.age_above c.age_ab17##c.age_ab17 c.age_be17##c.age_be17 lag_hastearn $controls if  below & agerange_dird & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 2
estadd local kernel "Uni"
estadd scalar bw 6
est sto dirdfunc_2 

reg hastearn DiRD near17 decPlus c.age_below##c.age_below##c.age_below c.age_above##c.age_above##c.age_above c.age_ab17##c.age_ab17##c.age_ab17 c.age_be17##c.age_be17##c.age_be17 lag_hastearn $controls if  below==1 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 3
estadd local kernel "Uni"
estadd scalar bw 6
est sto dirdfunc_3 
}

esttab dirdfunc_* using "dirdfunc.tex", booktabs replace ///
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles /// mtitles("O Degree" "1 Degree" "Loc. Poly" "2 Degree")
	indicate("Lagged DV = lag_hastearn" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust degree kernel bw, label("N" "Clusters" "Degree" "Kernel" "Bandwidth") fmt(%12.0gc)) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote2  $estnote  Results are estimated for varying degree local linear regresions with uniform or triangular kernels.  $controlnote } "')
	
//3 month bqndwidth
quietly {
reg hastearn DiRD near17 decPlus lag_hastearn $controls if inlist(ebmnth,1,2,3,10,11,12) & below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 0
estadd local kernel "Uni"
estadd scalar bw 3
est sto dirdfunc3_0

reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if inlist(ebmnth,1,2,3,10,11,12) & below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Uni"
estadd scalar bw 3
est sto dirdfunc3_1

reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if below==1 & agerange_dird  & post & samp [aw=kwt_new3], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Tri"
estadd scalar bw 3
est sto dirdfunc3_lp	

reg hastearn DiRD near17 decPlus c.age_below##c.age_below c.age_above##c.age_above c.age_ab17##c.age_ab17 c.age_be17##c.age_be17 lag_hastearn $controls if inlist(ebmnth,1,2,3,10,11,12) & below==1 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 2
estadd local kernel "Uni"
estadd scalar bw 3
est sto dirdfunc3_2

}



esttab dirdfunc_1 dirdfunc_lp dirdfunc_2 dirdfunc3_1 dirdfunc3_lp dirdfunc3_2 using "dirdfunc3.tex", booktabs replace ///
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles /// mtitles("1 Deg, Uni" "1 Deg, Tri" "2 Deg, Uni" "1 Deg, Uni" "1 Deg, Tri" "2 Deg, Uni" ) 
	mgroups("6 month bandwidth" "3 month bandwidth", pattern(1 0 0 1 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	indicate("Lagged DV = lag_hastearn" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust degree kernel bw, label("N" "Clusters" "Degree" "Kernel" "Bandwidth") fmt(%12.0gc)) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote2  $estnote  Results are estimated for varying degree local linear regresions with uniform or triangular kernels.  $controlnote } "')
	
	
* LFP

quietly {
reg par_lfp DiRD near17 decPlus lag_par_lfp $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 0
estadd local kernel "Uni"
estadd scalar bw 6
est sto lfp_dirdfunc_0

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Uni"
estadd scalar bw 6
est sto lfp_dirdfunc_1

reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below==1 & agerange_dird & post & samp [aw=kwt_new6], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Tri"
estadd scalar bw 6
est sto lfp_dirdfunc_lp

reg par_lfp DiRD near17 decPlus c.age_below##c.age_below c.age_above##c.age_above c.age_ab17##c.age_ab17 c.age_be17##c.age_be17 lag_par_lfp $controls if  below==1 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 2
estadd local kernel "Uni"
estadd scalar bw 6
est sto lfp_dirdfunc_2
}


//3 month bandwidth
quietly {
reg par_lfp DiRD near17 decPlus lag_par_lfp $controls if inlist(ebmnth,1,2,3,10,11,12) & below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 0
estadd local kernel "Uni"
estadd scalar bw 3
est sto lfp_dirdfunc3_0
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if inlist(ebmnth,1,2,3,10,11,12) & below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Uni"
estadd scalar bw 3
est sto lfp_dirdfunc3_1
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if below==1 & agerange_dird  & post & samp [aw=kwt_new3], cluster(cgroup)
estadd scalar degree 1
estadd local kernel "Tri"
estadd scalar bw 3
est sto lfp_dirdfunc3_lp	
reg par_lfp DiRD near17 decPlus c.age_below##c.age_below c.age_above##c.age_above c.age_ab17##c.age_ab17 c.age_be17##c.age_be17 lag_par_lfp $controls if inlist(ebmnth,1,2,3,10,11,12) & below==1 & agerange_dird & post & samp [aw=wt], cluster(cgroup)
estadd scalar degree 2
estadd local kernel "Uni"
estadd scalar bw 3
est sto lfp_dirdfunc3_2
}

esttab lfp_dirdfunc_1 lfp_dirdfunc_lp lfp_dirdfunc_2 lfp_dirdfunc3_1 lfp_dirdfunc3_lp lfp_dirdfunc3_2 using "lfp_dirdfunc3.tex", booktabs replace ///
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles /// mtitles("1 Deg, Uni" "1 Deg, Tri" "2 Deg, Uni" "1 Deg, Uni" "1 Deg, Tri" "2 Deg, Uni")
	mgroups("6 month bandwidth" "3 month bandwidth", pattern(1 0 0 1 0 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	indicate("Lagged DV = lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust degree kernel bw, label("N" "Clusters" "Degree" "Kernel" "Bandwidth") fmt(%12.0gc)) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote2  $estnote  Results are estimated for 1 or 2 degree local linear regresions with uniform or triangular kernels.  $controlnote } "')
	
	
//combined
esttab dirdfunc_1 dirdfunc_lp dirdfunc_2 dirdfunc3_0 lfp_dirdfunc_1 lfp_dirdfunc_lp lfp_dirdfunc_2 lfp_dirdfunc3_0 using "comb_dirdfunc3.tex", booktabs replace ///
	keep(DiRD near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles /// mtitles("\shortstack{1 Deg\\ Uni}" "\shortstack{1 Deg\\ Tri}" "\shortstack{2 Deg\\ Tri}" "\shortstack{0 Deg\\ 3 Mo.}" "\shortstack{1 Deg\\ Uni}" "\shortstack{1 Deg\\ Tri}" "\shortstack{2 Deg\\ Uni}" "\shortstack{0 Deg\\ 3 Mo.}") ///
	mgroups("Employment" "LFP", pattern(1 0 0 0 1 0 0 0 ) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust degree kernel bw, label("N" "Clusters" "Degree" "Kernel" "Bandwidth") fmt(%12.0gc)) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote2  $estnote  Results are estimated for varying degree local linear regresions with uniform or triangular kernels.  $controlnote } "')	
	

*******
*Fuzzy RD
*******
//program to compute fuzzy estimates
cap prog drop get_est
prog def get_est, rclass
	mat r = r(b)
	mat v = r(V)
	loc nl_b =r[1,1]
	loc nl_v = sqrt(v[1,1])
	loc nl_z = `nl_b' / `nl_v'
	loc nl_p = 2*(1-normal(abs(`nl_z'))) 
	loc nl_star = cond(`nl_p'<.01,"***",cond(`nl_p'<.05,"**",cond(`nl_p'<.1,"*","")))
	*di "`nl_b' `nl_v' `nl_z' `nl_p' `nl_star'"
	loc nl_bshort = string(`nl_b',"%4.3f")
	loc nl_vshort = string(`nl_v',"%4.3f")
	loc nl_symbol = cond("`nl_star'"!="",`"\sym{`nl_star'}"',"")
	return loc nl_est `"`nl_bshort'`nl_symbol'"'
	return loc nl_std = "("+"`nl_vshort'"+")"
end

gen mean_work = 1
gen inc = lag_par_taxinc / 1000
gen ret_work = lag_hastearn

qui reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below==1 & agerange_dird  & post & samp [aw=wt]
est sto e1
qui reg par_ctc_max DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below==1 & agerange_dird  & post & samp [aw=wt]
est sto e2
qui reg lag_hastearn mean_work if below==1 & agerange_dird  & post & samp [aw=wt], nocons
est sto earn_mean
qui reg inc i.ret_work if below==1 & agerange_dird  & post & samp [aw=wt]
est sto inc_mean
//get joint se
suest e1 e2 earn_mean inc_mean, cluster(cgroup)
//fuzzy rd
nlcom fuzzy: [e1_mean]DiRD / [e2_mean]DiRD
get_est
estadd local nl_est `r(nl_est)'
estadd local nl_std `r(nl_std)'
//elasticity
nlcom elas: ([e1_mean]DiRD / [earn_mean_mean]mean_work ) / ([e2_mean]DiRD / ([inc_mean_mean]1.ret_work))
get_est
estadd local nl_elas `r(nl_est)'
estadd local nl_elas_std `r(nl_std)'
est sto dird_fuzzy


*table
esttab dird_fuzzy using "dird_fuzzy.tex", booktabs replace /// 
	keep(DiRD mean_work 1.ret_work) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles ///
	coeflabel(mean_work "Mean" 1.ret_work "Mean") ///
	eqlabels("(A) Parent Employed" "(B) Maximum Eligible CTC (\\$1,000s)" "(C) Percent Working (lag)" "(D) Return to Work (lag, \\$1,000s)")  ///
	stats(nl_est nl_std nl_elas nl_elas_std N N_clust, label("ITT Estimate" "(\$=A/B\$)" "Elasticity at Average" "(\$=(A/C)/(B/D)\$)" "N" "Clusters") fmt(%4.3f %4.3f %4.3f %4.3f %12.0gc %12.0gc)) type ///
	equations("") ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  Discontinuity estimates include lagged presence of earnings and controls; C and D are simple means in sample.  Return to work is computed as difference in post-tax income between working and non-working parents.  $controlnote } "') 
	

//lfp
replace ret_work = lag_par_lfp
qui reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below==1 & agerange_dird  & post & samp [aw=wt]
est sto e1
qui reg par_ctc_max DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below==1 & agerange_dird  & post & samp [aw=wt]
est sto e2
qui reg lag_par_lfp mean_work if below==1 & agerange_dird & post & samp [aw=wt], nocons
est sto earn_mean
qui reg inc i.ret_work if below==1 & agerange_dird & post & samp [aw=wt]
est sto inc_mean
//get joint se
suest e1 e2 earn_mean inc_mean, cluster(cgroup)
//fuzzy rd
nlcom fuzzy: [e1_mean]DiRD / [e2_mean]DiRD
get_est
estadd local nl_est `r(nl_est)'
estadd local nl_std `r(nl_std)'
//elasticity
nlcom elas: ([e1_mean]DiRD / [earn_mean_mean]mean_work ) / ([e2_mean]DiRD / ([inc_mean_mean]1.ret_work))
get_est
estadd local nl_elas `r(nl_est)'
estadd local nl_elas_std `r(nl_std)'
est sto lfp_fuzzy_dird

*combined table
#delimit ;
esttab dird_fuzzy lfp_fuzzy_dird using "comb_dird_fuzzy.tex", booktabs replace 
	keep(DiRD mean_work 1.ret_work) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label  
	coeflabel(mean_work "Mean" 1.ret_work "Mean" ) 
	eqlabels("(A) Parent Employed / In LF" "(B) Maximum Eligible CTC (\\$1,000s) " "(C) Percent Working / LFP (lag)" "(D) Return to Work / LFP (lag, \\$1,000s)")  
	stats(nl_est nl_std nl_elas nl_elas_std N N_clust, label("ITT Estimate" "(\$=A/B\$)" "Elasticity at Average" "(\$=(A/C)/(B/D)\$)" "N" "Clusters") fmt(%4.3f %4.3f %4.3f %4.3f %12.0gc %12.0gc)) type 
	equations("") mtitles("Employed" "In Labor Force")
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  
	Return to work is computed as difference in post-tax income between working and non-working parents (and likewise for LFP). 
	Fuzzy RD and elasticity standard errors are computed using the delta method. 
	$controlnote } "') ;
	#delimit cr ;


	
	
*******
*Descriptives
*******
	
gen age = (agem+17*12)/12
gen hastearn_pct = hastearn
lab var hastearn_pct "Share of tax units with earnings"
gen lfp_pct = par_lfp
lab var lfp_pct "Share of tax units in labor force"
lab var par_taxinc "Post-tax income (2016$)"
lab var age "Child Age as of end of tax year"
lab var par_depx "Tax unit number of dependents"
lab var par_race "Either parent is non-white"
lab var par_educ "Highest Parent Education"
lab def educ 1 "< High School" 2 "HS Grad" 3 "Some College" 4 "College Grad" 5 "Advanced Degree", modify
lab val par_educ educ
tab par_educ, gen(par_educ)
lab var par_marr "Parents are married"
lab var par_age "Parent Age (max)"
lab var year "Year"
gen tab_ctc = par_ctc * 1000
lab var tab_ctc "Amount of CTC received (2016$)"
//add year? comma issue

estpost summ hastearn_pct lfp_pct par_taxinc tab_ctc age par_age par_depx par_race par_educ1-par_educ5 par_marr   if post & samp & agerange_dird [aw=wt]
est sto all_desc
estpost summ hastearn_pct lfp_pct par_taxinc tab_ctc age par_age par_depx par_race par_educ1-par_educ5 par_marr   if post & samp & agerange_dird & below [aw=wt]
est sto prim_desc

esttab all_desc using describe_dird_all.tex, booktabs replace type label mtitles("All Households") nonumbers ///
	cells("mean(fmt(%10.2fc)) sd(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr)) min(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr)) max(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr))") ///
	coeflabels(par_educ1 "\hspace{2em} < High School" par_educ2 "\hspace{2em} HS Grad" par_educ3 "\hspace{2em} Some College" par_educ4 "\hspace{2em} College Grad" par_educ5 "\hspace{2em} Advanced Degree") ///
	substitute(\$ \\$ < $<$) refcat(par_educ1 "\emph{Highest Parent Education}", nolabel)
esttab prim_desc using describe_dird.tex, booktabs replace type label mtitles("Primary Sample") nonumbers ///
	cells("mean(fmt(%10.2fc)) sd(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr)) min(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr)) max(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr))") ///
	coeflabels(par_educ1 "\hspace{2em} < High School" par_educ2 "\hspace{2em} HS Grad" par_educ3 "\hspace{2em} Some College" par_educ4 "\hspace{2em} College Grad" par_educ5 "\hspace{2em} Advanced Degree") ///
	substitute(\$ \\$ < $<$) refcat(par_educ1 "\emph{Highest Parent Education}", nolabel)	
*combined
esttab all_desc prim_desc using describe_dird_comb.tex, booktabs replace type label mtitles("All Households" "Primary Sample") nonumbers ///
	cells(mean(fmt(%10.2fc)) sd(fmt(%10.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr) par)  min(fmt(%11.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr) par("[" "")) & max(fmt(%11.2fc) drop(hastearn_pct lfp_pct par_race par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_marr) par("" "]"))  ) incelldelimiter(---) collabels(,none) ///
	coeflabels(par_educ1 "\hspace{2em} < High School" par_educ2 "\hspace{2em} HS Grad" par_educ3 "\hspace{2em} Some College" par_educ4 "\hspace{2em} College Grad" par_educ5 "\hspace{2em} Advanced Degree") ///
	substitute(\$ \\$ < $<$) refcat(par_educ1 "\emph{Highest Parent Education}", nolabel) order(hastearn_pct lfp_pct par_race par_marr par_educ1 par_educ2 par_educ3 par_educ4 par_educ5 par_taxinc tab_ctc age par_age par_depx )


	
*******
*Month FE method
*******	

*Main model (for 14-17 age range)
*no month fe
reg hastearn D zabove zbelow if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup) 
est store reg_basic
*month fe
reg hastearn D zabove zbelow i.ebmnth if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup) 
est store reg_month
*lagged earnings //preferred
reg hastearn D zabove zbelow i.ebmnth lag_hastearn if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup)
est sto reg_lag
*controls
reg hastearn D zabove zbelow i.ebmnth lag_hastearn $controls if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup)
est sto reg_controls 

*basic table
esttab reg_* using "regs_below.tex", booktabs replace ///
	keep(D) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label ///
	indicate("Month FE = 2.ebmnth" "Lagged DV = lag_hastearn" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type ///
	postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ Estimated in window of 14 to 17 year old children in tax units with prior year earnings below real value of $endyr CTC plateau. $controlnote }"') ///
	nomtitles 
	
	
*LFP results
*Main model (for 14-17 age range)
*no month fe
reg par_lfp D zabove zbelow if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup) 
est store lfp_reg_basic
*month fe
reg par_lfp D zabove zbelow i.ebmnth if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup) 
est store lfp_reg_month
*lagged earnings //preferred
reg par_lfp D zabove zbelow i.ebmnth lag_par_lfp if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup)
est sto lfp_reg_lag
*controls
reg par_lfp D zabove zbelow i.ebmnth lag_par_lfp $controls if below & post & samp & inrange(agem,-36,11) [aw=wt], cluster(cgroup)
est sto lfp_reg_controls 

*basic table
esttab lfp_reg_* using "regs_below_lfp.tex", booktabs replace ///
	keep(D) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label ///
	indicate("Month FE = 2.ebmnth" "Lagged DV = lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust, label("N" "Clusters") fmt(%12.0gc)) type ///
	postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ Estimated in window of 14 to 17 year old children in tax units with prior year earnings below real value of $endyr CTC plateau. $controlnote }"') ///
	nomtitles 

	
********
*Age 18 change
********

//age 18 with sample fix
reg hastearn DiRD18 DiRD near18 near17  decPlus age_below age_above age_ab17 age_be17 age_ab18 age_be18  if below & inrange(agem,-42,17) & post & samp [aw=wt], cluster(cgroup)
lincom DiRD + DiRD18
estadd r(estimate)
estadd r(se)
estadd scalar pstat = r(p)
est sto age18_base

reg hastearn DiRD18 DiRD near18 near17  decPlus age_below age_above age_ab17 age_be17 age_ab18 age_be18 lag_hastearn $controls if below & inrange(agem,-42,17) & post & samp [aw=wt], cluster(cgroup) 
lincom DiRD + DiRD18
estadd r(estimate)
estadd r(se)
estadd scalar pstat = r(p)
est sto age18_controls 


reg par_lfp DiRD18 DiRD near18 near17  decPlus age_below age_above age_ab17 age_be17 age_ab18 age_be18 if below & inrange(agem,-42,17) & post & samp [aw=wt], cluster(cgroup) 
lincom DiRD + DiRD18
estadd r(estimate)
estadd r(se)
estadd scalar pstat = r(p)
est sto age18_lfp_base

reg par_lfp DiRD18 DiRD near18 near17  decPlus age_below age_above age_ab17 age_be17 age_ab18 age_be18 lag_par_lfp $controls if below & inrange(agem,-42,17) & post & samp [aw=wt], cluster(cgroup) 
lincom DiRD + DiRD18
estadd r(estimate)
estadd r(se)
estadd scalar pstat = r(p)
est sto age18_lfp_controls


esttab age18_* using "age18.tex", booktabs replace ///
	keep(DiRD18 DiRD near18 near17 decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles coeflabels(DiRD18 "Age 18 Disc." DiRD "Age 17 Disc." near18 "Age 17.5+" near17 "Age 16.5+") ///
	mgroups("Employed" "Labor Force", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust estimate se pstat, label("N" "Clusters" "Age 18 + 17" "(se)" "(p-value)") fmt(%12.0gc %12.0gc 3 3 3) layout(@ @ @ "(@)" "[@]")) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "') 
	

esttab age18_* using "age18_short.tex", booktabs replace ///
	keep(DiRD18 DiRD decPlus) star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) label nomtitles coeflabels(DiRD18 "Age 18 Disc." DiRD "Age 17 Disc." near18 "Age 17.5+" near17 "Age 16.5+") ///
	mgroups("Employed" "Labor Force", pattern(1 0 1 0) span prefix(\multicolumn{@span}{c}{) suffix(}) erepeat(\cmidrule(lr){@span})) ///
	indicate("Lagged DV = lag_hastearn lag_par_lfp" "Controls = 2.par_educ", labels(Yes "")) ///
	stats(N N_clust estimate se pstat, label("N" "Clusters" "Age 18 + 17" "(se)" "(p-value)") fmt(%12.0gc %12.0gc 3 3 3) layout(@ @ @ "(@)" "[@]")) type ///
	nonotes postfoot("\bottomrule" "\end{tabular}" "}" `"\fnote{ $tabnote  $estnote  $controlnote } "') 
		
	
	
******************	
******************	
*	FIGURES
******************	
******************

	
*******
*bandwidth graph
*******

gen x2 = _n in 1/6 
quietly {
forval y = 1/6 {
loc left = -`y'
loc right = `y'-1
if `y'==1 loc slopes ""
else loc slopes "age_below age_above age_ab17 age_be17"
reg hastearn DiRD near17 decPlus `slopes' if  below==1 & inrange(age_below,`left',0) & inrange(age_above,0,`right') & inrange(agem,$win_length,5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_hst_band`y'_base
reg hastearn DiRD near17 decPlus `slopes' lag_hastearn $controls if  below==1 & inrange(age_below,`left',0) & inrange(age_above,0,`right') & inrange(agem,$win_length,5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_hst_band`y'_controls
reg par_lfp DiRD near17 decPlus `slopes' if  below==1 & inrange(age_below,`left',0) & inrange(age_above,0,`right') & inrange(agem,$win_length,5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_lfp_band`y'_base
reg par_lfp DiRD near17 decPlus `slopes' lag_par_lfp $controls if  below==1 & inrange(age_below,`left',0) & inrange(age_above,0,`right') & inrange(agem,$win_length,5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_lfp_band`y'_controls
}
}
quietly {
foreach outcome in hst lfp {
foreach est in base controls {
gen bandest_`outcome'_`est'_val = .
gen bandest_`outcome'_`est'_high = .
gen bandest_`outcome'_`est'_low = .
}
}
forval x = 1/6 { 
foreach outcome in hst lfp {
foreach est in base controls {
est restore dird_`outcome'_band`x'_`est'
replace bandest_`outcome'_`est'_val  = _b[DiRD] if x2==`x'
replace bandest_`outcome'_`est'_high = bandest_`outcome'_`est'_val + invnormal(0.05) * _se[DiRD] if x2==`x'
replace bandest_`outcome'_`est'_low  = bandest_`outcome'_`est'_val - invnormal(0.05) * _se[DiRD] if x2==`x'
}
}
}
}

twoway rspike  bandest_hst_base_low bandest_hst_base_high x2 || scatter bandest_hst_base_val x2 || in 1/6, scheme(s1mono) name(band_base_hastearn, replace) legend(off) title("DiRD Estimates for Employment, Raw") subtitle(Varying Bandwidth) ytitle(Percent of Children with Employed Parent) xtitle(Bandwidth in Months) yline(0, lcolor(gs12) lpattern(dash))

twoway rspike  bandest_hst_controls_low bandest_hst_controls_high x2 || scatter bandest_hst_controls_val x2 || in 1/6, scheme(s1mono) name(band_controls_hastearn, replace) legend(off) title("DiRD Estimates for Employment, with Controls") subtitle(Varying Bandwidth) ytitle(Percent of Children with Employed Parent) xtitle(Bandwidth in Months) yline(0, lcolor(gs12) lpattern(dash))

twoway rspike  bandest_lfp_base_low bandest_lfp_base_high x2 || scatter bandest_lfp_base_val x2 || in 1/6, scheme(s1mono) name(band_base_lfp, replace) legend(off) title("DiRD Estimates for LFP, Raw") subtitle(Varying Bandwidth) ytitle(Percent of Children with Parent in Labor Force) xtitle(Bandwidth in Months) yline(0, lcolor(gs12) lpattern(dash))

twoway rspike  bandest_lfp_controls_low bandest_lfp_controls_high x2 || scatter bandest_lfp_controls_val x2 || in 1/6, scheme(s1mono) name(band_controls_lfp, replace) legend(off) title("DiRD Estimates for LFP, with Controls") subtitle(Varying Bandwidth) ytitle(Percent of Children with Parent in Labor Force) xtitle(Bandwidth in Months) yline(0, lcolor(gs12) lpattern(dash))


//combined graph
graph combine band_controls_hastearn band_controls_lfp, name(band_combined, replace) rows(2) cols(1) scheme(s1mono) //play(windows) 
gr_edit .plotregion1.graph1.subtitle.text = {}
gr_edit .plotregion1.graph2.subtitle.text = {}
gr_edit .plotregion1.graph1.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.yaxis1.title.text = {}

//export graphs
foreach graph in  band_controls_hastearn band_controls_lfp band_combined {
graph export `graph'.pdf, name(`graph') replace
}


//get magnitudes just to know
esttab dird_hst_band*_controls, keep(DiRD) se star(* 0.10 ** 0.05 *** 0.01) b(3) se(3)
esttab dird_lfp_band*_controls, keep(DiRD) se star(* 0.10 ** 0.05 *** 0.01) b(3) se(3)
	

*******
*Graphs of seasonality over time
*******
	

preserve

keep if post & samp & below //to make coefplot run faster
	
forval ag = -204(12)60 {
*loc ag = -12
loc age = (`ag'+17*12)/12
cap drop disc`age' 
cap drop zabv`age' 
cap drop zblw`age'
cap drop mod`age'
gen disc`age' = inrange(agem,`ag',`ag'+5) //this gives raw discontinuity
gen zabv`age'= cond(inrange(agem,`ag'-6,`ag'+5),(agem+17*12-`age'*12)*disc`age', 0)
gen zblw`age'= cond(inrange(agem,`ag'-6,`ag'+5),(agem+17*12-`age'*12)*(1-disc`age'), 0)
gen mod`age' = inrange(agem,`ag'-6,`ag'+5)
cap drop ddisc`age' 
cap drop dzabv`age' 
cap drop dzblw`age'
cap drop dmod`age'
gen ddisc`age'= agem >=`ag' & (ebmnth>=7) //this gives diff in disc relative to prior year
gen dzabv`age'= cond(agem>=`ag'-6,age_above, 0)
gen dzblw`age'= cond(agem>=`ag'-6,age_below, 0)
gen dmod`age' = agem>=`ag'-6
}
drop disc22 zabv22 zblw22 mod22 zblw0 disc0 zabv0 mod0 //can't compute at ends
drop ddisc22 dzabv22 dzblw22 dmod22 dzblw0 ddisc0 dzabv0 dmod0 //can't compute at ends


reg hastearn disc* zabv* zblw* mod* if post & samp & below [aw=wt], cluster(cgroup)
coefplot, keep(disc*) drop(disc1 disc21) vert rename(disc* = " ") name(discByAge, replace) scheme(s1mono) ///
	yline(0) xtitle("Age Cutoff around End of Year") ytitle("Discontinuity for Percent with Employed Parent") ///
	title(Discontinuities in Parental Employment by Age Cutoff) subtitle(Primary Sample) ysc(titlegap(1.5)) ///
	recast(line) ciopts(recast(rline) lpattern(dash)) levels(90) xline(16.5, lcolor(red)) xline(15.5, lcolor(red))
	
graph export discByAge.pdf, name(discByAge) replace

reg hastearn disc* zabv* zblw* mod* lag_hastearn $controls if post & samp & below [aw=wt], cluster(cgroup)
coefplot, keep(disc*) drop(disc1 disc21) vert rename(disc* = " ") name(discByAge_controls, replace) scheme(s1mono) ///
	yline(0) xtitle("Age Cutoff around End of Year") ytitle("Discontinuity for Percent with Employed Parent") ///
	title(Discontinuities in Parental Employment by Age Cutoff) subtitle("Primary Sample, with Controls") ysc(titlegap(1.5)) ///
	recast(line) ciopts(recast(rline) lpattern(dash)) levels(90) xline(16.5, lcolor(red)) xline(15.5, lcolor(red))

graph export discByAge_controls.pdf, name(discByAge_controls) replace


reg par_lfp disc* zabv* zblw* mod* if post & samp & below [aw=wt], cluster(cgroup)
coefplot, keep(disc*) drop(disc1 disc21) vert rename(disc* = " ") name(discByAge_lfp, replace) scheme(s1mono) ///
	yline(0) xtitle("Age Cutoff around End of Year") ytitle("Discontinuity for Percent with Parent in Labor Force") ///
	title(Discontinuities in Parental LFP by Age Cutoff) subtitle(Primary Sample) ysc(titlegap(1.5)) ///
	recast(line) ciopts(recast(rline) lpattern(dash)) levels(90) xline(16.5, lcolor(red)) xline(15.5, lcolor(red))
graph export discByAge_lfp.pdf, name(discByAge) replace

reg par_lfp disc* zabv* zblw* mod* lag_par_lfp  $controls if post & samp & below [aw=wt], cluster(cgroup)
coefplot, keep(disc*) drop(disc1 disc21) vert rename(disc* = " ") name(discByAge_controls_lfp, replace) scheme(s1mono) ///
	yline(0) xtitle("Age Cutoff around End of Year") ytitle("Discontinuity for Percent with Parent in Labor Force") ///
	title(Discontinuities in Parental LFP by Age Cutoff) subtitle("Primary Sample, with Controls")  ysc(titlegap(1.5)) ///
	recast(line) ciopts(recast(rline) lpattern(dash)) levels(90) xline(16.5, lcolor(red)) xline(15.5, lcolor(red))
graph export discByAge_controls_lfp.pdf, name(discByAge_controls) replace

graph combine discByAge discByAge_lfp, rows(2) cols(1) name(discByAge_combined, replace) scheme(s1mono) //play(discByAge)
gr_edit .plotregion1.graph1.subtitle.text = {}
gr_edit .plotregion1.graph2.subtitle.text = {}
gr_edit .plotregion1.graph1.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.title.text = {"Discontinuities in Parental Labor Force Participation by Age Cutoff"}
graph export discByAge_combined.pdf, name(discByAge_combined) replace


graph combine discByAge_controls discByAge_controls_lfp, rows(2) cols(1) name(discByAge_combined_controls, replace) scheme(s1mono) //play(discByAge) 
gr_edit .plotregion1.graph1.subtitle.text = {}
gr_edit .plotregion1.graph2.subtitle.text = {}
gr_edit .plotregion1.graph1.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.title.text = {"Discontinuities in Parental Labor Force Participation by Age Cutoff"}
graph export discByAge_combined_controls.pdf, name(discByAge_combined_controls) replace


//plot changes in discontinuities over time
reg hastearn ddisc* dzabv* dzblw* dmod* lag_hastearn $controls if post & samp & below [aw=wt], cluster(cgroup)
coefplot, keep(ddisc*) drop(ddisc1 ddisc2 ddisc21) vert rename(ddisc* = " ") name(ddiscByAge_controls, replace) scheme(s1mono) ///
	yline(0) xtitle("Age Cutoff around End of Year") ytitle("DiRD for Percent with Employed Parent") ///
	title(Change in Discontinuities in Parental Employment by Age Cutoff) subtitle("Primary Sample, with Controls") ysc(titlegap(1.5)) ///
	recast(line) ciopts(recast(rline) lpattern(dash)) levels(90) xline(15.5, lcolor(red)) xline(14.5, lcolor(red))

graph export ddiscByAge_controls.pdf, name(discByAge_controls) replace

reg par_lfp ddisc* dzabv* dzblw* dmod* lag_par_lfp  $controls if post & samp & below [aw=wt], cluster(cgroup)
coefplot, keep(ddisc*) drop(ddisc1 ddisc2 ddisc21) vert rename(ddisc* = " ") name(ddiscByAge_controls_lfp, replace) scheme(s1mono) ///
	yline(0) xtitle("Age Cutoff around End of Year") ytitle("DiRD for Percent with Parent in Labor Force") ///
	title(Change in Discontinuities in Parental LFP by Age Cutoff) subtitle("Primary Sample, with Controls")  ysc(titlegap(1.5)) ///
	recast(line) ciopts(recast(rline) lpattern(dash)) levels(90) xline(15.5, lcolor(red)) xline(14.5, lcolor(red))
graph export ddiscByAge_controls_lfp.pdf, name(discByAge_controls) replace


graph combine ddiscByAge_controls ddiscByAge_controls_lfp, rows(2) cols(1) name(ddiscByAge_combined_controls, replace) scheme(s1mono) //play(ddiscByAge) 
gr_edit .plotregion1.graph1.subtitle.text = {}
gr_edit .plotregion1.graph2.subtitle.text = {}
gr_edit .plotregion1.graph1.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.yaxis1.title.text = {}
graph export ddiscByAge_combined_controls.pdf, name(ddiscByAge_combined_controls) replace



restore


*******
*Graph of Other Ages comparison
*******


//all years
quietly {
forval y = 1/16 {
loc start = -6 -`y'*12
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & inrange(agem,`start',5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_hst_back`y'_base
reg hastearn DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_hastearn $controls if  below==1 & inrange(agem,`start',5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_hst_back`y'_controls
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & inrange(agem,`start',5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_lfp_back`y'_base
reg par_lfp DiRD near17 decPlus age_below age_above age_ab17 age_be17 lag_par_lfp $controls if  below==1 & inrange(agem,`start',5)  & post & samp [aw=wt], cluster(cgroup)	
est sto dird_lfp_back`y'_controls
}
}
quietly {
gen y = _n in 1/16
gen x = 17-y in 1/16
foreach outcome in hst lfp {
foreach est in base controls {
gen est_`outcome'_`est'_val = .
gen est_`outcome'_`est'_high = .
gen est_`outcome'_`est'_low = .
}
}
forval x = 1/16 {
loc y = 17-`x'
foreach outcome in hst lfp {
foreach est in base controls {
est restore dird_`outcome'_back`y'_`est'
replace est_`outcome'_`est'_val  = _b[DiRD] if x==`x'
replace est_`outcome'_`est'_high = est_`outcome'_`est'_val + invnormal(0.05) * _se[DiRD] if x==`x'
replace est_`outcome'_`est'_low  = est_`outcome'_`est'_val - invnormal(0.05) * _se[DiRD] if x==`x'
}
}
}
}

replace x = x-0.5
twoway rspike  est_hst_base_low est_hst_base_high x || scatter est_hst_base_val x || in 1/16, scheme(s1mono) name(windows_base_hastearn, replace) legend(off) title("DiRD Estimates for Employment, Raw") subtitle(Varying Pre-Period Window) ytitle(Percent of Children with Employed Parent) xtitle(Minimum Age in Window) yline(0, lcolor(gs12) lpattern(dash))

twoway rspike  est_hst_controls_low est_hst_controls_high x || scatter est_hst_controls_val x || in 1/16, scheme(s1mono) name(windows_controls_hastearn, replace) legend(off) title("DiRD Estimates for Employment, with Controls") subtitle(Varying Pre-Period Window) ytitle(Percent of Children with Employed Parent) xtitle(Minimum Age in Window) yline(0, lcolor(gs12) lpattern(dash))

twoway rspike  est_lfp_base_low est_lfp_base_high x || scatter est_lfp_base_val x || in 1/16, scheme(s1mono) name(windows_base_lfp, replace) legend(off) title("DiRD Estimates for LFP, Raw") subtitle(Varying Pre-Period Window) ytitle(Percent of Children with Parent in Labor Force) xtitle(Minimum Age in Window) yline(0, lcolor(gs12) lpattern(dash))

twoway rspike  est_lfp_controls_low est_lfp_controls_high x || scatter est_lfp_controls_val x || in 1/16, scheme(s1mono) name(windows_controls_lfp, replace) legend(off) title("DiRD Estimates for LFP, with Controls") subtitle(Varying Pre-Period Window) ytitle(Percent of Children with Parent in Labor Force) xtitle(Minimum Age in Window) yline(0, lcolor(gs12) lpattern(dash))

//combined graph
graph combine windows_controls_hastearn windows_controls_lfp, name(windows_combined, replace) rows(2) cols(1)  scheme(s1mono) //play(windows)
gr_edit .plotregion1.graph1.subtitle.text = {}
gr_edit .plotregion1.graph2.subtitle.text = {}
gr_edit .plotregion1.graph1.yaxis1.title.text = {}
gr_edit .plotregion1.graph2.yaxis1.title.text = {}

//export graphs
foreach graph in  windows_controls_hastearn windows_controls_lfp windows_combined {
graph export `graph'.pdf, name(`graph') replace
}
	

	
*******
*first stage (used for graphs of effects)
*******	

reg par_ctc_max DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & agerange_dird  & post & samp [aw=wt]
est sto first_stage

	
*******************	
*graphs of effects
*******************

gen hastearn_below = hastearn if below 
gen hastearn_above = hastearn if below==0 

gen par_lfp_below = par_lfp if below 
gen par_lfp_above = par_lfp if below==0 

gen par_ctc_max_below = par_ctc_max if below

gen ag = age_below + age_above 

//get residualized y
	reg hastearn lag_hastearn $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
	predict hastearn_dird_res if e(sample), residuals
	reg hastearn_dird_res DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
	est sto res_dird

	reg par_lfp lag_par_lfp $controls if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
	predict par_lfp_dird_res if e(sample), residuals
	reg par_lfp_dird_res DiRD near17 decPlus age_below age_above age_ab17 age_be17 if  below==1 & agerange_dird  & post & samp [aw=wt], cluster(cgroup)
	est sto lfp_res_dird

//predict 16 and 17 lines separately for diff
	reg hastearn decPlus age_below age_above  if  below & agerange_dird & agem<=-7  & post & samp [aw=wt]
	est sto main16
	reg hastearn decPlus age_below age_above  if  below & agerange_dird & inrange(agem,-6,5)  & post & samp [aw=wt]
	est sto main17
	suest main16 main17, cluster(cgroup)
	est sto main1617

	//with controls
	reg hastearn_dird_res decPlus age_below age_above   if  below & agerange_dird & agem<=-7  & post & samp [aw=wt]
	est sto main_c16
	reg hastearn_dird_res decPlus age_below age_above   if  below & agerange_dird & inrange(agem,-6,5)  & post & samp [aw=wt]
	est sto main_c17
	suest main_c16 main_c17, cluster(cgroup)
	est sto main_c1617

	//lfp
	//predict 16 and 17 lines separately for diff
	reg par_lfp decPlus age_below age_above  if  below & agerange_dird & agem<=-7  & post & samp [aw=wt]
	est sto lfp16
	reg par_lfp decPlus age_below age_above  if  below & agerange_dird & inrange(agem,-6,5)  & post & samp [aw=wt]
	est sto lfp17
	suest lfp16 lfp17, cluster(cgroup)
	est sto lfp1617

	//with controls
	reg par_lfp_dird_res decPlus age_below age_above   if  below & agerange_dird & agem<=-7  & post & samp [aw=wt]
	est sto lfp_c16
	reg par_lfp_dird_res decPlus age_below age_above   if  below & agerange_dird & inrange(agem,-6,5)  & post & samp [aw=wt]
	est sto lfp_c17
	suest lfp_c16 lfp_c17, cluster(cgroup)
	est sto lfp_c1617

//loc poly
	gen ag_lpoly = ag 
	bys post samp below agerange_dird near17 ag_lpoly: replace ag_lpoly =. if _n>1
	replace ag_lpoly = . if !(post & samp & below & agerange_dird)
	lpoly hastearn ag if ag < 0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(hst_16_left) se(se_16_left) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly hastearn ag if ag >=0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(hst_16_right) se(se_16_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly hastearn ag if ag < 0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(hst_17_left) se(se_17_left)  at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly hastearn ag if ag >=0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(hst_17_right) se(se_17_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)

	lpoly par_lfp ag if ag < 0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(lfp_16_left) se(lse_16_left) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly par_lfp ag if ag >=0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(lfp_16_right) se(lse_16_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly par_lfp ag if ag < 0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(lfp_17_left) se(lse_17_left)  at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly par_lfp ag if ag >=0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(lfp_17_right) se(lse_17_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)

	//add controls
	lpoly hastearn_dird_res ag if ag < 0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(hstc_16_left) se(sec_16_left) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly hastearn_dird_res ag if ag >=0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(hstc_16_right) se(sec_16_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly hastearn_dird_res ag if ag < 0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(hstc_17_left) se(sec_17_left)  at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly hastearn_dird_res ag if ag >=0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(hstc_17_right) se(sec_17_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)

	lpoly par_lfp_dird_res ag if ag < 0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(lfpc_16_left) se(lsec_16_left) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly par_lfp_dird_res ag if ag >=0 & post & samp & below & agerange_dird & agem<=-7 [aw=wt], gen(lfpc_16_right) se(lsec_16_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly par_lfp_dird_res ag if ag < 0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(lfpc_17_left) se(lsec_17_left)  at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)
	lpoly par_lfp_dird_res ag if ag >=0 & post & samp & below & agerange_dird & inrange(agem,-6,5) [aw=wt], gen(lfpc_17_right) se(lsec_17_right) at(ag_lpoly) deg(1) nogr bwidth(6) kernel(tri) pwidth(6)


preserve


gen pop=1
collapse (mean) hastearn hastearn_below hastearn_above hastearn_dird_res par_lfp par_lfp_below par_lfp_above par_lfp_dird_res par_ctc_max par_ctc_max_below DiRD decPlus age_above age_below age_ab17 age_be17 (sum) below pop hst_* se_* lfp_* lse_* hstc_* sec_* lfpc_* lsec_* if samp & agerange_dird [aw=wt], by(ag near17 post)
expand 2 if ag==0, gen(dummy) //create dummy observations to extend left line to age zero
replace decPlus = 0 if dummy==1
replace DiRD = 0 if dummy==1



//general graph program
cap prog drop dird_graph
prog def dird_graph
	syntax varname [if], ESTimate(namelist max=1) name(string) title(string) [subtitle(string)] [gtitle(string)] ytitle(string) graphrange(numlist min=2 max=2) graphstep(numlist max=1)
	tempvar y y_u y_l  sd
	tokenize `graphrange'
	loc begin_range = `1'/100
	loc end_range = `2'/100
	loc graphstep = `graphstep'/100
	loc gtitle1 = "Age ${min_age}-16 Cutoff" + `"`gtitle'"'
	loc gtitle2 = "Age 17 Cutoff" + `"`gtitle'"'

	est restore `estimate'
	predict `y' 
	predict `sd',  stdp
	gen `y_u' = `y' + invnormal(0.05)*`sd' //uses 90% ci
	gen `y_l' = `y' - invnormal(0.05)*`sd'


	twoway rarea `y_l' `y_u' ag if ag<0 | dummy==1, color(gs15) || ///
	       rarea `y_l' `y_u' ag if ag>=0 & dummy==0, color(gs15)  || ///
		   scatter `varlist' ag, msymbol(circle) || ///
		   line `y' ag if ag<0 | dummy==1, lcolor(black) || ///
		   line `y' ag if ag>=0 & dummy==0, lcolor(black) || ///
		   pci `begin_range' 0 `end_range' 0, lcolor(black) || ///
		   `if' & near17==0 , xline(0) name(`name'16, replace)  ylab(`begin_range'(`graphstep')`end_range') title("`gtitle1'") xtitle(Child Month of Birth) ytitle(`ytitle') xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off)
	
	twoway rarea `y_l' `y_u' ag if ag<0 | dummy==1, color(gs15) || ///
	       rarea `y_l' `y_u' ag if ag>=0 & dummy==0, color(gs15)  || ///
		   scatter `varlist' ag, msymbol(circle) || ///
		   line `y' ag if ag<0 | dummy==1, lcolor(black) || ///
		   line `y' ag if ag>=0 & dummy==0, lcolor(black) || ///
		   pci `begin_range' 0 `end_range' 0, lcolor(black) || ///
		   `if' & near17==1 , xline(0) name(`name'17, replace)  ylab(`begin_range'(`graphstep')`end_range') title("`gtitle2'") xtitle(Child Month of Birth) ytitle(`ytitle') xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off)
	
	graph combine `name'16 `name'17, name(`name'_combined, replace) title(`"`title'"') subtitle(`"`subtitle'"') scheme(s1mono)

end

//main graph
dird_graph hastearn_below if post, est(dird_main_base) name(main) title(RD Results for Parental Employment) subtitle(Primary Sample) ytitle(Percent with Employed Parent) graphrange(50 90) graphstep(5)

//pre graph
dird_graph hastearn_below if post==0, est(pre_dird_base) name(pre) title(Placebo RD Results for Parental Employment) subtitle("Primary Sample, Before CTC Was Refundable") ytitle(Percent with Employed Parent) graphrange(50 90) graphstep(5)

//all graph
dird_graph hastearn if post, est(all_dird_base) name(all) title(RD Results for Parental Employment) subtitle(All Households) ytitle(Percent with Employed Parent) graphrange(85 100) graphstep(5)

//above graph
dird_graph hastearn_above if post, est(above_dird_base) name(above) title(RD Results for Parental Employment) subtitle(Households At or Above CTC Plateau) ytitle(Percent with Employed Parent) graphrange(95 100) graphstep(1)

//controls graph
dird_graph hastearn_dird_res if post, est(res_dird) name(res) title("RD Results for Parental Employment with Controls") subtitle(Primary Sample) ytitle(Residual for Percent with Employed Parent) graphrange(-20 20) graphstep(5)
   // scale looks a bit off--could do -10(5)10, but want to match scale of main graph


//lfp graph
dird_graph par_lfp_below if post, est(lfp_dird_base) name(lfp) title(RD Results for Labor Force Participation) subtitle(Primary Sample) ytitle(Percent with Parent in Labor Force) graphrange(60 100) graphstep(5)

//lfp with controls
dird_graph par_lfp_dird_res if post, est(lfp_res_dird) name(lfp_res) title("RD Results for Labor Force Participation with Controls") subtitle(Primary Sample) ytitle(Residual for Percent with Parent in Labor Force) graphrange(-20 20) graphstep(5)

//first stage
dird_graph par_ctc_max_below if post, est(first_stage) name(ctc) title(First Stage RD Results for CTC Eligbility) subtitle(Primary Sample) ytitle(Parent's Maximum Eligible CTC (\$1000s)) graphrange(0 300) graphstep(50)



//diff graph
cap prog drop dird_diff_graph
prog def dird_diff_graph
	syntax varname [if], ESTimate(namelist max=1) name(string) title(string) [subtitle(string)] [gtitle(string)] ytitle(string) graphrange(numlist min=2 max=2) graphstep(numlist max=1)
	tempvar y16 y17 diff yd yd_u yd_l sd
	tokenize `graphrange'
	loc begin_range = `1'/100
	loc end_range = `2'/100
	loc graphstep = `graphstep'/100
	est restore `estimate'16
	predict `y16'
	est restore `estimate'17
	predict `y17'
	sort post dummy ag near17
	by post dummy ag: gen `diff' = `varlist' - `varlist'[_n-1]
	gen `yd' = `y17' - `y16'
	est restore `estimate'1617
	predict `sd', stddp equation(`estimate'16_mean, `estimate'17_mean)
	gen `yd_u' = `yd' + invnormal(0.05)*`sd' //uses 90% ci
	gen `yd_l' = `yd' - invnormal(0.05)*`sd'

	twoway rarea `yd_l' `yd_u' ag if ag<0 | dummy==1, color(gs15) || ///
		   rarea `yd_l' `yd_u' ag if ag>=0 & dummy==0, color(gs15)  || ///
		   scatter `diff' ag, msymbol(circle) || ///
		   line `yd' ag if ag<0 | dummy==1  , lcolor(black) || ///
		   line `yd' ag if ag>=0 & dummy==0, lcolor(black) || ///
		   pci `begin_range' 0 `end_range' 0, lcolor(black) || ///
		`if' & near17==1 , xline(0) name(`name', replace)  ylab(`begin_range'(`graphstep')`end_range') title("`title'") subtitle("`subtitle'") xtitle(Child Month of Birth) ytitle(`"`ytitle'"') xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off) yscale(titlegap(2))

end


//main diff graphs
dird_diff_graph hastearn_below if post, est(main) name(diffdisc17) title("Difference, Age 17 Minus Age ${min_age}-16") subtitle(No Controls) ytitle(Difference in Percent with Employed Parent) graphrange(-20 20) graphstep(5)

dird_diff_graph hastearn_dird_res if post, est(main_c) name(diffres17) title("Difference, Age 17 Minus Age ${min_age}-16") subtitle(With Controls) ytitle("Diff. in Residual for Percent with Employed Parent") graphrange(-20 20) graphstep(5)


//combined diffs
graph combine diffdisc17 diffres17, name(diff_combined, replace) title(DiRD Results for Parental Employment) subtitle(Primary Sample) scheme(s1mono) 


//lfp diff graphs
dird_diff_graph par_lfp_below if post, est(lfp) name(lfpdiff17) title("Difference, Age 17 Minus Age ${min_age}-16") subtitle(No Controls) ytitle(Diff. in Percent with Parent in Labor Force) graphrange(-20 20) graphstep(5)

dird_diff_graph par_lfp_dird_res if post, est(lfp_c) name(lfpdiffres17) title("Difference, Age 17 Minus Age ${min_age}-16") subtitle(With Controls) ytitle("Diff. in Residual for Percent with Parent in Labor Force") graphrange(-20 20) graphstep(5)

graph combine lfpdiff17 lfpdiffres17, name(lfp_diff_combined, replace) title(DiRD Results for Labor Force Participation) subtitle(Primary Sample) scheme(s1mono) 


//combined outcome graph
graph combine diffres17 lfpdiffres17, name(both_dird_combined, replace) title(Discontinuities in Both Outcomes) subtitle("With Controls, Primary Sample") scheme(s1mono) 
gr_edit .plotregion1.graph1.title.text = {"Parent Employed"}
gr_edit .plotregion1.graph2.title.text = {"Parent in Labor Force"}
// graph play graph16 //apply new titles


//age 16 combined graph
graph combine main16 lfp16, name(age16_combined, replace) title(Discontinuities Prior to Loss of CTC Eligibility) subtitle("Age ${min_age}-16, Primary Sample") scheme(s1mono) 
gr_edit .plotregion1.graph1.title.text = {"Parent Employed"}
gr_edit .plotregion1.graph2.title.text = {"Parent in Labor Force"}
// graph play graph16 //apply new titles

graph combine res16 lfp_res16, name(age16res_combined, replace) title(Discontinuities Prior to Loss of CTC Eligibility) subtitle("Age ${min_age}-16, Primary Sample, with Controls") scheme(s1mono) 
gr_edit .plotregion1.graph1.title.text = {"Parent Employed"}
gr_edit .plotregion1.graph2.title.text = {"Parent in Labor Force"}
// graph play graph16 //apply new titles

//lpoly graphs
cap prog drop lpoly_graph
prog def lpoly_graph
	syntax varname [if], est(varlist) se(varlist) name(string) title(string) [subtitle(string)] [gtitle(string)] ytitle(string) graphrange(numlist min=2 max=2) graphstep(numlist max=1)
	tempvar y1 y2 y1_u y1_l y2_u y2_l sd1 sd2 
	tokenize `graphrange'
	loc begin_range = `1'/100
	loc end_range = `2'/100
	loc graphstep = `graphstep'/100
	tokenize `est'
		gen `y1'=`1'
		replace `y1'=`2' if ag>=0 & dummy==0
		gen `y2'=`3'
		replace `y2'=`4' if ag>=0 & dummy==0
	tokenize `se'
		gen `sd1'=`1'
		replace `sd1'=`2' if ag>=0 & dummy==0
		gen `sd2'=`3'
		replace `sd2'=`4' if ag>=0 & dummy==0
		
	loc gtitle1 = "Age ${min_age}-16" + `"`gtitle'"'
	loc gtitle2 = "Age 17" + `"`gtitle'"'

	gen `y1_u' = `y1' + invnormal(0.05)*`sd1' //uses 90% ci
	gen `y1_l' = `y1' - invnormal(0.05)*`sd1'
	gen `y2_u' = `y2' + invnormal(0.05)*`sd2' 
	gen `y2_l' = `y2' - invnormal(0.05)*`sd2'

	twoway rarea `y1_l' `y1_u' ag if ag<0 | dummy==1, color(gs15) || ///
	       rarea `y1_l' `y1_u' ag if ag>=0 & dummy==0, color(gs15)  || ///
		   scatter `varlist' ag, msymbol(circle) || ///
		   line `y1' ag if ag<0 | dummy==1, lcolor(black) || ///
		   line `y1' ag if ag>=0 & dummy==0, lcolor(black) || ///
		   pci `begin_range' 0 `end_range' 0, lcolor(black) || ///
		   `if' & near17==0 , xline(0) name(`name'16, replace)  ylab(`begin_range'(`graphstep')`end_range') title("`gtitle1'") xtitle(Child Month of Birth) ytitle(`ytitle') xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off)
	
	twoway rarea `y2_l' `y2_u' ag if ag<0 | dummy==1, color(gs15) || ///
	       rarea `y2_l' `y2_u' ag if ag>=0 & dummy==0, color(gs15)  || ///
		   scatter `varlist' ag, msymbol(circle) || ///
		   line `y2' ag if ag<0 | dummy==1, lcolor(black) || ///
		   line `y2' ag if ag>=0 & dummy==0, lcolor(black) || ///
		   pci `begin_range' 0 `end_range' 0, lcolor(black) || ///
		   `if' & near17==1 , xline(0) name(`name'17, replace)  ylab(`begin_range'(`graphstep')`end_range') title("`gtitle2'") xtitle(Child Month of Birth) ytitle(`ytitle') xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off)
	
	graph combine `name'16 `name'17, name(`name'_combined, replace) title(`"`title'"') subtitle(`subtitle') scheme(s1mono)

end

lpoly_graph hastearn_below if post, est(hst_16_left hst_16_right hst_17_left hst_17_right) se(se_16_left se_16_right se_17_left se_17_right) name(lpoly) title("RD Results for Employed Parent") subtitle(Primary Sample) ytitle(Percent with Employed Parent) graphrange(50 90) graphstep(5)
lpoly_graph hastearn_dird_res if post, est(hstc_16_left hstc_16_right hstc_17_left hstc_17_right) se(sec_16_left sec_16_right sec_17_left sec_17_right) name(lpolyc) title("RD Results for Employed Parent") subtitle("Primary Sample with Controls") ytitle("Diff. in Residual for Percent with Employed Parent") graphrange(-20 20) graphstep(5)

lpoly_graph par_lfp_below if post, est(lfp_16_left lfp_16_right lfp_17_left lfp_17_right) se(lse_16_left lse_16_right lse_17_left lse_17_right) name(lpoly_lfp) title("RD Results for Parent in Labor Force") subtitle(Primary Sample) ytitle(Percent with Parent in Labor Force) graphrange(60 100) graphstep(10)
lpoly_graph par_lfp_dird_res if post, est(lfpc_16_left lfpc_16_right lfpc_17_left lfpc_17_right) se(lsec_16_left lsec_16_right lsec_17_left lsec_17_right) name(lpolyc_lfp) title("RD Results for Parent in Labor Force") subtitle("Primary Sample with Controls") ytitle("Diff. in Residual for Percent with Parent in Labor Force") graphrange(-20 20) graphstep(5)



//age 16 combined graph
graph combine lpoly16 lpoly_lfp16, name(age16lpoly_combined, replace) title(Discontinuities Prior to Loss of CTC Eligibility) subtitle("Age ${min_age}-16, Primary Sample") scheme(s1mono) 
gr_edit .plotregion1.graph1.title.text = {"Parent Employed"}
gr_edit .plotregion1.graph2.title.text = {"Parent in Labor Force"}
// graph play graph16 //apply new titles

//histogram
gen new_count = below
replace new_count = new_count if near17==0 //avg for pooled period

scatter new_count ag  if near17==0 & post, xline(0) name(hist16, replace)   title("Age ${min_age}-16") xtitle(Child Month of Birth) ytitle(Weighted Observations) xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off)
scatter new_count ag  if near17==1 & post, xline(0) name(hist17, replace)  title("Age 17") xtitle(Child Month of Birth) ytitle(Weighted Observations) xlab(-6 "Jun" -5 "May" -4 "Apr" -3 "Mar" -2 "Feb" -1 "Jan" 0 "Dec" 1 "Nov" 2 "Oct" 3 "Sep" 4 "Aug" 5 "Jul", angle(90)) scheme(s1mono) legend(off)
graph combine hist16 hist17, name(hist_combined, replace) title(Density Results) scheme(s1mono) ycommon




//export graphs, stripping titles
foreach graph in main_combined pre_combined lfp_combined res_combined lfp_res_combined diff_combined lfp_diff_combined ctc_combined age16_combined age16res_combined hist_combined both_dird_combined lpoly_combined lpoly_lfp_combined lpolyc_combined lpolyc_lfp_combined {
graph save `graph' `graph'.gph, replace
graph use `graph', name(`graph', replace) //play(stripTitles) 
gr_edit .title.text = {}
gr_edit .subtitle.text = {}
graph export `graph'.pdf, name(`graph') replace
}

restore


***
*For paper - share paying no tax w/o refundable ctc

cd "$main"
use ctcPaper/rd_all_tax, clear
keep if primarytaxpayer==1
keep if mstat!=8 // drop dependent filers
gen tax_no_ctc = fiitax + nonrefundable_ctc
gen any_tax_no_ctc = tax_no_ctc>0 if !mi(tax_no_ctc)
gen any_tax = fiitax>0 if !mi(fiitax)
tab any_tax if agi<30000 & depx>0 & year>=2001 [iw=wt] 
tab any_tax_no_ctc if agi<30000 & depx>0 & year>=2001 [iw=wt] 
//these tables are used in paper



