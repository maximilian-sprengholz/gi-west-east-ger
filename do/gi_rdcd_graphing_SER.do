////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- DCD Graphing for SER (combines single graphs into one) --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

// labels for output
local p1lab "1983-1990"
local p2lab "1991-2003"
local p3lab "2004-2016"		

// styling
grstyle clear
grstyle init
grstyle color background white
grstyle set plain, nogrid
//grstyle set color Dark2
//grstyle set color gs11: p6 // natives
//grstyle set legend 6, nobox klength(medium)
grstyle set graphsize 57mm 57mm
grstyle set size 7pt: title
grstyle set size 9pt: subheading
grstyle set size 7pt: axis_title key_label tick_label small_body text_option body
grstyle set size 2pt: tick
grstyle set symbolsize 2, pt
grstyle set linewidth 0.125pt: axisline tick major_grid plotregion xyline graph
grstyle set color gs2: p#
grstyle set margin "0 0 3 9": axis_title
grstyle set margin "0 0 4 0": subheading
grstyle set margin "0 0 0 6": graph
grstyle set margin "1.5": twoway
grstyle set margin "0 0 0 0": body
grstyle set margin "0 0 0 0": note

// graph settings
graph set window fontface "Lucida Sans"

local dv wis
local pc pc1
local sel random
local co codot50001
local bs bs05
local dsp _dspike
local srs all

// delete rows with missing Xj
local sampreg 1 2
foreach s of local sampreg {
	if `s'==1 {
		local r West
		local decades 1 2 3
		local ytitle "Density of couples"
	}
	else if `s'==2 {
		local r East
		local decades 2 3
		local ytitle ""
	}
	foreach l of local decades {
		use "${dir_data}output/dcd/plot/dcdest_`dv'_`pc'_`sel'_`co'_`bs'`dsp'_`srs'_`r'_`l'.dta", clear
		gr twoway ///
			(rarea ciu cil r0 if r0 < 0.50001 & r0>=0, color(gs14) lwidth(0))   ///
			(rarea ciu cil r0 if r0 > 0.50001 & r0<=1, color(gs14) lwidth(0))   ///
			(scatter Yj Xj if n==1 & Xj>=0 & Xj<=1, msymbol(circle_hollow) mlwidth(0.15) mcolor(gs10))   ///
			(lowess fhat r0 if r0 < 0.50001 & r0>=0, lcolor(gs2) lwidth(0.2) bw(0.25))   ///
			(lowess fhat r0 if r0 > 0.50001 & r0<=1, lcolor(gs2) lwidth(0.2) bw(0.25)), ///
			xline(0.5, lcolor(black)) legend(off) ylabel(0(1)4, angle(horizontal)) ///
			yscale(noextend noline fill) xscale(noextend noline fill) ///
			xlabel(0(0.1)1) subtitle("{bf:`r' Germany `p`l'lab'}") ytitle(`ytitle') ///
			xtitle(Wife's share of household income) plotregion(lcolor(black) lwidth(0.1) ilwidth(0.1)) ///
			saving("${dir_g}McCrary_`dv'_`pc'_`sel'_`co'_`bs'_`srs'`dsp'_`r'_`l'.gph", replace)
	}
}

grstyle set graphsize 176mm 114mm
grstyle set margin "0 0 0 0": combinegraph
grstyle set size 2pt: tick
grstyle set size 7pt: title
grstyle set size 7pt: subheading
grstyle set size 7pt: axis_title key_label tick_label small_body text_option body
grstyle set symbolsize 3, pt
grstyle set linewidth 0.25pt: axisline tick major_grid plotregion xyline
grstyle set linewidth 0.125pt: p# p#mark
grstyle set color gs2: p#
grstyle set margin "0 1 1 4": axis_title
grstyle set margin "0 0 1 1": subheading
grstyle set margin "0 1 0 0": graph
grstyle set margin "0 0 0 0.75": body
grstyle set margin "0 0 0 0": note	

// combine	
gr combine 	"${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike_West_1.gph" /// 
			"${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike_West_2.gph" /// 
			"${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike_East_2.gph" /// 
			"${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike_West_3.gph" /// 
			"${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike_East_3.gph" ///
			, iscale(2) holes(2) col(2) altshrink ycommon ///
				note("{it:Notes:} Dots reflect the midpoints of a histogram with a bin width of 0.05. The solid line is the local" ///
				"linear regression smoother allowing for a break at the cut-off, CI 95%.", linegap(0.5)) ///
				caption("{it:Source:} SOEP v33.1, doi:10.5684/soep.v33.1.", linegap(0.5))				
graph export "${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike.eps", replace
graph export "${dir_g}McCrary_wis_pc1_random_codot50001_bs05_all_dspike.pdf", replace
// graph settings reset
graph set window fontface default	
