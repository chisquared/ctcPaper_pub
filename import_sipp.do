*Code to import raw Census SIPP files to Stata format

version 15.1

*adjust file rename command based on operating system
loc mv "mv"
if c(os)=="Windows" loc mv "ren" 

*main directory
cd "$main"

*time the script
timer clear
timer on 1
//note: takes about 4 hours to do everything except SPD (on a core i5 machine, 8GB RAM) 

****2014 data****
cd "$main/core/"

forval wave = 1/4 {
	
	*loc wave = 4

	*create base dictionary files from Excel and SAS dictionaries
	//SAS dictionary
	insheet using pu2014w`wave'.sas, delimit(" ") clear
	if `wave'==1 { //fix extra spaces at end of first wave file
	replace v4 = string(v12) in 5228
	replace v6 = v14 in 5228
	replace v4 = string(v7) in 5229/5230
	replace v6 = real(v9) in 5229/5230
	replace v4 = string(v7) in 5232/5233
	replace v6 = real(v9) in 5232/5233
	replace v4 = v8 in 5234
	replace v6 = v10 in 5234
	drop v7-v14
	}
	drop in 1/5 //remove header
	drop in -2/-1 //remove footer

	drop v2 v5
	ren v1 varname 
	ren v3 is_string
	ren v4 start 
	ren v6 end
	save pu2014w`wave'_sas.dta, replace

	//Excel dictionary
	import excel "$main/core/2014SIPP_W`wave'_Metadata_AllSections.xlsx", firstrow clear
	ren Name varname
	ren Topic SectionName //name used in v1.0 wave1 file

	replace StatusFlag = trim(StatusFlag)
	preserve
	//pull out status flags
	ren varname flagFor
	ren StatusFlag varname
	keep varname flagFor SectionName
	drop if mi(varname)
	duplicates drop varname, force //remove multiple variables referring to same flag
	save pu2014w`wave'_flaglist, replace
	restore
	append using pu2014w`wave'_flaglist
	replace Length = 1 if mi(Length)
	gen flag = !mi(flagFor)
	replace Description = "Allocation Flag for " + flagFor if flag==1
	merge 1:1 varname using pu2014w`wave'_sas, gen(sas_merge)
	destring start, replace
	li varname start end if sas_merge==2
	drop if sas_merge==2 //length is zero... so not in SAS file
	drop if sas_merge==1 //some flags not in sas file
	//fix string vars
	li varname Min Max if !mi(is_string)
	replace is_string="" if !inlist(varname,"EHRESIDENCID","ERESIDENCEID") //no strings necessary except for residence vars
	sort start
	save pu2014w`wave'_dctsource, replace



	*create separate dictionary and label files for six file chunks: Labor Force (2 parts), Assets, Programs, Health Insurance, and everything else
	forval q = 1/6 {
	use pu2014w`wave'_dctsource, clear
	sort start
	if `q'==1 drop if SectionName=="Labor Force" | SectionName=="Assets" | SectionName=="Programs"  | SectionName=="Health Insurance and Expenses" | SectionName=="Health Insurance" | SectionName=="Health Care"
	if `wave'==1 loc labsplit = 5797
	if `wave'==2 loc labsplit = 8485
	if `wave'==3 loc labsplit = 8496
	if `wave'==4 loc labsplit = 8493
	if `q'==2 keep if (SectionName=="Labor Force" & start<  `labsplit') | SectionName=="ID Variables" //split at question about commuting to work
	if `q'==3 keep if (SectionName=="Labor Force" & start>= `labsplit') | SectionName=="ID Variables"
	if `q'==4 keep if SectionName=="Assets" | SectionName=="ID Variables"
	if `q'==5 keep if SectionName=="Programs" | SectionName=="ID Variables"
	if `q'==6 keep if SectionName=="Health Insurance and Expenses" | SectionName=="ID Variables" | SectionName=="Health Insurance" | SectionName=="Health Care"

	//write dictionary file
	cap file close dict
	file open dict using pu2014w`wave'_`q'.dct, write replace
	file write dict "infile dictionary using pu2014w`wave'.dat {" _n
	file write dict "* Source: 2014SIPP`stub'_Metadata_AllSections.xlsx and pu2014w`wave'.sas" _n
	if `q'==1 loc des "All Except Labor Force, Assets, Programs, Health Insurance"
	if `q'==2 loc des "Labor Force, First Half Only"
	if `q'==3 loc des "Labor Force, Second Half Only"
	if `q'==4 loc des "Assets Only"
	if `q'==5 loc des "Programs Only"
	if `q'==6 loc des "Health Insurance Only"
	file write dict "* Section `q': `des'" _n
	loc bigN = _N
	forval i = 1/`bigN' { //loop through each variable
	loc start = start[`i']
	loc varname = lower(varname[`i'])
	loc length = Length[`i']
	loc sf = cond(is_string[`i']=="$","s","f")
	if "`sf'"=="s" loc type " str`length'"
	else if `length' > 7 loc type " double" //long variables as doubles
	else if `length' < 3 loc type " byte"
	else if `length' < 5 loc type " int"
	else loc type ""
	loc label = trim(substr(subinstr(subinstr(subinstr(Description[`i'],char(10),"",.),char(13),"",.),char(34),"'",.),1,80)) //limit to 80 characters, remove newlines and CR, and quotes 
	file write dict `"_column(`start')`type' `varname' %`length'`sf' "`label'" "' _n
	}
	file write dict "}" _n
	file close dict

	//write execution, label, and notes file
	cap file close do
	file open do using pu2014w`wave'_`q'.do, write replace
	file write do "infile using pu2014w`wave'_`q'.dct, clear" _n
	//write status flag label
	file write do `"lab def status_flag 0 "Not in universe" 1 "In universe, as reported" 2 "Statistical imputation (hot- deck)" 3 "Logical imputation" 4 "Model-based imputation" 5 "Cold-deck value imputation" 6 "Imputed from a range" 7 "Combination of 1 and 2/3/5/6" 8 "Combination of 2/3/5/6" 9 "Can be determined from the allocation flags for the components of this recode", modify"' _n
	loc bigN = _N
	forval i = 1/`bigN' { //loop through each variable
	loc varname = lower(varname[`i'])
	loc description = trim(subinstr(subinstr(Description[`i'],char(10),"",.),char(13),"",.)) //remove newlines
	file write do "********`varname'**********;" _n
	file write do `"notes `varname': `description'"' _n
	if flag[`i']!=1 { //don't describe universe for flags
		loc universe = trim(subinstr(subinstr(UniverseDescription[`i'],char(10),"",.),char(13),"",.)) //remove newlines
		if Universe[`i']!="" {
			loc universeformula = "(" + trim(subinstr(subinstr(Universe[`i'],char(10),"",.),char(13),"",.)) + ")" //remove newlines
		}
		file write do `"notes `varname': Universe: `universe' `universeformula'"' _n
	}
	if flag[`i']==1 { //write flag labels
		file write do "lab val `varname' status_flag " _n
	}
	else { //write labels
	loc labels = trim(AnswerList[`i'])
	if `"`labels'"'!="" {
		file write do `"notes `varname': Labels:"' _n 
		//parse label list by newlines
		loc labprocess = subinstr(subinstr(`"`labels'"'," ","|",.),char(13),"",.) //remove spaces and CRs
		loc newline = char(10)
		loc labtrans : subinstr loc labprocess "`newline'" " " , all count(loc linecount)  //replace newlines with spaces
		forval l = 1/`linecount' {
			loc labpart : word `l' of `labtrans' //split by spaces
			loc labprint : subinstr loc labpart "|" " ", all //substitue back to spaces
			file write do `"notes `varname':     `labprint' "' _n
		}
		if regexm(`"`labels'"',"101:499")!=1 & regexm(`"`labels'"',"101-499")!=1 & regexm(`"`labels'"',"1 - 999")!=1 ///
			& regexm(`"`labels'"',"1-6")!=1 & regexm(`"`labels'"',"\\$1: \\$9,999,999")!=1 ///
			& regexm(`"`labels'"',"\\$1:\\$9,999,999")!=1  & regexm(`"`labels'"',"\\$1:\\$999,999,999")!=1 ///
			& regexm(`"`labels'"',"1%:100%")!=1 { 	//don't add labels if they refer to a range
			forval l = 1/`linecount' {
				loc labpart : word `l' of `labtrans' //split by spaces
				loc labprint : subinstr loc labpart "|" " ", all //substitue back to spaces
				loc labquote : subinstr loc labprint ". " `" ""' //change first period to quote
				file write do `"lab def `varname'_lbl `labquote'", modify"' _n
			}
			//write the label definition
			file write do "lab val `varname' `varname'_lbl " _n
		}
	}
	}
	}
	//closing code
	file write do "compress" _n
	file close do
}


*import the data
set more off

if c(version)>=16 unzipfile pu2014w`wave'_dat.zip 
//unzipfile doesn't work in earlier versions for some reason... file probably too large. Must do manually via shell. ('tar' works for Mac, Unix, and Windows 10)
else shell tar -xf pu2014w`wave'_dat.zip

forval i = 1/6 {
	do pu2014w`wave'_`i'.do
	save pu2014w`wave'_`i'.dta, replace
}

erase pu2014w`wave'.dat //clean up to save space


*zip Stata files to save space
loc year = 12+`wave'
zipfile pu2014w`wave'_*.dta, saving(sippArchive`year')
forval i = 1/6 {
	erase pu2014w`wave'_`i'.dta
}

}


****2008 data****
* about 10 min

*create core files
cd "$main/core/"

forv i = 1/10 {
clear
unzipfile l08puw`i'.zip, replace
ddf2dct using l08puw1d.txt, data(l08puw`i'.dat) do(infile_core08_`i'.do) dct(infile_core08_`i'.dct) replace
do infile_core08_`i'.do
save sipp08_core`i'.dta, replace
cap erase l08puw`i'.dat //clean up to save space
}

*wave 11+ use different data dictionary
forv i = 11/16 {
clear
unzipfile l08puw`i'.zip, replace
ddf2dct using l08w11d.txt, data(l08puw`i'.dat) do(infile_core08_`i'.do) dct(infile_core08_`i'.dct) replace
do infile_core08_`i'.do
save sipp08_core`i'.dta, replace
cap erase l08puw`i'.dat //clean up to save space
}
*zip Stata files to save space
zipfile sipp08_core*.dta, saving(sippArchive08)
forval i = 1/16 {
	erase sipp08_core`i'.dta
}


*create tm files 
cd "$main/topical/"
foreach i in 2 4 5 6 7 8 10 {
clear
unzipfile p08putm`i'.zip, replace
ddf2dct using p08tm`i'd.txt, data(p08putm`i'.dat) do(infile_tm08_`i'.do) dct(infile_tm08_`i'.dct) replace
do infile_tm08_`i'.do
save sipp08_tm`i'.dta, replace
cap erase p08putm`i'.dat //clean up to save space
}


*create longitudinal weights
cd "$main/lgt/"
*weights through 2016
clear
unzipfile lgtwgt2008w16.zip, replace
ddf2dct using lgtwgt2008w16.txt, data(lgtwgt2008w16.dat) do(lgtwgt2008w16.do) dct(lgtwgt2008w16.dct) replace
do lgtwgt2008w16.do
save lgtwgt2008w16.dta, replace
cap erase lgtwgt2008w16.dat





****2004 data****
cd "$main/core/"
forv i = 1/12 {
clear
unzipfile l04puw`i'.zip, replace
ddf2dct using l04puw1d.txt, data(l04puw`i'.dat) do(infile_core04_`i'.do) dct(infile_core04_`i'.dct) replace
do infile_core04_`i'.do
save sipp04_core`i'.dta, replace
cap erase l04puw`i'.dat //clean up to save space
}
*zip Stata files to save space
zipfile sipp04_core*.dta, saving(sippArchive04)
forval i = 1/12 {
	erase sipp04_core`i'.dta
}


cd "$main/topical/"
foreach i in 3 4 6 7 {
clear
unzipfile p04putm`i'.zip, replace
ddf2dct using p04tm`i'd.txt, data(p04putm`i'.dat) do(infile_tm04_`i'.do) dct(infile_tm04_`i'.dct) replace
do infile_tm04_`i'.do
save sipp04_tm`i'.dta, replace
cap erase p04putm`i'.dat //clean up to save space
}


cd "$main/lgt/"
clear
unzipfile lgtwgt2004w12.zip, replace
ddf2dct using lgt04w12d.txt, data(lgtwgt2004w12.dat) do(lgtwgt2004w12.do) dct(lgtwgt2004w12.dct) replace
do lgtwgt2004w12.do
save lgtwgt2004w12.dta, replace
cap erase lgtwgt2004w12.dat //clean up to save space



****2001 data****
cd "$main/core/"

forv i = 1/9 {
clear
unzipfile l01puw`i'.zip, replace
ddf2dct using l01puw1d.txt, data(l01puw`i'.dat) do(infile_core01_`i'.do) dct(infile_core01_`i'.dct) replace
do infile_core01_`i'.do
save sipp01_core`i'.dta, replace
cap erase l01puw`i'.dat //clean up to save space
}
*zip Stata files to save space
zipfile sipp01_core*.dta, saving(sippArchive01)
forval i = 1/9 {
	erase sipp01_core`i'.dta
}



cd "$main/topical/"
foreach i in 3 4 6 7 9 {
clear
loc p ""
if inlist(`i',3,4,6) loc p "p"
unzipfile p01putm`i'.zip, replace
ddf2dct using p01`p'tm`i'd.txt, data(p01putm`i'.dat) do(infile_tm01_`i'.do) dct(infile_tm01_`i'.dct) replace
do infile_tm01_`i'.do
save sipp01_tm`i'.dta, replace
cap erase p01putm`i'.dat //clean up to save space
}


cd "$main/lgt/"
clear
unzipfile lgtwgt2001w9.zip, replace
ddf2dct using lgtwt01d.txt, data(lgtwgt2001w9.dat) do(lgtwgt2001w9.do) dct(lgtwgt2001w9.dct) replace
do lgtwgt2001w9.do
save lgtwgt2001w9.dta, replace
cap erase lgtwgt2001w9.dat //clean up to save space




****1996 data****
cd "$main/core/"

forv i = 1/12 {
clear
unzipfile l96puw`i'.zip
ddf2dct using sip96lgtd.asc, data(l96puw`i'.dat) do(infile_core96_`i'.do) dct(infile_core96_`i'.dct) replace
do infile_core96_`i'.do
save sipp96_core`i'.dta, replace
cap erase l96puw`i'.dat
}
*zip Stata files to save space
zipfile sipp96_core*.dta, saving(sippArchive96)
forval i = 1/12 {
	erase sipp96_core`i'.dta
}


cd "$main/topical/"
foreach i in 3 4 6 7 9 10 12 {
clear
loc name tm96puw`i'
if inlist(`i',10) loc name p96putm`i'
unzipfile `name'.zip
if inlist(`i',3,6,7) loc name p96putm`i'
ddf2dct using tm96pw`i'd.asc, data(`name'.dat) do(infile_tm96_`i'.do) dct(infile_tm96_`i'.dct) replace
do infile_tm96_`i'.do
save sipp96_tm`i'.dta, replace
cap erase `name'.dat
}


cd "$main/lgt/"
clear
unzipfile ctl_fer.zip
ddf2dct using ctl_ferd.asc, data(ctl_fer.dat) do(lgtwgt1996w12.do) dct(lgtwgt1996w12.dct) replace
do lgtwgt1996w12.do
save lgtwgt1996w12.dta, replace
cap erase ctl_fer.dat



****1993 data****
cd "$main/core/"

forv i = 1/9 {
clear
unzipfile s93w`i'.zip
!`mv' s93w`i' s93w`i'.dat //rename files if not already done
loc ddfname sipp93dd
if `i'>=6 loc ddfname s93w6dd
ddf2dct using `ddfname'.asc, data(s93w`i'.dat) do(infile_core93_`i'.do) dct(infile_core93_`i'.dct) replace
do infile_core93_`i'.do
save sipp93_core`i'.dta, replace
cap erase s93w`i'.dat
}



cd "$main/topical/"
foreach i in 4 5 7 8 {
clear
loc r ""
if inlist(`i',5,8) loc r "r"
unzipfile s93w`i'tm`r'.zip
!`mv' s93w`i'tm`r' s93w`i'tm`r'.dat
ddf2dct using s93tm`i'`r'dd.asc, data(s93w`i'tm`r'.dat) do(infile_tm93_`i'.do) dct(infile_tm93_`i'.dct) replace
do infile_tm93_`i'.do
save sipp93_tm`i'.dta, replace
cap erase s93w`i'tm`r'.dat
}

*get weights from longitudinal files
cd "$main/lgt/"
clear
unzipfile s93l9w.zip
!`mv' s93l9w s93l9w.dat
/* can't run ddf2dct--dictionary file is not proper structure for longitudinal files, b/c wide format
ddf2dct using s93l9w.asc, data(s93l9w.dat) do(long93.do) dct(long93.dct) replace 
do long93.do
save long93.dta, replace
*/
*import data directly, based on CEPR documentation (for which variables to match) and from dictionary directly
infix suseqnum 1-6 double suid 8-16 byte entry 17-18 pnum 19-21 double pnlwgt 224-235 double fnlwgt93 236-247 double fnlwgt94 248-259 using s93l9w.dat, clear
gen byte panel = 93
save "lgtwgt1993.dta", replace
cap erase s93l9w.dat




****1992 data****
cd "$main/core/"
//note wave 10 was conducted, but missing from available files
forv i = 1/9 {
clear
unzipfile s92w`i'.zip
!`mv' s92w`i' s92w`i'.dat //rename files if not already done
loc ddfname sipp92dd
if `i'>=9 loc ddfname s92w9dd
ddf2dct using `ddfname'.asc, data(s92w`i'.dat) do(infile_core92_`i'.do) dct(infile_core92_`i'.dct) replace
do infile_core92_`i'.do
save sipp92_core`i'.dta, replace
cap erase s92w`i'.dat
}

cd "$main/topical/"
foreach i in 4 5 7 8 {
clear
loc r ""
if inlist(`i',5,8) loc r "r"
unzipfile s92w`i'tm`r'.zip
!`mv' s92w`i'tm`r' s92w`i'tm`r'.dat
ddf2dct using s92tm`i'`r'dd.asc, data(s92w`i'tm`r'.dat) do(infile_tm92_`i'.do) dct(infile_tm92_`i'.dct) replace
do infile_tm92_`i'.do
save sipp92_tm`i'.dta, replace
cap erase s92w`i'tm`r'.dat
}

