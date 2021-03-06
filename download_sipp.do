*Code to Download SIPP files from Census
//note: requires about 10GB of space

version 15.1 

*main directory
cd "$main"

cap mkdir core 
cap mkdir topical 
cap mkdir lgt
cap mkdir lgt/spd
cap mkdir ctcPaper

*time script
timer clear 
timer on 1

****2014 data****

cd "$main/core/"

forval i = 1/4 {
if `i'==2 loc stub "" //deal with misplaced wave 2 file - not in "w2" directory
else loc stub "w`i'/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2014/w`i'/pu2014w`i'_dat.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/tech-documentation/data-dictionaries/2014/`stub'2014SIPP_W`i'_Metadata_AllSections.xlsx" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2014/w`i'/pu2014w`i'.sas" ./, replace
}





****2008 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/tech-documentation/data-dictionaries/2008/sipp-2008-panel-waves-01-10-core-data-dictionary.txt" l08puw1d.txt, replace
copy "https://www2.census.gov/programs-surveys/sipp/tech-documentation/data-dictionaries/2008/sipp-2008-panel-waves-11-and-after-core-data-dictionary.txt" l08w11d.txt, replace
forv i = 1/16 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2008/w`i'/l08puw`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 2 4 5 6 7 8 10 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2008/w`i'/p08putm`i'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2008/w`i'/p08tm`i'd.txt" ./, replace
}

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2008/w16/lgtwgt2008w16.txt" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2008/w16/lgtwgt2008w16.zip" ./, replace


****2004 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2004/w1/l04puw1d.txt" ./, replace
forv i = 1/12 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2004/w`i'/l04puw`i'.zip" ./, replace
}


*create tm files 
cd "$main/topical/"
foreach i in 3 4 6 7 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2004/w`i'/p04putm`i'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2004/w`i'/p04tm`i'd.txt" ./, replace
}

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2004/w12/lgt04w12d.txt" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2004/w12/lgtwgt2004w12.zip" ./, replace



****2001 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2001/w1/l01puw1d.txt" ./, replace
forv i = 1/9 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2001/w`i'/l01puw`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 3 4 6 7 9 {
loc p ""
if inlist(`i',3,4,6) loc p "p"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2001/w`i'/p01putm`i'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2001/w`i'/p01`p'tm`i'd.txt" ./, replace
}

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2001/lgtwt01d.txt" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/2001/w9/lgtwgt2001w9.zip" ./, replace





****1996 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1996/sip96lgtd.asc" ./, replace
forv i = 1/12 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1996/w`i'/l96puw`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 3 4 6 7 9 10 12 {
loc name tm96puw`i'
if inlist(`i',10) loc name p96putm`i'
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1996/w`i'/`name'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1996/w`i'/tm96pw`i'd.asc" ./, replace
}

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1996/ctl_ferd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1996/ctl_fer.zip" ./, replace



****1993 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/sipp93dd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/w6/s93w6dd.asc" ./, replace
forv i = 1/9 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/w`i'/s93w`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 4 5 7 8 {
loc r ""
if inlist(`i',5,8) loc r "r"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/w`i'/s93w`i'tm`r'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/s93tm`i'`r'dd.asc" ./, replace
}

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/s93l9w.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1993/s93l9w.zip" ./, replace



****1992 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/sipp92dd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/w9/s92w9dd.asc" ./, replace
forv i = 1/9 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/w`i'/s92w`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 4 5 7 8 {
loc r ""
if inlist(`i',5,8) loc r "r"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/w`i'/s92w`i'tm`r'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/w`i'/s92tm`i'`r'dd.asc" ./, replace
}

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/s92l10wdd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1992/s92lgt10w.zip" ./, replace


****1991 data****

*create core files
cd "$main/core/"

forv i = 1/8 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1991/w`i'/sipp91w`i'dd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1991/w`i'/s91w`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 4 7 8 {
loc r ""
if inlist(`i',8) loc r "r"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1991/w`i'/s91w`i'tm`r'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1991/w`i'/s91tm`i'`r'dd.asc" ./, replace
}
*revised tm5 from NBER (not on census site)
copy "https://data.nber.org/sipp/1991/sipp91r5.ddf" ./, replace
copy "https://data.nber.org/sipp/1991/sipp91r5.zip" ./, replace


*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1991/s91l8wdd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1991/s91lgt8w.zip" ./, replace



****1990 data****

*create core files
cd "$main/core/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/w1/sipp90w1dd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/w2/sipp90w2-8dd.asc" ./, replace
forv i = 1/8 {
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/w`i'/s90w`i'.zip" ./, replace
}

*create tm files 
cd "$main/topical/"
foreach i in 4 5 7 {
loc r ""
if inlist(`i',5) loc r "r"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/w`i'/s90w`i'tm`r'.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/w`i'/s90tm`i'`r'dd.asc" ./, replace
}
*revised tm8 from NBER (not on census site)
copy "https://data.nber.org/sipp/1990/sipp90r8.ddf" ./, replace
copy "https://data.nber.org/sipp/1990/sipp90r8.zip" ./, replace

*longitudinal weights
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/s90l8wdd.asc" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1990/s90lgt8w.zip" ./, replace


****1984-89 data****

*create core files (include TM information)
cd "$main/core/"
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

    copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/19`y'/w`i'/sipp`y'`prefix'`i'.ddf" ./, replace
    copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/19`y'/w`i'/sipp`y'_`prefix'`i'.zip" ./, replace
}
}
//copy files that will be edited later
copy sipp84w1.ddf sipp84w1_old.ddf, replace
copy sipp84t7.ddf sipp84t7_old.ddf, replace

*longitudinal files
cd "$main/lgt/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1988/s88lfp.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/1988/s88lfpdd.asc" ./, replace
*earlier longitudinal files from nber
forval i = 84/87 {
copy "https://data.nber.org/sipp/19`i'/sipp`i'fp.zip" ./, replace
}




*Get SPD data - longitudinal file only
cd "$main/lgt/spd/"
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/spd/spdlng3_finalv2.zip" ./, replace
copy "https://www2.census.gov/programs-surveys/sipp/data/datasets/spd/Third_LongitudinalFileData_Dictionary.txt" ./spdlongd.txt, replace

timer off 1
timer list
