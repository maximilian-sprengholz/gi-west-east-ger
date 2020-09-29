////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Monte Carlo Discontinuity Test Simulation Program Output Handler --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

capture program drop rdcdpost
program define rdcdpost, rclass
{
*	syntax
	syntax, ///
		dv(str) ///
		percut(integer) ///
		samp(integer) ///
		sel(string) ///
		cutoff(real) ///
		binsize(real) ///
		reps(integer) ///
		[ delspike graph ]
*	clean strings (sometimes buggy)	
	local dv = "`dv'"
*	set sample names for output
	if `samp' == 0 {
		local srs "allcohab" // full sample, including cohabiting couples
	}
	else if `samp' == 1 {
		local srs "all" // full sample, married couples only (main spec)
	}	
	else if `samp' == 2 {
		local srs "nomig" // only german born
	}
	else if `samp' == 3 {
		local srs "nomov" // not moved between East/West since 1989
	}
	else {
		local srs
	}
*	delete excess spike?
	if "`delspike'" != "" {
		local dsp "_dspike" // excess spike of equal earning couples deleted
		global delspike = 1 // pass on to called de-round do-file
	}
	else {
		local dsp // not deleted
		global delspike = 0
	}
*	strip dots off cutoff and binsize real and pass to string
	local co=usubinstr("`cutoff'",".","dot",.)
	local co "co`co'"
	local bsize=usubinstr("`binsize'",".","",.)
	local bs "bs`bsize'"
*	period cut
	local pc "pc`percut'"
*	resent counter
	global run = 0

***
*** Initialize
***	

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
		keep if (((l1.partz<=1 & partz<=1) & (l1.partz==partz)) | (missing(l1.partz) & partz<=1 & movedinm<0))
	}
*	additionally: at least one spouse born in Germany
	if `samp' == 2 {
		keep if corigin==1 & corigin_m==1
	}
*	not moved between East/West
	if `samp' == 3 {
		keep if sampreg==birthreg & sampreg==birthreg_m	
	}				
