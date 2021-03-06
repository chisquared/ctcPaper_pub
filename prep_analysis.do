** Prepare analysis files for CTC paper

version 16
loc rmdir "rm -r"
if c(os)=="Windows" loc rmdir "rmdir /S" 

cd "$main/core"

***************************
****Taxsim calculations****
***************************

cap log close _all
log using $main/ctcPaper/taxsim_extract.log, text name(taxsim_extract) replace
timer clear

*generate taxsim extract file for each year
//variables based on http://users.nber.org/~taxsim/to-taxsim/sipp/sipp2taxsim.pdf
//note that most tax module variables are available in limited years, poor quality, and in ranges--so using other variables where possible
loc gen_tms = 1 //set to 1 if recreating topical modules with tax vars for 1980s
// note: 1980s directory must be unzipped to allow this
if `gen_tms'==1 {
    loc archive "84-89"
    cap confirm file "$main/core/sippArchive`archive'/"
    if _rc!=0 {
            cap mkdir sippArchive`archive'
            cd sippArchive`archive'
            unzipfile "../sippArchive`archive'.zip" 
            cd "$main/core"
    }
}
forval year = 1984/2016 {
	timer on 1

	*loc year  1988 //uncomment to run specific years
	set more off
	clear frames


	//wrapper for year parameters
	if 1==1 {
		loc houstm //nothing for 89, 00, 06, 07, 08 or 12
		loc taxtm
		loc houstm2
		loc taxtm2

		//in 1980s, census docs suggest there are tax TMs, but appear not to be on files--perhaps b/c of budget cuts
		//or: http://nber.org/sipp/1984/sipp84rt9.pdf suggests tax files were restricted use
		//note that child care expenses may be available from child care module (tm8050)--but leaving out for consistency (code in v35)
		if "`year'"=="1984" {
		loc houstm 4
		//loc taxtm 6 //assets for 95 in next year
		}
		if "`year'"=="1985" {
		loc houstm 3
		//loc taxtm 5
		loc houstm2 7
		//loc taxtm2 9 
		}
		if "`year'"=="1986" {
		loc houstm 4
		//loc taxtm 5
		loc houstm2 7
		//loc taxtm2 8
		}
		if inlist(`year',1987,1988) {
		loc houstm 4
		//loc taxtm 5
		loc houstm2 7
		}
		if inlist(`year',1990,1991,1992,1993) { 
		loc houstm 4 //90, 92: no med or child care
		loc taxtm 5 //91: limited tax module available
		}
		if inlist(`year',1991,1992,1993) { 
		loc houstm2 7
		loc taxtm2 8 //91: limited 1990 tax module available
		}
		if inlist(`year',1996,2001,2004) {
		loc houstm 3
		loc taxtm 4
		}
		if inlist(`year',1997,2002,2005) {
		loc houstm 6
		loc taxtm 7
		}
		if "`year'"=="1994" {
		loc houstm 7 
		loc taxtm 8
		}
		if "`year'"=="1998" {
		loc houstm 9
		loc taxtm 10
		}
		if "`year'"=="1999" {
		loc houstm 12
		}
		if "`year'"=="2003" {
		loc houstm 9
		}
		if "`year'"=="2009" {
		loc houstm 4
		loc taxtm 5
		}
		if "`year'"=="2010" {
		loc houstm 7
		loc taxtm 8
		}
		if "`year'"=="2011" {
		loc houstm 10
		}
		if inrange(`year',2013,2016) { 
		//note year 2013 for 2008 panel has no TMs: https://www.census.gov/programs-surveys/sipp/tech-documentation/topical-modules/topical-modules-2008.html
		loc houstm 0 //variables on original file
		loc taxtm 0 //variables on original file
		}

		//panel values
		loc panel2
		loc mergevals "ssuid epppnum"
		if inrange(`year',1984,1989) {
		loc panel = substr("`year'",-2,2)
		loc mergevals "su_id pp_entry pp_pnum"
		if inrange(`year',1985,1989) {
		loc panel2 = `panel'-1
		}
		}
		if inrange(`year',1990,1993) {
		loc panel = substr("`year'",-2,2)
		loc mergevals "id entry pnum" 
		}
		if inrange(`year',1991,1993) {
		loc panel2 = `panel'-1
		}
		if inrange(`year',1994,1995) {
		loc panel "93"
		loc mergevals "id entry pnum" 
		}
		if inrange(`year',1996,1999) {
		loc panel "96"
		}
		if `year'==2000 loc panel "00"
		if inrange(`year',2001,2003) {
		loc panel "01"
		}
		if inrange(`year',2004,2007) {
		loc panel "04"
		}
		if inrange(`year',2008,2012) {
		loc panel "08"
		}
		if inrange(`year',2013,2016) {
		loc panel "14"
		}
	}	

	loc y = substr("`year'",-2,2)


	use $main/ctcPaper/rd_`y', clear
	drop _merge

	*compute number of CTC kids and dependents	
	frame copy default temp_kids
	frame temp_kids {
	
	gen dependents = dep & livespar==1 //only counts qualifying children
	gen ctc_kids = tage<17 & (mar!=2) & livespar==1
	gen dep13 = tage<13 & (mar!=2) & livespar==1
	gen dep18 = tage<18 & (mar!=2) & livespar==1
	
	keep if ctc_kids==1 | dependents ==1
	
	*get medical information for each child
	if "`houstm'"=="" | inlist(`year',1984,1985,1986,1987,1989,1990,1992,2000) gen medexp = .
	else {
		if `year'==1988 {
			gen double old_id = su_id
			replace su_id = . if spanel!=`year'
			if `gen_tms'==1 {
				preserve
				loc vals "tm8410"
				use `mergevals' `vals' using "$main/core/sippArchive84-89/sipp`panel'_core`houstm'", clear
				save $main/ctcPaper/sipp`panel'_tm`houstm', replace
				use `mergevals' `vals' using "$main/core/sippArchive84-89/sipp`panel2'_core`houstm2'", clear
				save $main/ctcPaper/sipp`panel2'_tm`houstm2', replace
				restore
			}
			merge m:1 `mergevals' using "$main/ctcPaper/sipp`panel'_tm`houstm'", keepusing(tm8410) keep(1 3) nogen 
			drop su_id
			gen double su_id = old_id if spanel==`year'-1
			merge m:1 `mergevals' using "$main/ctcPaper/sipp`panel2'_tm`houstm2'", keepusing(tm8410) keep(1 3) nogen 
			replace su_id = old_id
			gen trmoops = tm8410 * 12 //annualized
		}
		else if inrange(`year',1990,1995) & !inlist(`year',1990,1992) {
			gen double id = suid if spanel==`year'
			merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(tm8410) keep(1 3) nogen 
			if "`houstm2'"!="" { 
				drop id
				gen double id = suid if spanel==`year'-1
				merge m:1 `mergevals' using "$main/topical/sipp`panel2'_tm`houstm2'", keepusing(tm8410) update keep(1 3 4 5) nogen nolabel
			}
			gen trmoops = tm8410 * 12 //annualized
		}
		else if inrange(`year',1996,2012) {
			merge 1:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(trmoops) keep(1 3) nogen 
			//unclear if HI included for kids in 2004-2012, or only for adults
		}
		else if inrange(`year',2013,2016) {
			gen trmoops = tmdpay //see notes on this below - don't include HI for kids
		}
		gen medexp = max(0,trmoops)
	}
	
	//save $main/ctcPaper/temp_kids, replace
	}
	
	*assign kids to guardians when possible
	/* note guardians are generally moms, then dads, then other adults,
	*according to http://www.census.gov/population/www/socdemo/files/FatherInv.pdf
	count if epnguard!=epnmom & epnmom!=9999 & epnguard!=-1
	*/
	foreach var in guard {
	frame copy temp_kids dep_`var'
	frame dep_`var' {
		keep if !inlist(epnguard,-1,9999)
		drop if mi(epn`var') 
		gcollapse (sum) dep_`var' = dependents ctc_`var' = ctc_kids dep13_`var' = dep13 dep18_`var' = dep18 med_`var' = medexp , by(ssuid epn`var')
		ren epn`var' epppnum
	}
	}
	
	*special process for children over 19--assign to moms first, then dads (students who don't live with parents will not be counted as dependents)
	//pre 96, only one parent; in 2013+, "parent 1" is assigned to guardian if available, so never have dad but no guardian
	foreach var in mom dad {
		frame copy temp_kids dep_`var'
		frame dep_`var' {
			keep if inlist(epnguard,-1,9999)
			if "`var'"=="dad" keep if epnmom==9999
			drop if mi(epn`var') | (epn`var')==9999
			qui count
			if r(N)>0 {
				sort ssuid epn`var' epppnum
				by ssuid epn`var': egen max_kid_agi = max(temp_agi)
				gen maxid = epppnum if max_kid_agi==temp_agi
				by ssuid epn`var': egen max_kid_agi_id = min(maxid)
				collapse (sum) dep_`var' = dependents ctc_`var' = ctc_kids dep13_`var' = dep13 dep18_`var' = dep18 med_`var' = medexp (max) max_kid_agi max_kid_agi_id , by(ssuid epn`var')
				ren epn`var' epppnum
			}
			else {
				set obs 1 //make nearly empty data
				keep ssuid epppnum
				foreach var in dep_`var' ctc_`var' dep13_`var'  dep18_`var'  med_`var'  max_kid_agi max_kid_agi_id {
				gen `var'=.
				} 
			} 
		}
	}
	//filing with mother is a simplification--could look at more complex options later
	foreach var in guard mom dad {
		frlink 1:1 ssuid epppnum , frame(dep_`var') gen(fr_`var')
		frget *_`var', from(fr_`var')
	}
	
	*compute parental dependents 
	
	*get income of kids (who are not under 18, i.e., don't have guardians) 
	frame put ssuid epppnum fr_mom fr_dad temp_agi ems maxdepinc, into(dep_par)
	frame dep_par {
		frget max_kid_*, from(fr_mom) prefix(mom_)
		frget max_kid_*, from(fr_dad) prefix(dad_)
		egen max_kid_agi = rowmax(mom_max_kid_agi dad_max_kid_agi)
		gen max_kid_agi_id = mom_max_kid_agi_id
		replace max_kid_agi_id = dad_max_kid_agi_id if mi(max_kid_agi_id)
		
		gen kids_higher_inc = max_kid_agi>temp_agi & !mi(max_kid_agi) & ems!=1 //assume married parents are never dependents 
		
		gen parent_dep = (kids_higher_inc==1) & inrange(temp_agi,0,maxdepinc) //only claim parents if meet income test
		frame copy dep_par par_deps 
		keep if parent_dep==1
		keep parent_dep max_kid_agi_id ssuid
		ren max_kid_agi_id epppnum
		ren parent_dep dep_par
		qui count
		if r(N)>0 collapse (sum) dep_par, by(ssuid epppnum) //make blank file if no dependents
	}
	frlink 1:1 ssuid epppnum , frame(dep_par) gen(dp)
	frget dep_par, from(dp)
	frlink 1:1 ssuid epppnum , frame(par_deps) 
	frget parent_dep, from(par_deps)
	
	egen dependents = rowtotal(dep_guard dep_mom dep_dad dep_par)
	egen ctc_kids = rowtotal(ctc_guard ctc_mom ctc_dad)
	egen dep13 = rowtotal(dep13_guard dep13_mom dep13_dad)
	egen dep18 = rowtotal(dep18_guard dep18_mom dep18_dad)

	*tax info
	if "`taxtm'"=="" {
		foreach var in tfilstat ttotexmp tatkeogh ttaxbill tamtdedt tccamt tsapgain {
			gen `var' = .
		}
		loc rt t
	}
	else {
		if inrange(`year',1984,1989) {
		/* no tax TMs available in 80s */
		}
		else if inrange(`year',1990,1995) {
			if `year'==1991 {
				cap drop id //fewer tax variables available in 1991
				gen double id = suid if spanel==`year'
				merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`taxtm'", keepusing(tm9396 tm9398 tm9498) keep(1 3) nogen 
					if "`taxtm2'"!="" { 
						cap drop id
						gen double id = suid if spanel==`year'-1
						merge m:1 `mergevals' using "$main/topical/sipp`panel2'_tm`taxtm2'", keepusing(tm9396 tm9398 tm9498) update keep(1 3 4 5) nogen nolabel
					}
				rename (tm9396 tm9398 tm9498) (tfilstat ttotexmp ttaxbill)
				foreach var in tamtdedt tccamt tsapgain tatkeogh tadjincm tnettax terndamt {
					gen `var' = .
				}
			}
			else {
				cap drop id
				gen double id = suid if spanel==`year'
				merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`taxtm'", keepusing(tm9396 tm9398 tm9434 tm9448 tm9460 tm9364 tm9462 tm9464 tm9474 tm9498) keep(1 3) nogen 
					if "`taxtm2'"!="" { 
						cap drop id
						gen double id = suid if spanel==`year'-1
						merge m:1 `mergevals' using "$main/topical/sipp`panel2'_tm`taxtm2'", keepusing(tm9396 tm9398 tm9434 tm9448 tm9460 tm9364 tm9462 tm9464 tm9474 tm9498) update keep(1 3 4 5) nogen nolabel
					}
				rename (tm9396 tm9398 tm9434 tm9448 tm9460 tm9364 tm9462 tm9464 tm9474 tm9498) (tfilstat ttotexmp tamtdedt tccamt tsapgain tatkeogh tadjincm tnettax terndamt ttaxbill)
			}
		}
		else if inrange(`year',1996,2012) {
			if "`year'"=="1996" loc rt r //set prefix
			else loc rt t 
			merge 1:1 `mergevals' using "$main/topical/sipp`panel'_tm`taxtm'", keepusing(`rt'filstat `rt'totexmp tatkeogh `rt'taxbill `rt'amtdedt `rt'ccamt `rt'sapgain `rt'adjincm `rt'nettax `rt'erndamt) keep(1 3) nogen 
			if "`year'"=="1996" {
				foreach var in filstat totexmp taxbill amtdedt ccamt sapgain adjincm nettax erndamt {
					ren r`var' t`var'
				}
			}
		}
		else if inrange(`year',2013,2016) {
			foreach var in  ttotexmp tatkeogh ttaxbill tamtdedt tccamt tsapgain {
				gen `var' = .
			}
			/* have variable EDEPCLM, but doesn't give exemptions, b/c only available for age 15-25) */
			//know keogh value, but not amount withdrawn
			//no property txes or deductions, child care credit or capital gains
			rename (efstatus ) (tfilstat )
		}
	}
	//note: for tccamt tamtdedt tadjincm tnettax terndamt--all are coded in ranges, but codes vary across years

	*identify primary taxpayer (first listed in roster among spouses)
	gen primarytaxpayer = (epnspous > epppnum) //all ppl who are not second listed spouses  
	replace primarytaxpayer = 0 if ((dep==1 & livespar==1) | parent_dep==1)  & temp_agi==0 //assume dependents w/o income don't file
	 
	*values for primary taxpayer	
	gen pwages = pearn if primarytaxpayer==1
	*spouse earnings
	frame put ssuid epnspous pearn temp_agi tage, into(spouse)
	frame spouse {
		keep if epnspous!=9999
		ren epnspous epppnum
		ren pearn spouseearn
		ren temp_agi spouse_agi
		ren tage spouse_age
		duplicates tag ssuid epppnum, gen(dup)
		drop if dup>0 //remove duplicates--appears to only be a problem in pre-96
		drop dup
	}
	frlink 1:1 ssuid epppnum , frame(spouse) 
	frget spouseearn spouse_agi spouse_age, from(spouse)
	gen swages = spouseearn if primarytaxpayer==1
	gen mstat = (ems==1) + 1 if primarytaxpayer==1
	replace mstat = 3 if epnspous==9999 & dependents>0 & primarytaxpayer==1 //all unmarried w/ dep are Heads of Household
	replace mstat = 8 if ((dep==1 & livespar==1) | parent_dep==1) & primarytaxpayer==1 //dependent filers
	//assume no one files separately (mstat = 6)
	gen head_hh = mstat==3
	replace mstat = 1 if mstat==3 //switch from taxsim9 to taxsim27 coding
	gen page = tage if primarytaxpayer==1
	gen sage = spouse_age if primarytaxpayer==1
	replace sage = 0 if mstat!=2
	
	*map fips codes to taxsim state codes
	gen statefips = tfipsst if primarytaxpayer==1 & tfipsst<=56
	merge m:1 statefips using $main/ctcPaper/taxsim_crosswalk, keep(1 3) nogen keepusing(taxsim_state)
	gen state = taxsim_state
	replace state = 0 if tfipsst>56 //will not compute state tax for states with combined codes
	forv i = 1/1 { //wrapper for code folding
	#delimit ;
	lab def state
		1   Alabama
        2	Alaska
        3	Arizona 
        4	Arkansas
		5	California
		6	Colorado 
		7	Connecticut
		8	Delaware 
        9	DC 
		10	Florida 
		11	Georgia 
		12	Hawaii 
		13  Idaho 
		14	Illinois 
		15	Indiana 
		16  Iowa 
		17	Kansas 
		18	Kentucky
		19	Louisiana
		20  Maine 
		21 	Maryland 
		22	Massachusetts
		23	Michigan 
		24	Minnesota
		25	Mississippi
		26	Missouri 
		27	Montana 
		28	Nebraska
        29	Nevada 
		30	"New Hampshire"
		31	"New Jersey" 
		32	"New Mexico" 
		33	"New York"
		34	"North Carolina" 
		35	"North Dakota" 
        36  Ohio 
		37	Oklahoma 
        38	Oregon 
		39	Pennsylvania 
		40	"Rhode Island" 
		41	"South Carolina" 
		42	"South Dakota"
		43	Tennessee
        44	Texas 
        45	Utah 
		46	Vermont 
		47	Virginia 
		48	Washington 
		49	"West Virginia" 
		50	Wisconsin 
		51	Wyoming, modify ;
	#delimit cr ;
	}
	lab val state state
	
	
	*aged exemptions
	gen agex = (tage>=65)
	
	*property tax (using midpoints of distributions; note many misisng values, treated as 0
	if `year'<1996 recode ttaxbill (-2/0=0) (1=50) (2=150) (3=250) (4=350) (5=450) (6=550) (7=650) (8=750) (9=850) (10=950) (11=1050) (12=1150) (13=1250) (14=1400) (15=1650) (16=1950) (17=2100) , gen(proptax) //issues with 91tm8 and 92tm5--but likely typos
	if "`year'"=="1996" recode ttaxbill (-2/0=0) (1=50) (2=150) (3=250) (4=350) (5=450) (6=550) (7=650) (8=750) (9=850) (10=950) (11=1050) (12=1150) (13=1250) (14=1400) (15=1650) (16=1950) (17=2250) (18=2500) (19=2800) (20=4000) (21=5000) , gen(proptax)
	else if "`panel'"=="96" recode ttaxbill (-2/0=0) (1=50) (2=150) (3=250) (4=350) (5=450) (6=550) (7=650) (8=750) (9=850) (10=950) (11=1100) (12=1250) (13=1400) (14=1650) (15=1950) (16=2250) (17=2500) (18=2800) (19=4000) (20=5000) , gen(proptax)
	if "`panel'"=="01" recode ttaxbill (-2/0=0) (1=50) (2=150) (3=250) (4=350) (5=450) (6=550) (7=650) (8=750) (9=850) (10=950) (11=1100) (12=1250) (13=1400) (14=1600) (15=1800) (16=1950) (17=2150) (18=2400) (19=3650) (20=2900) (21=3250) (22=3750) (23=4500) (24=5000), gen(proptax)
	if "`panel'"=="04" recode ttaxbill (-2/0=0) (1=100) (2=300) (3=450) (4=600) (5=800) (6=1050) (7=1300) (8=1550) (9=1800) (10=2050) (11=2400) (12=2800) (13=3500) (14=4500) (15=5000)  , gen(proptax)
	if "`panel'"=="08" recode ttaxbill (-2/0=0) (1=100) (2=300) (3=500) (4=700) (5=900) (6=1100) (7=1300) (8=1550) (9=1800) (10=2050) (11=2400) (12=2800) (13=3500) (14=4500) (15=6000) (16=7000) , gen(proptax)
	//property tax variable appears to be defined for one person per tax unit
	if "`panel'"=="14" gen proptax=0
	if `year'==2000 gen proptax = ptxamtt
	else if inrange(`year',1998,2001) { //spd fixes
		replace proptax = ptxamtt if spd==1
	}

	
	*compute capital gains as midpoints of distribution; assume all capital gains are long-term
	//note $3000 loss limitation has applied since the 70s: http://wanderingtaxpro.blogspot.com/2013/07/deducting-capital-losses.html
	if `year'<1996 recode tsapgain (-4 15=-3000) (-3/0=0) (1=50) (2=150) (3=250) (4=400) (5=600) (6=850) (7=1150) (8=1650) (9=2500) (10=3500) (11=5000) (12=8000) (13=12500) (14=15000), gen(ltcg) 
	if "`panel'"=="96" recode tsapgain (-4=-3000) (-3/0=0) (1=50) (2=150) (3=250) (4=400) (5=600) (6=850) (7=1150) (8=1650) (9=2500) (10=3500) (11=5000) (12=8000) (13=12500) (14=15000), gen(ltcg) 
	if "`panel'"=="01" recode tsapgain (-4=-3000) (-3/0=0) (1=50) (2=150) (3=250) (4=400) (5=600) (6=850) (7=1150) (8=1650) (9=2500) (10=3500) (11=5000) (12=8000) (13=12500) (14=15000), gen(ltcg) 
	if "`panel'"=="04" recode tsapgain (-4=-3000) (-3/0=0) (1=50) (2=150) (3=250) (4=400) (5=600) (6=850) (7=1250) (8=1750) (9=2500) (10=3500) (11=5000) (12=8000) (13=15000) (14=20000), gen(ltcg) 
	if "`panel'"=="08" recode tsapgain (-4=-3000) (-3/0=0) (1=50) (2=550) (3=4000) (4=7000), gen(ltcg) 
	if "`panel'"=="14" gen ltcg=0
	if `year'==2000 gen ltcg=0
	gen stcg = 0
	
	*other property/childcare/asset variables from topical modules
	if "`houstm'"=="" {
		foreach var in thomeamt tmor1pr emor1int tcarecst trmoops  thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq {
			gen `var' = .
		}
	}
	else {
		if inrange(`year',1984,1989) {
			loc assetlist ""
			if `year'==1988 loc vals tm8410 tm8538 tm8564
			if `year'==1984 {
				loc vals tm8564 tm8580 tm8606
				loc assetlist "hhtnw hhtwlth hhdebt hhscdbt hhusdbt hhtheq"
				}	
			if inlist(`year',1985,1986,1987) {
				loc vals tm8564 tm8580
				loc assetlist "hh_tnw hh_twlth hh_debt hh_scdbt hh_usdbt hh_theq"
				}
			if `year'==1985 loc ast2 "hhtnw hhtwlth hhdebt hhscdbt hhusdbt hhtheq" //only in first TM
			else loc ast2 "`assetlist'"
			
			gen double old_id = su_id
			replace su_id = . if spanel!=`year'
			if `gen_tms'==1 {
				preserve
				use `mergevals' `vals' `assetlist' using "$main/core/sippArchive84-89/sipp`panel'_core`houstm'", clear
				save $main/ctcPaper/sipp`panel'_tm`houstm', replace
				if "`houstm2'"!="" { 
					use `mergevals' `vals' `ast2' using "$main/core/sippArchive84-89/sipp`panel2'_core`houstm2'", clear
					if `year'==1985 ren (`ast2') (`assetlist')
					save $main/ctcPaper/sipp`panel2'_tm`houstm2', replace
					}
				restore
			}
			merge m:1 `mergevals' using $main/ctcPaper/sipp`panel'_tm`houstm',  keep(1 3) nogen 
			if "`houstm2'"!="" { 
				drop su_id
				gen double su_id = old_id if spanel==`year'-1
				merge m:1 `mergevals' using $main/ctcPaper/sipp`panel2'_tm`houstm2',  keep(1 3) nogen 
			}
			replace su_id = old_id
			if `year'==1988 {
				gen trmoops = tm8410 * 12 //annualized
				rename (tm8538 tm8564) (thomeamt tcarecst)
				recode thomeamt (-3/-1=0)
				foreach var in tmor1pr emor1int thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq {
						gen `var'=.
				}
			}
			else if inlist(`year',1984,1985,1986,1987) {
				ren (tm8564 tm8580 `assetlist') (tmor1pr emor1int thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq )
				gen thomeamt = .
				gen tcarecst = .
				gen trmoops = .
			}
			if `year'==1984 {
				drop proptax
				recode tm8606 (-3/0=0) (1=50) (2=150) (3=250) (4=350) (5=450) (6=550) (7=650) (8=750) (9=850) (10=950) (11=1050) (12=1150) (13=1250) (14=1400) (15=1650) (16=1950) (17=2100) , gen(proptax) 
			}
			*get extra 1987 values
			if `year'==1987 {
				replace su_id = . if spanel!=`year'
				if `gen_tms'==1 {
					preserve
					use `mergevals' tm8412 tm8418 using "$main/core/sippArchive84-89/sipp`panel'_core3", clear
					save $main/ctcPaper/sipp`panel'_tm3, replace
					use `mergevals' tm8412 tm8418 using "$main/core/sippArchive84-89/sipp`panel2'_core6", clear
					save $main/ctcPaper/sipp`panel2'_tm6, replace
					restore
				}
				merge m:1 `mergevals' using $main/ctcPaper/sipp`panel'_tm3, keepusing(tm8412 tm8418) keep(1 3) nogen 
				drop su_id
				gen double su_id = old_id if spanel==`year'-1
				merge m:1 `mergevals' using $main/ctcPaper/sipp`panel2'_tm6, keepusing(tm8412 tm8418) keep(1 3) nogen 
				drop thomeamt
				gen thomeamt = tm8418
				drop proptax
				recode tm8412 -3=0, gen(proptax)
				replace su_id = old_id
			}
		}
		else if inrange(`year',1990,1995) {
			cap drop id
			gen double id = suid if spanel==`year'
			if inlist(`year',1994) {
				merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(tm8638 tm8564 tm8580 tm8657 hh_tnw hh_twlth hh_debt hh_scdbt hh_usdbt hh_theq) keep(1 3) nogen 
				ren (tm8638 tm8564 tm8580 tm8657 hh_tnw hh_twlth hh_debt hh_scdbt hh_usdbt hh_theq) (thomeamt tmor1pr emor1int tcarecst thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq)
				recode thomeamt (-3/-1=0)
			}
			if inlist(`year',1991,1993) { 
				merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(tm8538 tm8564) keep(1 3) nogen 
				if "`houstm2'"!="" { 
					cap drop id
					gen double id = suid if spanel==`year'-1
					merge m:1 `mergevals' using "$main/topical/sipp`panel2'_tm`houstm2'", keepusing(tm8538 tm8564) update keep(1 3 4 5) nogen nolabel
				}
				ren (tm8538 tm8564) (thomeamt tcarecst)
				foreach var in tmor1pr emor1int thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq {
						gen `var'=.
				}
				recode thomeamt (-3/-1=0)
			}
			if inlist(`year',1990,1992) {
				merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(tm8564 tm8580 hhtnw hhtwlth hhdebt hhscdbt hhusdbt hhtheq ) keep(1 3) nogen 
				if "`houstm2'"!="" { 
					cap drop id
					gen double id = suid if spanel==`year'-1
					merge m:1 `mergevals' using "$main/topical/sipp`panel2'_tm`houstm2'", keepusing(tm8564 tm8580 hhtnw hhtwlth hhdebt hhscdbt hhusdbt hhtheq ) update keep(1 3 4 5) nogen nolabel
				}
				ren (tm8564 tm8580 hhtnw hhtwlth hhdebt hhscdbt hhusdbt hhtheq) (tmor1pr emor1int thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq)
				gen thomeamt = .
				gen tcarecst = .
			}
			//medical values for pre-96
			if !inlist(`year',1990,1992) {
				cap drop id
				gen double id = suid if spanel==`year'
				merge m:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(tm8410) keep(1 3) nogen 
				if "`houstm2'"!="" { 
					cap drop id
					gen double id = suid if spanel==`year'-1
					merge m:1 `mergevals' using "$main/topical/sipp`panel2'_tm`houstm2'", keepusing(tm8410) update keep(1 3 4 5) nogen nolabel
				}
				gen trmoops = tm8410 * 12 //annualized
			}
			else gen trmoops = .
		}
		else if inrange(`year',1996,2012) {
			if `year' < 1997 loc hipay ""
			else loc hipay "thipay"
			if `year'>=2010 loc rt "t"
			else loc rt "r"
			merge 1:1 `mergevals' using "$main/topical/sipp`panel'_tm`houstm'", keepusing(thomeamt tmor1pr emor1int tcarecst trmoops `hipay' thhtnw thhtwlth thhdebt thhscdbt `rt'hhuscbt thhtheq) keep(1 3) nogen 
			if `year' >= 2004 {
				gen trmoops_orig = trmoops
				replace trmoops = trmoops+thipay //add health insurance premiums in 2004-2008 panels, when excluded from trmoops (included in 2001 and before)
				//don't add to trmoops for children, because only reported for respondent
			}
			if `year'<2010 ren rhhuscbt thhuscbt
		}
		else if inrange(`year',2013,2016) {
			rename (trentmort eprloan1rate tprloanamt) (thomeamt emor1int tmor1pr)
			//note tprloanamt includes all 3 mortgages, not just 1st (but same for tmor1pr)
			//trentmort is for december (thomeamt was for last month of TM)
			gen tcarecst = 4.333 * tpaywk //only weekly value available - make monthly
			gen trmoops = tmdpay + thipay //not no reimbursement variable present--assume all expenses are unreimbursed. Var appears to be for 12 months
		} 
	}
	
		egen kids_med = rowtotal(med_guard med_mom med_dad)
		gen medexp = max(0,trmoops) + kids_med	

		*note these variables are at household level--give value to reference person only
		gen rentpaid = 0
		replace rentpaid = thomeamt * 12 if etenure==2 & inlist(errp,1,2) //annualized 
	
		gen childcare = 0 
		replace childcare = tcarecst * 12 if inlist(errp,1,2) //annualized
	
		gen mortgage = 0
		replace mortgage = tmor1pr * (emor1int / (100*100)) if inlist(errp,1,2) //assumes all interest paid on principal; two implied decimals in most years
		replace mortgage = mortgage / 10 if inlist(spanel,2004,2008) //three implied decimals for these panels	
		replace mortgage = mortgage*(100) if inlist(spanel,2014) //no implied decimals for this panel

	gen otheritem = 0 //assumes no charitable contributions or other deductions
	

	*make tax units
	egen tax_num = rowmin(epppnum epnspous)
	quietly compress
	

	*add monthly earnings information
	if `year'!=2000 {
		merge 1:1 ssuid epppnum using $main/ctcPaper/famearn_months`y', keepusing(tpearn* rmesr*) nogen keep(1 3)  
		
		if "`y'"=="08" loc start 5
		else loc start 1
		forv i = `start'/12 {
			rename tpearn`i' tax_pearn`i'
			gen tax_worked`i' = inrange(rmesr`i',1,5)
			rename rmesr`i' tax_rmesr`i'
		}
	}
	else {
		forval i = 1/12 {
			gen tax_pearn`i' = .
			gen tax_worked`i' = .
			gen tax_rmesr`i' = .
		}
	}
	
	compress
	save $main/ctcPaper/taxsim_full_`y', replace
	timer list

	use $main/ctcPaper/taxsim_full_`y', clear
	
	gcollapse (sum) state mstat depx = dependents agex page sage pwages swages dividends intrec nonprop otherprop pensions gssi transfers rentpaid proptax otheritem childcare ui depchild = ctc_kids dep13 dep18 mortgage ltcg stcg medexp temp_agi tax_pearn* tax_worked* head_hh, by(ssuid tax_num)	
	
	
	*final tax variables
	gen year = `year'
	order ssuid tax_num year state
	
	*impute deduction amounts as last year's amounts in years with no topical module (or pre96, when only asked in some years)
	if !inlist(`year',1996,2000,2001,2004,2008,2013,2014,2015,2016) {
		if "`houstm'"=="" | ("`taxtm'"=="" & !inrange(`year',1984,1989)) | (`year'<1996 & "`panel2'"!="") {
			di "Replacing deduction values..."
			//get cpis
			cpigen, replace
			ren cpiu t_cpiu
			replace year = year-1
			cpigen, replace
			ren cpiu tm1_cpiu
			replace year = year+1
			
			//merge on data and inflate
			loc last = `year'-1
			loc l = substr("`last'",-2,2)
			if "`houstm'"=="" | (`year'<1996 & "`panel2'"!="") {
				merge 1:1 ssuid tax_num using $main/ctcPaper/taxsim_extract_`l', keep(1 3 4 5) update replace nogen keepusing(medexp rentpaid childcare mortgage) 
				//inflate, but assume mortgage costs don't inflate
				foreach var in medexp rentpaid childcare {
					replace `var' = t_cpiu * `var'/ tm1_cpiu
				}
			}
			if "`taxtm'"=="" | (`year'<1996 & "`panel2'"!="") {
				merge 1:1 ssuid tax_num using $main/ctcPaper/taxsim_extract_`l', keep(1 3 4 5) update replace nogen keepusing(proptax ltcg stcg) 
				//don't inflate ordinal categories
				*foreach var in proptax ltcg stcg {
				*	replace `var' = t_cpiu * `var'/ tm1_cpiu			
				*}
			}
			drop cpi t_cpiu tm1_cpiu
		}
	}
	
	*add in medical deduction using AGI
	gen medical = 0
	replace medical = max(0,medexp-.075*temp_agi) if !mi(medexp)
			//method from http://users.nber.org/~taxsim/taxsim-calc9/medical_deduction.html
	replace otheritem = medical //medical is an AMT preference: http://amtadvisor.com/AMT_adjustments.html
	drop medical temp_agi 
	
	*floor wages at zero, to avoid a taxsim error
	gen pw_diff = min(pwages,0)
	gen sw_diff = min(swages,0)
	replace otherprop = otherprop + pw_diff + sw_diff //subtract business losses
	drop pw_diff sw_diff
	replace pwages = 0 if pwages<0
	replace swages = 0 if swages<0 
	replace swages = 0 if mstat!=2 //add same check as taxsim9 performed behind scenes
	
	replace ltcg = max(ltcg,-3000) //limit capital gains to -3000 per household
	
	*set deductions to zero if missing
	foreach var in rentpaid childcare mortgage proptax ltcg stcg otheritem {
		replace `var' = 0 if mi(`var')
	}
	
	ren depchild dep17 //taxsim27 name
	
	//add taxsim32 variables - just to run, none will change results
	foreach var in scorp pbusinc pprofinc sbusinc sprofinc {
		gen `var' = 0 
	}	

	save $main/ctcPaper/taxsim_extract_`y', replace
	timer off 1
	timer list

}
if `gen_tms'==1 {
    shell `rmdir' "sippArchive84-89/" 
}
log close taxsim_extract


