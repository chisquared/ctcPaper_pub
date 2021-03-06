*****************
*set up rd file *
*****************

version 16
cd "$main/core"

*compute annual CPIs
import fred CPIAUCSL, aggregate(annual) clear
gen year = year(daten)
ren CPIAUCSL cpi
keep year cpi
save "$main/ctcPaper/annual_cpi", replace
li if year==2016 //2015 value used below


*get tax parameters (taken from TRIM3, see taxparm.xlsx)
clear
input year exemption stdded_joint stdded_hoh pct10_joint pct10_hoh pct15_joint pct15_hoh tax3
2016	4050	12600	9300	18550	13250	75300	50400	0.25
2015	4000	12600	9250	18450	13150	74900	50200	0.25
2014	3950	12400	9100	18150	12950	73800	49400	0.25
2013	3900	12200	8950	17850	12750	72500	48600	0.25
2012	3800	11900	8700	17400	12400	70700	47350	0.25
2011	3700	11600	8500	17000	12150	69000	46250	0.25
2010	3650	11400	8400	16750	11950	68000	45550	0.25
2009	3650	11400	8350	16700	11950	67900	45500	0.25
2008	3500	10900	8000	16050	11450	65100	43650	0.25
2007	3400	10700	7850	15650	11200	63700	42650	0.25
2006	3300	10300	7550	15100	10750	61300	41050	0.25
2005	3200	10000	7300	14600	10450	59400	39800	0.25
2004	3100	9700	7150	14300	10200	58100	38900	0.25
2003	3050	9500	7000	14000	10000	56800	38050	0.25
2002	3000	7850	6900	12000	10000	46700	37450	0.27
2001	2900	7600	6650	12000	10000	45200	36250	0.275
2000	2800	7350	6450	0	0	43850	35150	0.28
1999	2750	7200	6350	0	0	43050	34550	0.28
1998	2700	7100	6250	0	0	42350	33950	0.28
1997	2650	6900	6050	0	0	41200	33050	0.28
1996	2550	6700	5900	0	0	40100	32150	0.28
end
save "$main/ctcPaper/taxparm", replace 

