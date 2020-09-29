////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		--	Generate final dataset based on merged SOEP file --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

set more off

use "${dir_data}source/gi_SOEP_1984-2016.dta", clear

// label
label data "Datensatz Gender Identity SOEP 1984-2016"

//
// Harmonize / Label
//

// employment status
recode erwerbsstatus_84_ (1=1) (2=2) (3=3) (4=4) (5=9) (6=6) (7=9) (else=.)
recode erwerbsstatus_85b90_96b98 (1=1) (2=2) (3=3) (4=4) (6=6) (7=9) (else=.)  
recode erwerbsstatus_91b95_ (1=1) (2=1) (3=2) (4=2) (5=3) (6=4) (7=7) (8=6) (9=9) (else=.)
recode erwerbsstatus_99_ (1=1) (2=2) (3=3) (4=4) (5=6) (6=9) (8=8) (else=.)
recode erwerbsstatus_2000b2001_ (1=1) (2=2) (3=3) (4=4) (5=6) (6=6) (7=9) (8=8) (else=.)
recode erwerbsstatus_2002b2015_ (1=1) (2=2) (3=3) (4=4) (5=5) (7=6) (8=8) (9=9) (else=.)
recode erwerbsstatus_ab_2016_ (1=1) (2=2) (3=3) (4=4) (5=5) (7=6) (8=8) (9=9) (10=10) (else=.)

clonevar erwerbsstatus = erwerbsstatus_ab_2016_
replace erwerbsstatus = erwerbsstatus_84_ if year==1984
replace erwerbsstatus = erwerbsstatus_85b90_96b98 if (year>=1985 & year<=1990) | (year>=1996 & year<=1998)
replace erwerbsstatus = erwerbsstatus_91b95 if year>=1991 & year<=1995
replace erwerbsstatus = erwerbsstatus_99_ if year==1999
replace erwerbsstatus = erwerbsstatus_2000b2001_ if year==2000 | year==2001
replace erwerbsstatus = erwerbsstatus_2002b2015_ if year>=2002 & year<=2015

drop erwerbsstatus_84_
drop erwerbsstatus_85b90_96b98
drop erwerbsstatus_91b95_
drop erwerbsstatus_99_
drop erwerbsstatus_2000b2001_
drop erwerbsstatus_2002b2015_
drop erwerbsstatus_ab_2016_

lab var erwerbsstatus "Erwerbsstatus Selbsteinstufung"
label def lab_erwerbsstatus ///
	1 "vollzeitbeschaeftigt" ///
	2 "teilzeitbeschaeftigt" ///
	3 "Ausbildung/Lehre" ///
	4 "geringfuegig beschaeftigt" ///
	5 "Altersteilzeit, 0 Stunden" ///
	6 "(freiwilliger) Wehrdienst, Zivildienst, Soz./ökol. Jahr" ///
	7 "Elternzeit" ///
	8 "Werkstatt für behinderte Menschen" ///
	9 "nicht erwerbstätig" ///
	10 "betriebliches Praktikum"
label val erwerbsstatus lab_erwerbsstatus

// rename
rename erwerbsstatus erwstat
rename repgart NMW_repairs
rename kinderbetr NMW_childcare
rename hausarb NMW_housework
rename besorg NMW_errands
rename hausarb_sa NMW_hw_sat
rename hausarb_so NMW_hw_sun
rename derz_ausb ineduc 
rename tatzeit tatzt
rename vebzeit vebzt
rename hhnr_org cid
rename persnr pid
rename hhnr hid
rename year syear
rename ost sampreg
rename bilzeit bilzt
rename isced97 isced
rename alter_kind_min agekid
rename kzahl_16 nkids

// set sampreg for 1984-1989
replace sampreg = 1 if syear<=1989

// keep private households
keep if (netto>=10 & netto<20) & (pop==1 | pop==2)

//
// Merge additional data (10/2018)
//

*	merge pequiv data
	merge 1:1 pid syear using "${SOEP_l}pequiv.dta", ///
		keepusing(e11105 e11106 e11107 i11101 i11110 i11210 e11104 e11101) nogen
		rename i11110 yinc
		rename i11210 yinc_imp
		rename e11104 primact
		rename e11101 ywh
		rename i11101 hhinc
