////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Summary Statistics --
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
	// extended spec as requested by reviewer (1984 excluded, no check poss. if self-emp. or co-working)
	recode syear (1984/1991=1 "1984-1990") (1992/2004=2 "1991-2003") ///
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

*  ------------------------------  *
* |     SUMMARY STATISTICS    	 | *
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
		label var agekid1 "Age young. child (ref. none)"
		label var agekid2 "0--3 years"
		label var agekid3 "4--6 years"
		label var agekid4 "7--16 years"
	label var unempr_kkz "Unemployment rate, district level"

*** Summary stats by sample region
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
			/*
			if inlist(`xts', yinc, yinc_m, ftpt_m, ftpt, wis, wifeEarnsMore) {
				local dec decade_inc
				local age "age<=64 & age_m<=64"
			}
			else {
				local dec decade
				local age "age>=26 & age_m>=26"
			} */
			local dec decade
		***	tabstat
		*	West 1984-1990
			tabstat `xts' [aw=phrf] if sampreg==1 & `dec'==1, stats(mean sd min max) save
			matrix W1 = r(StatTotal)
		*	West 1997-2006
			tabstat `xts' [aw=phrf] if sampreg==1 & `dec'==2, stats(mean sd min max) save
			matrix W2 = r(StatTotal)
		*	West 2007-2016
			tabstat `xts' [aw=phrf] if sampreg==1 & `dec'==3, stats(mean sd min max) save
			matrix W3 = r(StatTotal)
		*	East 1997-2006
			tabstat `xts' [aw=phrf] if sampreg==2 & `dec'==2, stats(mean sd min max) save
			matrix E2 = r(StatTotal)
		*	East 2007-2016
			tabstat `xts' [aw=phrf] if sampreg==2 & `dec'==3, stats(mean sd min max) save
			matrix E3 = r(StatTotal)
		*	complete matrix
			matrix Z	=	(W1[1,1],  W1[2,1], W2[1,1], W2[2,1], W3[1,1], W3[2,1], E2[1,1],  E2[2,1], E3[1,1], E3[2,1])
			matrix list 	Z
			matrix X	=	`mtrx'
			matrix list 	X
			matrix Y	=	Z[1...,1..10]
			matrix list 	Y
			frmttable using "${dir_t}xt_sum_data.tex", `repl' tex statmat(Y) ///
				rtitle(" `hl' \noalign{\smallskip}{`title'}") ///
				ctitle("","{Mean}", "{Std. Dev.}","{Mean}", "{Std. Dev.}","{Mean}", "{Std. Dev.}" ,"{Mean}", "{Std. Dev.}","{Mean}", "{Std. Dev.}") ///
				fragment sfmt(f) sdec(2)
		}
		*	xtsum (n, N)
		xtsum yinc if sampreg==1 & decade==1
			local W1n = r(n)
			local W1N = r(N)
		xtsum yinc if sampreg==1 & decade==2
			local W2n = r(n)
			local W2N = r(N)		
		xtsum yinc if sampreg==1 & decade==3
			local W3n = r(n)
			local W3N = r(N)
		xtsum yinc if sampreg==2 & decade==2
			local E2n = r(n)
			local E2N = r(N)
		xtsum yinc if sampreg==2 & decade==3
			local E3n = r(n)
			local E3N = r(N)	
		matrix N = (	`W1N', . , `W2N', . , `W3N', . , `E2N', . ,`E3N', . \  ///
						`W1n', . , `W2n', . , `W3n', . , `E2n', . , `E3n', . )
		frmttable using "${dir_t}xt_sum_data.tex", append tex statmat(N) ///
			rtitle("\noalign{\smallskip}\hline\noalign{\smallskip}{N}" \, "{n}") ///
			fragment sfmt(g) sdec(0)
	
/////////
//
// PART II – all couples
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
	recode syear (1984/1991=1 "1984-1990") (1992/2004=2 "1991-2003") ///
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
	keep if !missing(yw)
	
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
		label var agekid1 "Age young. child (ref. none)"
		label var agekid2 "0--3 years"
		label var agekid3 "4--6 years"
		label var agekid4 "7--16 years"
	label var unempr_kkz "Unemployment rate, district level"

*** Summary stats by sample region
	 *	make Table
		local sumstats ///
			yw_m yw
		foreach xts in `sumstats' {
			local mtrx "X\Z"
			local repl "append"
			local title : var label `xts'
			local hl
			if "`xts'" == "yw_m" {
				local mtrx "Z"
				local repl "replace"
				local hl "\noalign{\smallskip}\hline\noalign{\smallskip}\noalign{\smallskip}\textbf{All couples}\\ \noalign{\smallskip}\hline \noalign{\smallskip}\emph{Husband}\\ "
			}
			else if "`xts'" == "yw" {
				local hl "\noalign{\smallskip}\hline\noalign{\smallskip}\emph{Wife}\\"
			}
			if inlist(`xts', yinc, yinc_m, wis, WEM) {
				local dec decade_inc
			}
			else {
				local dec decade
			}
		***	tabstat
		*	West 1984-1990
			tabstat `xts' [aw=phrf] if sampreg==1 & decade==1, stats(mean sd min max) save
			matrix W1 = r(StatTotal)
		*	West 1997-2006
			tabstat `xts' [aw=phrf] if sampreg==1 & decade==2, stats(mean sd min max) save
			matrix W2 = r(StatTotal)
		*	West 2007-2016
			tabstat `xts' [aw=phrf] if sampreg==1 & decade==3, stats(mean sd min max) save
			matrix W3 = r(StatTotal)
		*	East 1997-2006
			tabstat `xts' [aw=phrf] if sampreg==2 & decade==2, stats(mean sd min max) save
			matrix E2 = r(StatTotal)
		*	East 2007-2016
			tabstat `xts' [aw=phrf] if sampreg==2 & decade==3, stats(mean sd min max) save
			matrix E3 = r(StatTotal)
		*	complete matrix
			matrix Z	=	(W1[1,1],  W1[2,1], W2[1,1], W2[2,1], W3[1,1], W3[2,1], E2[1,1],  E2[2,1], E3[1,1], E3[2,1])
			matrix list 	Z
			matrix X	=	`mtrx'
			matrix list 	X
			matrix Y	=	Z[1...,1..10]
			matrix list 	Y
			frmttable using "${dir_t}xt_sum_data.tex", append tex statmat(Y) ///
				rtitle(" `hl' \noalign{\smallskip}{`title'}") ///
				ctitle("","{Mean}", "{Std. Dev.}","{Mean}", "{Std. Dev.}","{Mean}", "{Std. Dev.}" ,"{Mean}", "{Std. Dev.}","{Mean}", "{Std. Dev.}") ///
				fragment sfmt(f) sdec(2)
		}
		*	xtsum (n, N)
		xtsum yw if sampreg==1 & decade==1
			local W1n = r(n)
			local W1N = r(N)
		xtsum yw if sampreg==1 & decade==2
			local W2n = r(n)
			local W2N = r(N)		
		xtsum yw if sampreg==1 & decade==3
			local W3n = r(n)
			local W3N = r(N)
		xtsum yw if sampreg==2 & decade==2
			local E2n = r(n)
			local E2N = r(N)
		xtsum yw if sampreg==2 & decade==3 
			local E3n = r(n)
			local E3N = r(N)	
		matrix N = (	`W1N', . , `W2N', . , `W3N', . , `E2N', . ,`E3N', . \  ///
						`W1n', . , `W2n', . , `W3n', . , `E2n', . , `E3n', . )
		frmttable using "${dir_t}xt_sum_data.tex", append tex statmat(N) ///
			rtitle("\noalign{\smallskip}\hline\noalign{\smallskip}{N}" \, "{n}") ///
			fragment sfmt(g) sdec(0)
