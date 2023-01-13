global MyProject "C:\Users\User\Dropbox\PhD Research\Paper_2\stata_folder\"
use "$MyProject/processed/clean_processed.dta", replace

* GLOBAL CONTROLS
		global bgcontrols_cnt	sex ethnic W7Disabv1 unigrant uniwave   
		global bgcontrols_bin	W7Russell mparent_educ fam_cmp numsib 
		global controls_sub		w7science
		global priorcontrols	w1_hhmanage received_ema schoolatt2 ownhouse
		
		global workpredictors   sex w1_hhmanage received_ema schoolatt2 ownhouse ///
								mparent_educ fam_cmp numsib ///
								uniwave unigrant
	
	* Relabel some variables
	label var stdfa_locw2 "Locus of control, wave 2"
	label var uniwave "Enrolled in wave 6"
	
	keep 	W7finwt samppsu_w1 sampstratum_w1 NSID ///
			stdfa_locw7 stdfa_locw2 ///
			sex $priorcontrols $bgcontrols_cnt $bgcontrols_bin $controls_sub $workpredictors ///
			sample* ///
			wrk_*
			
	tempfile data
	save `data'
	
/* Start with the pooled "ever worked"
	* The IPW still works as a selection on observables
	* Probably does not account for the unobserved selection (which is the main problem)
	* Diff between my propensity to work var and this var? Contemporaneous vs historical?
	keep if sampleterm==1
	teffects ipw (stdfa_locw7) (wrk_uni sex $priorcontrols stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin) [pweight=W7finwt]
	tebalance overid, nolog
	// Cannot reject H0 that covariates are balanced
	
	teffects ipw (stdfa_locw7) (wrk_term sex $priorcontrols stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin) [pweight=W7finwt]
	tebalance overid, nolog
	
	teffects ipw (stdfa_locw7) (wrk_vac sex $priorcontrols stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin) [pweight=W7finwt]
	tebalance overid, nolog
	
	keep if samplerethol==1
	teffects ipw (stdfa_locw7) (wrk_chris sex $priorcontrols stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin) [pweight=W7finwt]	
	tebalance overid, nolog

	teffects ipw (stdfa_locw7) (wrk_easter sex $priorcontrols stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin) [pweight=W7finwt]	
	tebalance overid, nolog
*/
		
	*** Compare estimates when use the predicted weights and multiply with survey weights, and running estimates 
	use `data', clear
	keep if sampleterm==1
	foreach var of varlist wrk_uni wrk_term wrk_vac	{
	probit `var' stdfa_locw2 $workpredictors
		predict pwork_`var', pr 
		gen ipw_`var'=1.`var'/pwork_`var' + 0.`var'/(1-pwork_`var')
		gen double w_`var'=ipw_`var'*W7finwt
	}
	
	svyset [pweight=w_wrk_uni], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 wrk_uni  stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin  
	eststo ever_ipw
	
	svyset [pweight=w_wrk_term], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 wrk_term  stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin 
	eststo term_ipw
	
	svyset [pweight=w_wrk_vac], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 wrk_vac  stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin 
	eststo vac_ipw
	
	use `data', clear
	keep if samplerethol==1
	foreach var of varlist wrk_chris wrk_easter	{
	probit `var' stdfa_locw2 $workpredictors
		predict pwork_`var', pr 
		gen ipw_`var'=1.`var'/pwork_`var' + 0.`var'/(1-pwork_`var')
		gen double w_`var'=ipw_`var'*W7finwt
	}
		
	svyset [pweight=w_wrk_chris], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 wrk_chris stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin 
	eststo chris_ipw
	
	svyset [pweight=w_wrk_easter], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7 wrk_easter stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin 
	eststo easter_ipw
	
	esttab ever_ipw term_ipw vac_ipw chris_ipw easter_ipw using "$MyProject/results/tables/ipwreg.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.10 ** 0.05 *** 0.01) ///
	mtitles("Ever" "Term" "Summer" "Christmas" "Easter")
	
	** EOF