*	decade adjustment (to assign correct years bc of retrosspective survey)
*	based on user input (two thresholds)
	drop decade decade_east
	if `percut' == 1 {
		// extended spec as requested by reviewer
		recode syear (1984/1991=1 "1983-1990") (1992/2004=2 "1991-2003") ///
			(2005/2016=3 "2004-2016") (else=.), generate(decade)
		// labels for output
		local p1lab "1983-1990"
		local p2lab "1991-2003"
		local p3lab "2004-2016"		
	}
	else {
		// main spec as in first submission
		recode syear (1984/1991=1 "1983-1990") (1998/2007=2 "1997-2006") ///
			(2008/2016=3 "2007-2016") (else=.), generate(decade)
		// labels for output
		local p1lab "1983--1990"
		local p2lab "1997--2006"
		local p3lab "2007--2016"				
	}
	clonevar decade_east = decade
	replace decade_east=. if decade_east==1
*	adjust cross-sectional weights for pooling
	egen wsum = total(phrf), by(syear)
	gen phrf2 = phrf/wsum
/*	who actually changes breadwinning status (and back)?
	preserve
		do "${dir_do}gi_deround_post.do"
		rename wifeEarnsMore WEM
		keep if decade==1 & sampreg==1
		bys cid: gen cnt0=_N
		egen cnt=total(WEM), by(cid)
		*drop if cnt==cnt0
		*drop if cnt==0
		gen WEMch=0
		replace WEMch=1 if l1.WEM==0 & WEM==1
		gen f1WEM=f1.WEM

		tab WEM
		tab WEM f1WEM, row
		tab WEMch f1WEM, row
	restore	 
*/

	
***
*** RUN
***

*	define estimation program
	do ${dir_do}gi_rdcd_prog.do // xtfe regressions and scalar returns
*	simulate, run x times and pass params through
	simulate, reps(`reps'): rdcd, ///
		dv(`dv') percut(`percut') samp(`samp') sel(`sel') ///
		cutoff(`cutoff') binsize(`binsize') `graph'
*	save dataset
	save "${dir_data}output/dcd/dcd_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'.dta", replace
***
*** GRAPHING; if requested (based on dcd estimates stored in a single dataset per run)
***
	
	if "`graph'" != "" {
	
		// styling
		grstyle clear
		grstyle init
		grstyle color background white
		//grstyle set plain, grid noextend horizontal  // imesh = R
		//grstyle set color Dark2
		//grstyle set color gs11: p6 // natives
		//grstyle set legend 6, nobox klength(medium)
		grstyle set graphsize 50mm 57mm
		grstyle set size 7pt: axis_title subtitle
		grstyle set size 7pt: key_label
		grstyle set size 7pt: tick_label
		grstyle set symbolsize 2, pt
		grstyle set linewidth 1pt: plineplot
		grstyle set linewidth .25pt: pmark legend axisline tick major_grid
		grstyle set margin "0 0 3 3": axis_title
		//grstyle set margin "3 8 3 3": graph	

	* 	delete rows with missing Xj
		local sampreg 1 2
		foreach s of local sampreg {
			if `s'==1 {
				local r West
				local decades 1 2 3
			}
			else if `s'==2 {
				local r East
				local decades 2 3
			}
			foreach l of local decades {
				forvalues j=1/`reps' {
					use "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'.dta", clear
					keep if !missing(Xj)
				*	use cloned var for merging the shifted r0 and fhat values (whyever...)	
					rename r0_`r'_`l'_`j' lol
					cap drop r0
					rename lol r0_`r'_`l'_`j'
					clonevar r0=r0_`r'_`l'_`j'
					save "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'.dta", replace
					drop if missing(r0)
					save "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'_r0.dta", replace
				}
			*	master dataset	
				clear
				local obs = round(1.3/`binsize') // 130% width of running variable (for smoothing)
				set obs `obs' // one placeholder for each set of estimates
				gen multi = (_n-1) - floor(`obs'*0.65) // counter with offset of 15% of running var width at each margin, centered
				gen Xj = `cutoff' + (`binsize'/2) + `binsize'*multi // half of bin size --> bin midpoints
				clonevar r0=Xj
				drop multi
			*	merge	
				forvalues j=1/`reps' {
				*	merge	
					merge 1:1 Xj using "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'.dta", ///
						keepusing(Xj Yj*)
					drop if _merge==2
					drop _merge
				*	erase merged files	
					erase "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'.dta"	
				}
				* correct Xj/r0 shift in positions (issue when calculating means later)
				forvalues j=1/`reps' {	
				*	merge	
					merge 1:1 r0 using "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'_r0.dta", ///
						keepusing(fhat* se*)
					drop if _merge==2
					drop _merge
				*	erase merged files	
					erase "${dir_data}output/dcd/plot/dcdest_`r'_`l'_`j'_r0.dta"	
				}
			*	reshape	
				reshape long Yj_`r'_`l'_ fhat_`r'_`l'_ se_fhat_`r'_`l'_, i(Xj) j(run)
			*	average per run	
				sort Xj
				by Xj: egen Yj=mean(Yj_`r'_`l'_)
				by Xj: egen fhat=mean(fhat_`r'_`l'_)
				replace se_fhat_`r'_`l'_ = (se_fhat_`r'_`l'_)^2
				by Xj: egen se_fhat=mean(se_fhat_`r'_`l'_)
				replace se_fhat = sqrt(se_fhat)
				gen ciu=fhat+1.96*se_fhat
				gen cil=fhat-1.96*se_fhat
			*	keep average only	
				by Xj: gen n=_n
				keep if n==1
				save "${dir_data}output/dcd/plot/dcdest_`dv'_`pc'_`sel'_`co'_`bs'`dsp'_`srs'_`r'_`l'.dta", replace
				gr twoway           ///
					(rarea ciu cil r0 if r0 < 0.50001 & r0>=0, color(gs14) lwidth(0))   ///
					(rarea ciu cil r0 if r0 > 0.50001 & r0<=1, color(gs14) lwidth(0))   ///
					(scatter Yj Xj if n==1 & Xj>=0 & Xj<=1, msymbol(circle_hollow) mcolor(gs10))   ///
					(lowess fhat r0 if r0 < 0.50001 & r0>=0, lcolor(black) lwidth(0.3) lpattern(line) bw(0.25))   ///
					(lowess fhat r0 if r0 > 0.50001 & r0<=1, lcolor(black) lwidth(0.3) lpattern(line) bw(0.25)), ///
					 xline(0.5, lcolor(black) lwidth(0.3)) legend(off) ///
					bgcolor(white) yscale(noline) ylabel(0(1)3.5, angle(horizontal)) ///
					xlabel(0(0.1)1) subtitle("`r' Germany `p`l'lab'") ytitle(Density of couples) ///
					xtitle(Wife's share of household income) ///
					saving("${dir_g}McCrary_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'_`r'_`l'.gph", replace)
				graph export "${dir_g}McCrary_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'_`r'_`l'.eps", replace	
			}
		}
	*	load dcd dataset again for sum & export	
		use "${dir_data}output/dcd/dcd_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'.dta", clear
	}


***
*** SUM & EXPORT
***

