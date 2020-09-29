////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		--	Generate SOEP long file from wide files --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////


set more off

***
*** SOEP - Waves
***
global wave ///
	a b c d e f g h i j k l m n o p q r s t u v w x y z ba bb bc bd be bf bg
global year ///
	1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 ///
	1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 ///
	2014 2015 2016
global year2 ///
	84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 00 01 02 03 04 05 06 07 08 /// 
	09 10 11 12 13 14 15 16

***
*** Called Do-Files
***
global routine_p = "${dir_do}auxiliary/fetch_merge_save_erase_routine_dataset_p.do"

*** drop macros (avoid name doublettes and data overwrite)
macro drop crrnt_varname
macro drop crrnt_var
macro drop crrnt_wave
macro drop crrnt_year


				
						*  --------------------  *
						* | MASTER-FILE: PPFAD | *
						*  --------------------  *

clear

*** add variables that change for waves **************************************** ▼ ▼ ▼ add if new var
local ppfad_var ///
	hhnr netto pop
*** add variables that do not change for waves
local ppfad_fix ///
	persnr hhnr sex psample loc1989 migback corigin
******************************************************************************** ▲ ▲ ▲

*** Basisdatensatz aus zeit-invarianten Variablen
use `ppfad_fix' ///
	using ${SOEP}ppfad.dta, clear
save ${dir_data}source/temp/pmaster.dta, replace 

clear
*** Hinzufügen weiterer Pfaddaten
local n : word count ${wave}
*** 1984-1989 without sampreg
forvalues i=1/6{
	local x : word `i' of ${wave}
	local y : word `i' of ${year} 

*** translate varnames corresponding to wavenames
	foreach var in `ppfad_var' {
		local ppfad_vars`x' "`ppfad_vars`x'' `x'`var'"
	}
*** use vars per wave
	use persnr gebjahr `ppfad_vars`x'' using ${SOEP}ppfad.dta, clear 

	foreach var in `ppfad_var' {
		rename `x'`var' `var'`y'
		mvdecode `var'*, mv(-1 -2 -3)
	}
*** save per wave	
	save ${dir_data}source/temp/ppfad_`x'.dta, replace
}
*** 1990-2016 with sampreg
forvalues i=7/`n'{
	local x : word `i' of ${wave}
	local y : word `i' of ${year} 

*** translate varnames corresponding to wavenames; sampreg added
	local ppfad_var ///
		hhnr netto netold pop sampreg
	foreach var in `ppfad_var' {
		local ppfad_vars`x' "`ppfad_vars`x'' `x'`var'"
	}
*** use vars per wave
	use persnr gebjahr `ppfad_vars`x'' using ${SOEP}ppfad.dta, clear 

	foreach var in `ppfad_var' {
		rename `x'`var' `var'`y'
		mvdecode `var'*, mv(-1 -2 -3)
	}
*** save per wave	
	save ${dir_data}source/temp/ppfad_`x'.dta, replace
}
*** Generierung Alter
clear
forvalues i=1/`n' {
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
	use ${dir_data}source/temp/ppfad_`x'.dta
	mvdecode gebjahr, mv(-1)
	gen age`y'=.
	replace age`y'=`y'-gebjahr if gebjahr<=`y'
	save ${dir_data}source/temp/ppfad_`x', replace
}
*** merge
use ${dir_data}source/temp/pmaster.dta, clear
foreach x in $wave { 
	merge 1:1 persnr using ${dir_data}source/temp/ppfad_`x'.dta
	drop _merge 
}
*** save
save ${dir_data}source/temp/pmaster.dta, replace 
*** erase
foreach x in $wave { 
	erase ${dir_data}source/temp/ppfad_`x'.dta
}
*** save fetched vars in macro for reshape command
macro drop vars_fetched_from_ppfad
global vars_fetched_from_ppfad ///
	`ppfad_var' age
dis "$vars_fetched_from_ppfad"


						*  --------------------  *
						* | GEWICHTUNG: PHRF   | *
						*  --------------------  *

clear

*** add varnames that change for waves ***************************************** ▼ ▼ ▼ add if new var
local phrf_var ///
	phrf pbleib
*** add varnames that do not change for waves
local phrf_fix ///
	persnr prgroup
******************************************************************************** ▲ ▲ ▲

*** translate varnames corresponding to wavenames
local n : word count ${wave} // pbleib erst ab 1985
forvalues i=2/`n'{
	local x : word `i' of ${wave}
	foreach var in `phrf_var' {
		local phrf_vars "`phrf_vars' `x'`var'"
	}
}

*** use
use aphrf `phrf_vars' `phrf_fix' /// 
	using ${SOEP}phrf.dta

local n : word count ${wave}
forvalues i=2/`n'{
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
	
	foreach var in `phrf_var' {
		rename `x'`var' `var'`y'
	}
}
rename aphrf phrf1984 // rename manually
*
save ${dir_data}source/temp/phrf.dta, replace 
*** merge
use ${dir_data}source/temp/pmaster.dta, clear 
merge 1:1 persnr using ${dir_data}source/temp/phrf.dta
keep if _merge==3
drop _merge
*** save
save ${dir_data}source/temp/pmaster.dta, replace
*** erase
erase ${dir_data}source/temp/phrf.dta 
*** save fetched vars in macro for reshape command
macro drop vars_fetched_from_phrf
global vars_fetched_from_phrf ///
	`phrf_var'
dis "$vars_fetched_from_phrf"


						*  --------------------  *
						* | DATENSATZ: PGEN    | *
						*  --------------------  *

