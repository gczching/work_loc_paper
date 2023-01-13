************
* SCRIPT: 5_regressions.do
* PURPOSE: estimates regression models and saves the resulting output
************

* Preamble (unnecessary when executing run.do)
global MyProject "C:\Users\User\Dropbox\PhD Research\Paper_2\stata_folder\"
do "$MyProject/scripts/programs/_config.do"

************
* Code begins
************

tempfile results

use "$MyProject/processed/clean_processed.dta", replace

svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
svydescribe

	* Relabel some variables
	label var stdfa_locw2 "Locus of control, wave 2"
	label var uniwave "Enrolled in wave 6"
	
	tempfile data
	save `data'
	
*------------------------------------------------------------------------------------
* RUNNING TESTS FOR COVARIATES
*------------------------------------------------------------------------------------
	est clear 
	
	* USING STANDARDISED SCORES, FACTOR ANALYSIS  
	* EVER WORKED 
	
	keep if sampleterm==1
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)

	* Ever worked 
	
		global bgcontrols_cnt	sex ethnic W7Disabv1 unigrant uniwave   
		global bgcontrols_bin	W7Russell mparent_educ fam_cmp numsib 
		global controls_sub		w7science
		global priorcontrols	w1_hhmanage received_ema schoolatt2 ownhouse
		
	use `data', clear
	keep if sampleterm==1
	
	* 1. Coefficient comparison tests
	svy: reg stdfa_locw7 wrk_uni $bgcontrols_cnt $bgcontrols_bin   
	eststo uni_est0
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin   
	eststo uni_est1
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $controls_sub
	eststo uni_est2
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols
	eststo uni_est3
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols $controls_sub
	eststo uni_est4	
	
	esttab uni_est0 uni_est1 uni_est2 uni_est3 uni_est4 using "$MyProject/results/tables/uni_reg.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.1 ** 0.05 *** 0.01)	

	* 2. Checking balancing tests
	* 2.1. LHS balancing test
	
	global bgcontrols  sex ethnic W7Disabv1 unigrant uniwave W7Russell mparent_educ fam_cmp numsib   
	
	svy: reg stdfa_locw2 	wrk_uni  $bgcontrols
	eststo stdfa_locw2est
	svy: reg w7science		wrk_uni  $bgcontrols
	eststo w7scienceest
	svy: reg w1_hhmanage 	wrk_uni  $bgcontrols
	eststo w1_hhmanageest
	svy: reg received_ema 	wrk_uni  $bgcontrols
	eststo received_emaest
	svy: reg schoolatt2 	wrk_uni  $bgcontrols
	eststo schoolatt2est	
	svy: reg ownhouse		wrk_uni  $bgcontrols
	eststo ownhouseest

	suest stdfa_locw2est w7scienceest w1_hhmanageest received_emaest schoolatt2est ownhouseest
	
	esttab stdfa_locw2est w7scienceest w1_hhmanageest received_emaest schoolatt2est ownhouseest using "$MyProject/results/tables/unibalance.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.1 ** 0.05 *** 0.01)	
	
	test [stdfa_locw2est]wrk_uni=[w7scienceest]wrk_uni=[w1_hhmanageest]wrk_uni=[received_emaest]wrk_uni=[schoolatt2est]wrk_uni=[ownhouseest]wrk_uni

	* 2.2. RHS balancing test
	svy: reg wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols $controls_sub
	test stdfa_locw2=w7science=w1_hhmanage=received_ema=schoolatt2=ownhouse

*------------------------------------------------------------------------------------
	
	* Final covariates: remove science subject
	
	svy: reg wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	test stdfa_locw2=w1_hhmanage=received_ema=schoolatt2=ownhouse

	use `data', clear
	keep if sampleterm==1
	
	svy: reg stdfa_locw7 wrk_uni $bgcontrols_cnt $bgcontrols_bin   
	eststo uni_est0
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin   
	eststo uni_est1
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols
	eststo uni_est2
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols w7science
	eststo uni_est3
	
	* Term-time estimates 
	
	svy: reg stdfa_locw7 wrk_term $bgcontrols_cnt $bgcontrols_bin
	eststo term_est0
	svy: reg stdfa_locw7 wrk_term stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin   
	eststo term_est1
	svy: reg stdfa_locw7 wrk_term stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols
	eststo term_est2
	svy: reg stdfa_locw7 wrk_term stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols w7science
	eststo term_est3
	
	* Summer estimates
	svy: reg stdfa_locw7 wrk_vac $bgcontrols_cnt $bgcontrols_bin 
	eststo vac_est0
	svy: reg stdfa_locw7 wrk_vac stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin 
	eststo vac_est1
	svy: reg stdfa_locw7 wrk_vac stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols
	eststo vac_est2
	svy: reg stdfa_locw7 wrk_vac stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols w7science
	eststo vac_est3
	
	* Christmas
	use `data', clear
	keep if samplerethol==1
	
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 wrk_chris $bgcontrols_cnt $bgcontrols_bin
	eststo chris_est0
	svy: reg stdfa_locw7 wrk_chris stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin
	eststo chris_est1
	svy: reg stdfa_locw7 wrk_chris stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo chris_est2
	svy: reg stdfa_locw7 wrk_chris stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols w7science
	eststo chris_est3
	
	* Easter
	svy: reg stdfa_locw7 wrk_easter $bgcontrols_cnt $bgcontrols_bin
	eststo easter_est0
	svy: reg stdfa_locw7 wrk_easter stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin 
	eststo easter_est1
	svy: reg stdfa_locw7 wrk_easter stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo easter_est2
	svy: reg stdfa_locw7 wrk_easter stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols w7science
	eststo easter_est3

	foreach n in uni term vac chris easter	{
	esttab `n'_est0 `n'_est1 `n'_est2 `n'_est3 using "$MyProject/results/tables/`n'_reg.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.1 ** 0.05 *** 0.01) ///
	refcat(unisub1 "University subject: ref Business and Admin studies", nolabel)
	}
	