*School starting ages
import excel using "$main/ctcPaper/CompulsoryAttendance.xlsx", sheet("Attendance Laws") cellrange(A4:R55) clear firstrow
foreach var of varlist B-R {
ren `var' age`: var label `var''
}
ren State statename
reshape long age@, i(statename) j(year)
replace age = trim(age)
gen endage = real(substr(age,-2,2))
merge m:1 statename using "$main/ctcPaper/taxsim_crosswalk", keep(1 3) keepusing(statefips) nogen
drop if year==2013 //4 states have inconsistent ages with before/after, doesn't match NCSL report (http://www.ncsl.org/research/education/upper-compulsory-school-age.aspx), so data likely not trustworthy
xtset statefips year
tsfill, full
by statefips: replace endage = endage[_n-1] if mi(endage) //assume all changes happen at next observed year
save "$main/ctcPaper/school_ages", replace 





*set up analysis file
cd "$main"
timer clear
timer on 1
use $main/ctcPaper/rd_all_tax if agem<60, clear //take only up to age 22 to reduce file size on import

set more off 

***Correcting ages
//clean up year variables
replace tbyear = . if tbyear==0

//fix later panel imputation indicators
replace abmnth = 0 if abmnth==1 & spanel==2014
replace abmnth = 1 if abmnth==6 & spanel==2014 //count "imputed from a range" as hot deck
replace abyear = abyear - 1 if inrange(abyear,1,2) & spanel==2014

//merge on corrected ages (to see who has weird values)
merge m:1 spanel ssuid epppnum using $main/ctcPaper/agelink.dta, keep(1 3) keepusing(birth_mon) gen(invalid_age)
replace invalid_age = 0 if invalid_age==3
tab year invalid_age, mi //only a problem for 13-15--b/c imputed values
replace invalid_age = 1 if tage<0

//fix birth month to match non-imputed values
replace ebmnth = month(dofm(birth_mon))

***panel setup
egen hid = group(ssuid spanel)
egen pid = group(ssuid spanel epppnum)
xtset pid year
egen cgroup = group(ghlfsam gvarstr spanel )

***RD setup
//main RD indicators
gen D = agem>=0	
gen zabove = agem*D
gen zbelow = agem*(1-D)

//DiRD setup
gen agepost = agem>=-6 
lab var agepost "Age Near Cutoff"
gen treated = 12.ebmnth
lab var treated "December FE"
gen postmonths = inlist(ebmnth,10,11,12)
lab var postmonths "4th Quarter FE"
gen postmonths6 = inlist(ebmnth,7,8,9,10,11,12)
lab var postmonths6 "2nd Half-Year FE"

//year setup
gen post = year>=2001 //CTC started in 1998, this reflects Additional CTC starting in 2001
gen postD = post*D
gen postzabove = post*zabove
gen postzbelow = post*zbelow
gen postmonth = post*ebmnth

//revised DiRD indicators
gen near17 = agem>=-6 
gen decPlus = ebmnth>=7 & !mi(ebmnth)
gen janMinus = 1-decPlus
gen age_below = -ebmnth
replace age_below = 0 if ebmnth>=7
gen age_above = 12-ebmnth
replace age_above = 0 if ebmnth<=6
gen age_ab17 = age_above * near17 //change at age 17
gen age_be17 = age_below * near17 //change at age 17
gen DiRD = near17 * decPlus //agem>=0, but zeroed for first six month
lab var near17 "Age 16.5+ (Post)"
lab var DiRD "Diff in Disc."
lab var decPlus "December Disc."
lab var age_below "Age below cutoff"
lab var age_above "Age above cutoff"
lab var age_be17 "Age below cutoff, near 17"
lab var age_ab17 "Age above cutoff, near 17"

//placebo discontinuities
gen agem17 = agem
gen D17 = D
gen zabove17 = zabove
gen zbelow17 = zbelow
gen agepost17 = agepost
foreach a in 18 16 15 14 {
	if `a'<18 {
		loc a2 = `a'+1
		gen agem`a' = agem`a2'+12
	}
	else gen agem`a' = agem - 12 //age 18
	gen D`a' = agem`a'>=0     
	gen zabove`a' = agem`a'*D`a'
	gen zbelow`a' = agem`a'*(1-D`a')
	gen agepost`a' = agem`a'>=-6 
	gen near`a' = agepost`a'
	gen DiRD`a' = near`a' * decPlus
	gen age_ab`a' = age_above * near`a' 
	gen age_be`a' = age_below * near`a' 
}

//rd bandwidths
gen double kwt6 = max(0,1-abs(agem)/6)*(wt) //triangle kernel
gen double kwt12 = max(0,1-abs(agem)/12)*(wt) //triangle kernel, bw 12 months
gen double kwt60 = max(0,1-abs(agem)/60)*(wt) //triangle kernel, bw 60 months
gen double kwt24 = max(0,1-abs(agem)/24)*(wt) //triangle kernel, bw 24 months
gen double kwt36 = max(0,1-abs(agem)/36)*(wt) //triangle kernel, bw 36 months
gen double kwt48 = max(0,1-abs(agem)/48)*(wt) //triangle kernel, bw 48 months

//unweighted bandwidths
gen kw6 = max(0,1-abs(agem)/6)
gen kw12 = max(0,1-abs(agem)/12)
gen kw24 = max(0,1-abs(agem)/24)
gen kw36 = max(0,1-abs(agem)/36)
gen kw48 = max(0,1-abs(agem)/48)
gen kw60 = max(0,1-abs(agem)/60)

//revised kernals - adding 0.5 to age to treat December correctly, account for monthly data
gen double kwt_new3 = max(0,1-abs(age_below+age_above+0.5)/3)*(wt) 
gen double kwt_new6 = max(0,1-abs(age_below+age_above+0.5)/6)*(wt) 
gen double kwt_new12 = max(0,1-abs(age_below+age_above+0.5)/12)*(wt) 



***Sample selection
egen par_obs = rowmax(par_months_obs par_spous_months_obs) //changed to max
gen lag_obs = L.par_obs

