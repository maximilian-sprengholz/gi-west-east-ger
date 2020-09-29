////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Summary Statistics (Panel) for Appendix --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

set matsize 1000
set more off
set seed 1234567

global delspike=1

/////////
//
// PART I – working couples
//
/////////

***	load dataset
	use "${dir_data}gi_gen.dta", clear
*** Sample restricted according to ESt-Data sample used to derive rounding shares
*	xtset
	xtset cid syear
* 	age 25-64 (adjusted for time-lag 1 year)
	local age_min 26
	local age_max 65
	keep if age>=`age_min' & age<=`age_max' & age_m>=`age_min' & age_m<=`age_max'
* 	no self-employed
	keep if (((l1.stib>440 | l1.stib<410) & (l1.stib_m>440 | l1.stib_m<410) & !missing(l1.stib, l1.stib_m)) ///
		  | ((stib>440 | stib<410) & (stib_m>440 | stib_m<410) & missing(l1.stib, l1.stib_m)))
	keep if (l1.pgallbet!=5 & l1.pgallbet_m!=5) ///
		  | (pgallbet!=5 & pgallbet_m!=5 & missing(l1.pgallbet, l1.pgallbet_m))
*	identify spouses within same industry, occupation & company size
	gen cowork=0
	replace cowork=1 if (l1.pgbetr==l1.pgbetr_m & l1.e11105==l1.e11105_m & l1.pgnace==l1.pgnace_m) ///
		& !missing(l1.pgbetr, l1.pgbetr_m, l1.e11105, l1.e11105_m, l1.pgnace, l1.pgnace_m)		
*	further options
	keep if /*
		married or cohabiting couples (at time of interview): if no l1 availabe, use current info!
	*/	( 	((l1.partz<=2 & partz<=2) & (l1.partz==partz)) ///
		  | (missing(l1.partz) & partz<=2 & movedinm<0) ///
		) /* // caveat: there are possible combinations where partners might not have been living together in the pervious year 			
		no co-working couples
	*/	& cowork==0 /*
		working & positive income
		& yw_full==1 & yw_full_m==1 /// 
	*/	& ywm>0 & ywm_m>0  ///
		& yinc>0 & yinc_m>0 ///
			& !missing(yinc, yinc_m) /*
		no unemployed/pensioner/vocational training/in edu/motherhood/army or civil service 
		(make 1 criterium – 0s are also given when no data is available)
	*/	& !inlist(1, 	yunemp_full, yunemp_full_m, ///
						yvoc_full, yvoc_full_m, ///
						ypen_full, ypen_full_m, ///
						ymother_full, ymother_full_m, ///
						yschool_full, yschool_full_m, ///
						yservice_full, yservice_full_m )
*	married couples only
	keep if (((l1.partz<=1 & partz<=1) & (l1.partz==partz)) | (missing(l1.partz) & partz<=1 & movedinm<0))				
*	decade adjustment (to assign correct years bc of retrosspective survey)
*	based on user input (two thresholds)
	drop decade decade_east
	// extended spec as requested by reviewer
	recode syear (1984/1991=1 "1983-1990") (1992/2004=2 "1991-2003") ///
		(2005/2016=3 "2004-2016") (else=.), generate(decade)
	// labels for output
	local p1lab "1984--1990"
	local p2lab "1991--2003"
	local p3lab "2004--2016"			
*	gen full-time share indicator
	replace yftm=0 if missing(yftm)
	replace yptm=0 if missing(yptm)
	gen ftpt = yftm / (yftm + yptm)
	replace ftpt = 1 if yftm!=0 & yptm==0
	replace ftpt = 0 if yftm==0 & yptm!=0	
	replace ftpt = . if yftm==0 & yptm==0

	replace yftm_m=0 if missing(yftm_m)
	replace yptm_m=0 if missing(yptm_m)
	gen ftpt_m = yftm_m / (yftm_m + yptm_m)
	replace ftpt_m = 1 if yftm_m!=0 & yptm_m==0
	replace ftpt_m = 0 if yftm_m==0 & yptm_m!=0	
	replace ftpt_m = . if yftm_m==0 & yptm_m==0
	
***
*** De-Round
***		
qui do "${dir_do}gi_deround.do"
qui do "${dir_do}gi_deround_post.do"		
keep if !missing(wis)

***
***	correct year assignment
***
	xtset cid syear
//	overall sample
	codebook cid if (sampreg==1 & inlist(decade,1,2,3)) | (sampreg==2 & inlist(decade,2,3))

***
***	(3) base sample
***

*  ------------------------------  *
* |     XT SUMMARY STATISTICS    | *
*  ------------------------------  *	
***	relabel (Women vs. Men)
	label var wis "Wife's share of household income (gross)"
	label var WEM "Wife earns more"
	
	label var ftpt "Full-time share of worked months"
	label var ftpt_m "Full-time share of worked months"
	
	label var lfp "Labor force participation"
	label var lfp_m "Labor force participation"
	label var yinc "Annual labor income (gross)"
	label var yinc_m "Annual labor income (gross)"
	label var vebzt "Weekly working hours (contractual)"
	label var vebzt_m "Weekly working hours (contractual)"
	label var tatzt "Weekly working hours (actual)"
	label var tatzt_m "Weekly working hours (actual)"
	label var NMW_weekly "Weekly housework hours"
	label var NMW_weekly_m "Weekly housework hours"
	label var age "Age"
	label var age_m "Age"
	
	label var cimpgro "Wife's or husband's income imputed"
	tab agekidk, gen(agekid)
		label var agekid1 "Age y. child (ref. none)"
		label var agekid2 "0--3 years"
		label var agekid3 "4--6 years"
		label var agekid4 "7--16 years"
	label var unempr_kkz "Unemployment rate, district level"

*** Summary stats by sample region
	forvalues s=1/2 {
	*	set sample region name macro & options
		if `s'==1 {
			local r West
			local decade 1 2 3
		}
		else if `s'==2 {
			local r East
			local decade 2 3
		}
		else {
			local r GER
			local opts
		}
		foreach l in `decade' { 
			preserve
		*	restrict
			keep if sampreg==`s' & decade==`l'
			cap drop n
			bys cid: gen n=_n // for estimation of within variation
		*	make Table
			local sumstats ///
				yinc_m ftpt_m ///
				yinc ftpt wis WEM
			local cnt=0
			foreach xts in `sumstats' {
				local cnt=`cnt'+1
				local mtrx "X\Z"
				local repl "append"
				local title : var label `xts'
				local hl
				if "`xts'" == "yinc_m" {
					local mtrx "Z"
					local repl "replace"
					local hl "\noalign{\smallskip}\textbf{Working couples}\\ \noalign{\smallskip}\hline \noalign{\smallskip}\emph{Husband}\\"
				}
				else if "`xts'" == "yinc" {
					local hl "\noalign{\smallskip}\hline\noalign{\smallskip}\emph{Wife}\\"
				}
			***	tabstat & xtsum (apply proper weights!)
			*	overall
				tabstat `xts' [aw=phrf], stats(mean sd min max) save
				matrix O = r(StatTotal)
			*	between
				cap drop m_`xts'
				egen m_`xts' = mean(`xts'), by(cid)
				tabstat m_`xts' [aw=phrf] if n==1, stats(mean sd min max) save
				matrix B = r(StatTotal)
			*	within
				cap drop w_`xts'
				gen w_`xts'=`xts'-m_`xts'
				tabstat w_`xts' [aw=phrf] if n==1, stats(mean sd min max) save
				matrix W = r(StatTotal)
			*	xtsum (n, N, T-bar) --> observations with invalid weights already omitted!
				xtsum `xts'
			*	complete matrix	
				matrix Z	=	(O[1,1],  O[2,1], 	O[3,1], 	O[4,1], 	r(N), 	r(n), 	r(Tbar) ///
									  \., B[2,1], 	B[3,1], 	B[4,1],		. ,		. ,		. ///
									  \., W[2,1], 	W[3,1], 	W[4,1],		. ,		. ,		. )
				matrix list 	Z
				matrix X	=	`mtrx'
				matrix list 	X
				matrix Y	=	Z[1...,1..4]
				matrix list 	Y
				frmttable using "${dir_t}xt_sum_wc_split_`r'_`l'.tex", `repl' tex statmat(Y) ///
					rtitle(" `hl' \noalign{\smallskip}\multirow[t]{2}{3.5cm}{`title'}", "{overall}"\ "", "{between}"\"", "{within}") ///
					ctitle("","{Variance}","{Mean}", "{Std. Dev.}", "{Min}", "{Max}") ///
					fragment sfmt(f) sdec(2)
			}
		* 	merge N,n & Tbar
			mat N = X[1...,5..6]
			matrix list N
			frmttable using "${dir_t}xt_sum_wc_split_`r'_`l'.tex", merge tex statmat(N) ///
				ctitle("{N}", "{n}") sdec(0) fragment sfmt(g)
			mat T = X[1...,7]
			mat list T
			frmttable using "${dir_t}xt_sum_wc_split_`r'_`l'.tex", merge tex statmat(T) ///
				ctitle("{$\mathrm{\bar{T}}$}") sdec(2) fragment
		restore
		}
	}

	