*	merge pgen data
	merge 1:1 pid syear using "${SOEP_l}pgen.dta", ///
		keepusing(pgallbet pgnace pgbetr) nogen
*	merge pkal data
	merge 1:1 pid syear using "${SOEP_l}pkal.dta", ///
		keepusing(kal1d01 kal1d02 kal1a01 kal1a02 kal1b01 kal1b02 kal1k01 kal1k02) nogen
		rename kal1a01 yft
		rename kal1a02 yftm		
		rename kal1b01 ypt
		rename kal1b02 yptm
		rename kal1d01 yunemp
		rename kal1d02 yunempm
		rename kal1k01 ystw
		rename kal1k02 ystwm
*	merge ppfadl
	merge 1:1 pid syear using "${SOEP_l}ppfadl.dta", ///
		keepusing(birthregion)
	drop if _merge==2
	drop _merge
*	overwrite
	save  "${dir_data}gi_gen_all.dta", replace


//
// Gen dataset with partner info
//

// dataset for men
keep if sex==1 /* nur Männer */ 
keep if partz==1 | partz==2 | partz==3 | partz==4 /* mit Ehe- oder Lebenspartnerin */
local listm labgro impgro secjob secjobgro pen pengro alg1 ///
	alg1gro alg2 age isced casmin lfs erwstat stib partz sex ineduc bilzt ///
	NMW_errands NMW_housework NMW_childcare NMW_repairs NMW_hw_sat NMW_hw_sun ///
	tatzt vebzt corigin month e11105 e11106 e11107 hhinc yinc yinc_imp primact ///
	ywh pgallbet yft yftm ypt yptm yunemp yunempm ystw ystwm pgnace pgbetr birthregion ///
	loc1989
keep `listm' partnr syear
foreach x in `listm' {
rename `x' `x'_m 
}

rename partnr pid
mvdecode pid, mv(-8 -7 -6 -5 -4 -3 -2 -1)
save  "${dir_data}gi_gen_m.dta", replace
clear

// merge to women
use "${dir_data}gi_gen_all.dta", clear
keep if sex==2 /* nur Frauen */
merge 1:1 pid syear using "${dir_data}gi_gen_m.dta" /* Partner der Frauen anmergen */
drop if _merge==2
drop _merge
keep if !mi(partnr)

// erase temp
erase "${dir_data}gi_gen_all.dta"
erase "${dir_data}gi_gen_m.dta"

***
*** merge regional data (kkz)
***
	rename hid hhnrakt
	merge m:1 hhnrakt syear using "${SOEP_l_reg}kreise_v33.1_l.dta", nogen keepusing(kkz kkz_rek uemprate) // kreiskennziffer (kkz)
	drop if missing(pid)
	rename hhnrakt hid
	clonevar kkz_org = kkz
*	kkz missing for 1984 --> replace with kkz from 1985/86/87
*	(justifiable, we have only unemployment data on 12/1984 and cannot control 
*	for specific date of moving between interviews)
	egen kkz_t = total(kkz) if sampreg==1 & syear<=1985, by(pid)
	replace kkz = kkz_t if sampreg==1 & syear==1984 & kkz_t!=0
	drop kkz_t
	egen kkz_rek_t = total(kkz_rek) if sampreg==1 & syear<=1985, by(pid)
	replace kkz_rek = kkz_rek_t if sampreg==1 & syear==1984 & kkz_rek_t !=0
	drop kkz_rek_t
*	West all: kkz changed for Hannover, Berlin (available as 1 unique kkz in available data)
	replace kkz = kkz_rek if inlist(kkz, 3201, 3253, 11100, 11200)
*	West 2010: kkz changed for Aachen
	replace kkz = kkz_rek if inlist(kkz, 5313, 5354) & syear==2010