gen samp_8mo = livespar==1 & par_obs>=8 & lag_obs>=8 & !mi(par_obs) & !mi(lag_obs) & par_depx!=0 & invalid_age!=1 & !(head_tage<0 | spous_tage<0) //allow missing one wave
gen samp_nolag = livespar==1 & par_obs>=8 & !mi(par_obs) & par_depx!=0 & invalid_age!=1 & !(head_tage<0 | spous_tage<0)
gen samp_lag = livespar==1 & par_obs>=12 & lag_obs>=12 & !mi(par_obs) & !mi(lag_obs) & par_depx!=0 & invalid_age!=1 & !(head_tage<0 | spous_tage<0) //removed: abmnth!=1 (because using corrected ages)

	
***covariates
egen par_educ = rowmax(head_educ spous_educ)
gen head_poc = head_race!=1 if !mi(head_race)
gen spous_poc = spous_race!=1 if !mi(spous_race)
egen par_race = rowmax(head_poc spous_poc)
gen par_marr = par_mstat==2 //note missings are counted as zero in mstat
egen par_age = rowmax(head_tage spous_tage)
gen par_age2 = par_age * par_age

gen twopar = !inlist(epnmom,-1,9999) & !inlist(epndad,-1,9999)
gen par_coll = par_educ>=4 if !mi(par_educ)

gen poc = race!=1 if !mi(race) //child is non-white

gen met = tmetro==1

//education level
gen grade = eeducate - 26
replace grade = . if eeducate==-1
recode grade (5=0) (6=4) (7=6) (12=11) (13=12) (14/16=21) (17=22) (18=24) (19/21=26)
replace grade = higrade if year<1996
replace grade = . if higrade==0
replace grade = grade - 1 if year<1996 & grdcmpl!=1
replace grade = 21 if grade==20 //some college inclues non-completers
replace grade = grade-8 if grade > 20 & !mi(grade) //rescale college to years of school
gen hsgrad = inrange(educ,2,5)
gen lag_hsgrad = L.hsgrad
gen lead_hsgrad = F.hsgrad
gen enroll = inlist(renroll,1,2) if !inlist(renroll,-1,0) //ignore "niu" values--note variable is only defined for age 15+ kids


//flag single earning parents
gen par1_earn = (par_pwages>0 & !mi(par_pwages))
gen par2_earn = (par_swages>0 & !mi(par_swages))
gen onepar_earn = (par1_earn==1 & par2_earn==0) | (par1_earn==0 & par2_earn==1) 
gen twopar_earn = par1_earn==1 & par2_earn==1

gen par_sing_lths = par_marr==0 & par_educ<=2 


lab var par_coll "Education (College+)"
lab var par_race "Race (Non-White)"
lab var par_marr "Married"
lab var twopar "Two Parents"
lab var par_age "Age (max)"

lab var enroll "Enrolled in School" 
lab var poc "Child's Race (Non-White)"
lab var grade "Grade in School"



***inflation adjustments
merge m:1 year using "$main/ctcPaper/annual_cpi", keep(1 3) nogen

egen cpi2016 = max(cond(year==2016,cpi,0))
egen cpi2015 = max(cond(year==2015,cpi,0))
egen cpi2014 = max(cond(year==2014,cpi,0))
egen cpi2012 = max(cond(year==2012,cpi,0))

//set reference CPI
gen cpi_ref = cpi2016 //values in 2016 dollars

//recode incomes to real amounts
gen par_ctc_nom = par_ctc
replace par_ctc =  cpi_ref * par_ctc / cpi if !mi(cpi) 

gen par_agi_real =  cpi_ref * par_agi / cpi if !mi(cpi) 

gen par_allinc_nom = par_allinc
replace par_allinc =  cpi_ref * par_allinc / cpi if !mi(cpi) 

gen par_taxinc_nom = par_allinc_nom - par_fiitax - par_siitax - par_fica
gen par_taxinc =  cpi_ref * par_taxinc_nom / cpi if !mi(cpi) 

gen par_wage_real =  cpi_ref * par_wage / cpi if !mi(cpi) 

//alt ctc with one fewer child--not used
gen par_ctc_alt_nom = par_ctc_alt
replace par_ctc_alt =  cpi_ref * par_ctc_alt / cpi if !mi(cpi) 



***set CTC parameters
//parameters from TRIM3

//maximum CTC
gen par_ctc_max_nom = 1000 * par_ctc_kids if year>=2003
*replace par_ctc_max_nom = 1300 * par_ctc_kids if inlist(year,2008) //assume recovery rebate credit is claimed - not counting this as CTC
replace par_ctc_max_nom = 600 * par_ctc_kids if inlist(year,2001,2002)
replace par_ctc_max_nom = 500 * par_ctc_kids if inlist(year,1999,2000)
replace par_ctc_max_nom = 400 * par_ctc_kids if inlist(year,1998)

