*Make compressed versions of SIPP data files (December data only)

version 16

cd "$main/core"

***************************
*****Collect monthly data**
***************************

**get earnings and work status by month
foreach year in 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 {
	*loc year = 2016 //uncomment to run specific years
	loc y = substr("`year'",-2,2)
	set more off
	use $main/ctcPaper/cy`y'.dta, clear
	keep ssuid spanel epppnum tpearn rhcalmn rmesr
	greshape wide tpearn rmesr, i(spanel ssuid epppnum) j(rhcalmn)

	gen year = `year'

	gen epnmom = epppnum
	gen epndad = epppnum
	gen epnguard = epppnum

	compress
	save $main/ctcPaper/famearn_months`y'.dta, replace
}

**get monthly ages, standardize
// https://www.census.gov/programs-surveys/sipp/tech-documentation/user-notes/2004-and-2008-User-Note.html
if 1==1 { //wrapper for code folding
	use ssuid epppnum spanel rhcalyr rhcalmn ebmnth abmnth tbyear abyear tage using $main/ctcPaper/cy96, clear
	gen year = 1996
	foreach year of numlist 1997/2016 1984/1995 {
		*loc year = 2015 //uncomment to run specific years
		loc y = substr("`year'",-2,2)
		if `year'==2000 continue
		if `year'<1996 loc ab ""
		else loc ab "abmnth abyear"
		append using $main/ctcPaper/cy`y', keep(ssuid epppnum spanel rhcalyr rhcalmn ebmnth  tbyear tage `ab') nolabel 

		replace year = `year' if mi(year)
	}
	gen date = ym(rhcalyr, rhcalmn)
	format date %tm
	fsort spanel ssuid epppnum date

	//fix later panel imputation indicators
	replace abmnth = 0 if abmnth==1 & spanel==2014
	replace abmnth = 1 if abmnth==6 & spanel==2014 //count "imputed from a range" as hot deck
	replace abyear = abyear - 1 if inrange(abyear,1,2) & spanel==2014

	compress

	by spanel ssuid epppnum: gen diff = ebmnth != ebmnth[_n-1] | tbyear != tbyear[_n-1] if [_n]>1

	by spanel ssuid epppnum: gen last_ebmnth = ebmnth[_n-1]
	tab ebmnth last_ebmnth, col nofreq
	* seems okay - 99% of obs are consistent, except 2% in 06/07
	tab year diff, mi row nof

	//fix to find longitudinal age
	tab year abmnth, mi

	gen birth_mon =  ym(tbyear,ebmnth) if abyear!=1 & abmnth!=1
	format birth_mon %tm

	gcollapse (count) rhcalmn (min) date, by(birth_mon spanel ssuid epppnum)

	drop if mi(birth_mon)

	ren rhcalmn freq
	sort spanel ssuid epppnum freq date

	by spanel ssuid epppnum: egen f = max(freq)
	keep if f==freq //mode

	duplicates tag spanel ssuid epppnum, gen(p)
	tab p
	by spanel ssuid epppnum: gen md = _n==1
	keep if md==1

	save $main/ctcPaper/agelink.dta, replace
}

****************************
*****Create Analysis Files *
****************************

*income values for gross income test, from TRIM3 program rules and IRS instructions pre-94 (Chart B and exemption instructions)
//note pre-1989 rules were that a child could be any age and claimed w/o income test if a student; ignore this
//disabled child exception from test is only for 2005+; will ignore
if 1==1 { //wrapper for code folding
	#delimit ;
	/* Year	Value */ 
	matrix input depinc = (
	2016	4050 \
	2015	4000 \
	2014	3950 \
	2013	3900 \
	2012	3800 \
	2011	3700 \
	2010	3650 \
	2009	3650 \
	2008	3500 \
	2007	3400 \
	2006	3300 \
	2005	3200 \
	2004	3100 \
	2003	3050 \
	2002	3000 \
	2001	2900 \ 
	2000	2800 \
	1999	2750 \ 
	1998	2700 \
	1997	2650 \
	1996	2550 \
	1995	2500 \
	1994	2450 \
	1993	2350 \
	1992	2300 \
	1991	2150 \
	1990	2050 \
	1989	2000 \
	1988	1950 \
	1987	1900 \
	1986	1080 \
	1985	1040 \
	1984	1000 );
	#delimit cr ;
}

**make analysis files
cap log close _all
log using $main/ctcPaper/make_analysis.log, text name(make_analysis) replace
timer clear 1
forval year = 1984/2016 {
	clear frames
	*loc year  2016 //uncomment to run specific years

	loc y = substr("`year'",-2,2)
	timer on 1

	if `year' == 2000 {
		use $main/ctcPaper/spd_2000, clear 
		gen byte spd = 1
	}
	else {
		use $main/ctcPaper/cy`y'.dta, clear

		*keep last month info
		bys ssuid epppnum: egen max_month = max(rhcalmn)
		keep if rhcalmn==max_month

		//annualize partial year values 
		// this assumes average income in missing months is equal to average when observed
		foreach var in pearn dividends intrec nonprop otherprop pensions gssi totalinc {
			replace `var' = `var' * 12 / months_obs
		}

		//add in SPD
		if inrange(`year',1996,2001) {
			//add identifying notes
			foreach var of varlist lgtkey-lgtwt {
				notes `var': ****Start SPD for `year'****
			}
			append using $main/ctcPaper/spd_`year', gen(spd) 
			drop if spd==1 & wpfinwgt==0 //only count positive weights
			//split weights
			ren wpfinwgt wpfinwgt_orig
			gen double wpfinwgt = wpfinwgt_orig
			count if spd==1  
			loc r1 = `r(N)'
			count if spd==0
			loc r2 = `r(N)'
			loc wtmod = `r1' / (`r1'+`r2')
			di "Wt of SPD in `year' = `wtmod'"
			replace wpfinwgt = wpfinwgt_orig * `wtmod' if spd==1
			replace wpfinwgt = wpfinwgt_orig * (1-`wtmod') if spd==0
		}

	}

	**get parental earnings
	egen temp_agi = rowtotal(pearn dividends intrec nonprop otherprop pensions gssi ) //note includes all SocSec, not just taxable

	foreach var in mom dad guard {
	replace epn`var'=9999 if epn`var'==. | epn`var'==-1 
	frame put ssuid epppnum pearn educ tage race mar shhadid temp_agi totalinc, into(frame_`var')
	frlink m:1 ssuid epn`var', frame(frame_`var' ssuid epppnum) 
	frget pearn educ tage race mar shhadid temp_agi totalinc, from(frame_`var') prefix(`var'_)
	}

	*parental earnings
	egen parearn = rowtotal(mom_pearn dad_pearn)
	replace parearn = guard_pearn if epnmom==9999 & epndad==9999 & !inlist(epnguard,-1,9999) //guardian earnings

	egen parinc = rowtotal(mom_totalinc dad_totalinc)

	*get ages in months relative to dec 31 of year
	gen birthdate = date(string(tbyear,"%04.0f")+string(ebmnth,"%02.0f"), "YM") //sets to 1st day of month
	gen birthmonth = mofd(birthdate)
	format birthdate %td
	format birthmonth  %tm
	//use corrected ages
	merge 1:1 spanel ssuid epppnum using $main/ctcPaper/agelink.dta, keep(1 3) keepusing(birth_mon)
	replace birthmonth = birth_mon if !mi(birth_mon) //if missing modal value, use survey value for tax computation

	* RD running variable
	gen agem = mofd(date("31dec`year'","DMY")) - birthmonth - 17*12

	ren tage tage_old 
	gen tage = floor((agem + 17*12)/12) //make age consistent with birth month based calculation

	gen searn = fearn - pearn //earnings of family excluding self

	gen hasearn = fearn!=0 & !mi(fearn) //count negatives as having earnings
	gen haspearn = parearn!=0 & !mi(parearn) 
	gen hassearn = searn!=0 & !mi(searn) 

	lab var hassearn "Earnings in Family"
	lab var haspearn "Earnings for Parents"

	gen livespar = inlist(shhadid,mom_shhadid,dad_shhadid,guard_shhadid)


	*preliminary tax vars
	gen disabled = edisabl

	*convert dependent gross income levels from matrix to variable
	//method from http://www.stata.com/statalist/archive/2014-01/msg00870.html
	local imax=rowsof(depinc)
	gen maxdepinc = .
	forv i=1/`imax' {
		quietly replace maxdepinc = depinc[`i',2] if `year'==depinc[`i',1]
	}

	gen dep = (tage<19 | (renroll==1 & inrange(tage,19,23)) ) & (mar!=2)
	//assume only children and students count as dependents; 
	//no "qualifying relatives" or disabled children (in 2005+)
	//ignore lack of age 24 cutoff for students pre-89
	//assume married won't file as dependents

	*clean up variables
	foreach var in hmsa wicval pwsuid pwentry pwpnum t01amta t01amtk t05amt t25amt t27amt t29amt t30amt t31amt t32amt t34amt t35amt j110 o110 j110ri o110ri t39amt t42amt t37amt t53amt t54amt t02amt t36amt t38amt t52amt t55amt t50amt tdivinc tintinc esex birthdate birthmonth h_year year  {
		cap drop `var'
	}
	if `year'>=2013 {
		drop tjsmfinc-tostinc ttrinc tinc_bank tinc_bond elmpnow-tret7amt eminc_typ1yn-tminc_amt rrel*
	}
	compress

	save $main/ctcPaper/rd_`y'.dta, replace
	timer off 1
	timer list
}
log close make_analysis



*delete temporary files
cd "$main/ctcPaper"
forval year = 1984/2016 {
	*loc year = 2016 //uncomment to run specific years
	loc y = substr("`year'",-2,2)
	cap erase cy`y'.dta
	cap erase spd_`year'.dta
}
cap erase cy13a.dta
cap erase cy13b.dta
cap erase jb13b.dta
cap erase jb14.dta
cap erase jb15.dta
cap erase jb16.dta


