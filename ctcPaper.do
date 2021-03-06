* Master do-file for CTC paper

*Set directories - change as needed
if c(os)=="Windows" global main "C:\data\sipp" 
else global main "~/data/sipp"
global project "~/Files/Projects/CTC/ctcPaper"

*dependencies
ssc install egenmore
ssc install ddf2dct
ssc install rd
ssc install estout
ssc install coefplot
ssc install addplot
ssc install rdrobust
ssc install cpigen
ssc install ftools
ssc install gtools
net install taxsimlocal32, from("http://www.nber.org/stata") replace

*copy data files
cd "$project"
copy ddf2dct_edit.ado "$main/core/" , replace
copy data/CompulsoryAttendance.xlsx "$main/ctcPaper/CompulsoryAttendance.xlsx", replace 
copy data/taxsim_crosswalk.dta "$main/ctcPaper/taxsim_crosswalk.dta", replace 
cd "$main"

*download data and convert to Stata format
do "$project/download_sipp.do"
do "$project/import_sipp.do" 

*process files to get yearly raw analysis files
do "$project/prepare_sipp.do" 

*run taxsim and make combined file
do "$project/prep_analysis.do"

*make project master data file
do "$project/make_RD.do" 

*run RD results
do "$project/sippRD.do"