// PGEN (generierte Variablen) sind immer für alle Wellen verfügbar.
// Wir können also auf die Master globals zurückgreifen. Hier müssen nur die
// locals "var_block_prefix" und "var_block_suffix" editiert werden, wenn neue
// Variablen hinzukommen.

clear
******************************************************************************** ▼ ▼ ▼ add if new var						
*** Alle Variablen mit Struktur `x'varname (x => $wave (z.b. o für 1998))
local var_block_prefix ///
	famstd bilzeit tatzeit vebzeit erwzeit

*** Alle Variablen mit Struktur varname`z' (z => $year2 (z.B. 98 für 1998))
local var_block_suffix ///
	labgro impgro labnet impnet expft exppt expue emplst lfs isced97_ ///
	stib partz partnr month casmin
******************************************************************************** ▲ ▲ ▲	

local n : word count ${wave} // alle Wellen vorhanden für PGEN
forvalues i=1/`n'{
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
	local z : word `i' of ${year2}
*** Übersetzen in Suffix-/Prefix-Struktur und in varlist speichern
	foreach var in `var_block_prefix' {
		local pre `x'`var'
		local vars_pre_`x' = "`vars_pre_`x'' `pre'"
	}
	foreach var in `var_block_suffix' {
		local suf `var'`z'
		local vars_suf_`x' = "`vars_suf_`x'' `suf'"
	}
*** Hier werden alle Variablen zusammen aufgerufen für jede einzelne Welle
	use persnr `vars_pre_`x'' `vars_suf_`x'' using ${SOEP}`x'pgen.dta, clear
	dis as result "check"
*** Umbenennen Standard-Routine nach Struktur
	foreach var in `var_block_prefix' {
		rename `x'`var' `var'`y'
	}
	foreach var in `var_block_suffix' {
		rename `var'`z' `var'`y'
	}
	save ${dir_data}source/temp/`x'pgen.dta, replace
}
*
// Vermerk (20.12.2016): Die Var "erwtyp" existiert nicht mehr in der V.32
clear
tokenize ${wave} // every entry gets a number to address directly
use ${dir_data}source/temp/`1'pgen.dta // use first dataset
local n : word count ${wave} // merge every dataset starting with wave 2
forvalues i=2/`n'{
	local x : word `i' of ${wave}
	merge 1:1 persnr using ${dir_data}source/temp/`x'pgen.dta
	drop _merge
}
*** save
save ${dir_data}source/temp/pgen.dta, replace
*** erase
foreach x in $wave { 
	erase ${dir_data}source/temp/`x'pgen.dta
}
*** save fetched vars in macro for reshape command
macro drop vars_fetched_from_pgen
global vars_fetched_from_pgen ///
	`var_block_prefix' `var_block_suffix'
dis "$vars_fetched_from_pgen"


						*  --------------------  *
						* | DATENSATZ: P       | *
						* |	ALLE WELLEN >1984  | *
						*  --------------------  *

*** drop macro (wird sonst doppelt beschrieben wenn noch im cache)
macro drop vars_fetched_from_p
						
// Anmerkung Max 27.07.2017: Da hier die Variablen den in allen Wellen vorhanden
// sind, kann man dafür eine Schleife definieren (s.u.) auf Basis des year globals. 
// Wichtig: Im local "var_block" hinterlegte Namen sind auch die späteren 
// Variablennamen. Die Namen in diesem local müssen mit den local namen für die 
// einzelnen Items der Jahre übereinstimmen, damit diese angesprochen werden können.
// Die Verarbeitungsroutine für alle P Variablen ist im Master.do verlinkt.


*** Liste aller Variablen für die Schleife ************************************* ▼ ▼ ▼ add localname of new var	
local var_block ///
	hausarb repgart derz_ausb sat_inc_hh sat_life 
******************************************************************************** ▲ ▲ ▲

*** Hausarbeit Werktag in Stunden
local hausarb ///
	ap0103 bp0201 cp0201 dp0201 ep0201 fp0201 gp1301 hp0103 ip0103 jp0203 ///
	kp0803 lp0203 mp0203 np0203 op0503 ///
	pp02a3 qp05a3 rp0207 sp1103 tp1007 up0203 vp0207 wp6203 xp0207 yp1203 ///
	zp0203 bap0303 bbp0203 bcp0403 bdp1003 bep0503 bfp1003 bgp0903

*** Reperaturarbeiten & Gartenarbeit an einem Werktag in Stunden
local repgart ///
	ap0104 bp0205 cp0205 dp0205 ep0205 fp0205 gp1313 hp0106 ip0106 jp0206 ///
	kp0806 lp0206 mp0206 np0206 op0506 pp02a6 ///
	qp05a6 rp0219 sp1107 tp1019 up0207 vp0219 wp6207 xp0219 yp1207 zp0207 ///
	bap0307 bbp0207 bcp0407 bdp1007 bep0507 bfp1007 bgp0907

*** Derzeit in Ausbildung
local derz_ausb ///
	ap04 bp14 cp14 dp10 ep10 fp08 gp10 hp05 ip13 jp13 kp18 lp14 mp13 np09 ///
	op02 pp08 qp08 rp10 sp13 tp32 up07 vp08 wp05 xp11 yp16 zp07 bap07 bbp07 ///
	bcp09 bdp16 bep1001 bfp1601 bgp1501

*** Zufriedenheit mit dem Haushaltseinkommen
local sat_inc_hh ///
	ap0302 bp0102 cp0102 dp0102 ep0102 fp0102 gp0102 hp1004 ip9804 jp0104 ///
	kp0104 lp0104 mp0104 np0104 op0104 pp0104 qp0104 ///
	rp0104 sp0104 tp0104 up0104 vp0104 wp0104 xp0104 yp0105 zp0105 ///
	bap0105 bbp0105 bcp0105 bdp0105 bep0105 bfp0105 bgp0105

*** Lebenszufriedenheit
local sat_life ///
	ap6801 bp9301 cp9601 dp9801 ep89 fp108 gp109 hp10901 ip10901 jp10901 ///
	kp10401 lp10401 mp11001 np11701 op12301 pp13501 qp14301 rp13501 sp13501 ///
	tp14201 up14501 vp154 wp142 xp149 yp15501 ///
	zp15701 bap160 bbp15201 bcp151 bdp15801 bep151 bfp174 bgp175	
	
***
*** Ziehen, Umbenennen und Mergen der oben spezifizierten Variablen
***
foreach var in `var_block' {
	global crrnt_varname ///
		`var'
	global crrnt_var ///
		``var'' // this calls the local with the same name as the var in varlist
	global crrnt_year /// 
		${year} // für alle Jahre definiert im Master
	do  ${routine_p}
}


						*  --------------------  *
						* | DATENSATZ: P       | *
						* |	SPEZIFISCHE WELLEN | *
						* | EINZELITEMS        | *
						*  --------------------  *