*	create placeholder matrix
*	5 estimations with 7 returned scalars
	local estno = 5 // add 3 cols for ttest
	local stats theta se_theta df_theta drop_theta N
	local statsno : word count `stats'
	local statsno = `statsno' // add two rows for ttest
	mat mdcd = J(`estno',`statsno',.) // empty final matrix
*** fill matrix out of dataset parts
	local sampreg 1 2
	local cntest = 0 // estimation counter
 	foreach s of local sampreg {
		if `s'==1 {
			local r West
			local decades 1 2 3
		}
		else if `s'==2 {
			local r East
			local decades 2 3
		}
		foreach l of local decades {
		*	every stat for every estimation in one single cell in spec row of 
		*	placeholder matrix (for formatting later)
			local ++cntest
			local cntstats = 0
			foreach stat in `stats' {
				local ++cntstats
			*	create matrix for each stat per estimation	
				mkmat `stat'_`r'_`l', mat(mdcdpt)
			*	column means and fill in placeholder matrix
				mat rmdcdpt = J(rowsof(mdcdpt),1,1)
				if "`stat'" == "se_theta" {
					local cols = colsof(mdcdpt)
					local rows = rowsof(mdcdpt)
				*	exponentiate (take mean of variance)	
					forvalues h=1/`rows' {
						forvalues k=1/`cols' {
							mat mdcdpt[`h',`k']=(mdcdpt[`h',`k'])^2
						}
					}
				}
			*	calculate mean value	
				mat smdcdpt = (rmdcdpt' * mdcdpt)/rowsof(mdcdpt)
				if "`stat'" == "se_theta" {
					local cols = colsof(smdcdpt)
					local rows = rowsof(smdcdpt)
				*	take square root (get se)	
					forvalues h=1/`rows' {
						forvalues k=1/`cols' {
							mat smdcdpt[`h',`k']=sqrt(smdcdpt[`h',`k'])
						}
					}
				}
				mat mdcd[`cntstats',`cntest'] = smdcdpt[1,1]
			}
		}
	}	
*	transform df into p-values
	forvalues i=1/5 {
		mat mdcd[3,`i'] = 2*normal(-abs(mdcd[1,`i']/mdcd[2,`i']))
	}
