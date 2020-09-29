////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Master --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

/*
 To make this code work...
 
 ...you need the following data:
 
 - Access to the SOEP v33.1 (wide AND long)
 - Access to the SOEP v33.1 regional data (district level)
 - Access to the FAST income tax data of 2010

 ...you need the following Stata software:
 
 - DCdensity.ado (Altered version of the Justin McCrary (https://eml.berkeley.edu/~jmccrary/DCdensity/) version to enable graphing options, provided in the ado dir)
 - frmttable (by John Gallup, part of outreg (https://econpapers.repec.org/software/bocbocode/s375201.htm), modified version provided in the .ado dir)
 - grstyle (by Ben Jann, http://repec.sowi.unibe.ch/stata/grstyle/index.html)
 - Only for appendix: xtabond2 (by David Roodman, http://www.stata-journal.com/article.html?article=st0159)
 - Only for appendix: xtlsdvc (by Giovanni Bruno, https://journals.sagepub.com/doi/10.1177/1536867X0500500401)
 - Only for appendix: estout (by Ben Jann, http://repec.sowi.unibe.ch/stata/estout/index.html)
 
 ...please use the provided repository structure as is and edit the macros below.
 
*/

version 14
clear
clear matrix
set more off
set graphics on
set matsize 1000
set seed 1234567


//-----------------------------//
//     		 MACROS	  	  	   //
//-----------------------------//

global wd "C:/Users/sprenmax/Seafile/Projects/gi-west-east-ger/" // working directory

global SOEP "L:/Gsoep/Nutzer/Gsoep33/" // annual wide files
global SOEP_l "L:/Gsoep/Nutzer/Gsoep33/Gsoep33long/" // SOEP long files
global SOEP_l_reg "L:/Gsoep/Nutzer/Gsoep33/Gsoep33long/regionaldaten/" // SOEP long regional data (restricted access)

global FAST "C:/Users/sprenmax/Seafile/Library/DTA/FAST2010/3_datei/" // FAST income tax data (restricted access)

global dir_data "${wd}data/" // generated datasets
global dir_do "${wd}do/" // do
global dir_g "${wd}graphs/" // figures
global dir_t "${wd}tables/" // tables

// log
// capture log using "${wd}gi.log", text replace


//-----------------------------//
//     		  PREP	  	  	   //
//-----------------------------//

// WVS
do ${dir_do}gi_wvs.do // compare breadwinner attitudes between West and East

// FAST
do ${dir_do}gi_fast_gen.do // extract relevant parts of dataset
do ${dir_do}gi_fast_export.do // export shares of rounded values

// SOEP
do ${dir_do}gi_fetch.do  // fetch wide data 1984-2016 //
do ${dir_do}auxiliary/kreisdaten_unemp.do // county unemployment rates
do ${dir_do}gi_gen.do  // generate dataset

// Descriptives
do ${dir_do}gi_sumstats.do  // summary statistics
do ${dir_do}gi_sumstats_appendix.do  // summary statistics


//-----------------------------//
//     		  DCD	  	  	   //
//-----------------------------//

//	define estimation program
do ${dir_do}gi_rdcd_post_prog.do // define monte carlo simulation for dcd
/*	
	Program call:
	dv:			String: set dependent variable (wifeIncomeShare=wis)
	percut:		Integer: how period is cut into intervals
				0 = main, 84-90, 97-06, 07-16
				1 = extended, 84-90, 91-03, 04-16
	samp: 		0 = general, married and cohabiting couples
				1 = general + only married couples [MAIN SPEC]
				2 = general + only ppl. born in GER
				3 = general + not moved between sample regions since 1989
	sel:		String: Selection of independent observations
				any = all observation (ignoring dependence)
				median = median obs. per person
				random = random obs. per person
				wrandom = random obs., weighted to balance years (slight effect)
	cutoff:		Real (wis dv 0-1; value of interest: 0.5)
	binsize:	Real (wis dv 0-1; sensible values: 0.05, 0.02, 0.01)
	reps:		Integer: set no of simulation runs
	delspike(o):No argument; optional, set when del of excess spike of equal earning couples required
	graph (o):	No argument; optional, set when graphing required 
*/

//	Main specification
rdcdpost, dv(wis) percut(1) samp(1) sel(random) cutoff(0.50001) binsize(0.05) reps(100) delspike graph

