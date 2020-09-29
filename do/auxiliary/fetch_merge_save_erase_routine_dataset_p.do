********************************************************************************
***
*** 	FETCHING-ROUTINE
*** 	FOR WIDE DATA FROM WAVES OF DATASET P
***
*** 	Date:			23.08.2017
*** 	Author: 		Maximilian Sprengholz
***
*** 	Temporary globals are needed as input:
*** 	crrnt_varname 	- 	final variable name
*** 	crrnt_var		-	specific var names for each wave
***		crrnt_year		-	corresponding years
***
********************************************************************************	

clear

/* TRANSLATION crrnt_year == current_wave
To avoid input mistakes, the necessary input data for variables not available in
every year is constrained to $current_year. For the fetching process this year 
data needs to be translated into the corresponding wave data:

Every transferred year of the $crrnt_year macro is matched with the corresponding
wave. To achieve this, we loop through the $year macro from the master-file
(from 1/`n', n equals the length of the $year macro). Once $crrnt_year and $year
match, the corresponding entry from $wave at the same position `i' is saved in
local `cw' and then added to the $crrnt_wave global. This procedure ensures the
correct order and equivalence. */

local n : word count ${year}

foreach cy in $crrnt_year {
	forvalues i=1/`n' {
		local x : word `i' of ${wave}
		local y : word `i' of ${year}
		if `cy' == `y' {
			local cw `x'
			global crrnt_wave = "${crrnt_wave} `cw'"
		}
	}
}

/* FETCH, MERGE, SAVE, ERASE */

*** fetch
local n : word count ${crrnt_wave}
*	counts words in z_wave macro, then loops for every word (wave)
forvalues i=1/`n'{
	local x : word `i' of ${crrnt_wave}
	local y : word `i' of ${crrnt_year}
	local a : word `i' of ${crrnt_var}

	use persnr `a' using ${SOEP}`x'p.dta, clear 
*	use persnr (needed for merging) and variable `a' that is at position i 
*	in the local macro z_var from the corresponding dataset `x' that is at 
*	position i in the local macro z_wave. the used dataset name is always 
*	"`x'p.dta" under the specified file path ${SOEP}
	rename `a' ${crrnt_varname}`y'
*	every variable is renamed to the specified local macro varname with the
*	corresponding year as suffix (needed for reshaping)
	save ${temp}${crrnt_varname}`y'.dta, replace
*	data for every single wave is saved in a single dataset prior to merging
}
*** merge
tokenize ${crrnt_year}
*	tokenize enables us to adress every word in the local macro year via 
*	incrementing number tokens. the first saved dataset is therefore dataset 1
*	which is used as master for merging datasets 2 and following
use ${temp}${crrnt_varname}`1'.dta, clear
forvalues i=2/`n'{
	local y : word `i' of ${crrnt_year} 
	merge 1:1 persnr using ${temp}${crrnt_varname}`y'.dta
	drop _merge
}
*** save
save ${temp}${crrnt_varname}.dta, replace
*	the merged data for the variable is saved under the specified varname
*** erase
forvalues i=1/`n'{
	local y : word `i' of ${crrnt_year} 
	erase ${temp}${crrnt_varname}`y'.dta
*	temporarily saved datasets are deleted
}

/* ADD ALL PROCESSED VARS TO GLOBAL, DROP GLOBALS */

*** add all via this routine processed variables to macro for easy reshaping
local var_log "${vars_fetched_from_p} ${crrnt_varname}" // all stored + current
macro drop vars_fetched_from_p
global vars_fetched_from_p = "`var_log'" // overwrite global

*** drop macros (avoid name doublettes and data overwrite)
macro drop crrnt_varname
macro drop crrnt_var
macro drop crrnt_wave
macro drop crrnt_year