***	ttest East/West
	mat ttew = J(3,3,.)
	forvalues i=2/3 {
		local j = `i'+2
	*	macro values in local (ttest quirk)	
		local t1  = mdcd[1,`i']
		local sd1 = mdcd[2,`i']*sqrt(mdcd[5,`i'])
		local n1  = round(mdcd[5,`i'])				
		local t2  = mdcd[1,`j']
		local sd2 = mdcd[2,`j']*sqrt(mdcd[5,`j'])
		local n2  = round(mdcd[5,`j'])
	*	estimate
		ttesti `n1' `t1' `sd1' `n2' `t2' `sd2'
	*	fill matrix
		mat ttew[`i',1] = abs(r(mu_1)-r(mu_2))
		mat ttew[`i',2] = r(se)
		mat ttew[`i',3] = r(p)
	}
***	ttest periods
*	west
	mat ttperw = J(3,3,.)
	local tuples 1 3 2 1 3 2
	forvalues i=1(2)5 {
		local j = `i'+1
		local k : word `i' of `tuples'
		local l : word `j' of `tuples'
	*	macro values in local (ttest quirk)	
		local t1  = mdcd[1,`k']
		local sd1 = mdcd[2,`k']*sqrt(mdcd[5,`k'])
		local n1  = round(mdcd[5,`k'])				
		local t2  = mdcd[1,`l']
		local sd2 = mdcd[2,`l']*sqrt(mdcd[5,`l'])
		local n2  = round(mdcd[5,`l'])
	*	estimate
		ttesti `n1' `t1' `sd1' `n2' `t2' `sd2'
	*	fill matrix
		mat ttperw[`k',1] = abs(r(mu_1)-r(mu_2))
		mat ttperw[`k',2] = r(se)
		mat ttperw[`k',3] = r(p)			
	}
*	east
	mat ttpere = J(3,3,.)
	local k = 4
	local l = 5
*	macro values in local (ttest quirk)	
	local t1  = mdcd[1,`k']
	local sd1 = mdcd[2,`k']*sqrt(mdcd[5,`k'])
	local n1  = round(mdcd[5,`k'])				
	local t2  = mdcd[1,`l']
	local sd2 = mdcd[2,`l']*sqrt(mdcd[5,`l'])
	local n2  = round(mdcd[5,`l'])
*	estimate
	ttesti `n1' `t1' `sd1' `n2' `t2' `sd2'
*	fill matrix
	mat ttpere[3,1] = abs(r(mu_1)-r(mu_2))
	mat ttpere[3,2] = r(se)
	mat ttpere[3,3] = r(p)				
*	transpose and re-stack rows
	mat mdcd = mdcd'
	mat list mdcd
	mat wmdcd = mdcd[1..3,1...] // west
	mat emdcd = J(1,5,.)
	mat emdcd = emdcd \ mdcd[4..5,1...] // east
	mat mdcd = wmdcd, emdcd
	mat list mdcd
*	floor Ns
	forvalues r=1/3 {
		mat mdcd[`r',5] = round(mdcd[`r',5])
		mat mdcd[`r',10] = round(mdcd[`r',10])
	}
*	export full matrix with p-values
	mat pvalmdcd = mdcd, ttew, ttperw, ttpere
	frmttable using "${dir_t}pvals/dcd_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'_pvals.tex", replace tex nocenter /// 
		fragment statmat(pvalmdcd) ///
		rtitle("\noalign{\smallskip}`p1lab'" \ "`p2lab'" \ "`p3lab'") ///
		ctitle(" & \multicolumn{5}{c}{{\textit{West Germany}}} & \multicolumn{5}{c}{{\textit{East Germany}}} & \multicolumn{3}{c}{{\textit{\(\Delta\) East vs. West}}} & \multicolumn{3}{c}{{\textit{\(\Delta\) Periods West}}} & \multicolumn{3}{c}{{\textit{\(\delta\) Periods West}}} \\ \cmidrule(l{1em}){2-6}\cmidrule(l{1em}){7-11}\cmidrule(l{1em}){12-14}\cmidrule(l{1em}){15-17}\cmidrule(l{1em}){18-20}" ///
			,"{\(\theta\)}", "{SE}", "p", "\% drop", "N" /// 
			,"{\(\theta\)}", "{SE}", "p", "\% drop", "N" ///
			,"{\(\Delta\theta\)}", "{SE}", "p" ///
			,"{\(\Delta\theta\)}", "{SE}", "p" ///
			,"{\(\Delta\theta\)}", "{SE}", "p" ) ///
		sfmt(f) sdec(3)	
***	make final table
*	drop p-val cols
	matselrc mdcd fmdcd1 , r(1/3) c(1/2, 4/7, 9/10) // uses matselrc package!
	matselrc ttew fmdcd2 , r(1/3) c(1/2)
	matselrc ttperw fmdcd3 , r(1/3) c(1/2)
	matselrc ttpere fmdcd4 , r(1/3) c(1/2)
*	re-stack
	mat fmdcd = fmdcd1 , fmdcd2
	mat fmdcd2 = fmdcd3, J(3,2,.), fmdcd4, J(3,4,.)
	mat fmdcd = fmdcd \ fmdcd2
	mat list fmdcd
*	determine significance
	local colsb 1 5 9
	matrix stars = J(rowsof(fmdcd),colsof(fmdcd),0)
	local rowsb = rowsof(fmdcd)
	forvalues k = 1(4)9 {
		forvalues j = 1/`rowsb' {
			local h = `k'+1
			if fmdcd[`j',`k'] != . {
				matrix stars[`j',`k'] =   ///
				(abs(fmdcd[`j',`k']/fmdcd[`j',`h']) > 1.644854) +   ///
				(abs(fmdcd[`j',`k']/fmdcd[`j',`h']) > 1.959964) +   ///
				(abs(fmdcd[`j',`k']/fmdcd[`j',`h']) > 2.575829) +	///
				(abs(fmdcd[`j',`k']/fmdcd[`j',`h']) > 3.290527)	
			}
		}
	}	
*** export final table			
	frmttable using "${dir_t}dcd_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'.tex", replace tex nocenter /// 
		fragment statmat(fmdcd) plain annotate(stars) asymbol(\dag,"*","**","***") ///
		rtitle("\noalign{\smallskip}`p1lab'" \ "`p2lab'" \ "`p3lab'" \ ///
				"\cmidrule(l{0.5em}){2-11} & {\(\Delta\hat{\theta}\)} & {SE} & & & {\(\Delta\hat{\theta}\)} & {SE} & & & & \\ \hline\noalign{\smallskip}{\textit{Diff. Periods}} & & & & & & & & & \\ `p1lab' vs. `p3lab'" \ ///
				"`p1lab' vs. `p2lab'" \ "`p2lab' vs. `p3lab'") ///
		ctitle(" & \multicolumn{4}{c}{{\textit{West Germany}}} & \multicolumn{4}{c}{{\textit{East Germany}}} & \multicolumn{2}{c}{{\textit{West vs. East}}} \\ \cmidrule(l{0.5em}){2-5}\cmidrule(l{1em}){6-9}\cmidrule(l{1em}){10-11}" ///
			,"{\(\hat{\theta}\)}", "{SE}", "{\% drop}", "{N}" /// 
			,"{\(\hat{\theta}\)}", "{SE}", "{\% drop}", "{N}" ///
			,"{\(\Delta\hat{\theta}\)}", "{SE}" ) ///
		sfmt(f) sdec(2)
}
end