//get weights from longitudinal files
cd "$main/lgt/"
clear
unzipfile s92lgt10w.zip
!`mv' s92lgt10w s92lgt10w.dat
*get data directly, based on CEPR documentation (for which variables to match) and from dictionary directly
infix suseqnum 1-6 double suid 8-16 entry 17-19 pnum 20-23 double pnlwgt 288-299 double fnlwgt92 300-311 double fnlwgt93 312-323 double fnlwgt94 324-335 using s92lgt10w.dat, clear
gen byte panel = 92
save "lgtwgt1992.dta", replace
cap erase s92lgt10w.dat



****1991 data****
cd "$main/core/"

forv i = 1/8 {
clear
unzipfile s91w`i'.zip
!`mv' s91w`i' s91w`i'.dat //rename files if not already done
ddf2dct using sipp91w`i'dd.asc, data(s91w`i'.dat) do(infile_core91_`i'.do) dct(infile_core91_`i'.dct) replace
do infile_core91_`i'.do
save sipp91_core`i'.dta, replace
cap erase s91w`i'.dat
}



cd "$main/topical/"
foreach i in 4 7 8 {
clear
loc r ""
if inlist(`i',5,8) loc r "r"
unzipfile s91w`i'tm`r'.zip
!`mv' s91w`i'tm`r' s91w`i'tm`r'.dat
ddf2dct using s91tm`i'`r'dd.asc, data(s91w`i'tm`r'.dat) do(infile_tm91_`i'.do) dct(infile_tm91_`i'.dct) replace
do infile_tm91_`i'.do
save sipp91_tm`i'.dta, replace
cap erase s91w`i'tm`r'.dat
}
*add tm5r from NBER: http://www.nber.org/data/survey-of-income-and-program-participation-sipp-data.html
foreach i in 5 {
clear
unzipfile sipp91r`i'.zip
ddf2dct using sipp91r`i'.ddf, data(sipp91r`i'.dat) do(infile_tm91_`i'.do) dct(infile_tm91_`i'.dct) replace
do infile_tm91_`i'.do
save sipp91_tm`i'.dta, replace
cap erase sipp91r`i'.dat
}


//get weights from longitudinal files
cd "$main/lgt/"
clear
unzipfile s91lgt8w.zip
!`mv' s91lgt8w s91lgt8w.dat
*get data directly, based on CEPR documentation (for which variables to match) and from dictionary directly
infix suseqnum 1-6 double suid 8-16 byte entry 17-18 pnum 19-21 double pnlwgt 202-213 double fnlwgt91 214-225 double fnlwgt92 226-237 using s91lgt8w.dat, clear
gen byte panel = 91
save "lgtwgt1991.dta", replace
cap erase s91lgt8w.dat




****1990 data****
cd "$main/core/"

forv i = 1/8 {
clear
unzipfile s90w`i'.zip
!`mv' s90w`i' s90w`i'.dat //rename files if not already done
loc ddfname sipp90w1dd
if `i'>=2 loc ddfname "sipp90w2-8dd"
ddf2dct using `ddfname'.asc, data(s90w`i'.dat) do(infile_core90_`i'.do) dct(infile_core90_`i'.dct) replace
do infile_core90_`i'.do
save sipp90_core`i'.dta, replace
cap erase s90w`i'.dat
}

cd "$main/topical/"
foreach i in 4 5 7 {
clear
loc r ""
if inlist(`i',5,8) loc r "r"
unzipfile s90w`i'tm`r'.zip
!`mv' s90w`i'tm`r' s90w`i'tm`r'.dat
ddf2dct using s90tm`i'`r'dd.asc, data(s90w`i'tm`r'.dat) do(infile_tm90_`i'.do) dct(infile_tm90_`i'.dct) replace
do infile_tm90_`i'.do
save sipp90_tm`i'.dta, replace
cap erase s90w`i'tm`r'.dat
}
*add tm8r from NBER: http://www.nber.org/data/survey-of-income-and-program-participation-sipp-data.html
foreach i in 8 {
clear
unzipfile sipp90r`i'.zip
ddf2dct using sipp90r`i'.ddf, data(sipp90r`i'.dat) do(infile_tm90_`i'.do) dct(infile_tm90_`i'.dct) replace
do infile_tm90_`i'.do
save sipp90_tm`i'.dta, replace
cap erase sipp90r`i'.dat
}


//get weights from longitudinal files
cd "$main/lgt/"
clear
unzipfile s90lgt8w.zip
!`mv' s90lgt8w s90lgt8w.dat
*get data directly, based on CEPR documentation (for which variables to match) and from dictionary directly
infix suseqnum 1-6 double suid 8-16 byte entry 17-18 pnum 19-21 double pnlwgt 202-213 double fnlwgt90 214-225 double fnlwgt91 226-237 using s90lgt8w.dat, clear
gen byte panel = 90
save "lgtwgt1990.dta", replace
cap erase s90lgt8w.dat


*zip all early 1990s Stata files to save space
cd "$main/core/"
zipfile sipp9?_core*.dta , saving(sippArchive90-93.zip)
forval y = 90/93 {
	loc max = 8
	if `y'>=92 loc max = 9
	forval i = 1/`max' {
		cap erase sipp`y'_core`i'.dta
}
}


*** 1980s files and SPD require StataSE
if c(SE)==0 {
di "StataSE required for 1980s files and SPD"
exit
}

****1984-89 data****
cd "$main/core/"
adopath + "$main/core/"
//make minor edit (adding "1" to first line) for 84w1 ddf to avoid error
filefilter sipp84w1_old.ddf sipp84w1.ddf , from("D SUSEQNUM        5") to("D SUSEQNUM        5        1") replace
//remove extra line in sipp84t7 for TM8248 variable to avoid error
filefilter sipp84t7_old.ddf sipp84t7.ddf , from("D                       786    6146") to("") replace
//confirm ado file available
which ddf2dct_edit.ado 
//process files
forv y = 84/89 {
loc max = 7
if `y'==89 loc max = 3
if `y'==88 loc max = 6
if `y'==85 loc max = 8
if `y'==84 loc max = 9

forv i =1/`max' {
clear
loc prefix "t" //default prefix for files
if inlist(`i',1,2) & `y'==89 loc prefix "w"
if `i'==1 & inlist(`y',88,87,85) loc prefix "r"
if `i'==1 & `y'==86 loc prefix "w"
if inlist(`i',2,5,6) & inlist(`y',85) loc prefix "r"
if inlist(`i',1,2,6,9) & inlist(`y',84) loc prefix "w"
if "`prefix'"=="t" & `y'==84 loc st "sipptm" //special format for 1984 topical modules
else loc st ""
unzipfile sipp`y'_`prefix'`i'.zip
ddf2dct_edit using sipp`y'`prefix'`i'.ddf, data(sipp`y'_`prefix'`i'.dat) do(infile_core`y'_`i'.do) dct(infile_core`y'_`i'.dct) replace longstring `st' //drop(pp_fill0) //drop(pp_fill* pp_imp* ws*imp* se*imp* g2_imp*) - must be spelled out, no *
do infile_core`y'_`i'.do
save sipp`y'_core`i'.dta, replace
cap erase sipp`y'_`prefix'`i'.dat
}
}

//get weights from longitudinal NBER files
cd "$main/lgt/"
clear
forval y = 84/87 {
unzipfile sipp`y'fp.zip
}
unzipfile s88lfp.zip
!`mv' s88lfp s88lfp.dat
*get data directly, based on ddf documentation (for which variables to match)
infix suseqnum 1-6 double su_id 8-16 byte pp_entry 17-18 pp_pnum 19-21 double pnlwgt 136-147 double fnlwgt84 148-159 double fnlwgt85 172-183 using sipp84fp.dat, clear
gen byte panel = 84
save "$main/lgt/lgtwgt1984.dta", replace
infix suseqnum 1-6 double su_id 8-16 byte pp_entry 17-18 pp_pnum 19-21 double pnlwgt 138-149 double fnlwgt85 150-161 double fnlwgt86 162-173 using sipp85fp.dat, clear
gen byte panel = 85
save "$main/lgt/lgtwgt1985.dta", replace
infix suseqnum 1-6 double su_id 8-16 byte pp_entry 17-18 pp_pnum 19-21 double pnlwgt 202-213 double fnlwgt86 214-225 double fnlwgt87 226-237 using sipp86fp.dat, clear
gen byte panel = 86
save "$main/lgt/lgtwgt1986.dta", replace
infix suseqnum 1-6 double su_id 8-16 byte pp_entry 17-18 pp_pnum 19-21 double pnlwgt 202-213 double fnlwgt87 214-225 double fnlwgt88 226-237 using sipp87fp.dat, clear
gen byte panel = 87
save "$main/lgt/lgtwgt1987.dta", replace
infix suseqnum 1-6 double su_id 8-16 byte pp_entry 17-18 pp_pnum 19-21 double pnlwgt 202-213 double fnlwgt88 214-225 double fnlwgt89 226-237 using s88lfp.dat, clear
gen byte panel = 88 
	* note su_id might be pp_id... used NBER documentation, as DDF has issues
save "$main/lgt/lgtwgt1988.dta", replace
forval y = 84/87 {
cap erase sipp`y'fp.dat
}
cap erase s88lfp.dat

*zip all 1980s Stata files to save space
cd "$main/core/"
zipfile sipp8?_core*.dta , saving(sippArchive84-89.zip)
forval y = 84/89 {
	loc max = 7
	if `y'==84 loc max = 9
	if `y'==85 loc max = 8
	if `y'==88 loc max = 6
	if `y'==89 loc max = 3
	forval i = 1/`max' {
		cap erase sipp`y'_core`i'.dta
}
}



****Get SPD data****
//note: must be run in StataSE due to size
cd "$main/lgt/spd/"
clear
unzipfile spdlng3_finalv2.zip, replace

ddf2dct using spdlongd.txt, data(spdlng3_finalv2.dat) do(spd.do) dct(spd.dct) replace drop(FILLER)

do spd.do
compress
save spd_long, replace
zipfile spd_long.dta, saving(spd_long.zip)
cap erase spdlng3_finalv2.dat

*reshape file
set more off
use spd_long, clear

	//incorrect labels
lab var chie0 "T HHI:Any child covr'd - other health 99" 
lab var hii0 "T HI:Imputation flag for HIE0 99"
lab var currix "T HI:Imputation flag for CURREX 02"

foreach var of varlist rsnnie2-mchpix {

loc yr = substr("`: var lab `var''",-2,2)

loc stub = substr("`var'",1,length("`var'")-1)

if inlist("`yr'","91","92","93","94","96","97") | inlist("`yr'","98","99","00","01","02") {
	ren `var' `stub'_`yr'
}

}

loc n ""
foreach var of varlist rsnnie_92-mchpi_01 {
*loc s = subinstr("`var'","92","@",1)
loc s = substr("`var'",1,length("`var'")-2) + "@"
loc n : list n | s
}
*di "`n'"

reshape long ihhkey@ `n', i(sipp_pnl pp_id pp_pnum pp_entry) j(yr) string


gen year = real("20"+yr) if inlist(yr,"00","01","02")
replace year = real("19"+yr) if mi(year)

sort sipp_pnl pp_id pp_pnum pp_entry year
gen top5 = top5pce_
gen pct = pctcute_
by sipp_pnl pp_id pp_pnum pp_entry: replace top5pce_ = top5[_n-1]
by sipp_pnl pp_id pp_pnum pp_entry: replace pctcute_ = pct[_n-1]
drop top5 pct
drop if year==1991 //only used for top 5% variables

rename *_ *

compress
save spd_reshape, replace

zipfile spd_reshape.dta, saving(spd_reshape.zip)

timer off 1
timer list
