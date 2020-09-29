////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		-- De-rounding of heaped income values based on FAST 'true' shares --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

*	drop couples that earn more than 3 consecutive years the same income (if changing and no common values)
	drop if inlist(cid, 3456, 3571, 31551, 10732) // 4, 8, 6, 5 in a row
*	equal earners before
	noisily table decade sampreg, c(m eqearn2)

* 	check if integer multiple for husband/wife and sampreg
*	--> beginning with smallest to account for income values being multiples
*	of several integers
	cap drop rounded
	gen rounded = .
	cap drop rounded_m
	gen rounded_m = .

	forvalues s=1/2 {
		replace rounded = 50 if !mod(yinc,50)==1 & yinc>0 & sampreg==`s' // 50
		replace rounded = 100 if !mod(yinc,100)==1 & yinc>0 & sampreg==`s' // 100
		replace rounded = 500 if !mod(yinc,500)==1 & yinc>0 & sampreg==`s' // 500
		replace rounded = 1000 if !mod(yinc,1000)==1 & yinc>0 & sampreg==`s' // 1000
		replace rounded = 5000 if !mod(yinc,5000)==1 & yinc>0 & sampreg==`s' // 5000
		replace rounded = 10000 if !mod(yinc,10000)==1 & yinc>0 & sampreg==`s' // 10000

		replace rounded_m = 50 if !mod(yinc_m,50)==1 & yinc_m>0 & sampreg==`s' // 50
		replace rounded_m = 100 if !mod(yinc_m,100)==1 & yinc_m>0 & sampreg==`s' // 100
		replace rounded_m = 500 if !mod(yinc_m,500)==1 & yinc_m>0 & sampreg==`s' // 500
		replace rounded_m = 1000 if !mod(yinc_m,1000)==1 & yinc_m>0 & sampreg==`s' // 1000
		replace rounded_m = 5000 if !mod(yinc_m,5000)==1 & yinc_m>0 & sampreg==`s' // 5000
		replace rounded_m = 10000 if !mod(yinc_m,10000)==1 & yinc_m>0 & sampreg==`s' // 10000
	}

	bys decade: tab rounded sampreg, missing col
	bys decade: tab rounded_m sampreg, missing col

* 	income brackets (5)
	cap drop incbr
	gen incbr = .
	cap drop incbr_m
	gen incbr_m = .

	forvalues s=1/2 {
		replace incbr = 1 if yinc>0 & yinc_m<=10000 & sampreg==`s'
		replace incbr = 2 if yinc>10000 & yinc<=20000 & sampreg==`s'
		replace incbr = 3 if yinc>20000 & yinc<=35000 & sampreg==`s'
		replace incbr = 4 if yinc>35000 & yinc<=60000 & sampreg==`s'
		replace incbr = 5 if yinc>60000 & !missing(yinc) & sampreg==`s'

		replace incbr_m = 1 if yinc>0 & yinc_m<=10000 & sampreg==`s'
		replace incbr_m = 2 if yinc_m>10000 & yinc_m<=20000 & sampreg==`s'
		replace incbr_m = 3 if yinc_m>20000 & yinc_m<=35000 & sampreg==`s'
		replace incbr_m = 4 if yinc_m>35000 & yinc_m<=60000 & sampreg==`s'
		replace incbr_m = 5 if yinc_m>60000 & !missing(yinc_m) & sampreg==`s'

		tab incbr rounded if sampreg==`s', missing row
		tab incbr_m rounded_m if sampreg==`s', missing row
	}

***	merge income bracket share of rounded values based on FAST income tax data
	merge m:1 sampreg incbr using "${dir_data}output/est/shares_rounding_incbr.dta", keepusing(rnd*)
	drop if _merge==2
	drop _merge
	merge m:1 sampreg incbr_m using "${dir_data}output/est/shares_rounding_incbr_m.dta", keepusing(rnd*)
	drop if _merge==2
	drop _merge

***	De-round-loop
	local multiples ///
	50 100 500 1000 5000 10000
