////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Export heaping incidences in FAST data --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

set more off
use "${dir_data}source/fast2010_small.dta", clear

// destring weights
encode samplingweight, gen(pw)

// wife and husband: Zusammenveranlagung/Splitting table
*replace ef18 = 1 if ef18 == . & ef19 != 2 // no Zusammenveranlagung
*replace ef18 = 2 if ef18 == . & ef19 == 2 // Zusammenveranlagung
*count if ef18==2 & ef19==2 // 1,425,067
*keep if ef18==2 & ef19==2

// keep if same sample (note: no control if still in education)
keep if ef11<=2 & ef12<=2 // keep if not self-employed
keep if ef59==0 & ef61==0
keep if ef65>3 & ef65<12 & ef69>3 & ef69<12 // age: 25-65 --> mostly no students
drop if !missing(c71100) | !missing(c71150) | !missing(c71200)  // no male pensioners
drop if !missing(c72100) | !missing(c71150) | !missing(c71200) // no female pensioners
drop if (c47120>0 & !missing(c47120)) | (c48120>0 & !missing(c48120))  // no unemployment benefit/social subsidies
/* 532,703 observations meet the criteria */

// women's share of household income (both have positive income)
gen antlabgro = c65162/(c65162 + c65161) ///
	if !missing(c65162) & !missing(c65161) & c65162>0 & c65161>0
/* 149,000 couples with positive income */

