* ROBUSTNESS CHECKS
*--------------------

global MyProject "C:\Users\User\Dropbox\PhD Research\Paper_2\stata_folder\"
do "$MyProject/scripts/programs/_config.do"
use "$MyProject/processed/clean_processed.dta", replace

svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
svydescribe

* GLOBAL CONTROLS
	
		global bgcontrols_cnt	sex ethnic W7Disabv1 unigrant uniwave   
		global bgcontrols_bin	W7Russell mparent_educ fam_cmp numsib 
		global priorcontrols	w1_hhmanage received_ema schoolatt2 ownhouse
		
	* Using sum scores (without missing/DK)
	tempfile data
	save `data'

* ROBUSTNESS OF INITIAL ESTIMATES WITH SMALLER SAMPLE
*-----------------------------------------------------
	use `data', clear
	keep if samplerethol==1 & sampleterm==1
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)	
	svy: reg stdfa_locw7 wrk_uni stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols  
	eststo stdfa_est0
	
	svy: reg stdfa_locw7 wrk_term stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols  
	eststo stdfa_est1
	
	svy: reg stdfa_locw7 wrk_vac stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols  
	eststo stdfa_est2

	svy: reg stdfa_locw7 wrk_chris stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols  
	eststo stdfa_est3

	svy: reg stdfa_locw7 wrk_easter stdfa_locw2 sex $bgcontrols_cnt $bgcontrols_bin $priorcontrols  
	eststo stdfa_est4
	
	esttab stdfa_est0 stdfa_est1 stdfa_est2 stdfa_est3 stdfa_est4 using "$MyProject/results/tables/robustness_sample.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.10 ** 0.05 *** 0.01) ///
	mtitles("Term-time" "Summer" "Christmas" "Easter") 

	
* CHECK whether LOC in wave 2 determines students' participation in paid work in term-time in wave 7.
*-------------------------------------------------------------------------------------------------------
	est clear
	use `data', clear
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)	
	keep if  sampleterm==1
	
	svy: probit wrk_uni stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin  $priorcontrols 
		eststo predict_work
		
	svy: probit wrk_term stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin  $priorcontrols 
		eststo predict_term
	
	svy: probit wrk_vac stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin   $priorcontrols 
		eststo predict_vac
	
	use `data', clear
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)	
		
	keep if samplerethol==1
	svy: probit wrk_chris stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin   $priorcontrols 
		eststo predict_chris
	svy: probit wrk_easter stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin   $priorcontrols 
		eststo predict_easter
		
	esttab predict_work predict_term predict_vac predict_chris predict_easter using "$MyProject/results/tables/predictwork.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) star(* 0.10 ** 0.05 *** 0.01)

	
* SUM SCORES
*-------------------------------------------------------------------------------------------------------
	est clear
	use `data', clear 
	keep if sampleterm==1
	
	* Ever worked
	svy: reg LOCUSW7 wrk_uni LOCUSW2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo ever_est
	
	* Term-time estimates 
	svy: reg LOCUSW7 wrk_term LOCUSW2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo term_est
	
	* Summer estimates
	svy: reg LOCUSW7 wrk_vac LOCUSW2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo summer_est
	
	* Christmas/Easter estimates 
	use `data', clear
	keep if samplerethol==1
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	
	svy: reg LOCUSW7 wrk_chris LOCUSW2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo chris_est
	
	svy: reg LOCUSW7 wrk_easter LOCUSW2 $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo easter_est
	
	esttab ever_est term_est summer_est chris_est easter_est using "$MyProject/results/tables/sumscore_reg.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.10 ** 0.05 *** 0.01) ///
	mtitles("Ever" "Term-time" "Summer" "Christmas" "Easter") 
	

* COMPARE ESTIMATES WITH AND WITHOUT DK 
*-----------------------------------------------------------------------*
	est clear 
	
	* USING STANDARDISED SCORES, FACTOR ANALYSIS  
	* FA -> standardised
	* Any work?
	
	use `data', clear
	keep if sampletermdk==1
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)

	svy: reg stdfa_locw7dk wrk_uni $bgcontrols_cnt $bgcontrols_bin   
	eststo ever_est0
	svy: reg stdfa_locw7dk wrk_uni stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin   
	eststo ever_est1
	svy: reg stdfa_locw7dk wrk_uni stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin 
	eststo ever_est2
	svy: reg stdfa_locw7dk wrk_uni stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo ever_est3
	
	* Term-time estimates 
	
	svy: reg stdfa_locw7dk wrk_term sex $bgcontrols_cnt 
	eststo term_est0
	svy: reg stdfa_locw7dk wrk_term stdfa_locw2dk $bgcontrols_cnt    
	eststo term_est1
	svy: reg stdfa_locw7dk wrk_term stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin 
	eststo term_est2
	svy: reg stdfa_locw7dk wrk_term stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo term_est3
	
	* Summer estimates
	svy: reg stdfa_locw7dk wrk_vac $bgcontrols_cnt $bgcontrols_bin 
	eststo summer_est0
	svy: reg stdfa_locw7dk wrk_vac stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin 
	eststo summer_est1
	svy: reg stdfa_locw7dk wrk_vac stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin 
	eststo summer_est2
	svy: reg stdfa_locw7dk wrk_vac stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo summer_est3
	
	* Christmas
	use `data', clear
	keep if sampleretholdk==1
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svy: reg stdfa_locw7dk wrk_chris $bgcontrols_cnt $bgcontrols_bin
	eststo chris_est0
	svy: reg stdfa_locw7dk wrk_chris stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin
	eststo chris_est1
	svy: reg stdfa_locw7dk wrk_chris stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin  
	eststo chris_est2
	svy: reg stdfa_locw7dk wrk_chris stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo chris_est3
	
	* Easter
	svy: reg stdfa_locw7dk wrk_easter $bgcontrols_cnt $bgcontrols_bin
	eststo easter_est0
	svy: reg stdfa_locw7dk wrk_easter stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin 
	eststo easter_est1
	svy: reg stdfa_locw7dk wrk_easter stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin  
	eststo easter_est2
	svy: reg stdfa_locw7dk wrk_easter stdfa_locw2dk $bgcontrols_cnt $bgcontrols_bin $priorcontrols 
	eststo easter_est3	
	
	esttab ever_est3 term_est3 summer_est3 chris_est3 easter_est3 using "$MyProject/results/tables/all_regdk.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.1 ** 0.05 *** 0.01) 
	
	foreach n in ever term summer chris easter	{
	esttab `n'_est0 `n'_est1 `n'_est2 `n'_est3 using "$MyProject/results/tables/`n'_regdk.rtf", replace ///
	se ar2 label nogap onecell b(%9.3f) noconstant star(* 0.1 ** 0.05 *** 0.01) 
	}
	
** EOF