/////////
//
// PART II – all couples I (lagged vars)
//
/////////

***	load dataset
	use "${dir_data}gi_gen.dta", clear
*** Sample restricted according to ESt-Data sample used to derive rounding shares
*	xtset
	xtset cid syear
* 	age 25-64 (adjusted for time-lag 1 year)
	local age_min 26
	local age_max 65
	keep if age>=`age_min' & age<=`age_max' & age_m>=`age_min' & age_m<=`age_max'
*	married couples only
	keep if (((l1.partz<=1 & partz<=1) & (l1.partz==partz)) | (missing(l1.partz) & partz<=1 & movedinm<0))	
*	based on user input (two thresholds)
	drop decade decade_east
	// extended spec as requested by reviewer
	recode syear (1984/1991=1 "1983-1990") (1992/2004=2 "1991-2003") ///
		(2005/2016=3 "2004-2016") (else=.), generate(decade)
	// labels for output
	local p1lab "1984--1990"
	local p2lab "1991--2003"
	local p3lab "2004--2016"	
*	employed in t indicator (no longer on monthly basis!)
	gen yw = 0 if ywm==0
	replace yw = 1 if ywm>0 & !missing(ywm) // = employed
	gen yw_m = 0 if ywm_m==0
	replace yw_m = 1 if ywm_m>0 & !missing(ywm_m) // = employed
*	keep if full info available
	keep if !missing(agekidk)
*	use lagged age
	replace age = age-1
	replace age_m = age_m-1
	
***
***	(3) base sample
***

qui do "${dir_do}gi_deround_post.do"	

*  ------------------------------  *
* |     XT SUMMARY STATISTICS    | *
*  ------------------------------  *	
***	relabel (Women vs. Men)
	label var wis "Wife's share of household income (gross)"
	label var WEM "Wife earns more"
	
	label var yw "Employed"
	label var yw_m "Employed"
	label var yinc "Annual labor income (gross)"
	label var yinc_m "Annual labor income (gross)"
	label var vebzt "Weekly working hours (contractual)"
	label var vebzt_m "Weekly working hours (contractual)"
	label var tatzt "Weekly working hours (actual)"
	label var tatzt_m "Weekly working hours (actual)"
	label var NMW_weekly "Weekly housework hours"
	label var NMW_weekly_m "Weekly housework hours"
	label var age "Age"
	label var age_m "Age"
	
	label var cimpgro "Wife's or husband's income imputed"
	tab agekidk, gen(agekid)
		label var agekid1 "Age y. child (ref. none)"
		label var agekid2 "0--3 years"
		label var agekid3 "4--6 years"
		label var agekid4 "7--16 years"
	label var unempr_kkz "Unemployment rate, district level"

*** Summary stats by sample region
	forvalues s=1/2 {
	*	set sample region name macro & options
		if `s'==1 {
			local r West
			local decade 1 2 3
		}
		else if `s'==2 {
			local r East
			local decade 2 3
		}
		else {
			local r GER
			local opts
		}
		foreach l in `decade' { 
			preserve
		*	restrict
			keep if sampreg==`s' & decade==`l'
			cap drop n
			bys cid: gen n=_n // for estimation of within variation
		 *	make Table
			local sumstats ///
				yw_m age_m ///
				yw age
			local cnt=0
			foreach xts in `sumstats' {
				local cnt=`cnt'+1
				local mtrx "X\Z"
				local repl "append"
				local title : var label `xts'
				local hl
				if "`xts'" == "yw_m" {
					local mtrx "Z"
					local repl "replace"
					local hl "\textbf{All couples}\\ \noalign{\smallskip}\hline \noalign{\smallskip}\emph{Husband}\\ "
				}
				else if "`xts'" == "yw" {
					local hl "\noalign{\smallskip}\hline\noalign{\smallskip}\emph{Wife}\\"
				}
				else if "`xts'" == "agekid1" {
					local hl "\noalign{\smallskip}\hline\noalign{\smallskip}\emph{Couple}\\"
				}
			***	tabstat & xtsum (apply proper weights!)
			*	overall
				tabstat `xts' [aw=phrf], stats(mean sd min max) save
				matrix O = r(StatTotal)
			*	between
				cap drop m_`xts'
				egen m_`xts' = mean(`xts'), by(cid)
				tabstat m_`xts' [aw=phrf] if n==1, stats(mean sd min max) save
				matrix B = r(StatTotal)
			*	within
				cap drop w_`xts'
				gen w_`xts'=`xts'-m_`xts'
				tabstat w_`xts' [aw=phrf] if n==1, stats(mean sd min max) save
				matrix W = r(StatTotal)
			*	xtsum (n, N, T-bar) --> observations with invalid weights already omitted!
				xtsum `xts'
			*	complete matrix
				if `cnt'==2 | `cnt'==4 {
				matrix Z	=	(O[1,1],  O[2,1], 	O[3,1], 	O[4,1], 	r(N), 	r(n), 	r(Tbar))
				}
				else {
				matrix Z	=	(O[1,1],  O[2,1], 	O[3,1], 	O[4,1], 	r(N), 	r(n), 	r(Tbar) ///
									  \., B[2,1], 	B[3,1], 	B[4,1],		. ,		. ,		. ///
									  \., W[2,1], 	W[3,1], 	W[4,1],		. ,		. ,		. )
				}
				matrix list 	Z
				matrix X	=	`mtrx'
				matrix list 	X
				matrix Y	=	Z[1...,1..4]
				matrix list 	Y
				if `cnt'==2 | `cnt'==4  {
				frmttable using "${dir_t}xt_sum_ac1_split_`r'_`l'.tex", `repl' tex statmat(Y) ///
					rtitle(" `hl' \noalign{\smallskip}\multirow[t]{2}{3.5cm}{`title'}", "{overall}") ///
					fragment sfmt(f) sdec(2)
				}
				else {
				frmttable using "${dir_t}xt_sum_ac1_split_`r'_`l'.tex", `repl' tex statmat(Y) ///
					rtitle(" `hl' \noalign{\smallskip}\multirow[t]{2}{3.5cm}{`title'}", "{overall}"\ "", "{between}"\"", "{within}") ///
					fragment sfmt(f) sdec(2)				
				}
			}
			
		* 	merge N,n & Tbar
			mat N = X[1...,5..6]
			matrix list N
			frmttable using "${dir_t}xt_sum_ac1_split_`r'_`l'.tex", merge tex statmat(N) ///
				ctitle("{N}", "{n}") sdec(0) fragment sfmt(g)
			mat T = X[1...,7]
			mat list T
			frmttable using "${dir_t}xt_sum_ac1_split_`r'_`l'.tex", merge tex statmat(T) ///
				ctitle("{$\mathrm{\bar{T}}$}") sdec(2) fragment
		restore
		}
	}