*	East 2012: kkz changed for Greifswald/Neubrandenburg/Stralsund/Wismar/Bad Doberan
*	Demmin/Guestrow/Ludwigslust/Strelitz/Mueritz/Nordvorpommern/Nordwestmeckl./
*	Ostvorpommern/Parchim/Ruegen/Uecker_randow
	replace kkz = kkz_rek if inlist(kkz, 13001, 13002, 13005, 13006, 13051, 13052, ///
		13053, 13054, 13055, 13056, 13057, 13058, 13059, 13060, 13061, 13062) & syear==2012
*	East 2008: kkz changed for Dessau/ Anhalt-Zerbst/Bernburg/Bitterfeld/Wittenberg
*	Halle/Burgenlandkreis/Mansfelder Land/Merseburg-Querfurt/Saalkreis/Sangershausen/
*	Weissenfels/Magdeburg/Aschersleben/Boerdekreis/Halberstadt/Jerichower Land/
*	Ohrekreis/Stendal/Quedlinburg/Schoenebeck/Wernigerode/Altmarkkreis Salzwedel
	replace kkz = kkz_rek if inlist(kkz, 15101, 15151, 15153, 15154, 15171, 15202, 15256, ///
		15260, 15261, 15265, 15266, 15268, 15303, 15352, 15355, 15357, 15358, ///
		15362, 15363, 15364, 15367, 15369, 15370) & syear==2008			
*	merge unemp data
	merge m:1 kkz syear using "${dir_data}source/unemp_84_2016l.dta", nogen // monthly unemployment
	drop if missing(pid)


////////////
////////////
////////////

***	decode missing values
	mvdecode _all, mv(-8 -7 -6 -5 -4 -3 -2 -1)
	
////
//// Match monthly unemployment rate of districts by propensity to available data
////
*	clean up of dataset
	replace sampreg=2 if kkz==14014 // wrongly assigned
	replace month=3 if missing(month) // main month, only relevant for unemprate, precise enough
	replace m09_=m06_ if kkz==15358 & syear==2007 
*	gen placeholder	
	gen unempr_kkz = .
	lab var unempr_kkz "district unemployment rate in interview month"
*	rename for value loops	
	local months "01 02 03 04 05 06 07 08 09 10 11 12"
	foreach i in `months' {
		if "`i'" != "10" & "`i'" != "11" & "`i'" != "12" {
			local j = subinstr("`i'","0","",.)
			rename m`i'_ m`j'
		}
		else {
			rename m`i'_ m`i'
		}
	}
*	replace missing values for kkz by state level data for those kkz that are
*	unassignable due to county region changes
	forvalues s=1/2 {
		forvalues y=1991/1996 {
			forvalues i=1/12 {
				sum m`i' if syear==`y', meanonly
				replace m`i'=r(mean) if missing(m`i')
			}
		}
	}
*	egen unemp year mean for kkz as fallback
*	egen unemp_kkz_my = mean()
*	assign closest available values (at least quarterly measured -> +/- 2)
	foreach s in sampreg {
	*	additional options/restrictions
		if `s' == 1 {
			local opts "& syear>=1985 & sampreg==`s'"
		}
		else {
			local opts "& syear>=1991 & sampreg==`s'" // data starts in 1996 for East Germany
		}
		forvalues i=1/12 {
		*	if value available for month	
			replace unempr_kkz = m`i' if month==`i' & !missing(m`i') `opts'
		*	if value available for next/previous month
			if `i'>1 & `i'<12 {
				local j = `i'+1
				replace unempr_kkz = m`j' if month==`i' & !missing(m`j') `opts'
				local j = `i'-1
				replace unempr_kkz = m`j' if month==`i' & missing(m`i') & !missing(m`j') `opts'
			}
		*	if value available for previous month in december
			if `i'==12 {
				local j = `i'-1
				replace unempr_kkz = m`j' if month==`i' & !missing(m`j') & missing(unempr_kkz) `opts'
			}	
		*	if value available for next month in january
			if `i'==1 {
				local j = `i'+1
				replace unempr_kkz = m`j' if month==`i' & !missing(m`j') & missing(unempr_kkz) `opts'
			}
		*	if value available for month after next(+2)
			if `i'>=1 & `i'<=10 {
				local j = `i'+2
				replace unempr_kkz = m`j' if month==`i' & !missing(m`j') & missing(unempr_kkz) `opts' 
			}
		*	if value available for month before previous (-2)
			if `i'>2 & `i'<=12 {
				local j = `i'-2
				replace unempr_kkz = m`j' if month==`i' & !missing(m`j') & missing(unempr_kkz) `opts'
			}
		}
	}
	
