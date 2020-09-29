////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Monte Carlo Panel Regression Simulation Program Output Handler --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

capture program drop rxtfepost
program define rxtfepost, rclass 
{
*	syntax
	syntax, ///
		dv(str) ///
		iv(str) ///
		percut(integer) ///
		samp(integer) ///
		spec(integer) ///
		reps(integer) ///
		[ delspike ]
*	clean strings (sometimes buggy)	
	local dv = "`dv'"
	local iv = "`iv'"
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
*	set income specification names for output
	if `spec' == 0 {
		local incs "base" // only wife earns more
	}	
	else if `spec' == 1 {
		local incs "cc" // + cubic, cubic
	}
	else if `spec' == 2 {
		local incs "llsum" // + linear, linear, sum of wife's and husband's income
	}	
	else if `spec' == 3 {
		local incs "ccia" // + cubic, cubic, interaction
	}
	else if `spec' == 4 {
		local incs "cciaimp" // + cubic, cubic, interaction, imputation dummies [MAIN SPEC]
	}
	else if `spec' == 5 {
		local incs "cciaimpcare" // + cubic, cubic, interaction, imputation dummies, + care cov.
	}		
	else {
		local incs "base"
	}
*	delete excess spike?
	if "`delspike'" != "" {
		local dsp "_dspike" // excess spike of equal earning couples deleted
		global delspike = 1
	}
	else {
		local dsp // not deleted
		global delspike = 0
	}
*	period cut
	local pc "pc`percut'"
	if `percut' == 1 {
		local p1lab "1983--1990"
		local p2lab "1991--2003"
		local p3lab "2004--2016"
	}
	else {
		// labels for output
		local p1lab "1983--1990"
		local p2lab "1997--2006"
		local p3lab "2007--2016"				
	}

***
*** RUN
***

*	define estimation program
	do ${dir_do}gi_rxtfe_prog.do // xtfe regressions and scalar returns
*	simulate, run x times and pass params through
	simulate, reps(`reps'): rxtfe, ///
		dv(`dv') iv(`iv') percut(`percut') samp(`samp') spec(`spec')
*	save dataset for checking
	save "${dir_data}output/reg/`dv'_`pc'_`incs'_`srs'`dsp'.dta", replace


***
*** SUM & EXPORT
***

*	create placeholder matrix
*	5 estimations with 7 returned scalars
	local estno 5
	local stats b se p r2 r2a N Ng
	local statsno : word count `stats'
	mat mxtfe = J(`statsno',`estno',.) // empty final matrix
*** fill matrix out of dataset parts  (stepwise)	
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
				mkmat `dv'_`stat'_`iv'_`r'_`l', mat(mxtfept)
			*	column means and fill in placeholder matrix
				mat rmxtfept = J(rowsof(mxtfept),1,1)
				if "`stat'" == "se" {
					local cols = colsof(mxtfept)
					local rows = rowsof(mxtfept)
				*	exponentiate (take mean of variance)	
					forvalues h=1/`rows' {
						forvalues k=1/`cols' {
							mat mxtfept[`h',`k']=(mxtfept[`h',`k'])^2
						}
					}
				}
			*	calculate mean value	
				mat smxtfept = (rmxtfept' * mxtfept)/rowsof(mxtfept)
				if "`stat'" == "se" {
					local cols = colsof(smxtfept)
					local rows = rowsof(smxtfept)
				*	take square root (get se)	
					forvalues h=1/`rows' {
						forvalues k=1/`cols' {
							mat smxtfept[`h',`k']=sqrt(smxtfept[`h',`k'])
						}
					}
				}
				mat mxtfe[`cntstats',`cntest'] = smxtfept[1,1]
			}
		*	extract rows with same formatting (and exclude p-values)
			mat bmxtfe = mxtfe[1,1...] // b
			mat semxtfe = mxtfe[2,1...] // se
			mat r2mxtfe = mxtfe[4..5,1...] // r2
			mat nmxtfe = mxtfe[6..7,1...] // N
		*	determine significance of coefficients
			matrix stars = J(1,`estno',0)
			forvalues k = 1/`estno' {
				matrix stars[1,`k'] =   ///
				(abs(bmxtfe[1,`k']/semxtfe[1,`k']) > 1.644854) +   ///
				(abs(bmxtfe[1,`k']/semxtfe[1,`k']) > 1.959964) +   ///
				(abs(bmxtfe[1,`k']/semxtfe[1,`k']) > 2.575829) +	///
				(abs(bmxtfe[1,`k']/semxtfe[1,`k']) > 3.290527)
			}
		***	export final table in formatted parts			
		*	b
			frmttable using "${dir_t}`dv'_`pc'_`incs'_`srs'`dsp'.tex", replace tex nocenter /// 
				fragment statmat(bmxtfe) annotate(stars) asymbol(\dag,*,**,***) ///
				rtitle("\noalign{\smallskip}wifeEarnsMore in \textit{t--1}") ///
				ctitle(" & \multicolumn{3}{c}{{\textit{West Germany}}} & \multicolumn{2}{c}{{\textit{East Germany}}} \\ \cmidrule(l{1em}){2-4}\cmidrule(l{1em}){5-6}" ///
					,"{\Centerstack{(1)\\\`p1lab'}}", "{\Centerstack{(2)\\\`p2lab'}}", /// 
					"{\Centerstack{(3)\\\`p3lab'}}", "{\Centerstack{(4)\\\`p2lab'}}", ///
					"{\Centerstack{(5)\\\`p3lab'}}") ///
				sfmt(f) sdec(3)
		*	se
			frmttable using "${dir_t}`dv'_`pc'_`incs'_`srs'`dsp'.tex", append tex nocenter ///
				fragment plain statmat(semxtfe) brackets({(},{)} ) ///	
				sfmt(f) sdec(3) rtitle("")
		*	r2		
			frmttable using "${dir_t}`dv'_`pc'_`incs'_`srs'`dsp'.tex", append tex nocenter ///
				fragment plain statmat(r2mxtfe) ///	
				sfmt(f) sdec(3) rtitle("R-squared" \ "R-squared (adj.)")
		*	N		
			frmttable using "${dir_t}`dv'_`pc'_`incs'_`srs'`dsp'.tex", append tex nocenter ///
				fragment plain statmat(nmxtfe) brackets({,}) ///	
				sfmt(gc) sdec(0) rtitle("N (couple-years)" \ "n (couples)")
		***	export unformatted table with p-values
			frmttable using "${dir_t}pvals/`dv'_`pc'_`incs'_`srs'`dsp'_pvals.tex", replace tex nocenter /// 
				fragment statmat(mxtfe) ///
				rtitle("\noalign{\smallskip}wifeEarnsMore in \textit{t--1}" \ "" \ "p" \ ///
					"R-squared" \ "R-squared (adj.)" \ "N (couple-years)" \ "n (couples)" ) ///
				ctitle(" & \multicolumn{3}{c}{{\textit{West Germany}}} & \multicolumn{2}{c}{{\textit{East Germany}}} \\ \cmidrule(l{1em}){2-4}\cmidrule(l{1em}){3-5}" ///
					,"{\Centerstack{(1)\\\`p1lab'}}", "{\Centerstack{(2)\\\`p2lab'}}", /// 
					"{\Centerstack{(3)\\\`p3lab'}}", "{\Centerstack{(4)\\\`p2lab'}}", ///
					"{\Centerstack{(5)\\\`p3lab'}}") ///
				sfmt(f) sdec(3)
		}
	}

}
end

