////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- WEM -> f1.WEM; Dynamic Panel Model test --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

*	load dataset
	use "${dir_data}gi_gen.dta", clear
	global delspike 1
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
*	options for regression model (do not drop!)	
	global opts_general /*		
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
	global opts_married ///
		& (((l1.partz<=1 & partz<=1) & (l1.partz==partz)) | (missing(l1.partz) & partz<=1 & movedinm<0))
*	no movers
	global opts_sampreg ///
		& sampreg==birthreg & sampreg == birthreg_m				
*	spec adjustment
	drop decade decade_east
	// extended spec as requested by reviewer
	recode syear (1984/1990=1 "1984-1990") (1991/2003=2 "1991-2003") ///
		(2004/2016=3 "2004-2016") (else=.), generate(decade)
	// labels for output
	local p1lab "1984--1990"
	local p2lab "1991--2003"
	local p3lab "2004--2016"
	clonevar decade_east = decade
	replace decade_east=. if decade_east==1	
	
***
*** (2) De-Round
***

	do "${dir_do}gi_deround.do"
	
***
*** (3) Recodings
***	

	quietly do "${dir_do}gi_deround_post.do"
	
***
*** (4) Dynamic panel model
***

xtset cid syear

rename lnyinc winc
rename lnyinc_m minc

// gen lagged DV (allow for not having income in t)
gen f1WEM = f1.WEM
replace f1WEM = 1 if missing(f1WEM) & !missing(yinc, yinc_m) & yinc_m==0
replace f1WEM = 0 if missing(f1WEM) & !missing(yinc, yinc_m) & yinc==0

// gen interactions manually
gen winc2 = winc*winc
gen winc3 = winc*winc*winc
gen minc2 = minc*minc
gen minc3 = minc*minc*minc
gen wincxminc = winc*minc

// gen dummies manually
tab agegr5, gen(agegr5)
tab agegr5_m, gen(agegr5_m)
tab agekidk, gen(agekidk)
tab syear, gen(syear)

//
// LOOP
//

eststo clear
// sample region
forvalues s=1/2 {
	if `s'==1 {
		local r West
		levelsof decade, local(decades)
	}
	else if `s'==2 {
		local r East
		levelsof decade_east, local(decades)
	}
	// decades
	foreach l of local decades {
		
		////////////////////////////////////////////////////////////////////////
		//
		//	DYNAMIC PANEL DATA ESTIMATOR TEST
		//
		////////////////////////////////////////////////////////////////////////
		
		// gen year dummies to keep instruments in range
		cap drop yd*
		tab syear if decade==`l', gen(yd)
		
		/*
		 Boundaries: OLS and FE
		*/
		
		// ols
		qui reg f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
			winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
			unempr_kkz yd* if sampreg==`s' & decade==`l' ///
			$opts_general $opts_married, cluster(cid)
		eststo ols_`s'_`l'
		
		// fe
		qui xtreg f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
			winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
			unempr_kkz yd* if sampreg==`s' & decade==`l' ///
			$opts_general $opts_married, fe cluster(cid)
		local N = string(e(N), "%9.0gc")
		local N_g = string(e(N_g), "%9.0gc")
		local postfoot "`postfoot' & {`N'}"
		local postfoot2 "`postfoot2' & {`N_g'}"
		//eststo fe_`s'_`l'
		
		/*
		
		 GMM and System-GMM
		 
		 ----------------------------------
		 Sensitivity - We use a 2x3x2 design:
		 ----------------------------------
		 
		 1 - Arellano-Bond vs. Blundell-Bond
		 
		 2 - Exogeneity of regressors (WEM_i,t-1 always cons. endogenous):
		 
			1 X_it and L_it are considered as strictly exogenous
			2 X_it are considered strictly exogenous, L_it considered predetermined
			3 X_it are considered strictly exogneous, L_it considered endogenous
		 
		 3 - Lags/Instrument count (Instruments vs. N) - Only necessary in the predetermined/endogenous case
			
			1 Lags 2-6
			2 All lags, but collapsed into one moment condition
		
		*/
		
		// 		 
		// AB
		//
		
		local m "ab"
		
		// exogenous, all lags collapsed
		local e "ex"
		xi: xtabond2 f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
					winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
					unempr_kkz yd* ///
					if sampreg==`s' & decade==`l' $opts_general $opts_married, ///
					gmm(L.(f1WEM), orthog collapse) ///
					iv(	agegr52-agegr58 agegr5_m2-agegr5_m8 ///
						winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
						agekidk2-agekidk4 unempr_kkz yd* ) ///
					twostep orthog robust noleveleq
		eststo `m'_`e'_`s'_`l'
		estadd scalar `m'_ar1_`e' = e(ar1p) // AR(1) p value
		estadd scalar `m'_ar2_`e' = e(ar2p) // AR(2) p value
		estadd scalar `m'_sargan_`e' = e(sarganp) // Sargan p value
		estadd scalar `m'_hansen_`e' = e(hansenp) // Hansen p value
		local I = string(e(j), "%9.0gc")
		local `m'_icnt_`e' "``m'_icnt_`e'' & {`I'}"
		
		// predetermined, all lags collapsed
		local e "pre"
		xi: xtabond2 f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
					winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
					unempr_kkz yd* ///
					if sampreg==`s' & decade==`l' $opts_general $opts_married, ///
					gmm(L.(f1WEM) ///
						winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
						, orthog collapse) ///
					iv( agegr52-agegr58 agegr5_m2-agegr5_m8 ///
						agekidk2-agekidk4 unempr_kkz yd* ) ///
					twostep orthog robust noleveleq
		eststo `m'_`e'_`s'_`l'
		estadd scalar `m'_ar1_`e' = e(ar1p) // AR(1) p value
		estadd scalar `m'_ar2_`e' = e(ar2p) // AR(2) p value
		estadd scalar `m'_sargan_`e' = e(sarganp) // Sargan p value
		estadd scalar `m'_hansen_`e' = e(hansenp) // Hansen p value
		local I = string(e(j), "%9.0gc")
		local `m'_icnt_`e' "``m'_icnt_`e'' & {`I'}"
		
		// endogenous, all lags collapsed
		local e "end"
		xi: xtabond2 f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
					winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
					unempr_kkz yd* ///
					if sampreg==`s' & decade==`l' $opts_general $opts_married, ///
					gmm(L.(f1WEM winc winc2 winc3 minc minc2 minc3 wincxminc ///
						yinc_imp yinc_imp_m) , orthog collapse) ///
					iv( agegr52-agegr58 agegr5_m2-agegr5_m8 ///
						agekidk2-agekidk4 unempr_kkz yd* ) ///
					twostep orthog robust noleveleq
		eststo `m'_`e'_`s'_`l'
		estadd scalar `m'_ar1_`e' = e(ar1p) // AR(1) p value
		estadd scalar `m'_ar2_`e' = e(ar2p) // AR(2) p value
		estadd scalar `m'_sargan_`e' = e(sarganp) // Sargan p value
		estadd scalar `m'_hansen_`e' = e(hansenp) // Hansen p value
		local I = string(e(j), "%9.0gc")
		local `m'_icnt_`e' "``m'_icnt_`e'' & {`I'}"
		
		//
		// BB
		//
		
		local m "bb"

		// exogenous, all lags collapsed
		local e "ex"
		xi: xtabond2 f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
					winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
					unempr_kkz yd* ///
					if sampreg==`s' & decade==`l' $opts_general $opts_married, ///
					gmm(L.(f1WEM), orthog collapse) ///
					iv(	agegr52-agegr58 agegr5_m2-agegr5_m8 ///
						winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
						agekidk2-agekidk4 unempr_kkz yd* ) ///
					twostep orthog robust
		eststo `m'_`e'_`s'_`l'
		estadd scalar `m'_ar1_`e' = e(ar1p) // AR(1) p value
		estadd scalar `m'_ar2_`e' = e(ar2p) // AR(2) p value
		estadd scalar `m'_sargan_`e' = e(sarganp) // Sargan p value
		estadd scalar `m'_hansen_`e' = e(hansenp) // Hansen p value
		local I = string(e(j), "%9.0gc")
		local `m'_icnt_`e' "``m'_icnt_`e'' & {`I'}"
		
		// predetermined, all lags collapsed
		local e "pre"
		xi: xtabond2 f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
					winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
					unempr_kkz yd* ///
					if sampreg==`s' & decade==`l' $opts_general $opts_married, ///
					gmm(L.(f1WEM) ///
						winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
						 , orthog collapse) ///
					iv( agegr52-agegr58 agegr5_m2-agegr5_m8 ///
						agekidk2-agekidk4 unempr_kkz yd* ) ///
					twostep orthog robust
		eststo `m'_`e'_`s'_`l'
		estadd scalar `m'_ar1_`e' = e(ar1p) // AR(1) p value
		estadd scalar `m'_ar2_`e' = e(ar2p) // AR(2) p value
		estadd scalar `m'_sargan_`e' = e(sarganp) // Sargan p value
		estadd scalar `m'_hansen_`e' = e(hansenp) // Hansen p value
		local I = string(e(j), "%9.0gc")
		local `m'_icnt_`e' "``m'_icnt_`e'' & {`I'}"
		
		// endogenous, all lags collapsed
		local e "end"
		xi: xtabond2 f1WEM L.f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
					winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
					unempr_kkz yd* ///
					if sampreg==`s' & decade==`l' $opts_general $opts_married, ///
					gmm(L.(f1WEM winc winc2 winc3 minc minc2 minc3 wincxminc ///
						yinc_imp yinc_imp_m) , orthog collapse) ///
					iv( agegr52-agegr58 agegr5_m2-agegr5_m8 ///
						agekidk2-agekidk4 unempr_kkz yd* ) ///
					twostep orthog robust
		eststo `m'_`e'_`s'_`l'
		estadd scalar `m'_ar1_`e' = e(ar1p) // AR(1) p value
		estadd scalar `m'_ar2_`e' = e(ar2p) // AR(2) p value
		estadd scalar `m'_sargan_`e' = e(sarganp) // Sargan p value
		estadd scalar `m'_hansen_`e' = e(hansenp) // Hansen p value
		local I = string(e(j), "%9.0gc")
		local `m'_icnt_`e' "``m'_icnt_`e'' & {`I'}"
		
		/*
		 
		 Alternative to GMM estimations: LSDV with bias correction.
		 
		 - Initial bias determined by using Anderson and Hsiao Estimator 
			(starting value seems to be largely irrelevant)
		 - Sensitivity: Bias correction level 1
		
		*/
		
		// lsdvc	
		qui xtlsdvc f1WEM agegr52-agegr58 agegr5_m2-agegr5_m8 agekidk2-agekidk4 ///
			winc winc2 winc3 minc minc2 minc3 wincxminc yinc_imp yinc_imp_m ///
			unempr_kkz syear1-syear33 if sampreg==`s' & decade==`l' ///
			$opts_general $opts_married, initial(ah) vcov(10)
		eststo lsdvc_`s'_`l'
	}
}