*	(2.1) sample region
	forvalues s=1/2 {
		if `s'==1 {
			local r West
		}
		else if `s'==2 {
			local r East
		}
	  * (2.2)	wife and husband
		forvalues i=1/2 {
			local m ""
			local d "wife"
			if `i'==2 {
				local m "_m"
				local d "husband"
			}
			cap drop deroundval`m'
			gen deroundval`m' = .
			cap drop ts`m'
			gen ts`m' = .
			levelsof incbr`m', local(inc`m')
			sort incbr`m'
		*	randomly select heaped values to de-round (save for true share)
			cap drop random
			generate random=runiform()
			sort sampreg incbr`m' rounded`m' random
			by sampreg incbr`m' rounded`m': 	gen n`m'=_n if !missing(rounded`m') // amount of rounded values
			by sampreg incbr`m': 				gen max`m'=_N // observations in income bracket
			dis as result "" _newline "{hline 90}" ///
			_newline as result "Obs. per group vs. n of equal earners)" ///
			_newline "{hline 90}"
			table incbr`m' if sampreg==`s', c(m max`m' n n`m' )
		*	(2.3) income bracket
			foreach l of local inc`m' {
		*	(2.4) rounding-intervals
				forvalues j=1/6 {
					local multi : word `j' of `multiples'
					sum rnd`multi'`m' if sampreg==`s' & incbr==`j', meanonly
					local k = r(mean) // get threshold value from variable
					dis as result "" _newline "{hline 90}" ///
					_newline as text "Income `d' in `r': true share of values rounded to " as result "`multi':" ///
					_newline as result "`k'" ///
					_newline "{hline 90}"
				*	derive threshold (ceil rounds up --> account for sample size)
					replace ts`m' = round(max`m'*`k') ///
						if incbr`m'==`l' & rounded`m'==`multi' & sampreg==`s' // save for "true share" rounded to nearest integer
				*	control tables
					capture table incbr`m' /// opt: noisily
						if incbr`m'==`l' & rounded`m'==`multi' & sampreg==`s', ///
						c(m max`m' m ts`m' n n`m' ) missing
				*	derive deround value based on normal distribution and heaping probabilities
					replace deroundval`m' =  rnormal(0,`multi'/6) ///
						if incbr`m'==`l' & rounded`m'==`multi' & sampreg==`s'
					// Standard normal with 99% coverage of +/- multi/2: N(0,sd), where 3sd = 99%
				*	de-round
					replace yinc`m' = yinc`m' + deroundval`m' ///
						 if n`m'>ts`m' & incbr`m'==`l' ///
						 & rounded`m'==`multi' & sampreg==`s' & yinc`m'>0
				}
			}
			drop deroundval`m'
			drop ts`m'
			drop n`m'
			drop max`m'
		}
	local m
	local d
	local j
	local k
	local multi
	local inc
	local inc`m'
	}
*	Re-assign Euro values
*	replace yinc = round(yinc/1.95583) if syear<=2001
*	replace yinc_m = round(yinc_m/1.95583) if syear<=2001
*	Re-estimate share of household income
	xtset cid syear
	replace wis = yinc/(yinc_m + yinc) if yinc!=. & yinc_m!=. & yinc>0 & yinc_m>0
	replace eqearn2 = 0 if wis!=.
	replace eqearn2 = 1 if wis==0.5
*	Option/robustness: delete excess spike of equal earners
	if $delspike == 1 {
		gen sorter=runiform()
		sort sampreg eqearn2 sorter
		by sampreg eqearn2: gen eq_cnt=_n if eqearn2==1
		by sampreg: gen eq_ts=floor(0.0012*_N)
		tab eqearn2
		table sampreg, c(m eqearn2)
		replace wis=. if eq_cnt>=eq_ts & !missing(eq_cnt)
		replace eqearn2 = .
		replace eqearn2 = 0 if !missing(wis)
		replace eqearn2 = 1 if wis==0.5
		tab eqearn2
		table sampreg, c(m eqearn2)
	}