// Vars nicht in allen Wellen vorhanden oder unterschiedlich abgefragt

******************************************************************************* ▼ ▼ ▼ add var & year if new wave																	   				  

// Achtung: Erwerbsstatus wurde mehrfach anders erfragt, muss für alle
// nachfolgenden Zeitpunkte einzeln gezogen und dann neu generiert werden in GEN
***
*** Erwerbsstatus
***
global crrnt_varname ///
	erwerbsstatus_84_
global crrnt_var /// 
	ap08
global crrnt_year ///
	1984
do  ${routine_p}

global crrnt_varname ///
	erwerbsstatus_85b90_96b98_
global crrnt_var /// 
	bp16 cp16 dp12 ep12 fp10 gp12 mp15 np11 op09
global crrnt_year ///
	1985 1986 1987 1988 1989 1990 1996 1997 1998
do  ${routine_p}
// Anmerkung: Dashes not allowed in varname!
global crrnt_varname ///
	erwerbsstatus_91b95_
global crrnt_var /// 
	hp15 ip15 jp15 kp25 lp21 
global crrnt_year ///
	1991 1992 1993 1994 1995
do  ${routine_p}

global crrnt_varname ///
	erwerbsstatus_99_
global crrnt_var /// 
	pp10
global crrnt_year ///
	1999
do  ${routine_p}

global crrnt_varname ///
	erwerbsstatus_2000b2001_
global crrnt_var /// 
	qp10 rp12
global crrnt_year ///
	2000 2001
do  ${routine_p}

// Ab 2012: Wehrdienst, Soziales oder ökologisches Jahr ist freiwillig
global crrnt_varname ///
	erwerbsstatus_2002b2015_
global crrnt_var /// 
	sp15 tp34 up09 vp10 wp07 xp13 yp19 zp09 bap09 bbp09 bcp11 bdp18 bep12 bfp32
global crrnt_year ///
	2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015
do  ${routine_p}

global crrnt_varname ///
	erwerbsstatus_ab_2016_
global crrnt_var /// 
	bgp31
global crrnt_year ///
	2016
do  ${routine_p}

***
*** Seit Vorjahr neue Arbeit (Jobwechsel); seit 1994 jährlich
***
global crrnt_varname ///
	jobwechsel
global crrnt_var ///
	kp37 lp29 mp27 np21 op21 pp21 qp20 rp23 sp23 tp48 up19 vp24 wp17 ///
	xp28  yp29 zp22 bap19 bbp22 bcp21 bdp31 bep21 bfp43 bgp40
global crrnt_year /// 
	1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 ///
	2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Kinderbertreuung Werktag in Stunden; ab 1985
***
global crrnt_varname ///
	kinderbetr
global crrnt_var ///
	bp0202 cp0202 dp0202 ep0202 fp0202 gp1304 hp0104  ip0104 jp0204 kp0804 ///
	lp0204 mp0204 np0204 op0504 ///
	pp02a4 qp05a4 rp0210 sp1104 tp1010 up0204  vp0210 wp6204 xp0210 yp1204 ///
	zp0204 bap0304 bbp0204 bcp0404 bdp1004 bep0504 bfp1004 bgp0904
global crrnt_year /// 
	1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 ///
	1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 ///
	2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Hausarbeit an einem Samstag; ab 1990, ab 1993 alle 2 Jahre  
***
global crrnt_varname ///
	hausarb_sa
global crrnt_var ///
	gp1302 jp0210 lp0210 np0210 pp02b3 rp0208 tp1008 vp0208 xp0208 zp0212 ///
	bbp0212 bdp1013 bfp1013
global crrnt_year /// 
	1990 1993 1995 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015
do  ${routine_p}

***
*** Hausarbeit an einem Sonntag; ab 1990, ab 1993 alle 2 Jahre  
*** 
global crrnt_varname ///
	hausarb_so
global crrnt_var ///
	gp1303 jp0217 lp0217 np0217 pp02c3 rp0209 tp1009 vp0209 xp0209 ///
	zp0221 bbp0221 bdp1023 bfp1023
global crrnt_year /// 
	1990 1993 1995 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015
do  ${routine_p}

***
*** Kinderbetreuung an einem Samstag; ab 1990, ab 1993 alle 2 Jahre  
***  
global crrnt_varname ///
	kinderbetr_sa
global crrnt_var ///
	gp1305 jp0211 lp0211 np0211 pp02b4 rp0211 tp1011 vp0211 xp0211 ///
	zp0213 bbp0213 bdp1014 bfp1014