*get the tax data with NBER calculator
log using $main/ctcPaper/get_taxsim.log, text name(get_taxsim) replace
timer clear
forval year = 1984/2016 { 
	*loc year  2005 //uncomment to run specific years
	timer on 1

	loc y = substr("`year'",-2,2)

	set more off

	cd "$main/ctcPaper"
	use taxsim_extract_`y', clear
	drop medexp tax_pearn* tax_worked*
	drop if mstat==0
	drop if page<0 | sage<0 //remove problem ages

	taxsimlocal32, full replace
	confirm var ssuid //check if merge worked or not

	save taxsim_results_`y', replace
	timer off 1
	timer list
	cd ..
}
log close get_taxsim

*get counterfactual tax data with one fewer CTC child
//note ignores possibility of twins
forval year = 2001 / 2016 {
	*loc year  2008 //uncomment to run specific years

	loc y = substr("`year'",-2,2)

	set more off

	cd "$main/ctcPaper"
	use taxsim_extract_`y', clear
	drop medexp tax_pearn* tax_worked*
	replace dep17 = dep17 - 1
	drop if dep17<0 //send fewer records
	replace dep13 = min(dep13,dep17)
	drop if mstat==0
	drop if page<0 | sage<0 //remove problem ages

	*keep in 1/1000 //use to test server
	taxsimlocal32, full replace 

	rename (fiitax siitax v25) (fiitax_alt siitax_alt eitc_alt)
	egen ctc_alt = rowtotal(v22 v23)
	save taxsim_depchild_`y', replace
		
	cd ..
}