*	West: if syear==1984 and district unemprate is missing: replace with bula data!
	egen unempr_bula = mean(unemp_bula1984), by(bula)
	drop unemp_bula1984
	replace unempr_kkz = unempr_bula if syear==1984 & missing(unempr_kkz)	
	drop unempr_bula

*	check everything for relevant periods
	codebook unempr_kkz if sampreg==1 // 0
	codebook unempr_kkz if sampreg==2 & syear>=1991 // 2

*** Define decades/cohorts
	recode gebjahr (min/1945=1 "1945 or less") (1946/1964=2 "1946-1964") ///
		(1965/max=3 "1965 or more"), generate(bcohort)
	recode syear (1984/1990=1 "1984-1990") ///
		(1997/2006=2 "1997-2006") (2007/2016=3 "2007-2016") ///
		 (else=.), generate(decade)
	clonevar decade_east = decade
	replace decade_east=. if decade_east==1

*** Demographic groups
* 	Age 
	recode age (18/24=1 "18 bis 24") (25/29=2 "25 bis 29") (30/34=3 "30 bis 34") ///
		(35/39=4 "35 bis 39") (40/44=5 "40 bis 44") (45/49=6 "45 bis 49") ///
		(50/54=7 "50 bis 54") (55/59=8 "55 bis 59") (60/64=9 "60 bis 64") ///
		(else=.), generate(agegr5)
		lab var agegr5 "Alter, gruppiert"
	recode age_m (18/24=1 "18 bis 24") (25/29=2 "25 bis 29") (30/34=3 "30 bis 34") ///
		(35/39=4 "35 bis 39") (40/44=5 "40 bis 44") (45/49=6 "45 bis 49") ///
		(50/54=7 "50 bis 54") (55/59=8 "55 bis 59") (60/64=9 "60 bis 64") ///
		(else=.), generate(agegr5_m)
		lab var agegr5_m "Alter Ehemann, gruppiert"	
	recode age  (25/34=1 "25 bis 34") (35/44=2 "35 bis 44") (45/54=3 "45 bis 54") ///
		(55/64=4 "55 bis 64") (else=.), generate(agegr10)
		lab var agegr10 "Alter gruppiert"
	recode age_m  (25/34=1 "25 bis 34") (35/44=2 "35 bis 44") (45/54=3 "45 bis 54") ///
		(55/64=4 "55 bis 64") (else=.), generate(agegr10_m)
		lab var agegr10_m "Alter gruppiert, Mann"
*	ISCED
	recode isced (1/2=1 "keine Ausbildung") (3/4=2 "Ausbildung") (5/6=3 "höhere Bildung") (else=.), generate(iscgr_west)
		lab var iscgr_west "Bildung gruppiert, West"
	recode isced (1/4=1 "niedrige/mittlere Bildung") (5/6=2 "höhere Bildung") (else=.), generate(iscgr_east)
		lab var iscgr_east "Bildung gruppiert, East"

*	Age x ISCED x Sample region
* 	West
	lab def labeldemgr_west 1 "25-34, low education" 2 "25-34, medium education" 3 "25-34, high education" ///
			4 "35-44, low education" 5 "35-44, medium education" 6 "35-44, high education" ///
			7 "45-54, low education" 8 "45-54, medium education" 9 "45-54, high education" ///
			10 "55-64, low education" 11 "55-64, medium education" 12 "55-64, high education", modify
	generate demgr_west:labeldemgr_west=.
	local l=1
	forvalue i=1/4 {
		forvalue j=1/3{
				replace demgr_west=`l' if agegr10==`i' & iscgr_west==`j' & sampreg==1
				local l=`l' + 1
		}
	}
	label var demgr_west "Demographic group, West"
	replace demgr_west=9 if demgr_west==12 & decade==1 // Zusammenlegen 45-54 & 55-64 bei hoher Bildung wegen zu geringer Fallzahl
	*label def labeldemgr_west 9 "45-64, hohe Bildung" 12 "", modify  // if needed for table

* 	East
	lab def labeldemgr_east 1 "25-34, low/medium education" 2 "25-34, high education" ///
		3 "35-44, low/medium education" 4 "35-44, high education" ///
		5 "45-54, low/medium education" 6 "45-54, high education" ///
		7 "55-64, low/medium education" 8 "55-64, high education", modify
	generate demgr_east:labeldemgr_east=.
	local l=1
	forvalue i=1/4 {
		forvalue j=1/2{
				replace demgr_east=`l' if agegr10==`i' & iscgr_east==`j' & sampreg==2
				local l=`l' + 1
		}
	}
	label var demgr_east "Demographic group, East"