global crrnt_year /// 
	1990 1993 1995 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015
do  ${routine_p}

***
*** Kinderbetreuung an einem Sonntag; ab 1990, ab 1993 alle 2 Jahre  
***  
global crrnt_varname ///
	kinderbetr_so
global crrnt_var ///
	gp1306 jp0218 lp0218 np0218 pp02c4 rp0212 tp1012 vp0212 xp0212 ///
	zp0222 bbp0222 bdp1024 bfp1024
global crrnt_year /// 
	1990 1993 1995 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015
do  ${routine_p}

***
*** Reperatur- und Gartenarbeit an einem Samstag; ab 2001 alle 2 Jahre
*** 
global crrnt_varname ///
	repgart_sa
global crrnt_var ///
	rp0220 tp1020 vp0220 xp0220 zp0216 bbp0216 bdp1017 bfp1017 
global crrnt_year /// 
	2001 2003 2005 2007 2009 2011 2013 2015
do  ${routine_p}

***
*** Reperatur- und Gartenarbeit an einem Sonntag; ab 2001 alle 2 Jahre
***   
global crrnt_varname ///
	repgart_so
global crrnt_var ///
	rp0221 tp1021 vp0221 xp0221 zp0225 bbp0225 bdp1027 bfp1027
global crrnt_year /// 
	2001 2003 2005 2007 2009 2011 2013 2015
do  ${routine_p}

***
*** Besorgungen an einem Werktag in Stunden; ab 1991
***
global crrnt_varname ///
	besorg
global crrnt_var ///
	hp0102 ip0102 jp0202 kp0802 lp0202 mp0202 np0202 op0502 pp02a2 qp05a2 ///
	rp0204 sp1102 tp1004 up0202 vp0204 wp6202 xp0204 yp1202 zp0202 bap0302 ///
	bbp0202 bcp0402 bdp1002 bep0502 bfp1002 bgp0902
global crrnt_year /// 
	1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Regelmäßige Nebenerwerbstätigkeit
***
global crrnt_varname ///
	secjob
global crrnt_var ///
	bp0302 cp0302 dp0302 ep0302 fp0302 gp0702 hp0202 ip0202 jp0302 kp0902 ///
	lp0302 mp5502 np5502 op4602 pp6102 qp5702 rp5902 sp5902 tp7702 up6002 ///
	vp7202 wp6302 xp7402 yp7102 zp7302 bap6402 bbp7402 bcp6202 bdp8002 bep6002 ///
	bfp10902 bgp9302
global crrnt_year /// 
	1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 ///
	1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 ///
	2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Nebenerwerbstätigkeit, Tage pro Monat
***
global crrnt_varname ///
	secjobd
global crrnt_var ///
	bp0401 cp0401 dp0401 ep0401 fp0401 gp0801 hp0401 ip0401 jp0501 kp1101 ///
	lp0501 mp5701 np5701 op4801 pp6501 qp6101 rp63 sp63 tp81 up64 vp76 wp67 ///
	xp78 yp73 zp75 bap66 bbp76 bcp64 bdp83 bep62 bfp111 bgp95
global crrnt_year /// 
	1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 ///
	1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 ///
	2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Nebenerwerbstätigkeit, Stunden pro Tag // bis einschl. 2014
***
global crrnt_varname ///
	secjobhd
global crrnt_var ///
	bp0402 cp0402 dp0402 ep0402 fp0402 gp0802 hp0402 ip0402 jp0502 kp1102 ///
	lp0502 mp5702 np5702 op4802 pp6502 qp6102 rp64 sp64 tp82 up65 vp77 wp68 ///
	xp79 yp74 zp76 bap67 bbp77 bcp65 bdp84 bep63
global crrnt_year /// 
	1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 ///
	1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 ///
	2012 2013 2014
do  ${routine_p}

***
*** Nebenerwerbstätigkeit, Stunden pro Woche // ab 2015
***
global crrnt_varname ///
	secjobhw
global crrnt_var ///
	bfp112 bgp96
global crrnt_year /// 
	2015 2016
do  ${routine_p}

***
*** Bruttoverdienste Nebenerwerb
***
global crrnt_varname ///
	secjobgro
global crrnt_var ///
	lp7702 mp5802 np5802 op4902 pp6602 qp6302 rp6602 sp6602 tp8402 up67 vp79 ///
	wp70 xp81 yp76 zp78 bap69 bbp79 bcp67 bdp85 bep64 bfp113 bgp97
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Bezug von Rente y/n
***
global crrnt_varname ///
	pen
global crrnt_var ///
	lp7703 mp5811 np5811 op4911 pp6613 qp6303 rp6603 sp6603 tp8403 up6801 ///
	vp8001 wp7101 xp8201 yp7701 zp7901 bap7001 bbp8001 bcp6801 bdp8601 bep6501 ///
	bfp114d01m bgp99d01
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Rente, Höhe in Euro
***
global crrnt_varname ///
	pengro
global crrnt_var ///
	lp7704 mp5812 np5812 op4912 pp6614 qp6304 rp6604 sp6604 tp8404 up6804 ///
	vp8002 wp7102 xp8202 yp7702 zp7902 bap7002 bbp8002 bcp6802 bdp8602 bep6502 ///
	bfp114d03m bgp99d03
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Bezug von ALG I y/n
***
global crrnt_varname ///
	alg1
