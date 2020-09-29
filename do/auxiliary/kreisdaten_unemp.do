////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Monthly unemployment rate, disctrict level, 
//		   provided by the Agentur für Arbeit (BA) --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////
	
set more off

***
***	03/84 - 06/2007
***

*	insheet	
	clear
	insheet using "${dir_data}source/unemp/unemprate_months_84_2006.csv", delimiter(";") names
*	del empty cols
	drop kreis
	drop if missing(kkz)
*	destring
	destring m*, replace dpcomma
*	replace kkz
	replace kkz = kkz/1000
*	save
	save "${dir_data}source/temp/unemp_84_2016.dta", replace

***
***	East 91-96, only on state level available
***

*	insheet	
	clear
	insheet using "${dir_data}source/unemp/unemp_91_96_bula.csv", delimiter(",") names
*	del empty cols
	drop state
	drop if missing(bula)
*	destring
	destring m*, replace dpcomma
*	save
	save "${dir_data}source/temp/unemp_91_96_bula.dta", replace	

***
*** 07/2007 - 12/2016
***
	
***	insheet/Merge loop	
	foreach y in 07 08 09 10 11 12 13 14 15 16 {
		if "`y'" == "07" {
			local months "07 08 09 10 11 12"
		}
		else {
			local months "01 02 03 04 05 06 07 08 09 10 11 12"
		}
		foreach m in `months' {
		*	insheet
			clear
			insheet using "${dir_data}source/unemp/m`m'_20`y'.csv", delimiter(";") names
		*	del empty cols
			drop if missing(kkz)
		*	kkz digit recode
			if ("`y'"=="08" & "`m'"=="01") | ("`y'"=="07") {
				replace kkz = kkz/1000
			}
		*	destring
			destring m*, replace dpcomma
		*	merge
			merge 1:1 kkz using "${dir_data}source/temp/unemp_84_2016.dta", nogen
		*	save	
			save "${dir_data}source/temp/unemp_84_2016.dta", replace			
		}
	}

***	gen unemprate on bula basis to replace missing regional values
	clonevar bula = kkz
	tostring bula, replace
	replace bula = substr(bula,1,1) if kkz<10000
	replace bula = substr(bula,1,2) if kkz>=10000
	destring bula, replace	
*** add state data
	merge m:1 bula using "${dir_data}source/temp/unemp_91_96_bula.dta", update
	drop _merge
	save "${dir_data}source/temp/unemp_84_2016.dta", replace
***	reshape
	reshape long m01_ m02_ m03_ m04_ m05_ m06_ m07_ m08_ m09_ m10_ m11_ m12_, i(kkz) j(syear)
*	workaround for still missing kkz --> would not be merged otherwise for persons only available in 1984
	egen unemp_bula1984 = mean(m12_), by(bula)
*	save	
	save "${dir_data}source/unemp_84_2016l.dta", replace

// clear temp
!rmdir ${dir_data}temp  /s /q