// Robustness checks (sample, binsize, no spike deletion) 
rdcdpost, dv(wis) percut(1) samp(0) sel(random) cutoff(0.50001) binsize(0.05) reps(100) delspike // including cohabiting couples
rdcdpost, dv(wis) percut(1) samp(3) sel(random) cutoff(0.50001) binsize(0.05) reps(100) delspike // no movers
rdcdpost, dv(wis) percut(1) samp(1) sel(random) cutoff(0.50001) binsize(0.05) reps(100) // w/o deletion of excess
rdcdpost, dv(wis) percut(1) samp(1) sel(random) cutoff(0.50001) binsize(0.02) reps(100) delspike // binsize 0.02
rdcdpost, dv(wis) percut(1) samp(1) sel(random) cutoff(0.50001) binsize(0.01) reps(100) delspike // binsize 0.01
rdcdpost, dv(wis) percut(1) samp(1) sel(median) cutoff(0.50001) binsize(0.05) reps(100) delspike // other selection of couple obs.
rdcdpost, dv(wis) percut(1) samp(1) sel(nosel)  cutoff(0.50001) binsize(0.05) reps(100) delspike // other selection of couple obs.

// Graphing of main spec according to SER styleguide
do "${dir_do}gi_rdcd_graphing_SER.do"

	
//-----------------------------//
//     		   FE		  	   //
//-----------------------------//

//	define estimation program
do ${dir_do}gi_rxtfe_post_prog.do // xtfe regressions and scalar returns	
/*	
	Program call:
	dv:			String: set dependent variable (wifeEarnsMore=WEM)
	iv:			String: set independent variable (f1.WEM=f1WEM)
	XTFE spec:	0 = base
				1 = winc##winc##winc minc##minc##minc
				2 = winc minc winc+minc
				3 = winc##winc##winc minc##minc##minc winc#minc
				4 = winc##winc##winc minc##minc##minc winc#minc yinc_imp yinc_imp_m [MAIN SPEC]
				5 = winc##winc##winc minc##minc##minc winc#minc yinc_imp yinc_imp_m ib2.care (control for caring in hh)
	samp: 		0 = general, married and cohabiting couples
				1 = general + only married couples [MAIN SPEC]
				2 = general + only ppl. born in GER
				3 = general + not moved between sample regions since 1989
	reps:		Integer: set no of simulation runs 
*/

//
//	LFP
//

local dv f1yw
local iv WEM
local reps 100
local pc 1
// spec
forvalues s=1/5 {
	rxtfepost, dv(`dv') iv(`iv') spec(`s') percut(`pc') samp(1) reps(`reps') delspike
}
// sample
rxtfepost, dv(`dv') iv(`iv') spec(7) percut(`pc') samp(3) reps(`reps') delspike // no movers
rxtfepost, dv(`dv') iv(`iv') spec(7) percut(`pc') samp(1) reps(`reps') // no delspike

//
//	Full-time share
//

local dv f1ftpt // share of full time vs. non-full time
local iv WEM
local reps 100
local pc 1
// spec
forvalues s=1/5 {
	rxtfepost, dv(`dv') iv(`iv') spec(`s') percut(`pc') samp(1) reps(`reps') delspike
}
// sample
rxtfepost, dv(`dv') iv(`iv') spec(7) percut(`pc') samp(3) reps(`reps') delspike // no movers
rxtfepost, dv(`dv') iv(`iv') spec(7) percut(`pc') samp(1) reps(`reps') // no delspike

//
// Contractual working hours
//

local dv vebzt // contractual hours at interview
local iv WEM
local reps 100
local pc 1
// spec
forvalues s=1/5 {
	rxtfepost, dv(`dv') iv(`iv') spec(`s') percut(`pc') samp(1) reps(`reps') delspike
}
// sample
rxtfepost, dv(`dv') iv(`iv') spec(7) percut(`pc') samp(3) reps(`reps') delspike // no movers
rxtfepost, dv(`dv') iv(`iv') spec(7) percut(`pc') samp(1) reps(`reps') // no delspike


//-----------------------------//
//     		DPD TESTS		   //
//-----------------------------//

do "${dir_do}gi_dpd.do"


// log close
exit
