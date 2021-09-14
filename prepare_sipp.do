*Code to clean SIPP data for CTC paper
//note: requires about 15GB of free disk space for working files

version 15.1
loc rmdir "rm -r"
if c(os)=="Windows" loc rmdir "rmdir /S /Q" 

cd "$main/core"

***********************************
****** Prepare data		***********
***********************************

*set up main calendar year data files
cap log close _all
log using $main/ctcPaper/prepare_data.log, text name(prepare_data) replace 
timer clear 1
loc last_archive ""
foreach year in 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2012.5 2013 2014 2015 2016 {
	*note: year 2012.5 is the 2013 year of the 2008 panel
	*      due to overlapping data for calendar year 2013 (appears in both 2008 and 2014 panels)
	*loc year  "2012.5" //uncomment to run specific years
	set more off
	timer on 1

	//note some years will have smaller sample sizes due to December limitation 
	// (person must be observed in December to be in sample)

	loc y = substr("`year'",-2,2)
	
	****************
	//wrapper for year parameters, to allow code folding
	if 1==1 {
		*global parameters for panels
		if inrange(`year',1996,2000) {
		loc wtfile lgtwgt1996w12
		loc panel "96"
		}
		if inrange(`year',2001,2003) {
		loc wtfile lgtwgt2001w9
		loc panel "01"
		}
		if inrange(`year',2004,2007) {
		loc wtfile lgtwgt2004w12
		loc panel "04"
		}
		if inrange(`year',2008,2012) | "`year'"=="2012.5" {
		loc wtfile lgtwgt2008w16
		loc panel "08"
		}
		if inrange(`year',2013,2016) {
		loc panel "14"
		}

		**Old SIPP
		****CY 1984
		if "`year'"=="1984" {
		loc num = 2
		loc wt  fnlwgt84 
		loc panel "84"
		loc wtfile lgtwgt1984
		}
		if "`year'"=="1985" {
		loc num = 1
		loc wt  fnlwgt85 
		loc panel "85"
		loc wtfile lgtwgt1985
		loc panel2 "84"
		loc wtfile2 lgtwgt1984
		loc num2 = 5
		}
		if "`year'"=="1986" {
		loc num = 1
		loc wt  fnlwgt86
		loc panel "86"
		loc wtfile lgtwgt1986
		loc panel2 "85"
		loc wtfile2 lgtwgt1985
		loc num2 = 4
		}
		if "`year'"=="1987" {
		loc num = 1
		loc wt  fnlwgt87
		loc panel "87"
		loc wtfile lgtwgt1987
		loc panel2 "86"
		loc wtfile2 lgtwgt1986
		loc num2 = 4
		}
		if "`year'"=="1988" {
		loc num = 1
		loc wt  fnlwgt88
		loc panel "88"
		loc wtfile lgtwgt1988
		loc panel2 "87"
		loc wtfile2 lgtwgt1987
		loc num2 = 4
		}
		if "`year'"=="1989" {
		loc num = 1
		loc wt  fnlwgt89
		loc panel "89"
		loc wtfile "" //no longitudinal weight
		loc panel2 "88"
		loc wtfile2 lgtwgt1988
		loc num2 = 4
		}
		***break in overlapping panels
		****CY 1990
		if "`year'"=="1990" {
		loc num = 1 
		loc wt  fnlwgt90 
		loc panel "90"
		loc wtfile lgtwgt1990
		}
		****CY 1991
		if "`year'"=="1991" {
		loc num = 1
		loc wt  fnlwgt91 
		loc panel "91"
		loc wtfile lgtwgt1991
		loc panel2 "90"
		loc wtfile2 lgtwgt1990
		loc num2 = 4
		}
		****CY 1992
		if "`year'"=="1992" {
		loc num = 1
		loc wt  fnlwgt92 
		loc panel "92"
		loc wtfile lgtwgt1992
		loc panel2 "91"
		loc wtfile2 lgtwgt1991
		loc num2 = 4
		}
		****CY 1993
		if "`year'"=="1993" {
		loc num = 1
		loc wt  fnlwgt93 
		loc panel "93"
		loc wtfile lgtwgt1993
		loc panel2 "92"
		loc wtfile2 lgtwgt1992
		loc num2 = 4
		}
		****CY 1994
		if "`year'"=="1994" {
		loc num =  4
		loc wt  fnlwgt94 
		loc panel "93"
		loc wtfile lgtwgt1993
		loc panel2 "92"
		loc wtfile2 lgtwgt1992
		loc num2 = 7
		}
		****CY 1995
		if "`year'"=="1995" {
		loc num = 7 
		loc wt  //no calender year weight for 1995 
		loc panel "93"
		loc wtfile lgtwgt1993
		}
		**New SIPP
		****CY 1996
		if "`year'"=="1996" {
		loc num = 1 
		loc wt  lgtcy1wt 
		}
		****CY 1997
		if "`year'"=="1997" {
		loc num = 3 
		loc wt  lgtcy2wt 
		}
		****CY 1998
		if "`year'"=="1998" {
		loc num = 6 
		loc wt  lgtcy3wt
		}
		****CY 1999
		if "`year'"=="1999" {
		loc num = 9 
		loc wt  lgtcy4wt 
		}
		****CY 2001
		if "`year'"=="2001" {
		loc num = 1 
		loc wt  lgtcy1wt 
		}
		****CY 2002
		if "`year'"=="2002" {
		loc num = 4 
		loc wt  lgtcy2wt 
		}
		****CY 2003
		if "`year'"=="2003" {
		loc num = 7 
		loc wt  lgtcy3wt 
		}
		****CY 2004
		if "`year'"=="2004" {
		loc num = 1 
		loc wt  lgtcy1wt
		}
		****CY 2005
		if "`year'"=="2005" {
		loc num = 4
		loc wt  lgtcy2wt
		}
		****CY 2006
		if "`year'"=="2006" {
		loc num = 7 
		loc wt  lgtcy3wt
		}
		****CY 2007
		if "`year'"=="2007" {
		loc num = 10 
		loc wt  lgtcy4wt
		}
		****CY 2008
		if "`year'"=="2008" {
		loc num = 1 
		loc wt  
		}
		****CY 2009
		if "`year'"=="2009" {
		loc num = 2 //covers Dec-Jan 2009
		loc wt  lgtcy1wt
		}
		****CY 2010
		if "`year'"=="2010" {
		loc num = 5 //covers Dec-Jan 2010
		loc wt  lgtcy2wt
		}
		****CY 2011
		if "`year'"=="2011" {
		loc num = 8
		loc wt  lgtcy3wt
		}
		****CY 2012
		if "`year'"=="2012" {
		loc num = 11
		loc wt  lgtcy4wt
		}
		****CY 2013, 2008 panel
		if "`year'"=="2012.5" {
		loc num = 14
		loc wt  lgtcy5wt
		}
		**Reengineered SIPP
		****CY 2013
		if "`year'"=="2013" {
		loc num = 1
		}
		****CY 2014
		if "`year'"=="2014" {
		loc num = 2
		}
		****CY 2015
		if "`year'"=="2015" {
		loc num = 3
		}
		****CY 2016
		if "`year'"=="2016" {
		loc num = 4
		}
	}

	****************
	* Extract archive if needed
	loc archive "`panel'"
	if inrange(`year',2013,2016) loc archive "`y'" //separate archives for each year with 2014 SIPP
	if inrange(`year',1984,1989) loc archive "84-89"
	if inrange(`year',1990,1995) loc archive "90-93"
	if "`last_archive'"!="`archive'" {
		//clean up old archives
		if "`last_archive'"!="" {
			shell `rmdir' "sippArchive`last_archive'/" 
		}
		//unzip current archive
		cap confirm file "$main/core/sippArchive`archive'/"
		if _rc!=0 {
				cap mkdir sippArchive`archive'
				cd sippArchive`archive'
				unzipfile "../sippArchive`archive'.zip" 
				cd "$main/core"
		}
	}
	loc coreloc "$main/core/sippArchive`archive'"
	
	****************
	*Newest (2014) SIPP panel
	if `year'>=2013 {
		if `year'==2013 loc y "13b"
		loc redojobs = 1 //set to 1 for first pass

		use "`coreloc'/pu20`panel'w`num'_1.dta", clear 
		merge 1:1 ssuid pnum monthcode using "`coreloc'/pu20`panel'w`num'_2.dta", keepusing(ejb*_bmonth ejb*_emonth tjb*_occ tjb*_ind ejb*_rsend ejb*_clwrk ejb*_chermn* ejb*_chhomn*  tjb*_hourly* tjb*_jobhrs*) nogen
		merge 1:1 ssuid pnum monthcode using "`coreloc'/pu20`panel'w`num'_3.dta", keepusing(tpearn tmwkhrs rmwkwjb rmesr enj_nowrk*) nogen
		merge 1:1 ssuid pnum monthcode using "`coreloc'/pu20`panel'w`num'_4.dta", keepusing(tjsmfinc tjomfinc tomfinc tjsstinc tjostinc tostinc ///
			trentmort eprloan1rate tprloanamt tinc_bank tinc_bond ttrinc thnetworth thval_ast thdebt_ast thdebt_sec thdebt_usec theq_home) nogen
		merge 1:1 ssuid pnum monthcode using "`coreloc'/pu20`panel'w`num'_5.dta", keepusing(edisabl taliamt tret1amt ///
			tret2amt tret5amt tret3amt tret4amt tret6amt tret7amt tret8amt tlifeamt elmpnow elmptyp*yn tlmpamt tdeferamt ///
			tsssamt tsscamt  tuc1amt twicamt tfs_amt efstatus edepclm eeitc efiling ewillfile tminc_amt eminc_typ*yn ) nogen
		merge 1:1 ssuid pnum monthcode using "`coreloc'/pu20`panel'w`num'_6.dta", keepusing(tmdpay thipay) nogen


		#delimit ;
		loc keepvars "ssuid pnum monthcode spanel swave  ghlfsam gvarstr tehc_metro
			tehc_st ehresidencid rfamnum  wpfinwgt 
			tage tage_ehc edob_bmonth adob_bmonth tdob_byear adob_byear
			esex erace eorigin erelrp ems eeduc edisabl ejobcant
			epnspouse epnpar1 epnpar2 erefpar epar1typ epar2typ
			eedenroll renroll  etenure ecert
			tptotinc tpearn tpprpinc tptrninc tpothinc tpscininc 
			tjsmfinc tjomfinc tomfinc tjsstinc tjostinc tostinc 
			taliamt tinc_bank tinc_bond tminc_amt eminc_typ*yn tlifeamt tdeferamt
			tret1amt tret2amt tret5amt tret3amt tret4amt tret6amt tret8amt 
			tret6amt tret7amt tret8amt ttrinc
			elmpnow elmptyp*yn tlmpamt 
			tsssamt tsscamt  tuc1amt twicamt tfs_amt
			rfpov tmwkhrs rmwkwjb rmesr enj_nowrk*
			ebornus ecitizen espeak
			efstatus edepclm eeitc efiling ewillfile trentmort eprloan1rate tprloanamt 
			tpaywk tmdpay thipay
			ejb*_bmonth ejb*_emonth tjb*_occ tjb*_ind ejb*_rsend ejb*_clwrk ejb*_chermn* ejb*_chhomn* tjb*_hourly* tjb*_jobhrs* rrel*
			thnetworth thval_ast thdebt_ast thdebt_sec thdebt_usec theq_home" ;
		#delimit cr ; 
		keep `keepvars' 

		/*
		missing or changed relative to 2008:
			eentaid 
			srefmon (not relevant)
			tfearn (can construct)
			no "mom" or "dad" identifiers - treat "parent 1" as mother (check tax logic)
			eoutcome (seems to be eppmis variables, which are suppressed)
			eppintvw (no sign of proxy interview status... although it still happens, as mentioned in user's guide)
			rhtype
			ulftmain (can see who did move with rmover, which is like old tmovrflg)
			uentmain
			eclwrk1 tpyrate1 ejbhrs1 ersend1 ejbind1 tjbocc1 - require concept of constant "job 1" (done below)
			tdivinc - see below
			t42amt - see below
			tret6amt tret7amt tret8amt  -  retirement income from other sources - mixed in t38amt in older SIPPS, railroad retirement in t02amt 
			efstatus trentmort eprloan1rate tprloanamt tpaywk tmdpay thipay - variables that used to be in TMs 
		*/

		//fix the job variables to refer to "job 1" in all months
		//approach: 2008 SIPP asked about "first" job by wave. Here, take first listed job (i.e. started earliest) by month.
		if `redojobs'==1 {
		preserve
		keep ssuid pnum monthcode ejb*_bmonth ejb*_emonth tjb*_occ tjb*_ind ejb*_rsend ejb*_clwrk ejb*_chermn* ejb*_chhomn* tjb*_hourly* tjb*_jobhrs*

		greshape long ejb@_bmonth ejb@_emonth tjb@_occ tjb@_ind ejb@_rsend ejb@_clwrk ejb@_chermn1 ejb@_chermn2 ejb@_chhomn1 ejb@_chhomn2 tjb@_hourly1 tjb@_hourly2 tjb@_hourly3 tjb@_jobhrs1 tjb@_jobhrs2 tjb@_jobhrs3, i(ssuid pnum monthcode) j(job)
		drop if mi(ejb_bmonth) //job start month is missing once job is no longer held
		tab job //note very few high numbered jobs

		sort ssuid pnum monthcode job
		by ssuid pnum monthcode: keep if _n==1 //keep first listed job per month

			//fix variables that allow up to 3 changes to be one continuous change
		foreach var in tjb_jobhrs tjb_hourly {
		if "`var'"=="tjb_hourly" loc stub "er"
		else loc stub "ho"
		gen `var' = `var'1
		replace `var' = `var'2 if monthcode>=ejb_ch`stub'mn1 //after date of first change
		replace `var' = `var'3 if monthcode>=ejb_ch`stub'mn2 //after date of second change
		}


		keep ssuid pnum monthcode ejb_clwrk  tjb_hourly tjb_jobhrs ejb_rsend tjb_ind tjb_occ

		save $main/ctcPaper/jb`y', replace
		restore
		}

		drop ejb*_bmonth ejb*_emonth tjb*_occ tjb*_ind ejb*_rsend ejb*_clwrk ejb*_chermn* ejb*_chhomn* tjb*_hourly* tjb*_jobhrs*
		merge 1:1 ssuid pnum monthcode using $main/ctcPaper/jb`y', nogen


		//rename to 2008 panel names
		#delimit ;
		rename (pnum monthcode tehc_st ehresidencid rfamnum edob_bmonth adob_bmonth tdob_byear adob_byear 
			epnspouse epnpar1 epnpar2 erefpar epar1typ epar2typ eedenroll renroll ejobcant 
			tmwkhrs taliamt tret1amt tret2amt tret5amt tret3amt tret4amt tret6amt tret8amt tsssamt tsscamt  tuc1amt twicamt tfs_amt tlifeamt
			ejb_clwrk  tjb_hourly tjb_jobhrs ejb_rsend tjb_ind tjb_occ
			thnetworth thval_ast thdebt_ast thdebt_sec thdebt_usec theq_home)
			(epppnum rhcalmn tfipsst shhadid rfid ebmnth abmnth tbyear abyear 
			epnspous epnmom epndad epnguard etypmom etypdad renroll eenrlm edisprev 
			ehrsall t29amt t30amt t31amt t32amt t34amt t35amt t02amt t38amt t01amta t01amtk t05amt t25amt t27amt t36amt
			eclwrk1 tpyrate1 ejbhrs1 ersend1 ejbind1 tjbocc1
			thhtnw thhtwlth thhdebt thhscdbt thhuscbt thhtheq);
		#delimit cr ; 


		//create missing variables
		gen rhcalyr = `year'
		gen double lgtkey = ssuid * 1000 + epppnum //use ssuid and pnum only
		gen lgtmon = 12*(`year'-2013)+rhcalmn

		bys ssuid rfid: egen tfearn = total(tpearn) //compute value for families - note subject to topcoding, unlike earlier waves
		//note per SIPP release notes--tpearn no longer includes severance payments
		// https://www.census.gov/programs-surveys/sipp/tech-documentation/user-notes/2014-usernotes/2014w1-tpearn.html
		egen tdivinc = rowtotal(tjsmfinc tjomfinc tomfinc tjsstinc tjostinc tostinc) //stocks + mutual fund income, by ownership type--includes jointly held with others, doesn't divide by reinvested or not
		egen tintinc = rowtotal(tinc_bank tinc_bond)
		gen t39amt = tlmpamt if elmptyp1yn==1 //approximation - include lump sums for those who got a retirement lump sum (but could include other lump sums, like severance pay, if multiple sources)
		gen t42amt = . //actual IRA/KEOGH values should be part of tret8amt (not broken out--includes other stuff)
		gen severance = tlmpamt if elmptyp1yn!=1 & elmptyp2yn==1 //assign to severance if not retirement
		replace severance = severance + tdeferamt if elmptyp3yn==1 //add final paycheck - but note, tdeferamt likely already in earnings
		gen t52amt = tlmpamt if (elmptyp1yn!=1 /*& elmptyp2yn!=1 & elmptyp3yn!=1 */) //assign "other" lump sums to this variable (nclude severance, but don't exclude deferred paycheck, as not captured in this variable

		//get misc earnings--not broken out separately, so assume all in "misc" type (but only if other types false--assume mixed income not taxable)
		gen t56amt = tminc_amt if min(eminc_typ1yn,eminc_typ2yn,eminc_typ4yn) > 1 //exclude charity, family/friends, estates
		gen t53amt = .
		gen t54amt = .
		gen t55amt = .

		gen t37amt = . //ttrinc is trusts only, and appears to be part of tpprpinc--estates are in misc income, but assume not taxable

		//variables with different codings
		recode tehc_metro 0=3, gen(tmetro)
		recode eeduc 41=40 42=43 43=44 44=45 45=46 46=47, gen(eeducate) //note 2008 "diploma / certificate" vs 2014 "one year college" - recode 2014 to "some college"
		replace eeducate = 41 if ecert==1 & eeducate<43 //add Certificate info if no Associates+
		recode erelrp 4=10 5=4 6=5 7=6 8=7 9=8 10=9, gen(errp)

		foreach var in  tdivinc tintinc t37amt t39amt severance t52amt t36amt t56amt {
		replace `var' = round(`var'/12) //annual value, so divide out; round to match other monthly values
		}
		//note: main income variables are already monthly 
		//  egen tot = rowtotal(tpearn tpprpinc tpothinc tptrninc tpscininc)
		//  is equal to tptotinc except for children under 15 (who can have tpearn values, but no tptotinc value)

		//add severance pay to earnings--to match coding of old panels
		*gen tpearn_orig = tpearn
		*replace tpearn = tpearn + severance if !mi(severance) 
		//for paper, leave tpearn as is (since severance is lump sum)

		*fix missing parental indicators for kids with partial years of data 
		preserve
		tempfile parframe
		keep ssuid epppnum rhcalmn tage_ehc
		ren epppnum epnmom
		ren tage_ehc pa_tage_ehc
		gen epndad = epnmom
		save `parframe'
		restore
		merge  m:1 ssuid epnmom rhcalmn using `parframe', keep(1 3) keepusing(pa_tage_ehc) nogen
		compare tage_ehc pa_tage_ehc //check how ages compare--find only two cases where parent1 is older than child

		forval i = 1/20 {
		gen ch_mom`i' =  (inlist(rrel`i',5,6,7,18) & mi(epnmom) & tage_ehc < 19) 
		replace epnmom = rrel_pnum`i' if ch_mom`i' //assigns to first found parent
		gen ch_dad`i' = (inlist(rrel`i',5,6,7,18) & !mi(epnmom) & mi(epndad) & epnmom!=rrel_pnum`i' & tage_ehc < 19)
		replace epndad = rrel_pnum`i' if ch_dad`i' //second found parent
		}
		egen ch_mom = rowmax(ch_mom*)
		egen ch_dad = rowmax(ch_dad*)

		//both parents and children will be flagged, so use lower age to find child
		ren pa_tage_ehc mom_tage_ehc 
		compare tage_ehc mom_tage_ehc 
		replace epnmom = . if ch_mom==1 & tage_ehc >= mom_tage_ehc
		
		merge  m:1 ssuid epndad rhcalmn using `parframe', keep(1 3) keepusing(pa_tage_ehc) nogen
		ren pa_tage_ehc dad_tage_ehc
		compare tage_ehc dad_tage_ehc 
		replace epndad = . if ch_dad==1 & tage_ehc >= dad_tage_ehc

		drop ch_mom?* ch_dad?* mom_tage_ehc dad_tage_ehc 

		replace epnmom = 9999 if mi(epnmom)
		replace epndad = 9999 if mi(epndad)
		replace epnguard = 9999 if mi(epnguard)
		replace epnspous = 9999 if mi(epnspous)

		replace wpfinwgt = wpfinwgt*10000 //match number of decimal places in 2008; note has 6 decimals, so two extra

		ren tage tage_endyr
		ren tage_ehc tage //value is as of each month, better matching monthly values from older panels

		/*
		*notes on more differences from 2008 panel:
		- edisabl changed to not mention "job or business"
		- edisprev is approximated by ejobcant (similar, but includes both disabled through edisabl and those who are limited in jobs thru efindjob)
		- variables seem defined based on monthly rather than annual ages (but maybe same as before - only difference would be people with birthdates in reference period)
		- erefpar now only defined for 17 and under (was 19 and under)
		- renroll is  now monthly (same as old eenrlm), but for age 3+
		- eedenroll is like old renroll (enrolled any time in reference period- but ref period is now year rather than 4 months)
		- new rrel_pnum`x' variables give household relationships for everyone (used to be a topical module)
		-  new combined tpscininc social insurance income variable
		- tptotinc and tpprpinc now reported as annual values (not monthly!!)
		-  Type 2 people: those who resided in hh, but not at time of interview (i.e. moved out during year)
		-  poverty , etc is defined including these people
		- job info changed (no "job 1" with most hours... instead, chronological
		- tmwkhrs is average hours worked in all jobs in month, rather than ehrsall "usual" hours
		- asset income in new format: only annual values
		- dividends: come from stocks + mutual funds. Not broken down by checks received vs reinvested (and divided by 2 if joint, rather than separate shares)
		- tret1amt - company or union pension, 2014 includes profit-sharing plans
		- note t38amt - other retirement/disab/survivor - not included as pension income in code for all years
		- for t39amt (pension/retirment lump sum) - can no longer distinguish amounts between retirement and severence or other lump sums
		- t42amt - ira/keogh no longer broken out as providing income, just put in "other retirement income" field (per user's guide)
		- t01amtk is now for age 18+ (there all year) rather than age 15+ (there in 4 months)
		-  all RR (t02amt) income recorded is retirement
		*/


	}

	****************
	*Newer (1996-2008) SIPP panels
	if `year'>=1996 & `year'< 2013 {
		if `year'==2012.5 {
		loc year 2013
		loc y "13a"
		}
		use "`coreloc'/sipp`panel'_core`num'.dta", clear 

		//different variables for 96 panel
		loc rfpov "rfpov"
		loc ehrsall "ehrsall"
		loc incvars ""
		if inlist("`panel'","96") loc rfpov "tfpov"
		if inlist("`panel'","96","01") loc ehrsall ""
		if inlist("`panel'","96","01") loc incvars "t37amt t53amt"

		#delimit ;
		loc keepvars "ssuid eentaid epppnum lgtkey lgtmon rhcalyr rhcalmn spanel swave srefmon ghlfsam gvarstr tmetro
			tfipsst shhadid rfid tfearn wpfinwgt 
			tage ebmnth tbyear abmnth abyear 
			esex erace eorigin  errp ems eeducate edisabl edisprev
			epnspous epnmom epndad epnguard etypmom etypdad
			renroll eenrlm etenure 
			eoutcome eppintvw ersnowrk
			tptotinc tpearn tpprpinc tptrninc tpothinc  
			tintinc t29amt t36amt t38amt t55amt t56amt t02amt t52amt `incvars'
			tdivinc t30amt t31amt t32amt t34amt t35amt t39amt t42amt t01amta t01amtk t05amt t25amt t27amt
			rhtype `rfpov' ulftmain uentmain `ehrsall' rmwkwjb rmesr eclwrk1 tpyrate1 ejbhrs1
			ersend1 ejbind1 tjbocc1" ;
		#delimit cr ; 
		if inlist("`panel'","04","08") loc extra "ebornus ecitizen espeak" //only available in later panels--earlier panels likely have this in TM2, but not added yet
		keep `keepvars' `extra'
		append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel nonotes
		if !inlist(`year',2008) append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel nonotes
		if !inlist(`year',2003,2007,2008,2013) append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel  nonotes //short periods (end of panel)
		if inlist(`year',1997,1998) append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel nonotes //longer periods
		keep if rhcalyr==`year'
		format ssuid %12.0f

		*get longitudinal weights - see notes on this in v4
		if !inlist(`year',2008) {
		merge m:1 lgtkey using $main/lgt/`wtfile'.dta, keepusing(`wt') nogen keep(1 3)
		ren `wt' lgtwt
		}
		else gen lgtwt = .


		if inlist("`panel'","01","96") {
		ren eorigin ethncty
		gen eorigin = inrange(ethncty,20,29) //Hispanic origins in 96 and 01 panels
		}

		if inlist("`panel'","96") ren tfpov rfpov

		if inlist("`panel'","04","08") {
		gen t37amt = .
		gen t53amt = .
		}
		gen t54amt = . //National Guard income never present
		//note: these variables are in the questionaire, so presumably issue is just that no one answered yes

	}

	****************
	*1990s panels
	if inrange(`year',1990,1995) {
		use "`coreloc'/sipp`panel'_core`num'.dta", clear 
		#delimit ;
		loc keepvars "suid pnum year month panel wave refmth hhsc hstrat hmetro 
			hstate addid fid fearn fnlwgt
			age brthmn brthyr 
			sex race ethncty rrp ms disab
			pnsp pnpt pngdu 
			enrold htenure 
			hitm36b intvw
			totinc earn prop tran other
			s29amt s30amt s31amt s32amt s34amt s35amt s01amta s01amtk s05amt wicval s27amt s36amt s38amt s55amt s56amt s02amta s52amt s37amt s53amt s54amt
			j110ri o110ri j110 o110 
			j10003 o10003 j10407 o10407
			grdcmpl higrade entry 
			pwsuid pwentry pwpnum 
			hmsa 
			htype fpov realft reaent uhours wksjob esr ws12012 ws12028 ws12024 ws1ind ws1occ" ;
		#delimit cr ; 
		keep `keepvars' 
		append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel nonotes
		append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel nonotes
		if !inlist(`year',1995)  append using "`coreloc'/sipp`panel'_core`++num'", keep( `keepvars') nolabel nonotes //short periods (end of panel)
		if !inlist(`year',1990,1995) {
		append using "`coreloc'/sipp`panel2'_core`num2'", keep( `keepvars') nolabel nonotes //overlapping panels
		append using "`coreloc'/sipp`panel2'_core`++num2'", keep( `keepvars') nolabel nonotes
		append using "`coreloc'/sipp`panel2'_core`++num2'", keep( `keepvars') nolabel nonotes
		if !inlist(`year',1994) append using "`coreloc'/sipp`panel2'_core`++num2'", keep( `keepvars') nolabel nonotes //missing wave 10 of 1992 data
		}
		gen rhcalyr = real("19"+string(year))   //edit to four digits

		keep if rhcalyr==`year'

		*get longitudinal weights 
		if `year'==1995 gen lgtwt = . //no calendar year weight this year
		else {
		merge m:1 panel suid entry pnum using $main/lgt/`wtfile'.dta, keepusing(`wt') nogen keep(1 3)
		if `year'==1990 ren `wt' lgtwt //1990 only has one panel
		else {
		merge m:1 panel suid entry pnum using $main/lgt/`wtfile2'.dta, keepusing(`wt') nogen update keep(1 3 4 5)
		ren `wt' lgtwt
		}
		}

		//adjust weights for overlapping panels, per Table 8-9 in SIPP user's guide
		if "`panel2'"!="" {
		ren lgtwt lgtwt_orig
		ren  fnlwgt fnlwgt_orig
		gen double fnlwgt = fnlwgt_orig
		gen double lgtwt = lgtwt_orig
		count if panel==`panel2' & month==12 //do adjustment based on December
		loc r1 = `r(N)'
		count if panel==`panel' & month==12 //do adjustment based on December
		loc r2 = `r(N)'
		loc wtmod = `r1' / (`r1'+`r2')
		di "Wt of `panel2' in `year' = `wtmod'"
		replace lgtwt = lgtwt_orig * `wtmod' if (panel==`panel2') 
		replace lgtwt = lgtwt_orig * (1-`wtmod') if (panel==`panel') 
		replace fnlwgt = fnlwgt_orig * `wtmod' if (panel==`panel2') 
		replace fnlwgt = fnlwgt_orig * (1-`wtmod') if (panel==`panel') 
		}


		*make longitudinal key
		sort panel suid entry pnum
		format suid %12.0f
		egen double lgtkey = group(panel suid entry pnum)
		gen spanel = real("19"+string(panel))
		egen ssuidi = concat(panel suid entry), format(%16.0f)
		gen double ssuid = real(ssuidi)
		drop ssuidi
		format ssuid %12.0f
		gen epppnum = pnum

		/*
		*rename to 1996 names
		- rename variables based on 2001 SIPP user's guide (appendix A)
		- missing: lgtkey lgtmon abmnth abyear edisprev t39amt t42amt ersnowrk
		- dividends pre-96 combine stocks and mutual funds; post-96 have them as separate vars
		- already set variables like rhcalyr, spanel, ssuid, epppnum and lgtwt
		- no separate epndad epnmom (only "parent" and guardian)--will call parent variable "epnmom"
		- eeducate present (but coded differently) in higrade
		- enrold not exactly like renroll and eenrlm--closest to the latter
		- abmnth not available--seems from User's guide chap 4 and p. 10-36 to be not imputed except when intvw=3/4, but unclear
		- using hitm36b istead of h5mis to map to eoutcome
		- user's guide appears to be wrong in mapping s40amt to t39amt
		*/

		#delimit ;
		rename (month wave refmth hhsc hstrat hmetro 
			hstate addid fid fearn fnlwgt
			age brthmn brthyr 
			sex race rrp ms disab
			pnsp pnpt pngdu 
			enrold htenure 
			hitm36b intvw
			totinc earn prop tran other
			s29amt s30amt s31amt s32amt s34amt s35amt  s01amta s01amtk s05amt s27amt
			s36amt s38amt s55amt s56amt s02amta s52amt s37amt s53amt s54amt
			htype fpov realft reaent uhours wksjob esr ws12012 ws12028 ws12024 ws1ind ws1occ)
			(rhcalmn swave srefmon ghlfsam gvarstr tmetro
			tfipsst shhadid rfid tfearn wpfinwgt 
			tage ebmnth tbyear 
			esex erace  errp ems edisabl 
			epnspous epnmom epnguard 
			eenrlm  etenure 
			eoutcome eppintvw
			tptotinc tpearn tpprpinc tptrninc tpothinc  
			t29amt t30amt t31amt t32amt t34amt t35amt  t01amta t01amtk t05amt t27amt
			t36amt t38amt t55amt t56amt t02amt t52amt t37amt t53amt t54amt
			rhtype rfpov ulftmain uentmain ehrsall rmwkwjb rmesr eclwrk1 tpyrate1 ersend1 ejbind1 tjbocc1);
		#delimit cr ; 
		*make versions of missing 1996 vars
		gen t25amt = wicval / 100
		gen t39amt = 0 //no lump sum pensions
		gen t42amt = 0 // no 401k distributions in core
		egen tdivinc = rowtotal(j110ri o110ri j110 o110) //same concepts as TMJNTDIV, TMOWNDIV, TMJADIV, TMOWNADV, TSJNTDIV, TSOWNDIV, TSJADIV, and TSOWNADV
		egen tintinc = rowtotal(j10003 o10003 j10407 o10407) //interest from all sources--but note adds item 107, "other" interest, relative to 1996+ SIPP
		bys lgtkey:  egen renroll = max(eenrlm)
		gen epndad = .
		recode epnguard (0=-1) (999=9999) //fix to match 96+ values
		recode epnmom (0=-1) (999=9999)
		recode epnspous (0 999=9999)
		gen eorigin = inrange(ethncty,14,20) //Hispanic origins
		gen byte eentaid = entry

		*drop "merged" households (see 2001 SIPP user guide, chapter 10, page 25)
		drop if pwentry > 0 & !mi(pwentry)
		//may be too restrictive, since drops even unduplicated ppl--but doesn't affect many households
	}

	****************
	*1980s panels
	if inrange(`year',1984,1989) {
		//special handling for changing variable names
		loc enroll "sc1656"
		if inlist(`year',1984,1985) loc enroll "" //exclude for the two years with no data

		loc birthvars "brthmn brthyr"
		if inlist(`year',1984,1985) loc birthvars "u_brthmn u_brthyr" 
		loc birthvars2 "`birthvars'"
		if `year'==1986 loc birthvars2 "u_brthmn u_brthyr" 

		loc prev_wave "mover_id sc0066 sc0068"
		loc prev_wave2 "mover_id sc0066 sc0068"
		if `year'==1984 loc prev_wave "prev_id sc0064 sc0066"
		if `year'==1985 {
		loc prev_wave "mover_id sc0066 sc0064" //order is switched in this year
		loc prev_wave2 "prev_id sc0064 sc0066"
		}
		if `year'==1986 loc prev_wave2 "mover_id sc0066 sc0064" 
		loc prev_wave1 ""
		if `num'>1 loc prev_wave1 "`prev_wave'" //exclude first waves

		loc fnlwgt "fnlwgt*"
		loc fnlwgt2 "fnlwgt*"
		if `year'==1989 loc fnlwgt "finalwgt*"

		loc reasleft "u_entlf*"
		if `year'==1984 loc reasleft "u_realft u_reaent"
		loc reasleft2 "`reasleft'"
		if `year'==1985 loc reasleft2 "u_realft u_reaent"
		loc reasleft1 "`reasleft'"
		if `year'==1985 loc reasleft1 "u_realft u_reaent"
		loc reasleft3 "`reasleft'" //special value for 3rd wave of list
		if `year'==1985 loc reasleft3 "u_reasn1 u_reasn2"

		#delimit ;
		loc keepvars "su_id pp_pnum h*_year h*_month h*_sampl pp_wave h*_hsc h*_strat h*_metro
			h*_state h*_addid f*_numbr f*_earn 
			age*
			sex race ethnicty rrp* ms* sc1460
			pnsp* pnpt* u_pngd 
			`enroll' h*_tenur
			h1itm36b pp_intvw
			pptotin* pp_earn* pp_prop* pp_tran* ppother* 
			i29amt* i30amt* i31amt* i32amt* i34amt* i35amt* i01amt* i05amt* wicval* i27amt* i02amt* i36amt* i38amt* i52amt* i55amt* i56amt* i37amt* i53amt* i54amt* 
			jdic110* odic110* jdir110* odir110*
			jint100* oint100* jint104* oint104*
			grd_cmpl higrade pp_entry 
			h*_msa
			f*_pov* sc1230 wksjb* esr* ws1_2012 ws1_2028 ws1_2024 ws1_ind ws1_occ"; 
		/* previous wave vars found via SIPP UG 2nd edition, p. 5-3 of "userguide_notes.pdf") */
		/* matches to 1990 vars as follows:
		suid pnum year month panel wave hhsc hstrat hmetro 
			hstate addid fid fearn fnlwgt
			age
			sex race ethncty rrp ms disab
			pnsp pnpt pngdu 
			enrold htenure 
			hitm36b intvw
			totinc earn prop tran other
			s30amt s31amt s32amt s34amt s35amt s01amta(+s01amtk) s05amt wicval s27amt
			j110ri o110ri j110 o110 
			grdcmpl higrade entry 
			hmsa
			fpov uhours wksjob esr ws12012 ws12028" ; 
			plus prev wave vars: (pwsuid pwentry pwpnum) and reasons left (realft reaent) 
		*/
		#delimit cr ; 

		*to allow use in intercooled stata: extract needed variables from files before appending
			*process all needed files, trimming variables
			loc first_nums = `num'
			loc last_nums = `num'+2
			if !inlist(`year',1989) loc last_nums = `num'+3
			forval k = `first_nums'/`last_nums' {
			loc reasleft_include "`reasleft'"
			loc prev_wave_include "`prev_wave'"
			if `k'==`num' {
			loc reasleft_include "`reasleft1'"
			loc prev_wave_include "`prev_wave1'"
			}
			if `k'==`num'+2 loc reasleft_include "`reasleft3'"
			use `keepvars' `birthvars' `fnlwgt' `reasleft_include' `prev_wave_include' using "`coreloc'/sipp`panel'_core`k'.dta", clear
			save $main/ctcPaper/sipp`panel'_trimmed`k', replace
			}
			if !inlist(`year',1984) {
			loc first_nums2 = `num2'
			loc last_nums2 = `num2'+2
			if !inlist(`year',1989) loc last_nums2 = `num2'+3
			forval k = `first_nums2'/`last_nums2' {
			use `keepvars' `birthvars2' `fnlwgt2' `reasleft2' `prev_wave2' using "`coreloc'/sipp`panel2'_core`k'.dta", clear
			save $main/ctcPaper/sipp`panel2'_trimmed`k', replace
			}
			}

			use $main/ctcPaper/sipp`panel'_trimmed`num', clear
			append using "$main/ctcPaper/sipp`panel'_trimmed`++num'", keep( `keepvars' `birthvars' `fnlwgt' `reasleft' `prev_wave') nolabel nonotes
			append using "$main/ctcPaper/sipp`panel'_trimmed`++num'", keep( `keepvars' `birthvars' `fnlwgt' `reasleft3' `prev_wave') nolabel nonotes
			if !inlist(`year',1989)  append using "$main/ctcPaper/sipp`panel'_trimmed`++num'", keep( `keepvars' `birthvars' `fnlwgt' `reasleft' `prev_wave') nolabel nonotes //short periods (end of panel)
			if !inlist(`year',1984) {
			append using "$main/ctcPaper/sipp`panel2'_trimmed`num2'", keep( `keepvars' `birthvars2' `fnlwgt2' `reasleft2' `prev_wave2') nolabel nonotes //overlapping panels
			append using "$main/ctcPaper/sipp`panel2'_trimmed`++num2'", keep( `keepvars' `birthvars2' `fnlwgt2' `reasleft2' `prev_wave2') nolabel nonotes
			append using "$main/ctcPaper/sipp`panel2'_trimmed`++num2'", keep( `keepvars' `birthvars2' `fnlwgt2' `reasleft2' `prev_wave2') nolabel nonotes
			if !inlist(`year',1989) append using "$main/ctcPaper/sipp`panel2'_trimmed`++num2'", keep( `keepvars' `reasleft2' `birthvars2' `fnlwgt2' `prev_wave2') nolabel nonotes //short panel in 1989
			}
		* end extraction

		loc fn89 ""
		if `year'==1989 {
		//split up weights
		gen double finalwgt_1 = real(substr(finalwgt,1,10))
		gen double finalwgt_2 = real(substr(finalwgt,11,10))
		gen double finalwgt_3 = real(substr(finalwgt,21,10))
		gen double finalwgt_4 = real(substr(finalwgt,31,10))
		gen double finalwgt_5 = real(substr(finalwgt,41,10))
		loc fn89 "finalwgt_@"
		}

		if `year'==1984 rename (f1_povd f2_povd f3_povd f4_povd) (f1_pov f2_pov f3_pov f4_pov)
		if `year'==1985 {
			forv i = 1/4 {
				replace f`i'_pov = f`i'_povd if mi(f`i'_pov)
				drop f`i'_povd
			}
		}

		*reshape file
		#delimit ;
		reshape long  h@_year h@_month h@_sampl h@_hsc h@_strat h@_metro
			h@_state h@_addid f@_numbr f@_earn fnlwgt_@ `fn89'
			age_@ rrp_@ ms_@ pnsp_@ pnpt_@ h@_tenur
			pptotin@ pp_earn@ pp_prop@ pp_tran@ ppother@ 
			i29amt@ i30amt@ i31amt@ i32amt@ i34amt@ i35amt@ i01amt@ i05amt@ wicval@ i27amt@ i02amt@ i36amt@ i38amt@ i52amt@ i55amt@ i56amt@  i37amt@ i53amt@ i54amt@   
			jdir110@ odir110@ jdic110@ odic110@ h@_msa
			jint100@ oint100@ jint104@ oint104@
			f@_pov wksjb@ esr_@,
			i(su_id pp_entry pp_pnum pp_wave)
			j(srefmon) ;
		#delimit cr ; 

		drop if srefmon==5 //remove values for "interview month"


		//fix differences between years
		if inlist(`year',1984,1985) {
			gen sc1656 = .
			drop ws1_2024 //this code refers to hours per week at job for these waves
			gen ws1_2024 = .
		}
		if `year'==1984 rename (prev_id sc0064 sc0066 u_brthmn u_brthyr) (pwsuid pwentry pwpnum brthmn brthyr)
		else if `year'==1985 {
		gen double pwsuid = mover_id
		replace pwsuid = prev_id if h_sampl==84
		gen pwentry = sc0066
		replace pwentry = sc0064 if h_sampl==84
		gen pwpnum = sc0064
		replace pwpnum = sc0066 if h_sampl==84
		drop mover_id prev_id sc0066 sc0064
		rename (u_brthmn u_brthyr) (brthmn brthyr)
		}
		else if `year'==1986 {
		ren (mover_id sc0066) (pwsuid pwentry)
		gen pwpnum = sc0068
		replace pwpnum = sc0064 if h_sampl==85
		replace brthmn = u_brthmn if h_sampl==85
		replace brthyr = u_brthyr if h_sampl==85
		drop sc0064 u_brthmn u_brthyr
		}
		else rename (mover_id sc0066 sc0068) (pwsuid pwentry pwpnum)
		if `year'==1989 {
		replace fnlwgt_ = finalwgt_ if h_sampl==89
		}

		ren h_sampl panel 
		ren h_month month
		ren fnlwgt_ fnlwgt
		drop if panel==0 //remove ppl who left sample in a month

		gen rhcalyr = real("19"+string(h_year))   //edit to four digits

		keep if rhcalyr==`year'

		*get longitudinal weights 
		if `year'==1989 gen lgtwt = . //no calendar year weight in 1989 panel
		else {
		merge m:1 panel su_id pp_entry pp_pnum using $main/lgt/`wtfile'.dta, keepusing(`wt') nogen keep(1 3)
		if `year'==1984 ren `wt' lgtwt //1984 only has one panel
		else {
		merge m:1 panel su_id pp_entry pp_pnum using $main/lgt/`wtfile2'.dta, keepusing(`wt') nogen update keep(1 3 4 5)
		ren `wt' lgtwt
		}
		}
		//adjust weights for overlapping panels, per Table 8-9 in SIPP user's guide
		if "`panel2'"!="" {
		ren lgtwt lgtwt_orig
		ren  fnlwgt fnlwgt_orig
		gen double fnlwgt = fnlwgt_orig
		gen double lgtwt = lgtwt_orig
		count if panel==`panel2' & month==12 //do adjustment based on December
		loc r1 = `r(N)'
		count if panel==`panel' & month==12 //do adjustment based on December
		loc r2 = `r(N)'
		loc wtmod = `r1' / (`r1'+`r2')
		di "Wt of `panel2' in `year' = `wtmod'"
		replace lgtwt = lgtwt_orig * `wtmod' if (panel==`panel2') 
		replace lgtwt = lgtwt_orig * (1-`wtmod') if (panel==`panel') 
		replace fnlwgt = fnlwgt_orig * `wtmod' if (panel==`panel2') 
		replace fnlwgt = fnlwgt_orig * (1-`wtmod') if (panel==`panel') 
		}



		*make longitudinal key
		gen double suid = su_id
		gen pnum = pp_pnum
		gen byte entry = pp_entry
		sort panel suid entry pnum
		format suid %12.0f
		egen double lgtkey = group(panel suid entry pnum)
		gen spanel = real("19"+string(panel))
		egen ssuidi = concat(panel suid entry), format(%16.0f)
		gen double ssuid = real(ssuidi)
		drop ssuidi
		format ssuid %12.0f
		gen epppnum = pnum

		*fix missing values for income
		foreach var in i29amt i30amt i31amt i32amt i34amt i35amt i01amt i05amt jdic110 odic110 jdir110 odir110 jint100 oint100 jint104 oint104 i27amt i02amt i36amt i38amt i52amt i55amt i56amt i37amt i53amt i54amt {
		replace `var' = 0 if `var'==-9
		}

		*rename to 1996 or 1990 names
		//follows values used for 1990s
		#delimit ;
		rename (month pp_wave h_hsc h_strat h_metro
			h_state h_addid f_numbr f_earn fnlwgt
			age_ brthmn brthyr
			sex race rrp_ ms_ sc1460
			pnsp_ pnpt_ u_pngd 
			sc1656 h_tenur
			h1itm36b pp_intvw
			pptotin pp_earn pp_prop pp_tran ppother 
			i29amt i30amt i31amt i32amt i34amt i35amt i01amt i05amt i27amt i02amt i36amt i38amt i52amt i55amt i56amt i37amt i53amt i54amt 
			ethnicty grd_cmpl h_msa jdic110 odic110 jdir110 odir110
			jint100 oint100 jint104 oint104
			f_pov sc1230 wksjb esr_ ws1_2012 ws1_2028 ws1_2024 ws1_ind ws1_occ)
			(rhcalmn swave ghlfsam gvarstr tmetro
			tfipsst shhadid rfid tfearn wpfinwgt 
			tage ebmnth tbyear 
			esex erace errp ems edisabl 
			epnspous epnmom epnguard 
			eenrlm  etenure 
			eoutcome eppintvw
			tptotinc tpearn tpprpinc tptrninc tpothinc  
			t29amt t30amt t31amt t32amt t34amt t35amt t01amta t05amt t27amt t02amt t36amt t38amt t52amt t55amt t56amt t37amt t53amt t54amt     
			ethncty grdcmpl hmsa j110ri o110ri j110 o110 
			j10003 o10003 j10407 o10407
			rfpov ehrsall rmwkwjb rmesr eclwrk1 tpyrate1 ersend1 ejbind1 tjbocc1);
		#delimit cr ; 
		*make versions of missing 1996 vars
		gen t25amt = wicval / 100
		gen t39amt = 0 //no lump sum retirement question asked
		gen t42amt = 0 //no 401k distributions in core
		egen tdivinc = rowtotal(j110ri o110ri j110 o110) //same as 1990s
		egen tintinc = rowtotal(j10003 o10003 j10407 o10407) //same as 1990s
		gen t01amtk = 0 //full amount of Soc Sec is in adult value
		bys lgtkey:  egen renroll = max(eenrlm)
		gen epndad = .
		recode epnguard (0=-1) (999=9999) //fix to match 96+ values
		recode epnmom (0=-1) (999=9999)
		recode epnspous (0 999=9999)
		gen eorigin = inrange(ethncty,14,20) //Hispanic origins
		gen byte eentaid = entry
		replace ebmnth = . if ebmnth==-9 | ebmnth==0 //fix odd month values


		*drop "merged" households (see 2001 SIPP user guide, chapter 10, page 25)
		drop if pwentry > 0 & !mi(pwentry)
		//may be too restrictive, since drops even unduplicated ppl--but doesn't affect many households
	}

	****************
	***begin code for all years***

	order lgtkey ssuid epppnum 
	sort lgtkey rhcalyr rhcalmn
	gen wt = wpfinwgt //monthly weight for Dec
	svyset ghlfsam [pw=wt], strata(gvarstr)

	*sum up earnings values 
	bys lgtkey: egen fearn = total(tfearn) //value for families
	bys lgtkey: egen pearn = total(tpearn) 
	//note these include negative values
	//and aren't counting months when ppl are not in sample

	*sum up income values for tax simulation
	bys lgtkey: egen dividends = total(tdivinc) 
	bys lgtkey: egen intrec = total(tintinc) 
	egen nonpr = rowtotal(t29amt t52amt t53amt t54amt t55amt t56amt) //non-property--currently, just alimony, roomers, Nat Guard, occasional and misc income; could include IRA contrib? etc.
	bys lgtkey: egen nonprop = total(nonpr) 
	gen negdiv = - tdivinc
	gen negint = - tintinc
	egen othpr = rowtotal(tpprpinc negdiv negint t36amt t37amt) //includes annuities / life ins, and estates/trusts
	bys lgtkey: egen otherprop	 = total(othpr) 
	egen pen = rowtotal(t30amt t31amt t32amt t34amt t35amt t38amt t39amt t42amt) //note not excluding Keogh, since almost no respondents for tatkeogh in tax module. 
	bys lgtkey: egen pensions = total(pen) 
	egen soc = rowtotal(t01amta t01amtk t02amt)
	bys lgtkey: egen gssi = total(soc) 
	bys lgtkey: egen transfers = total(tptrninc) 
	bys lgtkey: egen ui = total(t05amt) 
	/*
	 - excluding: non-cash, t50amt (charity), t51amt (gifts), 
	 -  Note that pension amounts listed may not be for retirement... may be disability
	Issues:
	 -   t36amt (life ins / annuity) - life ins may not be taxable, annuity is
	 -   t38amt (other retirement/disab/survivor--can't tell if taxable), 
	 -   t02amt (treating RR as social security - in reality, only tier 1 taxed the same way). Also assuming all is retirement (not disab or survivors); could fix with rrrsn==2 (1996+ only)
	 -   t52amt (non-pension or severance lump sum) (pre 1996, all lump sums classified here)
	 -   t53amt (roomers/boarders) - deleted in 2004-2008
	 -   t37amt (not in all years--estates and trust survivors income)
	 -   t54amt (National Guard income), not in all years

	 checks:
	 -  egen taxable = rowtotal(pearn dividends intrec nonprop otherprop pensions gssi transfers ui)
	 -  br taxable totalinc tptotinc tpearn tpprpinc tpothinc  tptrninc tpscininc severance pearn dividends intrec nonprop otherprop pensions gssi transfers ui t01amta t01amtk t02amt if taxable != totalinc
	*/

	*sum up other income values
	bys lgtkey: egen totalinc = total(tptotinc)
	egen noncsh = rowtotal(t25amt t27amt) //food stamps and wic; note doesn't include liheap, housing subsidies, child care, health insurance
	bys lgtkey: egen noncash = total(noncsh)

	drop nonpr othpr soc pen noncsh negdiv negint 

	*total months in sample
	gen co = 1
	bys lgtkey: egen months_obs = total(co)
	drop co

	*demographics
	gen race = erace
	replace race = 4 if race==3
	replace race = 3 if eorigin==1
	lab def race_cat 1 "White" 2 "Black" 3 "Hispanic" 4 "Other"
	lab val race race_cat

	if `year'>=1996 {
		recode eeducate (-1=.) (31/38=1) (39=2) (40/43=3) (44=4) (45/47=5), gen(educ)
		lab def educ 1 "<HS" 2 "HS Grad" 3 "Some College" 4 "College Grad" 5 "Advanced"
		lab val educ educ
	}
	else {
		//codes based on http://ceprdata.org/wp-content/cps/programs/march/cepr_march_educ.do
		recode higrade (0/11=1) (12=2) (21/23=3) (24=4) (25/26=5), gen(educ)
		replace educ = . if tage<15 //not applicable for under 15 year olds
		replace educ = 1 if higrade==12 & grdcmpl==2 //didn't complete HS
		replace educ = 3 if higrade==16 & grdcmpl==2 //didn't complete college
		lab def educ 1 "<HS" 2 "HS Grad" 3 "Some College" 4 "College Grad" 5 "Advanced"
		lab val educ educ
	}

	recode ems (1=2) (2/5=3) (6=1), gen(mar)
	lab def mar 1 "Single" 2 "Married" 3 "Sep/Div/Wid"
	lab val mar mar

	gen female = esex==2

	save $main/ctcPaper/cy`y'.dta, replace
	timer off 1
	timer list

	loc last_archive "`archive'"
}
cd "$main/core"
shell `rmdir' "sippArchive`archive'/" //remove final directory
log close prepare_data
*end main calendar year files

* combine 2013 files into one year
use $main/ctcPaper/cy13a, clear
tostring shhadid, replace force
save $main/ctcPaper/cy13a, replace

use $main/ctcPaper/cy13b, clear
append using $main/ctcPaper/cy13a
save $main/ctcPaper/cy13, replace


*prepare spd files
log using $main/ctcPaper/prepare_spd.log, replace name(prepare_spd)
loc archive "90-93"
cap confirm file "$main/core/sippArchive`archive'/"
if _rc!=0 {
	cap mkdir sippArchive`archive'
	cd sippArchive`archive'
	unzipfile "../sippArchive`archive'.zip" 
}
//clear up space in archive directory
cd "$main/core/sippArchive90-93/"
foreach yr in 90 91 {
	loc d : dir "$main/core/sippArchive90-93/" files "sipp`yr'_core*.dta"
	foreach file of local d {
		cap erase `file'
	}
}
cap confirm file "$main/lgt/spd/spd_long.dta"
if _rc!=0 {
	cd "$main/lgt/spd"
	unzipfile spd_long.zip 
	cd "$main/core"
}

foreach year in 1996 1997 1998 1999 2000 2001 {

	*loc year 1996 //uncomment to run specific years

	*use longitudinal file
	loc endyr = substr("`=`year'+1'",-1,1)
	if `year'==2001 loc endyr = "x" 
	loc yr = substr("`=`year'+1'",-2,2)
	loc keeplist "pp_id-natvtyi ihhkey`yr' *`endyr'"  //get vars based on name (ending indicates year of data)
	use `keeplist' using "$main/lgt/spd/spd_long", clear

	//fix names to remove ending for year
	ren ihhkey`yr' ihhkey
	if `year' < 2001 ren spdtlw01 wgt
	else ren spdtlw02 wgt
	ren sample98 samp_spd
	ren sex mf //to deal with "x" ending
	drop spd* //remove weights
	ren *`endyr' *
	ren mf sex
	ren samp_spd sample98

	ren (sipp_pnl pp_id pp_pnum pp_entry) (panel suid pnum entry)

	*make longitudinal key
	sort panel suid entry pnum
	format suid %12.0f
	gen spanel = panel //already has "19" portion
	replace panel = real(substr(string(spanel),-2,2))
	egen double lgtkey = group(panel suid entry pnum)
		//changed: value was too long to concatenate
	egen ssuidi = concat(panel suid entry), format(%16.0f)
	gen double ssuid = real(ssuidi)
	drop  ssuidi
	format ssuid %12.0f
	gen epppnum = pnum
	gen month = 12
	gen refmth = 1
	merge 1:1 panel suid pnum entry refmth using "$main/core/sippArchive90-93/sipp92_core1.dta", gen(merge92) keepusing(brthmn brthyr  htype ) 
	drop if merge92==2
	merge 1:1 panel suid pnum entry refmth using "$main/core/sippArchive90-93/sipp93_core1.dta", gen(merge93) keepusing(brthmn brthyr htype  ) nolabel
	drop if merge93==2
	//some unmatched--presumably those who joined sample later
		//they will have missing birth months
	tab merge*
	summ wgt if merge92==1 & merge93==1 //all have no longitudinal weight

	if `year'>1997 loc ptxamtt "ptxamtt"
	else loc ptxamtt ""
	if `year'>1996 loc hscollr "hscollr"
	else loc hscollr ""
	keep ssuid epppnum spanel lgtkey panel suid pnum entry refmth merge* ///
		month  refmth halfsamp varstrat  stfipsr addide famnume fernvlr wgt aget brthmn brthyr sex race rrpe maritle dishpe spousee  despare  tenuree ptotvlr pernvlr  pothvlr almvalt ssvalt ucvalt hfdvalr finvalt  intvalt divvalt htype povcute ulprespd  hrswke wkswrke clwkr  rsnotwe indusr occupe hgar ///
		oivalt oioffe numperr retvl1t retsc1e retvl2t retsc2e `hscollr' rntvalt ssivalt vetvalt pawvalt origin natvty dobyrt `ptxamtt' lkwkse nwlkwke


	*rename to 1996 names
	#delimit ;
	rename (month  refmth halfsamp varstrat  
		stfipsr addide famnume fernvlr wgt
		aget brthmn brthyr 
		sex race rrpe maritle dishpe
		spousee  despare 
		tenuree 
		ptotvlr pernvlr  pothvlr
		almvalt ssvalt ucvalt hfdvalr finvalt 
		intvalt divvalt
		htype povcute ulprespd  hrswke wkswrke clwkr  rsnotwe indusr occupe hgar)
		(rhcalmn  srefmon ghlfsam gvarstr 
		tfipsst shhadid rfid tfearn wpfinwgt 
		tage ebmnth tbyear 
		esex erace  errp ems edisabl 
		epnspous  epnguard 
		etenure 
		tptotinc tpearn  tpothinc  
		t29amt t01amta t05amt t27amt t51amt
		tintinc tdivinc
		rhtype rfpov ulftmain  ehrsall rmwkwjb  eclwrk1  ersend1 ejbind1 tjbocc1 eeducate);
	#delimit cr ; 
	/* missing variables:
	pnpt enrold hitm36b intvw prop tran 
	epnmom eenrlm eoutcome eppintvw tpprpinc tptrninc t55amt   t52amt  t53amt t54amt uentmain rmesr tpyrate1 tehc_metro
	* want to add: famknde citshpe nwlkwke lkwkse lkstrhe pyrsne ?
	*/
	*retirement vars 
	forval i = 1/8 {
	if `i'<4 loc j = `i'-1
	else loc j = `i'
	gen t3`j'amt = retvl1t*cond(retsc1e==`i',1,0) + retvl2t*cond(retsc2e==`i',1,0) 
	//works because retirement sources are mutually exclusive
	}
	ren t37amt t42amt //401k / IRA listed under this, rather than trusts
	ren t35amt t02amt //railroad retirement
	gen t35amt = 0 //can't separate state and local pension
	gen t37amt = oivalt * cond(oioffe==8,1,0) //estates/trusts 
	notes t37amt: Created from "other income"
	gen t56amt = oivalt * cond(oioffe==19,1,0) //group "anything else" with cash
	notes t56amt: Created from "other income"

	replace t27amt = t27amt / numperr //make food stamps be person level by dividing by household size

	//add in "other" income
	replace t01amta = t01amta + oivalt * cond(oioffe==1,1,0)
	replace t30amt = t30amt + oivalt * cond(oioffe==2,1,0)
	replace t36amt = t36amt + oivalt * cond(oioffe==13,1,0)

	//make aggregate amounts - found sources for aggregates in 1993 SIPP tech docs, Appendix A-2
	gen tpprpinc = tintinc + tdivinc + rntvalt + oivalt * cond(inlist(oioffe,5,6,7),1,0)
	gen tptrninc = ssivalt + vetvalt + pawvalt 
	replace tpearn = tpearn + oivalt * cond(oioffe==16,1,0)
	replace tpothinc = tpothinc - tpprpinc - tptrninc -  oivalt * cond(oioffe==16,1,0) //remove other income sources from total "other"

	*make versions of missing 1996 vars
	gen t25amt = 0 //no WIC
	gen t39amt = 0 //no lump sum pensions
	gen t01amtk = . //no kid soc sec
	foreach var in t55amt  t52amt  t53amt t54amt {
	gen `var'=.
	}
	if `year'>1996 gen renroll = inlist(hscollr,1,2) //ref period is last school year, rather than 4 months
	else gen renroll = .

	gen epndad = .
	gen epnmom = .
	recode epnspous (0 =9999)

	gen eorigin = inrange(origin,1,7) //Hispanic origins
	gen byte eentaid = entry
	replace edisabl = -1 if edisabl==0 //change NIU code

	gen rhcalyr = `year'

	***start all years CY code***

	order lgtkey ssuid epppnum 
	sort lgtkey rhcalyr rhcalmn
	gen wt = wpfinwgt 

	//survey set
	svyset ghlfsam [pw=wt], strata(gvarstr)

	*sum up earnings values 
	bys lgtkey: egen fearn = total(tfearn) //value for families
	bys lgtkey: egen pearn = total(tpearn) 

	*sum up income values for tax simulation
	bys lgtkey: egen dividends = total(tdivinc) 
	bys lgtkey: egen intrec = total(tintinc) 
	egen nonpr = rowtotal(t29amt t52amt t53amt t54amt t55amt t56amt) //non-property--currently, just alimony, roomers, Nat Guard, occasional and misc income; could include IRA contrib? etc.
	bys lgtkey: egen nonprop = total(nonpr) 
	gen negdiv = - tdivinc
	gen negint = - tintinc
	egen othpr = rowtotal(tpprpinc negdiv negint t36amt t37amt) //includes annuities / life ins, and estates/trusts
	bys lgtkey: egen otherprop	 = total(othpr) 
	egen pen = rowtotal(t30amt t31amt t32amt t34amt t35amt t38amt t39amt t42amt) //note not excluding Keogh, since almost no repondents for tatkeogh in tax module. Added t38amt
	bys lgtkey: egen pensions = total(pen) 
	egen soc = rowtotal(t01amta t01amtk t02amt)
	bys lgtkey: egen gssi = total(soc) 
	bys lgtkey: egen transfers = total(tptrninc) 
	bys lgtkey: egen ui = total(t05amt) 

	*sum up other income values
	bys lgtkey: egen totalinc = total(tptotinc)
	egen noncsh = rowtotal(t25amt t27amt) //food stamps and wic; excludes liheap, housing subsidies, child care, health ins
	bys lgtkey: egen noncash = total(noncsh)

	drop nonpr othpr soc pen noncsh negdiv negint 

	*total months in sample
	gen months_obs = 12 //annual data

	*demographics
	gen race = erace
	replace race = 4 if race==3
	replace race = 3 if eorigin==1
	lab def race_cat 1 "White" 2 "Black" 3 "Hispanic" 4 "Other"
	lab val race race_cat

	//education: close to post-1996 values
	recode eeducate (0=.) (31/38=1) (39=2) (40/42=3) (43=4) (44/46=5), gen(educ)
	lab def educ 1 "<HS" 2 "HS Grad" 3 "Some College" 4 "College Grad" 5 "Advanced"
	lab val educ educ

	recode ems (1=2) (2/5=3) (6=1), gen(mar)
	lab def mar 1 "Single" 2 "Married" 3 "Sep/Div/Wid"
	lab val mar mar

	gen female = esex==2


	save $main/ctcPaper/spd_`year', replace

}
cd "$main/core/"
shell `rmdir' "sippArchive90-93/" //remove directory
erase "$main/lgt/spd/spd_long.dta"
log close prepare_spd





