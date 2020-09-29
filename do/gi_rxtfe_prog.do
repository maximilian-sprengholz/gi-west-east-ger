////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Monte Carlo Panel Regression Simulation Program --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

capture program drop rxtfe
program define rxtfe, rclass 
{
*	syntax
	syntax, ///
	dv(str) ///
	iv(str) ///
	percut(integer) ///
	samp(integer) ///
	spec(integer)
*	clean strings (sometimes buggy)	
	local dv = "`dv'"
	local iv = "`iv'"

***
*** (1) Sample/Specification preparation
***
	
*	load dataset
	use "${dir_f}gi_gen.dta", clear

*	xtset
	xtset cid syear
* 	age 25-64 
	local age_min 26
	local age_max 65
	keep if age>=`age_min' & age<=`age_max' & age_m>=`age_min' & age_m<=`age_max'
* 	no self-employed
	keep if (((l1.stib>440 | l1.stib<410) & (l1.stib_m>440 | l1.stib_m<410) & !missing(l1.stib, l1.stib_m)) ///
		  | ((stib>440 | stib<410) & (stib_m>440 | stib_m<410) & missing(l1.stib, l1.stib_m)))
	keep if (l1.pgallbet!=5 & l1.pgallbet_m!=5) ///
		  | (pgallbet!=5 & pgallbet_m!=5 & missing(l1.pgallbet, l1.pgallbet_m))
*	identify spouses within same industry, occupation & company size
	cap drop cowork
	gen cowork=0
	replace cowork=1 if (l1.pgbetr==l1.pgbetr_m & l1.e11105==l1.e11105_m & l1.pgnace==l1.pgnace_m) ///
		& !missing(l1.pgbetr, l1.pgbetr_m, l1.e11105, l1.e11105_m, l1.pgnace, l1.pgnace_m)

*------------------------------------------------------------------------------*
*
* 	Sample/Specification: 
* 	-----------------------------
* 
* 	-> t-1 positive income (no benefits, no education)
*	-> t no restrictions (but contractual hours reported)
*	-> different polynomials for income values
*
*------------------------------------------------------------------------------*

*	options for regression model (do not drop!)	
	local opts_general /*		
		married or cohabiting couples (at time of interview): if no l1 availabe, use current info!
	*/	& ( ((l1.partz<=2 & partz<=2) & (l1.partz==partz)) ///
			| (missing(l1.partz) & partz<=2 & movedinm<0) ///
		  ) /* // caveat: there are possible combinations where partners might not have been living together in the pervious year 			
		no co-working couples
	*/	& cowork==0 /*
		working & positive income
	*/	& ywm>0 & ywm_m>0 ///
		& yinc>0 & yinc_m>0 & !missing(yinc, yinc_m) /*
		no unemployed/pensioner/vocational training/in edu/motherhood/army or civil service 
		(make 1 criterium – 0s are also given when no data is available)
	*/	& !inlist(1, 	yunemp_full, yunemp_full_m, ///
						yvoc_full, yvoc_full_m, ///
						ypen_full, ypen_full_m, ///
						ymother_full, ymother_full_m, ///
						yschool_full, yschool_full_m, ///
						yservice_full, yservice_full_m )
*	married couples only
	if `samp' != 0 {
		local opts_married ///
			& (((l1.partz<=1 & partz<=1) & (l1.partz==partz)) | (missing(l1.partz) & partz<=1 & movedinm<0))
	}
	else {
		local opts_married
	}
*	additionally: at least one spouse born in Germany
	if `samp' == 2 {
		local opts_corigin ///
			& (corigin==1 | corigin_m==1)
	}
	else {
		local opts_corigin
	}
*	not moved between East/West
	if `samp' == 3 {
		local opts_sampreg ///
			& sampreg==birthreg & sampreg==birthreg_m	
	}
	else {
		local opts_sampreg
	}
*	regression specification
	if `spec' == 0 {
		local inccov 
	}	
	else if `spec' == 1 {
		local inccov "c.winc##c.winc##c.winc c.minc##c.minc##c.minc"
	}
	else if `spec' == 2 {
		local inccov "c.winc c.minc c.suminc"
	}
	else if `spec' == 3 {
		local inccov "c.winc##c.winc##c.winc c.minc##c.minc##c.minc c.winc#c.minc"
	}
	else if `spec' == 4 {
		local inccov "c.winc##c.winc##c.winc c.minc##c.minc##c.minc c.winc#c.minc yinc_imp yinc_imp_m"
	}
	else if `spec' == 5 {
		// add care dummy (reviewer request)
		local inccov "ib2.care c.winc##c.winc##c.winc c.minc##c.minc##c.minc c.winc#c.minc yinc_imp yinc_imp_m"
	}	
	else {
		local inccov
	}