//////
////// 24.01.2017: Income = labgro + secjobgro // treated as composite labour income!
//////

/*	Note: Not adjusted for inflation! But needed to de-round integer multiples */

	egen clabgro = rowtotal(labgro secjobgro) ///
		if !missing(labgro) | !missing(secjobgro)
	egen clabgro_m = rowtotal(labgro_m secjobgro_m) ///
		if !missing(labgro_m) | !missing(secjobgro_m)
	sum clabgro

	recode clabgro .=0 // missing --> 0
	recode clabgro_m .=0 // missing --> 0
	generate antlabgro = clabgro / (clabgro + clabgro_m) if (clabgro~=0 | clabgro_m~=0)
	lab var antlabgro "Anteil der Partnerin am Verdienst"

	gen eqearn = 0 if antlabgro!=.
	replace eqearn = 1 if antlabgro==0.5
	tab eqearn
***	
*** annual income as income share basis (07.10.2018)
***
	* 	gen couple ID
	drop cid
	egen cid = group(pid partnr)
	* 	set couple panel
	xtset cid syear
	*	annual data available for previous year!
	gen wis = yinc/(yinc_m + yinc) if yinc!=. & yinc_m!=. & yinc>0 & yinc_m>0
	
	gen eqearn2=0 if wis!=.
	replace eqearn2=1 if wis==0.5
	tab eqearn2

	
*** age groups kids
	recode agekid (.=0 "keine Kinder") (0/3=1 "bis 3 Jahre") (4/6=2 "4 bis 6 Jahre") ///
		(7/16=3 "7 bis 16 Jahre") (else=.), generate(agekidk)
	lab var agekidk "Alter des jüngsten Kindes, klassiert"

***
*** Housework
***	
	local listHA ///
		NMW_errands NMW_housework NMW_childcare NMW_repairs NMW_errands_m NMW_housework_m ///
		NMW_childcare_m NMW_repairs_m NMW_hw_sat NMW_hw_sun NMW_hw_sat_m NMW_hw_sun_m
	gen totNonMarketWork=  NMW_errands +  NMW_housework +  NMW_childcare +  NMW_repairs
		lab var totNonMarketWork "Stunden Hausarbeit Ehefrau"
	gen totNonMarketWork_m =  NMW_errands_m +  NMW_housework_m +  NMW_childcare_m +  NMW_repairs_m
		lab var totNonMarketWork_m "Stunden Hausarbeit Ehemann"
	gen AntHA= totNonMarketWork/(totNonMarketWork + totNonMarketWork_m)
		lab var AntHA "Anteil Hausarbeit der Frau"

	recode totNonMarketWork 16/max=16 if totNonMarketWork~=., generate(tNMW) 
		label var tNMW "Stunden Hausarbeit Ehefrau, topcoded"
	recode totNonMarketWork_m 16/max=16 if totNonMarketWork_m~=., generate(tNMW_m) 
		label var tNMW_m "Stunden Hausarbeit Ehemann, topcoded"
	gen AHA= tNMW/(tNMW + tNMW_m)
		lab var AHA "Anteil Hausarbeit der Frau, topcoded"