gen par_ctc_max = (par_ctc_max_nom / 1000) *  cpi_ref / cpi if !mi(cpi) //scaled to 1000s

//lowest income to get refundable CTC
gen ctc_threshold = .
replace ctc_threshold = 10000 if year==2001
replace ctc_threshold = 10350 if year==2002
replace ctc_threshold = 10500 if year==2003
replace ctc_threshold = 10750 if year==2004
replace ctc_threshold = 11000 if year==2005
replace ctc_threshold = 11300 if year==2006
replace ctc_threshold = 11750 if year==2007
replace ctc_threshold = 8500 if year==2008
replace ctc_threshold = 3000 if year>=2009

gen ctc_phasein = 0.15 if year>=2004
replace ctc_phasein = 0.1 if inrange(year,2001,2003)


//tax calculations to get ctc cutoff
merge m:1 year using "$main/ctcPaper/taxparm", keep(1 3) nogen

gen par_std = cond(par_marr==1,stdded_joint,stdded_hoh)
gen par_10pct = cond(par_marr==1,pct10_joint,pct10_hoh)
gen par_15pct = cond(par_marr==1,pct15_joint,pct15_hoh)
gen par_unearned = par_agi - par_wage 

gen tax_cutoff = par_std + (1+par_marr+par_depx)*exemption
gen earn_cutoff = tax_cutoff - par_unearned
gen tax_cut1 = tax_cutoff
gen tax_cut2 = tax_cutoff + par_10pct
gen tax_cut3 = tax_cutoff + par_15pct

gen ctc_cat = 0 if par_ctc_max_nom == 0
replace ctc_cat = 1 if 0 < par_ctc_max_nom & par_ctc_max_nom <= 0.1 * par_10pct
replace ctc_cat = 2 if 0.1 * par_10pct < par_ctc_max_nom & par_ctc_max_nom <= 0.15 *  (par_15pct-par_10pct) + 0.1 * par_10pct 
replace ctc_cat = 3 if 0.15 *  (par_15pct-par_10pct) + 0.1 * par_10pct  < par_ctc_max_nom & par_ctc_max_nom < .
bys ctc_cat: summ par_ctc_max_nom

gen ctc_tax_cut = .
replace ctc_tax_cut = earn_cutoff + par_ctc_max_nom / 0.1 if ctc_cat==1
replace ctc_tax_cut = earn_cutoff + par_10pct + (par_ctc_max_nom - 0.1*par_10pct) / 0.15 if ctc_cat==2
replace ctc_tax_cut = earn_cutoff + par_10pct + par_15pct + (par_ctc_max_nom - (0.15 *  (par_15pct-par_10pct) + 0.1 * par_10pct)) / tax3 if ctc_cat==3

gen ctc_refund_cut = ctc_threshold + par_ctc_max_nom / ctc_phasein if !mi(ctc_phasein) & par_ctc_max_nom>0

//set earnings cutoffs
gen ctc_cutoff = ctc_refund_cut if ctc_refund_cut < earn_cutoff & !mi(ctc_refund_cut) & par_ctc_kids>0 //only gets actc
replace ctc_cutoff = ctc_tax_cut if ctc_tax_cut < ctc_threshold & !mi(ctc_threshold) & par_ctc_kids>0 //only gets ctc