*	decade choice
*	based on user input (two thresholds)
	if `percut' == 1 {
		drop decade decade_east
		// extended spec as requested by reviewer
		recode syear (1984/1990=1 "1984-1990") (1991/2003=2 "1991-2003") ///
			(2004/2016=3 "2004-2016") (else=.), generate(decade)
		// labels for output
		local p1lab "1983--1990"
		local p2lab "1991--2003"
		local p3lab "2004--2016"
		clonevar decade_east = decade
		replace decade_east=. if decade_east==1	
	}
	else {
		// labels for output
		local p1lab "1983--1990"
		local p2lab "1997--2006"
		local p3lab "2007--2016"				
	}	
/*	sample size
	preserve
		keep if !missing(decade) `opts_general'
		bys cid: gen cids = _n
		noisily count if cids==1
	restore 
*/
	
***
*** (2) De-Round
***

	do "${dir_do}gi_deround.do"
	
***
*** (3) Recodings
***	

	do "${dir_do}gi_deround_post.do"
	
***
*** (4) Regressions
***

*** Preparation
//	xtset
	xtset cid syear
//	annual working indicator replaces lfp var (only valid for interview month)
	if "`dv'" == "f1yw" {
		gen f1yw = 0 if f1.ywm==0
		replace f1yw = 1 if (f1.ywm>0 & !missing(f1.ywm)) // = employed
	}	
//	income vars	
	rename lnyinc winc
	rename lnyinc_m minc
	gen suminc = ln(yinc + yinc_m)
//	alternative working hour measures	
	// weekly hours based on annual working hours
	gen f1ywh = f1.ywh/(12*4.333)
	gen f1ywh_m = f1.ywh_m/(12*4.333) // weekly working hours		
	// replace with missing if implausibly low working hours
	// below 5hrs/week, below minimum amount of months x 4.33 x 35h
	replace f1ywh = . if f1ywh<=1 | f1.ywm==. ///
		| f1.ywh<((f1.ywm*4.33*35)/(12*4.33))
	replace f1ywh_m = . if f1ywh_m<=1 | f1.ywm_m==. ///
		| f1.ywh_m<((f1.ywm_m*4.33*35)/(12*4.33))
	replace vebzt = . if vebzt<=1
	// share of part-time relative to full-time months
	// if multiple jobs, replace with full-time
	replace yftm=0 if missing(yftm)
	replace yptm=0 if missing(yptm)
	gen f1ftpt = f1.yftm / (f1.yftm + f1.yptm)
	replace f1ftpt = 1 if f1.yftm!=0 & f1.yptm==0
	replace f1ftpt = 0 if f1.yftm==0 & f1.yptm!=0	
	replace f1ftpt = . if f1.yftm==0 & f1.yptm==0
*	mean weight
//	egen pw = mean(phrf), by(`id')
*	covariates
	local cov ///
		i.agegr5 i.agegr5_m i.agekidk ///
		`inccov' ///
		unempr_kkz i.syear // l1.unempr_kkz (?)
*** (1) West/East ***
	levelsof sampreg, local(states)
	foreach s of local states {
	preserve
***	set sample region name macro & decades	
		if `s'==1 {
			local r West
			levelsof decade, local(decades) // NMW available for two decades only
		}
		else if `s'==2 {
			local r East
			levelsof decade_east, local(decades)
		}
	*** (3) decades ***
		foreach l of local decades {
			local p : label decade `l' // use labels for titles
			dis as result "" _newline "{hline 80}" ///
			_newline "Fixed-Effects Regression `dv' on `iv' for `r' `p'" ///
			_newline "{hline 80}"
		* 	panel regression continuous iv *	
			xtreg `dv' i.`iv' `cov' ///
				if sampreg==`s' & decade==`l' ///
				`opts_general' `opts_married' `opts_corigin' `opts_sampreg', fe cluster(cid)
		* 	extract estimates for scalar returns
		  * b
			matrix C = e(b)
			matrix list C
			return scalar `dv'_b_`iv'_`r'_`l' = C[1,2]
		  * se	
			matrix V = e(V)
			matrix V = vecdiag(V)
			matrix list V
			return scalar `dv'_se_`iv'_`r'_`l' = sqrt(V[1,2])
		  *	p-value based on z statistic: z=b/se; p=2*normal(-abs(z))
			return scalar `dv'_p_`iv'_`r'_`l' = 2*normal(-abs(C[1,2]/sqrt(V[1,2])))
		  * N / N groups / R2 / adj. R2
			return scalar `dv'_r2_`iv'_`r'_`l' = e(r2)
			return scalar `dv'_r2a_`iv'_`r'_`l' = e(r2_a)
			return scalar `dv'_N_`iv'_`r'_`l' = e(N)
			return scalar `dv'_Ng_`iv'_`r'_`l' = e(N_g)
		  * clear	
			ereturn clear		
		}
	restore
	dis as result _newline "{hline 80}" ///
		_newline"----------> dataset restored" ///
		_newline "{hline 80}"
	}
}
end