/*
//
// DCD graphing (test if SOEP results are sensible)
//

// West
preserve
	DCdensity antlabgro if ef63==1, breakpoint(0.50001) b(0.05) ///
							generate(Xj Yj r0 fhat ///
							se_fhat) nograph
	// prep graph
	replace Xj = . if Xj > 1
	bys Xj: gen dblt = _n if !missing(Xj)
	replace Xj=. if dblt==2
	drop dblt
	gen ciu=fhat+1.96*se_fhat
	gen cil=fhat-1.96*se_fhat
	// graph
	gr twoway           ///
		(rarea ciu cil r0 if r0 < 0.50001 & r0>=0, color(gs14) lwidth(0))   ///
		(rarea ciu cil r0 if r0 > 0.50001 & r0<=1, color(gs14) lwidth(0))   ///
		(scatter Yj Xj if Xj>=0 & Xj<=1, msymbol(circle_hollow) mcolor(gs10))   ///
		(lowess fhat r0 if r0 < 0.50001 & r0>=0, lcolor(black) lwidth(0.3) lpattern(line) bw(0.25))   ///
		(lowess fhat r0 if r0 > 0.50001 & r0<=1, lcolor(black) lwidth(0.3) lpattern(line) bw(0.25)), ///
		 xline(0.5, lcolor(black) lwidth(0.3)) legend(off) graphregion(color(white) lcolor(black) margin(medlarge)) ///
		bgcolor(white) xscale(titlegap(2)) yscale(noline titlegap(3)) ylabel(0(1)3, angle(horizontal)) ///
		xlabel(0(0.1)1) title(/*`r' Germany `p'*/) subtitle(/*`sl'*/) ytitle(Density of couples) ///
		xtitle(Wife's share of household income) xsize(8) ysize(6) scheme(s1color) scale(1.3)
	// export
	graph export "${dir_g}McCrary_est_West_2010.eps", replace
	// drop: 11.8%
	// theta: -.125900823 (.030381943)

restore

// East
preserve
	DCdensity antlabgro if ef63==2, breakpoint(0.50001) b(0.05) ///
							generate(Xj Yj r0 fhat ///
							se_fhat) nograph
	// prep graph
	replace Xj = . if Xj > 1
	bys Xj: gen dblt = _n if !missing(Xj)
	replace Xj=. if dblt==2
	drop dblt
	gen ciu=fhat+1.96*se_fhat
	gen cil=fhat-1.96*se_fhat
	// graph
	gr twoway           ///
		(rarea ciu cil r0 if r0 < 0.50001 & r0>=0, color(gs14) lwidth(0))   ///
		(rarea ciu cil r0 if r0 > 0.50001 & r0<=1, color(gs14) lwidth(0))   ///
		(scatter Yj Xj if Xj>=0 & Xj<=1, msymbol(circle_hollow) mcolor(gs10))   ///
		(lowess fhat r0 if r0 < 0.50001 & r0>=0, lcolor(black) lwidth(0.3) lpattern(line) bw(0.25))   ///
		(lowess fhat r0 if r0 > 0.50001 & r0<=1, lcolor(black) lwidth(0.3) lpattern(line) bw(0.25)), ///
		 xline(0.5, lcolor(black) lwidth(0.3)) legend(off) graphregion(color(white) lcolor(black) margin(medlarge)) ///
		bgcolor(white) xscale(titlegap(2)) yscale(noline titlegap(3)) ylabel(0(1)3, angle(horizontal)) ///
		xlabel(0(0.1)1) title(/*`r' Germany `p'*/) subtitle(/*`sl'*/) ytitle(Density of couples) ///
		xtitle(Wife's share of household income) xsize(8) ysize(6) scheme(s1color) scale(1.3)
	// export
	graph export "${dir_g}McCrary_est_East_2010.eps", replace
	// drop: 7.2%
	// theta: -.075130914 (.034312441)

restore
*/
// equal earners
gen eqearn = 0 if antlabgro!=.
replace eqearn = 1 if antlabgro==0.5
tab eqearn // about 0.105% equal earners (unweighted)
table ef63 [pw=pw], c(m eqearn) // weighted: West: 0.010; East: 0.011
bys ef63: tab ef48 eqearn, row

// nearly equal earners: comparison with SOEP
gen neqearn = 1 if antlabgro>0.48 & antlabgro<0.52
tab neqearn, missing

// 	income brackets
gen incbrm = .
replace incbrm = 1 if c65161<=10000
replace incbrm = 2 if c65161>10000 & c65161<=20000
replace incbrm = 3 if c65161>20000 & c65161<=35000
replace incbrm = 4 if c65161>35000 & c65161<=60000
replace incbrm = 5 if c65161>60000 & !missing(c65161)
gen incbrw = .
replace incbrw = 1 if c65162<=10000
replace incbrw = 2 if c65162>10000 & c65162<=20000
replace incbrw = 3 if c65162>20000 & c65162<=35000
replace incbrw = 4 if c65162>35000 & c65162<=60000
replace incbrw = 5 if c65162>60000 & !missing(c65162)

// 	check if integer multiple for husband/wife; east/west
forvalues s=1/2 {
gen roundedm_`s' = .
    replace roundedm_`s' = 50 if !mod(c65161,50)==1 & ef63==`s' // 50
    replace roundedm_`s' = 100 if !mod(c65161,100)==1 & ef63==`s' // 100
    replace roundedm_`s' = 500 if !mod(c65161,500)==1 & ef63==`s' // 500
    replace roundedm_`s' = 1000 if !mod(c65161,1000)==1 & ef63==`s' // 1000
    replace roundedm_`s' = 5000 if !mod(c65161,5000)==1 & ef63==`s' // 5000
    replace roundedm_`s' = 10000 if !mod(c65161,10000)==1 & ef63==`s' // 10000
    gen roundedw_`s' = .
    replace roundedw_`s' = 50 if !mod(c65162,50)==1 & ef63==`s' // 50
    replace roundedw_`s' = 100 if !mod(c65162,100)==1 & ef63==`s' // 100
    replace roundedw_`s' = 500 if !mod(c65162,500)==1 & ef63==`s' // 500
    replace roundedw_`s' = 1000 if !mod(c65162,1000)==1 & ef63==`s' // 1000
    replace roundedw_`s' = 5000 if !mod(c65162,5000)==1 & ef63==`s' // 5000
    replace roundedw_`s' = 10000 if !mod(c65162,10000)==1 & ef63==`s' // 10000
}

// tab and save parts
foreach g in m w {
    forvalues s=1/2 {
		if ("`g'"=="w") local m ""
			else local m "_m"
        preserve
            // aggregate
            tab rounded`g'_`s', missing
            // by income brackets
            tab incbr`g', matcell(nrow)
            tab incbr`g' rounded`g'_`s', missing row matcell(ncell)
            mat cperc = ncell[1..5,1..6]
            forvalues r=1/5 {
                forvalues c=1/6 {
                    mat cperc[`r',`c'] = cperc[`r',`c'] / nrow[`r',1] // row percent
					dis "ok"
                }
            }
            // export
			drop _all
			matname cperc rnd50`m' rnd100`m' rnd500`m' rnd1000`m' rnd5000`m' rnd10000`m', columns(1..6) explicit
            svmat cperc, names(col)
            gen incbr`m' = _n
			gen sampreg = `s'
			order sampreg incbr
            save "${dir_data}output/est/shares_rounding_incbr_`g'_`s'.dta", replace
        restore
    }
}

// merge and export
foreach g in m w {
	drop _all
    forvalues s=1/2 {
		append using "${dir_data}output/est/shares_rounding_incbr_`g'_`s'.dta"
		erase "${dir_data}output/est/shares_rounding_incbr_`g'_`s'.dta"
	}
	if ("`g'"=="w") save "${dir_data}output/est/shares_rounding_incbr.dta", replace
		else save "${dir_data}output/est/shares_rounding_incbr_`g'.dta", replace
}