// First part of table: OLS, FE, AB

local m "ab"

esttab ols* using "${dir_t}lsdv_`m'.tex", replace fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	prehead("& \multicolumn{3}{c}{{\textit{West Germany}}} & \multicolumn{2}{c}{{\textit{East Germany}}} \\ \cmidrule(l{1em}){2-4}\cmidrule(l{1em}){5-6} & {\Centerstack{(1)\\1984--1990}} & {\Centerstack{(2)\\1991--2003}} & {\Centerstack{(3)\\2004--2016}} & {\Centerstack{(4)\\1991--2003}} & {\Centerstack{(5)\\2004--2016}}\\ \hline") ///
	coeflabels(L.f1WEM "\noalign{\smallskip}\textbf{\textit{OLS}} & & & & & \\ wifeEarnsMore in \textit{t--1}") ///
	collabels(none)
esttab fe* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\hline\noalign{\smallskip}\textbf{\textit{FE}} & & & & & \\ wifeEarnsMore in \textit{t--1}") ///
	collabels(none)

local e "ex"	
esttab ab_ex* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\hline\noalign{\smallskip}\textbf{\textit{AB}} & & & & & \\ \noalign{\smallskip}\(L_{i,t-1}\)\textit{ strictly exogenous, all lags collapsed} & & & & & \\ \noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
	collabels(none) substitute(\_ _) postfoot("Instruments ``m'_icnt_`e'' \\ ") ///
	stats(`m'_ar1_`e' `m'_ar2_`e' `m'_sargan_`e' `m'_hansen_`e', ///
		label("AR(1) p-value" "AR(2) p-value" "Sargan p-value" "Hansen p-value") fmt(3 3 3 3))