*merge tax data back to original RD file
cap log close taxsim_prepare
log using $main/ctcPaper/taxsim_prepare.log, text name(taxsim_prepare) replace
timer clear
forval year = 1984/2016 {
	*loc year  2008 //uncomment to run specific years
	timer on 1

	loc y = substr("`year'",-2,2)

	set more off
	clear frames

	use $main/ctcPaper/rd_`y', clear
	egen tax_num = rowmin(epppnum epnspous)

	foreach var in dividends intrec nonprop otherprop pensions gssi transfers ui  {
	ren `var' person_`var'
	}

	merge m:1 ssuid tax_num using $main/ctcPaper/taxsim_results_`y', keep (1 3) keepusing(v22 v23 dep17 fiitax siitax fica v10 v14 v17 v18 v19 v25 v24) nogen
	merge m:1 ssuid tax_num using $main/ctcPaper/taxsim_extract_`y', keep (1 3) nogen
	if `year'>=2001 {
		merge m:1 ssuid tax_num using $main/ctcPaper/taxsim_depchild_`y', keep (1 3) keepusing(fiitax_alt siitax_alt eitc_alt ctc_alt) nogen
	}
	else {
		gen fiitax_alt =.
		gen siitax_alt =.
		gen eitc_alt =.
		gen ctc_alt =.
	}
	merge 1:1 ssuid epppnum using $main/ctcPaper/taxsim_full_`y', keep (1 3) nogen keepusing(dep_par tax_rmesr* thhtnw thhtwlth thhdebt thhscdbt thhuscbt  thhtheq) nolabel


	egen ctc = rowtotal(v22 v23)
	sum ctc
	ren dep17 ctc_kids
	ren v10 agi
	ren v14 exemptions
	ren v17 itemized_deductions
	ren v18 taxable_income
	ren v19 regular_tax
	ren v22 nonrefundable_ctc
	ren v23 refundable_ctc
	ren v24 child_care_credit
	ren v25 eitc
	gen primarytaxpayer = epnspous > epppnum
	egen allinc = rowtotal(pwages swages dividends intrec nonprop otherprop pensions gssi transfers ui ltcg stcg)

	//spd setup for parental links
	if inrange(`year',1996,2001) {
		egen spd_lfp = rowtotal( nwlkwke lkwkse rmwkwjb) if spd==1
		gen spd_wrk = rmwkwjb if spd==1
		loc spdvars "spd_lfp spd_wrk"
	}
	else loc spdvars ""


	qui compress
	save $main/ctcPaper/rd_combined_`y', replace

	*set up fuzzy rd
	**merge ctc amounts and parent variables to kids
	if `year'>=1996 loc edu "eeducate"
	else loc edu ""

	//start new frame code
	frame put ssuid epnspous months_obs race educ `edu' tage tax_rmesr* `spdvars' , into(spouse2)
	frame spouse2 {
	keep if epnspous!=9999
	ren epnspous epppnum
	duplicates tag ssuid epppnum, gen(dup)
	drop if dup>0 //remove duplicates--appears to only be a problem in pre-96
	drop dup
	}

	frame put ssuid epppnum ctc ctc_kids depx agi pwages swages dividends intrec nonprop otherprop pensions gssi transfers ui ltcg stcg allinc mstat months_obs race educ `edu' tage tax_pearn* tax_worked* ctc_alt fiitax siitax fica tax_rmesr* `spdvars' , into(ctc_amts)
	frame ctc_amts {
	frlink 1:1 ssuid epppnum, frame(spouse2)
	frget months_obs race educ `edu' tage tax_rmesr* `spdvars', from(spouse2) prefix(spous_)
	}
	//final link
	gen parlink = epnguard
	replace parlink = epnmom if mi(parlink) | inlist(parlink,-1,9999)
	replace parlink = epndad if mi(parlink) | inlist(parlink,-1,9999)
	frlink m:1 ssuid parlink, frame(ctc_amts ssuid epppnum) 
	frget ctc ctc_kids depx agi pwages swages dividends intrec nonprop otherprop pensions gssi transfers ui ltcg stcg allinc mstat months_obs spous_months_obs tax_pearn* tax_worked* ctc_alt fiitax siitax fica, from(ctc_amts) prefix(par_)
	frget race educ `edu' tage tax_rmesr* `spdvars', from(ctc_amts) prefix(head_)
	frget spous_* , from(ctc_amts)


	replace par_ctc = par_ctc/1000 //get units of $1000s
	gen pct_ctc = par_ctc * 1000 / max(0,par_agi)
	gen pct2_ctc = par_ctc * 1000 / max(0,par_allinc)
	replace par_ctc_alt = par_ctc_alt/1000 //get units of $1000s

	egen par_wage = rowtotal(par_pwages par_swages) //uses tax units to match
	gen hastearn = par_wage!=0 & !mi(par_wage)
	replace hastearn = . if mi(par_pwages) & mi(par_swages)


	*add labels
	la var hassearn "Proportion in Family with Earnings"
	la var agem "Age (months) relative to age 17 cutoff"
	la var par_ctc "Amount of CTC received ($1000s)"
	la var pct_ctc "Amount of CTC received (% of AGI)"
	la var pct2_ctc "Amount of CTC received (% of Broad Income)"
	la var par_ctc_alt "Counterfactual Amount of CTC received ($1000s)"

	la var hastearn "Proportion in Tax Unit with Earnings"
	gen hasgearn = guard_pearn!=0 & !mi(guard_pearn) 
	lab var hasgearn "Proportion of Guardians with Earnings"
	gen hasmearn = mom_pearn!=0 & !mi(mom_pearn) 
	lab var hasmearn "Proportion of Mothers with Earnings"
	gen in_school = renroll==1
	lab var in_school "Proportion in School Full-Time"

	//fix address ids (beccome string in 2014)
	if `year'< 2013 {
		foreach pref in "" mom_ dad_ guard_ {
			lab val `pref'shhadid .
			tostring `pref'shhadid, replace
		}
	}

	save $main/ctcPaper/rd_`y'_tax, replace
	timer off 1
	timer list
}
log close taxsim_prepare