* 	Housework share
	gen AntNMW = NMW_housework/(NMW_housework + NMW_housework_m)
		lab var AntNMW "Anteil reine Hausarbeit der Frau"
	gen NMW_weekly= 5*NMW_housework + NMW_hw_sat + NMW_hw_sun
		lab var NMW_weekly "Hausarbeit pro Woche Frau"
	gen NMW_weekly_m= 5*NMW_housework_m + NMW_hw_sat_m + NMW_hw_sun_m
		lab var NMW_weekly_m "Hausarbeit pro Woche Mann"
	gen AntNMW_weekly =NMW_weekly/(NMW_weekly + NMW_weekly_m)
		lab var AntNMW_weekly "Anteil reine Hausarbeit der Frau pro Woche"

* 	Housework share weekdays (1984-2016 available)
	gen NMWwd = 5*NMW_housework
		lab var NMWwd "Hausarbeit Summe werktags Frau"
	gen NMWwd_m = 5*NMW_housework_m
		lab var NMWwd_m "Hausarbeit Summe werktags Mann"

*	Share HW Sat
	gen AntNMW_sat =NMW_hw_sat/(NMW_hw_sat + NMW_hw_sat_m)
		lab var AntNMW_sat "Anteil reine Hausarbeit der Frau an einem Samstag"

* 	Share HW Sun
	gen AntNMW_sun =NMW_hw_sun/(NMW_hw_sun + NMW_hw_sun_m)
		lab var AntNMW_sun "Anteil reine Hausarbeit der Frau an einem Sonntag"
		
*	HW Gap
	gen NMW_Gap=NMW_weekly - NMW_weekly_m
		lab var NMW_Gap "Hausarbeitszeitdifferenz Frau - Mann"
	gen Ngwd=NMWwd - NMWwd_m
		lab var Ngwd "Hausarbeitszeitdifferenz Frau - Mann, werktags"


*** Country of origin
	recode corigin (1=0) (else=1), gen(MIG_w)
	recode corigin_m (1=0) (else=1), gen(MIG_m)
	gen MIG=0
		replace MIG=1 if MIG_w==1 | MIG_m==1	

*** Log. working hours (actual)
	replace tatzt=vebzt if missing(tatzt) & !missing(vebzt)
	replace tatzt_m=vebzt_m if missing(tatzt_m) & !missing(vebzt_m)
	gen lntatzt=ln(tatzt)
		lab var lntatzt "Tatsächliche Arbeitszeit, logarithmiert"
	gen lntatzt_m=ln(tatzt_m)
		lab var lntatzt_m "Tatsächliche Arbeitszeit, logarithmiert, husband"

*** Log. working hours (contractual)
	replace vebzt=tatzt if missing(vebzt) & !missing(tatzt)
	replace vebzt_m=tatzt_m if missing(vebzt_m) & !missing(tatzt_m)
	gen lnvebzt=ln(vebzt)
		lab var lnvebzt "Vereinbarte Arbeitszeit, logarithmiert"
	gen lnvebzt_m=ln(vebzt_m)
		lab var lnvebzt_m "Vereinbarte Arbeitszeit, logarithmiert, husband"

*** Labor Force Status
*	At time of interview
	recode lfs (1/9=0 "Nicht berufstätig") (10/12=1 "berufstätig"), generate(lfp)
		lab var lfp "Labor Force Participation Frau"
	recode lfs_m (1/9=0 "Nicht berufstätig") (10/12=1 "berufstätig"), generate(lfp_m)
		lab var lfp_m "Labor Force Participation Mann"
	gen lfp_wo=0
		replace lfp_wo=1 if lfp==1 & lfp_m==0
		lab var lfp_wo "Only wife is working"
	gen lfp_mo=0
		replace lfp_mo=1 if lfp==0 & lfp_m==1
		lab var lfp_mo "Only husband is working"

***	Employment status (Full-Time / Part-Time)
*	at time of interview
	lab def labelVZ 0 "nicht VZ beschäftigt" 1 "VZ beschäftigt", modify
	gen VZ:labelVZ=0
	replace VZ=1 if erwstat==1 & ((tatzt>=35 & tatzt~=.) | (vebzt>35 & vebzt~=.))
	lab var VZ "Vollzeit beschäftigt"
	gen VZ_m:labelVZ=0
	replace VZ_m=1 if erwstat_m==1 & ((tatzt_m>=35 & tatzt_m~=.) | (vebzt_m>35 & vebzt_m~=.))
	lab var VZ_m "Vollzeit beschäftigt"