*-----------------------------------------------------------------------------------
	* ONLY KEEP SAMPLE FOR THOSE WHO WORKED 
	* AVERAGE HOURS OF WORK 
	
	preserve
		est clear
		keep if sampleterm==1 & hr_term>0
		g hr_termsq=hr_term*hr_term
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		svy: reg stdfa_locw7 hr_term stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo termhrs	
		margins, at(hr_term=(5 10 15 20 25 30)) atmeans
		marginsplot

		svy: reg stdfa_locw7 hr_term hr_termsq stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols
		eststo termhrs2

		* SUMMER
		use `data', clear
		keep if sampleterm==1 & hr_vac>0
		g hr_vacsq=hr_vac*hr_vac
				
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		svy: reg stdfa_locw7 hr_vac stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo vachrs
		
		svy: reg stdfa_locw7 hr_vac hr_vacsq stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo vachrs2
		
		* CHRISTMAS
		use `data', clear
		keep if samplerethol==1 & hr_chris>0
		g hr_chrissq=hr_chris*hr_chris
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		svy: reg stdfa_locw7 hr_chris stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo chrishrs	
	
		svy: reg stdfa_locw7 hr_chris hr_chrissq stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo chrishrs2
		
		* EASTER
		use `data', clear
		keep if samplerethol==1 & hr_easter>0
		g hr_eastersq=hr_easter*hr_easter 
		svy: reg stdfa_locw7 hr_easter stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo easterhrs	
		
		svy: reg stdfa_locw7 hr_easter hr_eastersq stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo easterhrs2	
		
	esttab termhrs termhrs2 vachrs vachrs2 chrishrs chrishrs2 easterhrs easterhrs2 using "$MyProject/results/tables/avhoursnozero_reg.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.10 ** 0.05 *** 0.01) ///
	mtitles("Term-time" "Term-time sq" "Summer" "Summer sq" "Christmas" "Christmas sq" "Easter" "Easter sq")
		
		restore	

*-----------------------------------------------------------------------------------
* REGRESSION BY CATEGORICAL HOURS
*---------------------------------

	est clear 
	preserve
	use `data', clear
	keep if sampleterm==1 & hr_term>0
	
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 i.cathr_term stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo cathrterm
		test 1.cathr_term=2.cathr_term=3.cathr_term=4.cathr_term
		estadd scalar pval_allterm = r(p)
		test 1.cathr_term=2.cathr_term
		estadd scalar pval12_term = r(p)
		test 2.cathr_term=3.cathr_term
		estadd scalar pval23_term = r(p)
		test 3.cathr_term=4.cathr_term
		estadd scalar pval34_term = r(p)
		test 1.cathr_term=3.cathr_term
		estadd scalar pval14_term = r(p)
		eststo cathrterm
	
	use `data', clear
	keep if sampleterm==1 & hr_vac>0
	svy: reg stdfa_locw7 i.cathr_vac stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo cathrvac	
		test 1.cathr_vac=2.cathr_vac=3.cathr_vac=4.cathr_vac
		estadd scalar pval_allvac = r(p)
		test 1.cathr_vac=2.cathr_vac
		estadd scalar pval12_vac = r(p)
		test 2.cathr_vac=3.cathr_vac
		estadd scalar pval23_vac = r(p)
		test 3.cathr_vac=4.cathr_vac
		estadd scalar pval34_vac = r(p)
		test 1.cathr_vac=3.cathr_vac
		estadd scalar pval14_vac = r(p)
		eststo cathrvac	
		
	use `data', clear
	keep if samplerethol==1	& hr_chris>0
	
	svy: reg stdfa_locw7 i.cathr_chris stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo cathrchris
		test 1.cathr_chris=2.cathr_chris=3.cathr_chris=4.cathr_chris
		estadd scalar pval_allchris = r(p)
		test 1.cathr_chris=2.cathr_chris
		estadd scalar pval12_chris = r(p)
		test 2.cathr_chris=3.cathr_chris
		estadd scalar pval23_chris = r(p)
		test 3.cathr_chris=4.cathr_chris
		estadd scalar pval34_chris = r(p)
		test 1.cathr_chris=3.cathr_chris
		estadd scalar pval14_chris = r(p)
		eststo cathrchris
		
	use `data', clear
	keep if samplerethol==1	& hr_easter>0
	
	svy: reg stdfa_locw7 i.cathr_easter stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo cathreaster	
		test 1.cathr_easter=2.cathr_easter=3.cathr_easter=4.cathr_easter
		estadd scalar pval_alleaster = r(p)
		test 1.cathr_easter=2.cathr_easter
		estadd scalar pval12_easter = r(p)
		test 2.cathr_easter=3.cathr_easter
		estadd scalar pval23_easter = r(p)
		test 3.cathr_easter=4.cathr_easter
		estadd scalar pval34_easter = r(p)
		test 1.cathr_easter=3.cathr_easter
		estadd scalar pval14_easter = r(p)
		eststo cathreaster
	esttab  cathrterm cathrvac cathrchris cathreaster using "$MyProject/results/tables/hourcategorynozero_reg.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.10 ** 0.05 *** 0.01) ///
	mtitles("Term-time" "Summer" "Christmas" "Easter") ///
	scalar(pval_allterm pval12_term pval23_term pval34_term pval14_term ///
	pval_allvac pval12_vac pval23_vac pval34_vac pval14_vac ///
	pval_allchris pval12_chris pval23_chris pval34_chris pval14_chris ///
	pval_alleaster pval12_easter pval23_easter pval34_easter pval14_easter) 
	
	restore


*-------------------------------------------------------------------------------------
	* INTERACTION TERMS
	*==================
	** HETEROGENEITY BY GENDER
		global bgcontrols_cnt	ethnic W7Disabv1 unigrant uniwave    
		
		est clear
		use `data', clear
		keep if sampleterm==1
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		
		foreach var of varlist wrk_uni wrk_term wrk_vac	{
		svy: qui reg stdfa_locw7 i.`var'##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo `var'sex
		}
		
		svy: reg stdfa_locw7 i.wrk_uni##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols
		margins i.wrk_uni#i.sex
		margins sex, dydx(wrk_uni)
		
		use `data', clear
		keep if samplerethol==1
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
				
		foreach var of varlist wrk_chris wrk_easter	{
		svy: reg stdfa_locw7 i.`var'##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
		eststo `var'sex		
		}
		
		esttab wrk_unisex wrk_termsex wrk_vacsex using "$MyProject/results/tables/std_reg_sex.rtf", replace ///
		se ar2 label nogap onecell b(%9.3f) star(* 0.10 ** 0.05 *** 0.01) 

		esttab wrk_chrissex wrk_eastersex using "$MyProject/results/tables/std_reg_sex2.rtf", replace ///
		se ar2 label nogap onecell b(%9.3f) star(* 0.10 ** 0.05 *** 0.01) 

	** MARGINSPLOTS by HOURS OF WORK
			
		global bgcontrols_cnt	ethnic W7Disabv1 unigrant uniwave    
	
		est clear
		use `data', clear
		keep if sampleterm==1 & hr_term>0
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		
		svy: reg stdfa_locw7 c.hr_term##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols  
		margins sex, at (hr_term = (5(5)30)) atmeans
		marginsplot, scheme(s1mono) xlabel(5(5)30) title("Term-time") xtitle("") ytitle(,size(medlarge)) name(hr_termsex, replace)
		
		use `data', clear
		keep if sampleterm==1 & hr_vac>0
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		
		svy: reg stdfa_locw7 c.hr_vac##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols    
		quietly margins sex, at (hr_vac = (5(5)30)) atmeans
		marginsplot, scheme(s1mono) xlabel(5(5)30) title("Summer") xtitle("") ytitle(,size(medlarge)) name(hr_vacsex, replace)	 

		use `data', clear
		keep if samplerethol==1 & hr_chris>0
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		
		svy: reg stdfa_locw7 c.hr_chris##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols   
		quietly margins sex, at (hr_chris = (5(5)30)) atmeans
		marginsplot, scheme(s1mono) xlabel(5(5)30) title("Christmas") ytitle(,size(medlarge)) xtitle("Average weekly hours worked", size(medlarge)) name(hr_chrissex, replace)
		
		use `data', clear
		keep if samplerethol==1 & hr_easter>0
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
		
		svy: reg stdfa_locw7 c.hr_easter##i.sex stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols   
		quietly margins sex, at (hr_easter = (5(5)30)) atmeans
		marginsplot, scheme(s1mono) xlabel(5(5)30) title("Easter") ytitle(,size(medlarge)) xtitle("Average weekly hours worked", size(medlarge)) ytitle("") name(hr_eastersex, replace) 
				

	set graphics on
	grc1leg hr_termsex hr_vacsex hr_chrissex hr_eastersex, scheme(s1mono) ycommon
	graph export "$MyProject/results/figures/int_sex.tif", as(tif) replace	

	
** EOF