clear frames //clean up frames

****************************
****Clean up and combine****
****************************

*create unified notes 
use $main/ctcPaper/rd_08_tax, clear
foreach var of varlist lgtkey-lgtwt {
	notes `var': *****End Notes for 2008*******
}
keep lgtkey-lgtwt 
foreach year of numlist 2009/2016 2001/2007 1990/2000 1984/1989 {
	loc v = substr("`year'",-2,2)
	append using $main/ctcPaper/rd_`v'_tax, nolabel 
	foreach var of varlist lgtkey-lgtwt {
		notes `var': *****End Notes for `year'*******
	}
	keep lgtkey-lgtwt 
	keep in 1
}
save $main/ctcPaper/rd_all_notes, replace



*combine all years
timer clear
use $main/ctcPaper/rd_08_tax, clear

foreach year of numlist 2009/2016 2001/2007 1990/2000 1984/1989 {
	timer on 1
	loc v = substr("`year'",-2,2)
	append using $main/ctcPaper/rd_`v'_tax, nolabel nonotes
	timer off 1
	timer list
}
timer on 1

notes drop lgtkey-lgtwt
append using $main/ctcPaper/rd_all_notes, nolabel gen(all_notes) //replaces all notes
drop if all_notes==1

fsort year ssuid epppnum

//fix weight var (saved as float previously)
drop wt
gen double wt = wpfinwgt
replace wpfinwgt_orig = wpfinwgt if year==2000

***cleaning up unneeded variables
drop   temp_agi   tax_pearn* tax_worked* tax_rmesr*
drop  su_id pp_entry pp_pnum suid panel pnum entry  u_realft u_reaent  f1_povd f2_povd f3_povd f4_povd u_entlf1 u_entlf2 sc0068 finalwgt rrp age ms pnsp pnpt finalwgt_ merge* j10003-lgtwt_orig *valt
drop   u_entlft u_entlft1 u_reasn1 u_reasn2 all_notes

compress
save $main/ctcPaper/rd_all_tax, replace
timer off 1
timer list


*delete temporary files
cd "$main/ctcPaper"
forval year = 1984/2016 {
	*loc year = 2016 //uncomment to run specific years
	loc y = substr("`year'",-2,2)
    cap erase famearn_months`y'.dta
	cap erase rd_`y'_tax.dta
    cap erase rd_combined_`y'.dta
    cap erase taxsim_extract_`y'.dta
    cap erase taxsim_results_`y'.dta
    cap erase taxsim_full_`y'.dta
    cap erase taxsim_depchild_`y'.dta
}
loc files80s : dir . files "sipp8*.dta"
foreach f of local files80s {
    cap erase `f'
}