*	full-time indicator based on months p.a.
	gen yvz = 0
		replace yvz = 1 if yftm==12
		label var yvz "full-time employed wife (year before)"
	gen yvz_m = 0
		replace yvz_m = 1 if yftm_m==12
		label var yvz_m "full-time employed husband (year before)"


/* month-based precise estimation */

rename pid pid_temp
rename partnr pid

*	merge pkal data
	merge 1:1 pid syear using "${SOEP_l}pkal.dta", ///
		keepusing(	kal1a001-kal1a012 ///
					kal1b001-kal1b012 kal1c001-kal1c012 kal1d001-kal1d012 ///
					kal1e001-kal1e012 kal1f001-kal1f012 kal1g001-kal1g012 ///
					kal1h001-kal1h012 ///
					kal1k001-kal1k012 kal1n001-kal1n012)
	drop if _merge==2
	drop _merge
	/* multiple variables for the same concept
	replace kal1a001_v1 = kal1a001_v2 if syear>=1998
	rename kal1a001_v1 kal1a001
	replace kal1h001_v1 = kal1h001_v2 if syear>=2002 & syear<=2011
	replace kal1h001_v1 = kal1h001_v3 if syear>=2012
	rename kal1h001_v1 kal1h001	*/
*	rename for men		
	foreach a in a b c d e f g h k n {
		foreach i in 01 02 03 04 05 06 07 08 09 10 11 12 {
			rename kal1`a'0`i' kal1`a'0`i'_m
		}	
	}
	rename pid partnr
	rename pid_temp pid
*	merge pkal data
	merge 1:1 pid syear using "${SOEP_l}pkal.dta", ///
		keepusing(	kal1a001-kal1a012 ///
					kal1b001-kal1b012 kal1c001-kal1c012 kal1d001-kal1d012 ///
					kal1e001-kal1e012 kal1f001-kal1f012 kal1g001-kal1g012 ///
					kal1h001-kal1h012 ///
					kal1k001-kal1k012 kal1n001-kal1n012)
	drop if _merge==2
	drop _merge
	

xtset cid syear
					
***	gen indicator that individual was (not) doing x until the month of the interview
*	individual was working (full or part time)
	foreach gender in 1 2 {
		if `gender'==2 {
			local g "_m"
		}
		foreach a in a c d e f g h {
			gen kal1`a'`g'=0
			gen kal1`a'`g'_full=0
			forvalues m=1/12 {	
				if `m' < 10 {
					local j = 0
				}
				else {
					local j
				}
				if `m'>1 {
					local k "&"
				}
				if "`a'"=="a" {
				*	all months before & including interview
					local rules "(kal1a0`j'`m'`g'==1 | kal1b0`j'`m'`g'==1 | kal1k0`j'`m'`g'==1 | kal1n0`j'`m'`g'==1 ) `k' `rules'"
					replace kal1`a'`g'=1 if `rules' & l1.month`g'==`m'
				*	all months in year
					if `m'==12 {
						replace kal1`a'`g'_full=1 if `rules'
					}
				}
				else {
				*	in no month before & including interview
					local rules ", kal1`a'0`j'`m'`g' `rules'"
					replace kal1`a'`g'=1 if inlist(1 `rules') & l1.month`g'==`m'
				*	in no month of full year
					if `m'==12 {
						replace kal1`a'`g'_full=1 if inlist(1 `rules')
					}	
				}
				local k
			}
			local rules
		}	
		rename kal1a`g' 		yw_int`g'	
		rename kal1a`g'_full 	yw_full`g'
		rename kal1c`g' 		yvoc_int`g'
		rename kal1c`g'_full 	yvoc_full`g'
		rename kal1d`g' 		yunemp_int`g'
		rename kal1d`g'_full 	yunemp_full`g'
		rename kal1e`g'			ypen_int`g'
		rename kal1e`g'_full 	ypen_full`g'
		rename kal1f`g' 		ymother_int`g'
		rename kal1f`g'_full 	ymother_full`g'
		rename kal1g`g' 		yschool_int`g'
		rename kal1g`g'_full 	yschool_full`g'
		rename kal1h`g' 		yservice_int`g'
		rename kal1h`g'_full 	yservice_full`g'	
	}
	// Caution: data until interview missing for 1984! (But not needed in regressions)

*	use short-time work (>92) and minijob info (>2005)
*	get "maximum" value per month
	lab def yemplstm 1 "full-time" 2 "part-time" 3 "short-time" 4 "marginal", modify
	forvalues s=1/2 {
		if `s'==1 {
			local g "_m"
		}
		else {
			local g
		}
		forvalues m=1/12 {
			if `m' < 10 {
				local j = 0
			}
			else {
				local j
			}
			gen yemplstm`m'`g' = 0 if !missing(kal1a0`j'`m'`g', kal1b0`j'`m'`g', kal1k0`j'`m'`g', kal1n0`j'`m'`g')
			replace yemplstm`m'`g' = 4 if kal1n0`j'`m'`g'==1 // mini-job
			replace yemplstm`m'`g' = 3 if kal1k0`j'`m'`g'==1 // short-time
			replace yemplstm`m'`g' = 2 if kal1b0`j'`m'`g'==1 // part-time
			replace yemplstm`m'`g' = 1 if kal1a0`j'`m'`g'==1 // full-time
			lab var yemplstm`m'`g' "max. employment status month `m'"
			lab val yemplstm`m'`g' yemplstm
			// full-time vs. part-time (part-time includes marginal and short-time)
			gen yptm`m'`g' = 0 if !missing(yemplstm`m'`g')
			replace yptm`m'`g' = 1 if yemplstm`m'`g'>1 & yemplstm`m'`g'<=4
			gen yftm`m'`g' = 0 if !missing(yemplstm`m'`g')
			replace yftm`m'`g' = 1 if yemplstm`m'`g'==1	
		}
	*	correct months per year
		cap drop yptm`g'
		cap drop yftm`g'
		cap drop ywm`g'
		egen yptm`g' = rowtotal(yptm1`g' yptm2`g' yptm3`g' yptm4`g' yptm5`g' /// 
			yptm6`g' yptm7`g' yptm8`g' yptm9`g' yptm10`g' yptm11`g' yptm12`g')
		egen yftm`g' = rowtotal(yftm1`g' yftm2`g' yftm3`g' yftm4`g' yftm5`g' ///
			yftm6`g' yftm7`g' yftm8`g' yftm9`g' yftm10`g' yftm11`g' yftm12`g')
		egen ywm`g' = rowtotal(yptm`g' yftm`g')
	}
/* year-based estimation if individual changed the sample region */
	
*	where was couple 1989?	
	recode loc1989 (1=2) (2=1) (else=.), gen(sampreg1989)
	recode loc1989_m (1=2) (2=1) (else=.), gen(sampreg1989_m)
*	sample region of birth if location 1989 missing or abroad (Berlin = .)
	recode birthregion (1/10 = 1) (12/16 = 2) (else=.), gen(birthreg)
	recode birthregion_m (1/10 = 1) (12/16 = 2) (else=.), gen(birthreg_m)
	replace birthreg = sampreg1989 if missing(birthreg)
	replace birthreg_m = sampreg1989_m if missing(birthreg_m)
	label def birthreg 1 "West" 2 "East", modify
	label val birthreg birthreg
	label val birthreg_m birthreg
	drop sampreg1989

*	add care variables
	merge m:1 hid syear using "${SOEP_l}hl.dta", ///
		keepusing(hlf0291)
	drop if _merge==2
	drop _merge
	replace hlf0291 = . if hlf0291<0
	rename hlf0291 carehh

*	add variable checking if partners lived together the full year before interview
	merge 1:1 pid syear using "${SOEP_l}pl.dta", ///
		keepusing(pld0139)
	drop if _merge==2
	drop _merge
	rename pld0139 movedinm
	
*** save	
	label data "Dataset Gender Identity, generated"
	save  "${dir_data}gi_gen.dta", replace

	clear all
	log close