local e "pre"		
esttab ab_pre* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\noalign{\medskip}\(L_{i,t-1}\)\textit{ predetermined, all lags collapsed} & & & & & \\ \noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
	collabels(none) substitute(\_ _) postfoot("Instruments ``m'_icnt_`e'' \\ ") ///
	stats(`m'_ar1_`e' `m'_ar2_`e' `m'_sargan_`e' `m'_hansen_`e', ///
		label("AR(1) p-value" "AR(2) p-value" "Sargan p-value" "Hansen p-value") fmt(3 3 3 3))
local e "end"		
esttab ab_end* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\noalign{\medskip}\(L_{i,t-1}\)\textit{ endogenous, all lags collapsed} & & & & & \\ \noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
	collabels(none) substitute(\_ _) postfoot("Instruments ``m'_icnt_`e'' \\ \hline \noalign{\smallskip} N (couple-years) `postfoot' \\ n (couples) `postfoot2' \\") ///
	stats(`m'_ar1_`e' `m'_ar2_`e' `m'_sargan_`e' `m'_hansen_`e', ///
		label("AR(1) p-value" "AR(2) p-value" "Sargan p-value" "Hansen p-value") fmt(3 3 3 3)) ///

// First part of table: OLS, FE, BB, LSDVC	
	
local m "bb"

