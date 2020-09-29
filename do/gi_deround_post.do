////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- Recodes after de-rounding procedure --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

*** log income (annual)
gen lnyinc=ln(yinc)
	lab var lnyinc "(Log.) income annual wife"
gen lnyinc_m=ln(yinc_m)
	lab var lnyinc_m "(Log.) income annual husband"

*** HH labor income (annual)
gen lnyincHH=ln(yinc + yinc_m)
gen yincHH=yinc + yinc_m

*** wife earns more (annually) --> previous year!
lab def labelWEM 0 "No" 1 "Yes" 
	gen WEM:labelWEM =  yinc_m < yinc if !missing(yinc, yinc_m)
lab var WEM "Wife earns more"

***	income share (categorized) --> previous year!
gen wis_cat=1 if wis>=0 & wis<=0.25	
	replace wis_cat=2 if wis>0.25 & wis<=0.5
	replace wis_cat=3 if wis>0.5 & wis<=0.75
	replace wis_cat=4 if wis>0.75 & wis<=1
	lab var wis_cat "wife income share (categorized)"
	lab def lbl_wis_cat 1 "0-25%" 2 ">25-50%" 3 ">50-75%" 4 ">75%-100%"
	lab val wis_cat lbl_wis_cat