*/
/////////
//
// PART II – all couples II (not lagged vars)
//
/////////

***	load dataset
	use "${dir_data}gi_gen.dta", clear
*** Sample restricted according to ESt-Data sample used to derive rounding shares
*	xtset
	xtset cid syear
* 	age 25-64 (adjusted for time-lag 1 year)
	local age_min 25
	local age_max 64
	keep if age>=`age_min' & age<=`age_max' & age_m>=`age_min' & age_m<=`age_max'
*	married couples only
	keep if (((l1.partz<=1 & partz<=1) & (l1.partz==partz)) | (missing(l1.partz) & partz<=1 & movedinm<0))	
*	based on user input (two thresholds)
	drop decade decade_east
	// extended spec as requested by reviewer
	recode syear (1984/1990=1 "1984-1990") (1991/2003=2 "1991-2003") ///
		(2004/2016=3 "2004-2016") (else=.), generate(decade)
	// labels for output
	local p1lab "1984--1990"
	local p2lab "1991--2003"
	local p3lab "2004--2016"	
*	employed in t indicator (no longer on monthly basis!)
	gen yw = 0 if ywm==0
	replace yw = 1 if ywm>0 & !missing(ywm) // = employed
	gen yw_m = 0 if ywm_m==0
	replace yw_m = 1 if ywm_m>0 & !missing(ywm_m) // = employed
*	keep if full info available
	keep if !missing(agekidk)

***
***	(3) base sample
***

qui do "${dir_do}gi_deround_post.do"	

*  ------------------------------  *
* |     XT SUMMARY STATISTICS    | *
*  ------------------------------  *	
***	relabel (Women vs. Men)
	label var wis "Wife's share of household income (gross)"
	label var WEM "Wife earns more"
	
	label var yw "Employed"
	label var yw_m "Employed"
	label var yinc "Annual labor income (gross)"
	label var yinc_m "Annual labor income (gross)"
	label var vebzt "Weekly working hours (contractual)"
	label var vebzt_m "Weekly working hours (contractual)"
	label var tatzt "Weekly working hours (actual)"
	label var tatzt_m "Weekly working hours (actual)"
	label var NMW_weekly "Weekly housework hours"
	label var NMW_weekly_m "Weekly housework hours"
	label var age "Age"
	label var age_m "Age"
	
	label var cimpgro "Wife's or husband's income imputed"
	tab agekidk, gen(agekid)
		label var agekid1 "Age y. child (ref. none)"
		label var agekid2 "0--3 years"
		label var agekid3 "4--6 years"
		label var agekid4 "7--16 years"
	label var unempr_kkz "Unemployment rate, district level"

*** Summary stats by sample region
	forvalues s=1/2 {
	*	set sample region name macro & options
		if `s'==1 {
			local r West
			local decade 1 2 3
		}
		else if `s'==2 {
			local r East
			local decade 2 3
		}
		else {
			local r GER
			local opts
		}
		foreach l in `decade' { 
			preserve
		*	restrict
			keep if sampreg==`s' & decade==`l'
			cap drop n
			bys cid: gen n=_n // for estimation of within variation
		 *	make Table
			local sumstats ///
				agekid1 agekid2 agekid3 agekid4 unempr_kkz
			local cnt=0
			foreach xts in `sumstats' {
				local cnt=`cnt'+1
				local mtrx "X\Z"
				local repl "append"
				local title : var label `xts'
				local hl
				if "`xts'" == "agekid1" {
					local mtrx "Z"
					local repl "replace"
					local hl "\noalign{\smallskip}\hline\noalign{\smallskip}\emph{Couple}\\"
				}
			***	tabstat & xtsum (apply proper weights!)
			*	overall
				tabstat `xts' [aw=phrf], stats(mean sd min max) save
				matrix O = r(StatTotal)
			*	between
				cap drop m_`xts'
				egen m_`xts' = mean(`xts'), by(cid)
				tabstat m_`xts' [aw=phrf] if n==1, stats(mean sd min max) save
				matrix B = r(StatTotal)
			*	within
				cap drop w_`xts'
				gen w_`xts'=`xts'-m_`xts'
				tabstat w_`xts' [aw=phrf] if n==1, stats(mean sd min max) save
				matrix W = r(StatTotal)
			*	xtsum (n, N, T-bar) --> observations with invalid weights already omitted!
				xtsum `xts'
			*	complete matrix
				if `cnt'>1 &`cnt'<5 {
				matrix Z	=	(O[1,1],  O[2,1], 	O[3,1], 	O[4,1], 	r(N), 	r(n), 	r(Tbar))
				}
				else {
				matrix Z	=	(O[1,1],  O[2,1], 	O[3,1], 	O[4,1], 	r(N), 	r(n), 	r(Tbar) ///
									  \., B[2,1], 	B[3,1], 	B[4,1],		. ,		. ,		. ///
									  \., W[2,1], 	W[3,1], 	W[4,1],		. ,		. ,		. )
				}
				matrix list 	Z
				matrix X	=	`mtrx'
				matrix list 	X
				matrix Y	=	Z[1...,1..4]
				matrix list 	Y
				if `cnt'<5 {
				frmttable using "${dir_t}xt_sum_ac2_split_`r'_`l'.tex", `repl' tex statmat(Y) ///
					rtitle(" `hl' \noalign{\smallskip}\multirow[t]{2}{3.5cm}{`title'}", "{overall}") ///
					fragment sfmt(f) sdec(2)
				}
				else {
				frmttable using "${dir_t}xt_sum_ac2_split_`r'_`l'.tex", `repl' tex statmat(Y) ///
					rtitle(" `hl' \noalign{\smallskip}\multirow[t]{2}{3.5cm}{`title'}", "{overall}"\ "", "{between}"\"", "{within}") ///
					fragment sfmt(f) sdec(2)				
				}
			}
			
		* 	merge N,n & Tbar
			mat N = X[1...,5..6]
			matrix list N
			frmttable using "${dir_t}xt_sum_ac2_split_`r'_`l'.tex", merge tex statmat(N) ///
				ctitle("{N}", "{n}") sdec(0) fragment sfmt(g)
			mat T = X[1...,7]
			mat list T
			frmttable using "${dir_t}xt_sum_ac2_split_`r'_`l'.tex", merge tex statmat(T) ///
				ctitle("{$\mathrm{\bar{T}}$}") sdec(2) fragment
		restore
		}
	}	