global crrnt_var ///
	lp7701 mp5803 np5803 op4903 pp6603 qp6307 rp6607 sp6611 tp8411 up6805 ///
	vp8005 wp7105 xp8205 yp7705 zp7905 bap7005 bbp8005 bcp6805 bdp8605 bep6505 ///
	bfp114h01m bgp99h01
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** ALG I, Höhe in Euro
***
global crrnt_varname ///
	alg1gro
global crrnt_var ///
	lp7712 mp5804 np5804 op4904 pp6604 qp6308 rp6608 sp6612 tp8412 up6806 ///
	vp8006 wp7106 xp8206 yp7706 zp7906 bap7006 bbp8006 bcp6806 bdp8606 bep6506 ///
	bfp114h03m bgp99h03
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Bezug von ALG II y/n
***
global crrnt_varname ///
	alg2
global crrnt_var ///
	lp7713 mp5805 np5805 op4905 pp6605 qp6309 rp6609 sp6613 tp8413 up6807 ///
	vp8007 wp7107 xp8207 yp7707 zp7907 bap7007 bbp8007 bcp6807 bdp8607 bep6507 ///
	bfp114q01m bgp99q01
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Mutterschafts-, Erziehungsurlaub; seit 1999
***
global crrnt_varname ///
	elternzeit_mutterschutz
global crrnt_var ///
	pp06 qp03 rp08 sp09 tp12 up04 vp06 wp03 xp09 yp14 zp05 bap05 bbp0501 ///
	bcp06 bdp13 bep07 bfp13	bgp11
global crrnt_year /// 
	1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ///
	2013 2014 2015 2016
do  ${routine_p}

***
*** Letzes Wort finanzielle Entscheidungen; 
*** abgefragt in: 2005 2008 2010 2012 2015 (muss jedes Jahr geprüft werden)
global crrnt_varname ///
	LetztesWortFinanz
global crrnt_var ///
	vp151 yp152 bap154 bcp132 bfp152	
global crrnt_year /// 
	2005 2008 2010 2012 2015
do  ${routine_p}

***
*** Regelung mit Ehe-,Partner im Umgang mit Einkommen 
*** abgefragt in: 2004 2005 2008 2010 2012
global crrnt_varname ///
	finanz_regeln_partner
global crrnt_var ///
	up142 vp150 yp151 bap153 bcp131	
global crrnt_year /// 
	2004 2005 2008 2010 2012 
do  ${routine_p}

***
*** Partner im Haushalt; ab 1991
*** 
global crrnt_varname ///
	partner_hh
global crrnt_var ///
	hp10202 ip10202 jp10202 kp10202 lp10202 mp10702 np11402 ///
	op12002 pp13202 qp14102 rp13202 sp13202 tp13902 up14102 vp14902 wp12602 ///
	xp13302 yp15002 zp13102 bap15202 bbp13402 bcp13002 bdp13602 bep12802 ///
	bfp149 bgp155 	
global crrnt_year /// 
	1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 ///
	2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Zufriedenheit mit persönlichem Einkommen; ab 2004
***
global crrnt_varname ///
	sat_inc_p
global crrnt_var ///
	up0105 vp0105 wp0105 xp0105 yp0106 zp0106 bap0106 bbp0106 bcp0106 ///
	bdp0106 bep0106 bfp0106 bgp0106
global crrnt_year ///
	2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Gesundheitszustand Selbsteinschätzung; seit 1995 jährlich
***
global crrnt_varname ///
	gesundzustand
global crrnt_var ///
	lp89 mp75 np79 op66 pp95 qp95 rp95 sp86 tp98 up83 vp104 wp87 xp98 ///
	yp99 zp95 bap87 bbp97 bcp91 bdp110 bep89 bfp127 bgp105
global crrnt_year /// 
	1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 ///
	2008 2009 2010 2011 2012 2013 2014 2015 2016
do  ${routine_p}

***
*** Frist der derzeitigen Beschäftigung (ab 1985)
***
global crrnt_varname ///
	befrist
global crrnt_var ///
	bp45 cp36 dp34 ep34 fp27g gp30g hp32g ip32g jp32g kp44 lp42 mp40 np3401 ///
	op3401 pp3701 qp3501 rp3901 sp3901 tp6501 up3601 vp41 wp34 xp45 yp44 ///
	zp40 bap36 bbp40 bcp38 bdp49 bep38 bfp61 bgp57 
global crrnt_year /// 
	1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 ///
	1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ///
	2013 2014 2015 2016
do  ${routine_p}

***
*** Derzeit feste Partnerschaft
***
global crrnt_varname ///
	partnerschaft
global crrnt_var ///
	ap59 cp9001 dp9201 ep8301 fp10201 gp10201 hp10201 ip10201 jp10201 kp10201 ///
	lp10201 mp10701 np11401 op12001 pp13201 qp14101 rp13201 sp13201 tp13901 ///
	up14101 vp14901 wp12601 xp13301 yp15001 zp13101 bap15201 bbp13401 bcp13001 ///
	bdp13601 bep12801 bfp148 bgp15402
global crrnt_year /// 
	1984 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 ///
	1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ///
	2013 2014 2015 2016
do  ${routine_p}

***
*** Überstunden geleistet letzter Monat DUMMY
****
global crrnt_varname ///
	ueberstd_ja
global crrnt_var ///
	cp4902 ep4102 fp4302 gp4102 hp5202 ip5202 jp5202 kp6202 lp5102 mp4502 ///
	np5302 op4402 pp5902 qp5502 rp5603 sp5701 tp7501 up5801 vp7001 wp5801 ///
	xp7201 yp6701 zp7101 bap6001 bbp7201 bcp5801 bdp7601 bep5601 bfp9901 bgp7801
global crrnt_year /// 
	1986 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 ///
	1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ///
	2013 2014 2015 2016
