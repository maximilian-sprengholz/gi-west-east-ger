////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		--	WVS attitude comparison West/East --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

set more off

// WVS 1995-1998
use "${dir_data}source/WV3_Data_Stata_v20180912.dta", clear
keep if V2 == 276 // Germany

// Item: 
// 		'If a woman earns more money than her husband, 
// 		it's almost certain to cause problems.'

tab V102, mi
recode V102 (-1 = .) (1 2=1 "Agree")(3 4 = 0 "No explicit agreement"), gen(mb_dummy)
ttest mb_dummy, by(V2A) // delta: 0.08, sign. p=<0.001

// WVS 2010-2014
use "${dir_data}source/WV6_Stata_v_2016_01_01.dta", clear
keep if V2 == 276 // Germany

// Item: 
// 		'If a woman earns more money than her husband, 
// 		it's almost certain to cause problems.'

tab V47, mi
recode V47 (-5/-1 = .) (1=1 "Agree")(2 3 = 0 "No explicit agreement"), gen(mb_dummy)
ttest mb_dummy, by(V2A) // delta: 0.00, insign. p=0.39