//trickiest case is when thresholds overlap, so receiving both ACTC and CTC at same time. Resolve via brute force calculation.
cap frame drop calc
frame put if mi(ctc_cutoff) & par_ctc_max_nom > 0 & !mi(par_ctc_max_nom) & par_ctc_kids>0 , into(calc)
*cwf calc
frame calc {
	keep pid year par_unearned tax_cutoff par_* tax3 ctc_* 
	gen e = 0
	gen taxable_inc = max(e + par_unearned - tax_cutoff,0) 
	gen tax = taxable_inc * .1 + max(taxable_inc - par_10pct,0)*.05 + max(taxable_inc - par_15pct,0)*(tax3 - .15)
	gen actc = min(max(ctc_phasein*(e-ctc_threshold),0),max(par_ctc_max_nom - tax,0))
	gen ctc_val = actc + min(par_ctc_max_nom,tax)
	gen ctc_val_old = ctc_val
	gen e_final0 = .
	//zeroth pass - find values to ten-thousanth place
	forval e = 1/10 {
	quietly {
	replace e = `e'*10000
	replace taxable_inc = max(e + par_unearned - tax_cutoff,0) 
	replace tax = taxable_inc * .1 + max(taxable_inc - par_10pct,0)*.05 + max(taxable_inc - par_15pct,0)*(tax3 - .15)
	replace actc = min(max(ctc_phasein*(e-ctc_threshold),0),max(par_ctc_max_nom - tax,0))
	replace ctc_val = actc + min(par_ctc_max_nom,tax)
	replace e_final0 = e - 10000 if ctc_val_old==ctc_val & ctc_val > 0 & !mi(ctc_val) & mi(e_final0)
	replace ctc_val_old = ctc_val
	}
	}
	//first pass - find values to thousanth place
	gen e_final = .
	replace ctc_val_old = .
	forval e = 0/12 {
	quietly {
	replace e = e_final0 - 10000 +`e'*1000 - 1000
	replace taxable_inc = max(e + par_unearned - tax_cutoff,0) 
	replace tax = taxable_inc * .1 + max(taxable_inc - par_10pct,0)*.05 + max(taxable_inc - par_15pct,0)*(tax3 - .15)
	replace actc = min(max(ctc_phasein*(e-ctc_threshold),0),max(par_ctc_max_nom - tax,0))
	replace ctc_val = actc + min(par_ctc_max_nom,tax)
	replace e_final = e - 1000 if ctc_val_old==ctc_val & ctc_val > 0 & !mi(ctc_val) & mi(e_final)
	replace ctc_val_old = ctc_val
	}
	}
	//second pass - find values to hundredth place
	gen e_final2 = .
	replace ctc_val_old = .
	forval e = 0/12 {
	quietly {
	replace e = e_final - 1000 +`e'*100 - 100
	replace taxable_inc = max(e + par_unearned - tax_cutoff,0) 
	replace tax = taxable_inc * .1 + max(taxable_inc - par_10pct,0)*.05 + max(taxable_inc - par_15pct,0)*(tax3 - .15)
	replace actc = min(max(ctc_phasein*(e-ctc_threshold),0),max(par_ctc_max_nom - tax,0))
	replace ctc_val = actc + min(par_ctc_max_nom,tax)
	replace e_final2 = e - 100 if ctc_val_old==ctc_val & ctc_val > 0 & !mi(ctc_val) & mi(e_final2)
	replace ctc_val_old = ctc_val
	}
	}
	//third pass - find values to tenth place
	gen e_final3 = .
	replace ctc_val_old = .
	forval e = 0/12 {
	quietly {
	replace e = e_final2 - 100 +`e'*10 - 10
	replace taxable_inc = max(e + par_unearned - tax_cutoff,0) 
	replace tax = taxable_inc * .1 + max(taxable_inc - par_10pct,0)*.05 + max(taxable_inc - par_15pct,0)*(tax3 - .15)
	replace actc = min(max(ctc_phasein*(e-ctc_threshold),0),max(par_ctc_max_nom - tax,0))
	replace ctc_val = actc + min(par_ctc_max_nom,tax)
	replace e_final3 = e - 10 if ctc_val_old==ctc_val & ctc_val > 0 & !mi(ctc_val) & mi(e_final3)
	replace ctc_val_old = ctc_val
	}
	}
	//last pass - find values to ones place
	gen e_final4 = .
	replace ctc_val_old = .
	forval e = 0/12 {
	quietly {
	replace e = e_final3 - 10 +`e'*1 - 1
	replace taxable_inc = max(e + par_unearned - tax_cutoff,0) 
	replace tax = taxable_inc * .1 + max(taxable_inc - par_10pct,0)*.05 + max(taxable_inc - par_15pct,0)*(tax3 - .15)
	replace actc = min(max(ctc_phasein*(e-ctc_threshold),0),max(par_ctc_max_nom - tax,0))
	replace ctc_val = actc + min(par_ctc_max_nom,tax)
	replace e_final4 = e - 1 if ctc_val_old==ctc_val & ctc_val > 0 & !mi(ctc_val) & mi(e_final4)
	replace ctc_val_old = ctc_val
	}
	}
}
*cwf default
frlink 1:1 pid year, frame(calc)
frget e_final4, from(calc)
frame drop calc
replace ctc_cutoff = e_final4 if mi(ctc_cutoff) & par_ctc_kids > 0

replace ctc_cutoff = max(ctc_cutoff,0) //can't have negative values
gen ctc_cutoff_real = ctc_cutoff * cpi_ref / cpi

gen below_cutoff = (par_wage < ctc_cutoff) if par_ctc_kids>0 


//ctc plateau with consistent income cutoff (using 2009+ parameters)
gen ctc_plateau_inc_constant =  ((min(par_ctc_kids,3) * 1000 / 0.15) + 3000)  if par_ctc_kids > 0 //in base_cpi  dollars. Note doesn't work for age 18 and above

gen below_plateau = (par_wage_real < ctc_plateau_inc_constant) if par_ctc_kids>0


//ctc plateau using actual parameters--doesn't work for pre-2001
gen ctc_plateau_inc = (par_ctc_max_nom  / 0.15) + ctc_threshold if year>=2004
replace ctc_plateau_inc = (par_ctc_max_nom  / 0.1) + ctc_threshold if inrange(year,2001,2003)
replace ctc_plateau_inc = . if par_ctc_kids == 0

gen below_plateau_nom = (par_wage < ctc_plateau_inc) if par_ctc_kids>0  

 
//use 2009 parameters, in 2012 dollars (to match end of old sample)
gen below_plateau_2012 = ((par_wage_real *  cpi2012  /  cpi_ref)  < ctc_plateau_inc_constant) if par_ctc_kids>0


//agi cutoff (2015 parameters, from 1040 form)
gen ctc_agi_thresh = cond(par_marr==1,12600,9250) + (1+par_marr+par_depx)*4000 + (par_ctc_kids*1000/.1) if par_ctc_kids>0 //ignores 15% bracket

gen below_agi = par_agi_real < ctc_agi_thresh


gen below_with_agi =  below_agi * below_plateau


*other incomes
gen has_childearn = pearn>0 & !mi(pearn) if tage>=15 //only defined for 15+
foreach var in par_dividends par_otherprop par_pensions par_gssi par_transfers par_ui {
gen has_`var' = `var'>0 & !mi(`var')
}


***add school starting ages
recode tfipsst (0 60/99=.) , gen(statefips) //remove combined areas
merge m:1 statefips year using "$main/ctcPaper/school_ages", keepusing(endage) gen(school_merge)
drop if school_merge==2 //combined states


***attrition
sort spanel srefmon year
by spanel srefmon: gen last_obs = year[_N]
xtset

gen attrit = F.hastearn==. if year<last_obs

gen next_months = F.months_obs if year<last_obs
replace next_months = 0 if mi(next_months) & year<last_obs



***fix weight
replace wt = wt/10000 //account for 4 implied decimals



***Outcomes

//lfp
forval month = 1/12 {
gen par_lfp`month' = inrange(head_tax_rmesr`month',1,7) | inrange(spous_tax_rmesr`month',1,7)
}
egen par_lfp = rowmax(par_lfp1-par_lfp12) //ever in labor force during year
egen par_months_lfp = rowtotal(par_lfp1-par_lfp12) //note there is seam bias - spikes at 4,8,12)


//employment (from ESR)
forval month = 1/12 {
gen par_wrk`month' = inrange(head_tax_rmesr`month',1,5) | inrange(spous_tax_rmesr`month',1,5)
}
egen par_wrk = rowmax(par_wrk1-par_wrk12) //ever has job during year

//spd measures of lfp 
drop spd_lfp spd_wrk 
egen spd_lfp = rowtotal(head_spd_lfp spous_spd_lfp)
egen spd_wrk = rowtotal(head_spd_wrk spous_spd_wrk)
replace par_lfp = (spd_lfp>0) if spd==1 & !mi(spd_lfp)
replace par_wrk = (spd_wrk>0) if spd==1 & !mi(spd_wrk)


//assets 
gen assets = thhtnw - thhtheq //exclude home value
gen ihs_assets = log(assets + sqrt(assets^2 + 1))
gen real_wealth = thhtnw * cpi_ref / cpi
gen ihs_wealth =  log(real_wealth + sqrt(real_wealth^2 + 1))



***prior year variables
xtset
gen lag_hastearn = L.hastearn
gen lag_par_lfp = L.par_lfp
gen lag_par_wrk = L.par_wrk

gen lag_par_ctc = L.par_ctc
gen lag_pct_ctc = L.pct_ctc
gen lag_pct2_ctc = L.pct2_ctc
gen lag_par_ctc_alt = L.par_ctc_alt
gen lag_par_wage_real = L.par_wage_real
gen lag_par_agi_real = L.par_agi_real
gen lag_par_taxinc = L.par_taxinc
gen lag_par_allinc = L.par_allinc
gen lag_ihs_assets = L.ihs_assets
gen lag_real_wealth = L.real_wealth


gen par_lfp_diff = D.par_lfp
gen hastearn_diff = hastearn - lag_hastearn
gen hst_diff = D.hastearn


***alternate income cutoffs
summ below_cutoff below_plateau below_agi below_with_agi below_plateau_2012 below_plateau_nom

gen below_fixed = L.below_plateau
gen below_rt = L.below_cutoff
gen below_nom = L.below_plateau_nom
gen below2012 = L.below_plateau_2012

//Limit to agi from 0-30k
gen below30k = inrange(lag_par_agi_real,0,30000)
gen below_and_30k = below_fixed * below30k //note uses old below definition


// 20k income cutoff
gen below20k = inrange(lag_par_agi_real,0,20000)

//25k
gen below25k =  inrange(lag_par_agi_real,0,25000) // & inrange(L.par_wage_real,0,25000)

//post-tax income cut
gen below_taxinc = inrange(lag_par_taxinc,0,25000)
gen just_above_taxinc = inrange(lag_par_taxinc,25000,35000)

//all income, 20k
gen below_allinc = inrange(lag_par_allinc,0,20000)


***make indicators for near plateau	 
gen just_above_plateau = (par_wage_real - 10000 < ctc_plateau_inc_constant) & (par_agi_real - 10000 < ctc_agi_thresh) if par_ctc_kids>0	
replace just_above_plateau = 0 if below_plateau==1 &  below_agi==1
gen just_above_fixed = L.just_above_plateau

gen just_above_plateau2012 = (par_wage_real * (cpi2012 / cpi_ref) - 10000 < ctc_plateau_inc_constant)*(1-below2012) 
gen just_above2012 = L.just_above_plateau2012

gen just_above_plateau30k = (par_wage_real - 10000 < ctc_plateau_inc_constant) * (inrange(par_agi_real,0,40000)) * (1-below_and_30k)
gen just_above30k = L.just_above_plateau30k

gen just_above20k = inrange(lag_par_agi_real,20000.01,30000)

gen just_above25k = inrange(lag_par_agi_real,25000,35000) // & inrange(L.par_wage_real,25000,35000) 

gen just_above_allinc = inrange(lag_par_allinc,20000,30000)



**labels
lab var D "Discontinuity"
lab var post "Post Period (2001+)"
lab var postD "Diff. in Disc."
lab var lag_hastearn "Lagged Employment (0/1)"
lab var par_lfp "Parent in Labor Force"
lab var par_ctc_max "Maximum CTC Eligibility ($1000s)"

compress





***********
***set default values
***********

*Age range
gen agerange = inrange(agem,-36,11) //only include 14 to 17 year olds
gen agerange_dird = inrange(agem,-42,5) //age 13.5+


*sample
*gen samp = samp_lag
gen samp = samp_8mo //alow up to 4 missing months of data, income imputed

* //remove spd
drop if spd==1 
replace wt = wpfinwgt_orig if inrange(year,1996,2001)
*


*income cut
/*
gen below = below_fixed 
gen just_above = just_above_fixed


gen below = below25k
gen just_above = just_above25k


gen below = below_taxinc
gen just_above = just_above_taxinc
*/

gen below = below20k
gen just_above = just_above20k

gen above = (1- below)
gen inc_typ = below
replace inc_typ = 2 if just_above==1
replace inc_typ = 3 if inc_typ==0
lab def inc_typ 1 "Below Plateau" 2 "Near Plateau" 3 "Above Plateau"
lab val inc_typ inc_typ

compress
save $main/ctcPaper/rd_sample, replace
timer off 1
timer list