do  ${routine_p}	

*** Überstunden geleistet letzter Monat ANZAHL
global crrnt_varname ///
	ueberstd_mon
global crrnt_var ///
	cp4901 ep4101 fp4301 gp4101 hp5201 ip5201 jp5201 kp6201 lp5101 mp4501 ///
	np5301 op4401 pp5901 qp5501 rp5601 sp5702 tp7502 up5802 vp7002 wp5802 ///
	xp7202 yp6702 zp7102 bap6002 bbp7202 bcp5802 bdp7602 bep5602 bfp9902 bgp7802
global crrnt_year /// 
	1986 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 ///
	1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 ///
	2013 2014 2015 2016
do  ${routine_p}


******************************************************************************** ▲ ▲ ▲



						*  --------------------  *
						* | DATENSATZ: P       | *
						* |	MERGE              | *
						*  --------------------  *

// Die Routine für den P-Datensatz legt alle verarbeiteten Variablen automatisch
// im global $vars_fetched_from_p ab. Diese werden nun in einen P-Datensatz 
// gemerged.

*** merge
tokenize ${vars_fetched_from_p}
use ${dir_data}source/temp/`1'.dta, clear
local n : word count ${vars_fetched_from_p}
forvalues i=2/`n' {
	local x : word `i' of ${vars_fetched_from_p}  
	merge 1:1 persnr using ${dir_data}source/temp/`x'.dta
	drop _merge 
}
*** save
save ${dir_data}source/temp/p.dta,replace
*** erase
forvalues i=1/`n'{
	local x : word `i' of ${vars_fetched_from_p}
	erase ${dir_data}source/temp/`x'.dta
}
*** anzeigen der verarbeiteten Variablen
dis "$vars_fetched_from_p"


						*  ---------------------  *
						* | DATENSATZ: BIOBIRTH | *
						*  ---------------------  *

// Für Alter bei Geburt des ersten Kindes

*** fetch ********************************************************************** ▼ ▼ ▼ add vars if new var
use persnr kidgeb01 ///
	using ${SOEP}biobirth.dta, clear
******************************************************************************** ▲ ▲ ▲
*** save
save ${dir_data}source/temp/biobirth.dta, replace 



						*  ---------------------  *
						* | MERGE PERSONENDATEN | *
						*  ---------------------  *

*** pmaster.dta
	use ${dir_data}source/temp/pmaster.dta, clear
*** pgen.dta
	merge 1:1 persnr using ${dir_data}source/temp/pgen.dta  
	drop _merge
*** p.dta
	merge 1:1 persnr using ${dir_data}source/temp/p.dta
	drop _merge
*** biobirth
	merge 1:1 persnr using ${dir_data}source/temp/biobirth.dta
	drop if _merge==2
	drop _merge

*** save all p data (file name: period of observation)
	tokenize ${year}
	local n : word count ${year}	
	save ${dir_data}source/Personendaten_`1'_``n''_WIDE.dta, replace

*** erase temp files
	erase ${dir_data}source/temp/pmaster.dta
	erase ${dir_data}source/temp/pgen.dta
	erase ${dir_data}source/temp/p.dta
	erase ${dir_data}source/temp/biobirth.dta


				//////////////////////////////////////////////
			//////////									//////////		
		//////////				 HAUSHALTSDATEN				//////////	
			//////////								  ///////////
			   /////////////////////////////////////////////

			   
// Vorgehen: Ich speichere für jedes Jahr einzeln die Haushaltsdatensätze und 
// eliminiere die Beobachtungen mit missing values auf der ID-Variable ($$hhnr). 
// Zum Schluss merge ich jeden Haushaltsdatensatz an die Personendaten.
				
				
						*  --------------------  *
						* | 	   HPFAD       | *
						*  --------------------  *

*** fetch 
local n : word count ${wave} // Daten für alle Wellen verfügbar
forvalues i=1/`n'{
	local x: word `i' of ${wave}
	local y: word `i' of ${year}
******************************************************************************** ▼ ▼ ▼ add vars if new var																	   				  
***																					   rename if necessary
	use hhnr `x'hhnr `x'hnetto `x'hpop ///
		using ${SOEP}hpfad.dta, clear
	rename `x'hhnr hhnr`y'
	rename `x'hnetto hnetto`y'
	rename `x'hpop hpop`y'
******************************************************************************** ▲ ▲ ▲
 
	drop if hhnr`y' < 0 // drop missing values
	save ${dir_data}source/temp/hpfad`y'.dta, replace
}


						*  --------------------  *
						* | 	  HBRUTTO      | *
						*  --------------------  *
						
*** fetch 
local n : word count ${wave} // Daten für alle Wellen verfügbar
forvalues i=1/`n'{
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
******************************************************************************** ▼ ▼ ▼ add vars if new var																	   				  
***																					   rename if necessary	
	use `x'hhnr `x'hhgr `x'bula ///
		using ${SOEP}`x'hbrutto.dta, clear
	rename `x'hhnr hhnr`y'
	rename `x'hhgr hhgr`y'
	rename `x'bula bula`y'
******************************************************************************** ▲ ▲ ▲
	
	drop if hhnr`y' < 0 // drop missing values
	save ${dir_data}source/temp/hbrutto`y'.dta, replace 
}


						*  --------------------  *
						* | 	   HGEN        | *
						*  --------------------  *

*** fetch 
local n : word count ${wave} // Daten für alle Wellen verfügbar
forvalues i=1/`n'{
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
	local z : word `i' of ${year2}
