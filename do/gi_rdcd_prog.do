////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Monte Carlo Discontinuity Test Simulation Program --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

capture program drop rdcd
program define rdcd, rclass 
{
*	syntax
	syntax, ///
		dv(str) ///
		percut(integer) ///
		samp(integer) ///
		sel(string) ///
		cutoff(real) ///
		binsize(real) ///
		[ graph ]
*	clean strings (sometimes buggy)	
	local dv = "`dv'"

preserve
	***
	*** De-Round
	***		

		do "${dir_do}gi_deround.do"
		keep if !missing(`dv') // no missings on wifeIncomeShare before sorting
		
	***
	*** McCrary Density Discontinuity Test
	***
	*	initiate counter
		global run = $run + 1
	*	keep only necessary variables
		keep cid `dv' sampreg decade decade_east syear yentry yentry_m phrf phrf2
	***	set loops for (1)West/East, (2)decades, (3)All/Full-time only
	* 	(1) West/East
		levelsof sampreg, local(states)
		foreach s of local states {
		*	set sample region name macro & decades	
			if `s'==1 {
				local r West
				levelsof decade, local(decades)
			}
			else if `s'==2 {
				local r East
				levelsof decade_east, local(decades)
			}
		* 	(2) decades
			foreach l of local decades {
				local p: label decade `l' // use labels for var/graph naming	
			*	sample restriction
				local opts1 "if sampreg==`s' & decade==`l'"
			* 	Draw for each cid in sampreg/decade (robustness: random; first observation)
				sort sampreg decade
				cap drop pointer
				generate pointer=1 `opts1' // only indicator
				// select median observation
				if "`sel'"=="median" {
					cap drop n
					sort cid decade syear // no longer random: middle year of couple in dec
					by cid decade: gen n=_n if !missing(pointer)
					cap drop nn
					by cid decade: gen nn=round(_N/2) if !missing(pointer) // use median year per observation
					// gen indicator
					replace n = 999 if nn!=n
					replace n = 1 if nn==n
				}
				else if "`sel'"=="random" {
					// select randomly
					sort sampreg decade
					cap drop random
					generate random=runiform() `opts1'
					cap drop n
					sort cid random
					// gen indicator
					by cid: gen n=_n if !missing(random)
				}
				else if "`sel'"=="wrandom" {
					// select randomly but adjust prob. according to 
					// inverse inclusion prob. of year (ameliorate sample size
					// increase over time)
					sort sampreg decade
					cap drop random
					generate random=runiform() `opts1'
					cap drop dec_n_max
					// weights based on year shares in decade sample
					bys sampreg decade: gen dec_n_max=_N
					cap drop year_n_max
					bys sampreg syear: gen year_n_max=_N
					cap drop y_prob
					gen y_prob = year_n_max/dec_n_max
					// re-weight
					replace random = random * (1/y_prob)
					cap drop n
					sort cid random
					// gen indicator
					by cid: gen n=_n if !missing(random)
				}
				else if "`sel'"=="wrgeq2" {
					// select randomly but adjust prob. according to 
					// cross-sectional weights
					sum phrf if pointer==1, d
					cap drop phrfrel
					gen phrfrel = phrf/r(max)					
					// random prob
					sort sampreg decade
					cap drop random
					generate random=runiform() `opts1'
					cap drop dec_n_max
					// weights based on year shares in decade sample
					bys sampreg decade: gen dec_n_max=_N
					cap drop year_n_max
					bys sampreg syear: gen year_n_max=_N
					cap drop y_prob
					gen y_prob = year_n_max/dec_n_max
					// re-weight
					replace random = random * (1/y_prob) * phrfrel
					// gen indicator
					cap drop n
					sort cid random
					by cid: gen n=_n if !missing(random)
				}				
				else {
					local sel "nosel"
					// all persons (ref)
					cap drop n
					gen n=1
				}
				count if n==1 & pointer==1 // number of obs
				return scalar N_`r'_`l' = r(N)
			* 	DCdensity program call			
				DCdensity `dv' if n==1 & pointer==1, breakpoint(`cutoff') b(`binsize') ///
						generate(Xj_`r'_`l'_$run Yj_`r'_`l'_$run ///
						r0_`r'_`l'_$run fhat_`r'_`l'_$run ///
						se_fhat_`r'_`l'_$run) nograph
			*	returns			
				return scalar theta_`r'_`l' 		= r(theta)
				return scalar se_theta_`r'_`l' 		= r(se)
				return scalar drop_theta_`r'_`l'	= (1-exp(r(theta)))*100
				return scalar df_theta_`r'_`l' 		= e(df_r)
				ereturn clear	
			*	save histogram estimates for graphing (if requested)
			*	sorted by Xj (bin midpoint) --> used for merging later
			*	DCdensity quirk: one of the bins without obs created twice! --> delete
				if "`graph'" != "" {
					rename Xj_`r'_`l'_$run Xj
					replace Xj = . if Xj > 1
					bys Xj: gen dblt = _n if !missing(Xj)
					replace Xj=. if dblt==2
					drop dblt
					save "${dir_data}output/dcd/plot/dcdest_`r'_`l'_$run.dta", replace
				}
			*	drop estimates	
				drop Xj Yj_`r'_`l'_$run r0_`r'_`l'_$run ///
				fhat_`r'_`l'_$run se_fhat_`r'_`l'_$run
			}
		}
restore

}
end