esttab ols* using "${dir_t}lsdv_`m'.tex", replace fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	prehead("& \multicolumn{3}{c}{{\textit{West Germany}}} & \multicolumn{2}{c}{{\textit{East Germany}}} \\ \cmidrule(l{1em}){2-4}\cmidrule(l{1em}){5-6} & {\Centerstack{(1)\\1984--1990}} & {\Centerstack{(2)\\1991--2003}} & {\Centerstack{(3)\\2004--2016}} & {\Centerstack{(4)\\1991--2003}} & {\Centerstack{(5)\\2004--2016}}\\ \hline") ///
	coeflabels(L.f1WEM "\noalign{\smallskip}\textbf{\textit{OLS}} & & & & & \\ wifeEarnsMore in \textit{t--1}") ///
	collabels(none)
esttab fe* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\hline\noalign{\smallskip}\textbf{\textit{FE}} & & & & & \\ wifeEarnsMore in \textit{t--1}") ///
	collabels(none)

local e "ex"
esttab bb_ex* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\hline\noalign{\smallskip}\textbf{\textit{BB}} & & & & & \\ \noalign{\smallskip}\(L_{i,t-1}\)\textit{ strictly exogenous, all lags collapsed} & & & & & \\ \noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
	collabels(none) substitute(\_ _) postfoot("Instruments ``m'_icnt_`e'' \\ ") ///
	stats(`m'_ar1_`e' `m'_ar2_`e' `m'_sargan_`e' `m'_hansen_`e', ///
		label("AR(1) p-value" "AR(2) p-value" "Sargan p-value" "Hansen p-value") fmt(3 3 3 3))
local e "pre"		
esttab bb_pre* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\noalign{\medskip}\(L_{i,t-1}\)\textit{ predetermined, all lags collapsed} & & & & & \\ \noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
	collabels(none) substitute(\_ _) postfoot("Instruments ``m'_icnt_`e'' \\ ") ///
	stats(`m'_ar1_`e' `m'_ar2_`e' `m'_sargan_`e' `m'_hansen_`e', ///
		label("AR(1) p-value" "AR(2) p-value" "Sargan p-value" "Hansen p-value") fmt(3 3 3 3))
local e "end"		
esttab bb_end* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\noalign{\medskip}\(L_{i,t-1}\)\textit{ endogenous, all lags collapsed} & & & & & \\ \noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
	collabels(none) substitute(\_ _) postfoot("Instruments ``m'_icnt_`e'' \\ ") ///
	stats(`m'_ar1_`e' `m'_ar2_`e' `m'_sargan_`e' `m'_hansen_`e', ///
		label("AR(1) p-value" "AR(2) p-value" "Sargan p-value" "Hansen p-value") fmt(3 3 3 3))

esttab lsdvc* using "${dir_t}lsdv_`m'.tex", append fragment cells(b(fmt(%9.3f) star) se(par("{(}" "{)}"))) compress ///
	nolabel noomitted nobaselevels nonumbers nomtitles noobs nolines nodepvars nonotes keep(*WEM*) ///	
	coeflabels(L.f1WEM "\hline\noalign{\smallskip}\textbf{\textit{LSDVC}} & & & & & \\ wifeEarnsMore in \textit{t--1}") ///
	postfoot("\hline \noalign{\smallskip} N (couple-years) `postfoot' \\ n (couples) `postfoot2' \\ ") ///
	collabels(none)
	

/*

How does the probability of a wife of out-earning her husband change after
she manages to do it?

We would assume that the probability increases for all wives, but the question
is then: how much? There is a clear trend for West Germany.

egen totWEM = total(WEM), by(pid decade)
bys pid decade: gen toty = _N
gen i = 0 
replace i = 1 if totWEM==0 | totWEM == toty

xtset cid syear

tab f1WEM WEM if WEM==0 & sampreg==1 & decade==1 & i==0 $opts_general $opts_married, col
tab f1WEM WEM if WEM==1 & sampreg==1 & decade==1 & i==0 $opts_general $opts_married, col

tab f1WEM WEM if WEM==0 & sampreg==1 & decade==2 & i==0 $opts_general $opts_married, col
tab f1WEM WEM if WEM==1 & sampreg==1 & decade==2 & i==0 $opts_general $opts_married, col

tab f1WEM WEM if WEM==0 & sampreg==1 & decade==3 & i==0 $opts_general $opts_married, col
tab f1WEM WEM if WEM==1 & sampreg==1 & decade==3 & i==0 $opts_general $opts_married, col

tab f1WEM WEM if WEM==0 & sampreg==2 & decade==2 & i==0 $opts_general $opts_married, col
tab f1WEM WEM if WEM==1 & sampreg==2 & decade==2 & i==0 $opts_general $opts_married, col

tab f1WEM WEM if WEM==0 & sampreg==2 & decade==3 & i==0 $opts_general $opts_married, col
tab f1WEM WEM if WEM==1 & sampreg==2 & decade==3 & i==0 $opts_general $opts_married, col
*/