******************************************************************************** ▼ ▼ ▼ add vars if new var																	   				  
***																					   rename if necessary
	use `x'hhnr fhinc`z' i5hinc`z' ///
		using ${SOEP}`x'hgen.dta, clear
	rename `x'hhnr hhnr`y' 
	rename fhinc`z' iflag`y' 
	rename i5hinc`z' hinc_netto`y'   
******************************************************************************** ▲ ▲ ▲

	drop if hhnr`y' < 0 // drop missing values
	save ${dir_data}source/temp/hgen`y'.dta, replace
}


						*  --------------------  *
						* |    KINDERDATEN     | *
						*  --------------------  *

			   
// Anmerkung: Die persnr im kind.dta identifiziert die Kinder. Diese sind
// im SOEP Core nicht enhalten. Über die hhnr und die Zeiger-Variablen können 
// Informationen über die Kinder an die Haushalts- bzw. Personendaten gespielt 
// werden.
// Wir benötigen nur Infos über die Kinder auf Haushaltsebene. Ziehen 
// der Variablen auf Personenebene wird nur für Generierung benötigt.


// Folgende Var. sind in allen Wellen vorhanden
*** Zahl der Kinder unter 16 im Haushalt
* $$kzahl 
*** Geburtsjahr Kind --> für Generierung "Zahl der Kinder unter 3" 
* $$bfkgjahr 
*** Zeiger auf Mutter --> für Generierung der Var "Kind in Betreuung"
* $$bfkmutti
*** Kinderkrippe, Kindergarten, Kindertageseinrichtung, Hort



local n : word count $wave // kgjahr hieß bis 1986 kgeburt
forvalues i=1/3{
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
******************************************************************************** ▼ ▼ ▼ add var if new var
***																					   rename if necessary	
	use persnr `x'hhnr `x'kzahl `x'kgeburt `x'kmutti ///
	using ${SOEP}`x'kind.dta, clear
	
	rename `x'hhnr hhnr`y'
	rename `x'kzahl kzahl_16_`y' 
	rename `x'kgeburt kgjahr`y'
	rename `x'kmutti kmutti`y'
******************************************************************************** ▲ ▲ ▲
	
	mvdecode kgjahr`y', mv(-1 -2 -3) 
	save ${dir_data}source/temp/kind`y'.dta, replace
}
forvalues i=4/`n'{
	local x : word `i' of ${wave}
	local y : word `i' of ${year}
******************************************************************************** ▼ ▼ ▼ add var if new var
***																					   rename if necessary	
	use persnr `x'hhnr `x'kzahl `x'kgjahr `x'kmutti ///
	using ${SOEP}`x'kind.dta, clear
	
	rename `x'hhnr hhnr`y'
	rename `x'kzahl kzahl_16_`y' 
	rename `x'kgjahr kgjahr`y'
	rename `x'kmutti kmutti`y'
******************************************************************************** ▲ ▲ ▲
	
	mvdecode kgjahr`y', mv(-1 -2 -3) 
	save ${dir_data}source/temp/kind`y'.dta, replace
}

***
*** Vereinheitlichung der Codierung des Geburtsjahres (bis 1999)
***
forvalues i=1984/1999{
	use ${dir_data}source/temp/kind`i'.dta
	replace kgjahr`i' = 1900+kgjahr`i'
	save ${dir_data}source/temp/kind`i'.dta, replace 
}

// Anmerkung: An dieser Stelle generiere ich bereits die Kinder-Variablen auf
// Haushaltsebene, weil es im WIDE-Format am besten funktioniert

***
*** Zahl der Kinder unter 3 und unter 16 im Haushalt
***
// Vermerk: Diejenigen Haushalte, die keine Kinder leben, müssen später auf den
// Variablen zur Kinderzahl noch den Wert 0 zugewiesen bekommen. Das geht aber 
// erst nach dem mergen an die Haushaltsdaten --> wurde implementiert

*** unter 3
foreach year in $year {
	use ${dir_data}source/temp/kind`year'.dta, clear
	gen alter_kind`year'=`year' - kgjahr`year'
	collapse (count) persnr if alter_kind`year' < 4, by (hhnr`year')
	rename persnr kzahl_3_`year'
	save ${dir_data}source/temp/kzahl_3_`year'.dta, replace   
}
*** unter 16
foreach year in $year {
	use ${dir_data}source/temp/kind`year'.dta, clear
	gen alter_kind`year'=`year' - kgjahr`year'
	collapse (count) persnr if alter_kind`year' <= 16, by (hhnr`year')
	rename persnr kzahl_16_`year'
	save ${dir_data}source/temp/kzahl_16_`year'.dta, replace   
}

***
*** Alter des jüngsten Kindes im Haushalt
***
foreach year in $year {
	use ${dir_data}source/temp/kind`year'.dta, clear
	gen alter_kind`year'=`year' - kgjahr`year'
	collapse (min) alter_kind`year', by(hhnr`year')
	rename alter_kind`year' alter_kind_min`year'
	save ${dir_data}source/temp/alter_kind_min`year'.dta, replace 
}

***
*** Alter des ältesten Kindes im Haushalt
***
foreach year in $year {
	use ${dir_data}source/temp/kind`year'.dta, clear
	gen alter_kind`year'=`year' - kgjahr`year'
	collapse (max) alter_kind`year', by(hhnr`year')
	rename alter_kind`year' alter_kind_max`year'
	save ${dir_data}source/temp/alter_kind_max`year'.dta, replace 
}


				//////////////////////////////////////////////
			//////////									//////////		
		//////////				MERGE ALL DATA				//////////	
			//////////								  ///////////
			   /////////////////////////////////////////////

*** use p data
tokenize ${year}
local n : word count ${year}	
use ${dir_data}source/Personendaten_`1'_``n''_WIDE.dta, clear

*** merge hh data available for every year
forvalues i=1/`n' {
	local y : word `i' of ${year}

	display "hpfad"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/hpfad`y'.dta
	drop if _merge == 2
	drop _merge
	
	display "hbrutto"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/hbrutto`y'.dta
	drop if _merge == 2
	drop _merge
	
	display "hgen"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/hgen`y'.dta
	drop if _merge == 2
	drop _merge

*	Anmerkung: Wenn Haushalte nicht in dem Kinder-Datensatz vorkommen, gehe ich
*	davon aus, dass keine Kinder dort leben und der Wert 0 auf der Variable 
*	Kinderzahl zugewiesen werden kann. Genauso bei Zahl der Kinder in Betreuung
	 
	display "kzahl_3_"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/kzahl_3_`y'.dta
	replace kzahl_3_`y'=0 if _merge==1
	drop _merge

	display "kzahl_16_"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/kzahl_16_`y'.dta
	replace kzahl_16_`y'=0 if _merge==1
	drop _merge

	display "alter_kind_min"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/alter_kind_min`y'.dta, nogen

	display "alter_kind_max"`y' as text
	merge m:1 hhnr`y' using ${dir_data}source/temp/alter_kind_max`y'.dta, nogen
}
																			   
*** erase ********************************************************************** ▼ ▼ ▼ add if new hh var/dataset
forvalues i=1/`n'{
	local y : word `i' of ${year}
	erase ${dir_data}source/temp/hgen`y'.dta
	erase ${dir_data}source/temp/hpfad`y'.dta 
	erase ${dir_data}source/temp/hbrutto`y'.dta 
	erase ${dir_data}source/temp/kind`y'.dta
	erase ${dir_data}source/temp/kzahl_3_`y'.dta 
	erase ${dir_data}source/temp/kzahl_16_`y'.dta 
	erase ${dir_data}source/temp/alter_kind_min`y'.dta 
	erase ${dir_data}source/temp/alter_kind_max`y'.dta
	erase ${dir_data}source/Personendaten_`1'_``n''_WIDE.dta, clear
}
******************************************************************************** ▲ ▲ ▲

/*** save all WIDE data
tokenize ${year}
local n : word count ${year}	
save ${dir_data}source/FiF_WIDE_`1'-``n''.dta, replace */



				//////////////////////////////////////////////
			//////////									//////////		
		//////////				RESHAPE DATASET				//////////	
			//////////								  ///////////
			   /////////////////////////////////////////////

* use ${dir_data}source/FiF_WIDE_`1'-``n''.dta, clear
mvdecode _all, mv(-1 -2 -3 -4 -5 -6 -7 -8 -9) 
rename hhnr hhnr_org

// Anmerkung: Es gibt in WIDE Haushalte ohne (hhnr_org) ohne zugeordnete Personen.
// Noch rausfinden warum! (Anm. Max: ?)

drop if persnr ==.

*** Festlegen aller Variablen, die reshaped werden müssen
// Anmerkung: Die gezogenen Variablen der Personendaten werden immer 
// gleich in den jeweiligen Code-Abschnitten gespeichert und können hier per 
// macro abgerufen werden. Wichtig: Alle Haushaltsvariablen werden hier direkt 
// eingetragen! Das local wird doppelt definiert, weil Stata aus unbekannten
// Gründen nicht nacheinander varlists und vars akzeptiert ohne Deklaration
// als String.

local stubs ///
	$vars_fetched_from_ppfad $vars_fetched_from_phrf ///
	$vars_fetched_from_pgen $vars_fetched_from_p ///
	$vars_fetched_from_pequiv

*** erase ********************************************************************** ▼ ▼ ▼ add if new hh var
local stubs ///
	`stubs' hnetto hpop hhgr hinc_netto iflag bula kzahl_3_ kzahl_16_ alter_kind_min ///
	alter_kind_max 
******************************************************************************** ▲ ▲ ▲

*** Speichern der Variablenlabels vor Reshape (gehen sonst verloren)
// Labels werden in einem Macro gespeichert und dem Variablennamen nach dem
// reshape zugeordnet. Dazu werden die vier Jahresziffern am Ende des Namens
// subtrahiert. Bei Wiedervergabe werden die ignoriert, die nicht der Struktur 
// entsprechen (zeit-invariant, wie z.b. ost).
foreach v of var * {
	local s`v' = ustrlen("`v'")-4
	local long = usubstr("`v'",1,`s`v'')
	local l`long' : variable label `v'
}

*** reshape
reshape long `stubs' , i(persnr) j(year)

*** Labels werden wieder vergeben
ds year, not // benutze alles bis auf year (durch reshape immer ohne label!)
foreach v of var `r(varlist)' {
	local L`v' : variable label `v'
	if `"`L`v''"' == "" & `"`l`v''"' != ""{
	label var `v' "`l`v''"
	}
}

*** rename (& omit underscores) ************************************************ ▼ ▼ ▼ add if new var and 
***																					   rename necessary after reshape
rename sampreg					ost
rename isced97_ 				isced97
******************************************************************************** ▲ ▲ ▲


// Als nächstes werden nur diejenigen Beobachtungen beibehalten, die im
// entsprechenden Jahr tatsächlich ein Interview erfolgreich absolviert haben
// und 18 Jahre oder älter sind.

keep if (netto==10 | netto==12 | netto==13 | netto==14 | netto==15 | netto==19) /// 
	& age >=18
	
*** label and save final dataset
save ${dir_data}source/gi_SOEP_`1'-``n''.dta, replace


