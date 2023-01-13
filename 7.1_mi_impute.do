* Multiple imputation

* Preamble (unnecessary when executing run.do)
do "$MyProject/scripts/programs/_config.do"

	use "$MyProject/processed/clean_processed.dta", clear
			
	keep NSID W7finwt samppsu_w1 sampstratum_w1 ///
	W7Fat1YP* W7Fat5YP* W7Fat7YP* W7Fat8YP*  ///
	W2Fat1YP* W2Fat5YP* W2Fat7YP* W2Fat8YP* ///
	sex ethnic W7Disabv1 unigrant uniwave ///
	W7Russell mparent_educ fam_cmp numsib ///
	w7science ///
	w1_hhmanage received_ema schoolatt2 ownhouse ///
	wrk_chris wrk_easter
	
	keep if wrk_chris!=. 
	replace W7Disabv1=. if 	W7Disabv1>.
	replace W7Russell=. if W7Russell>.
	replace w7science=. if w7science>.
	

	misstable summarize
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)	
	
	mi set wide
	mi svyset 
	
	* LOC
	*=====
	* Impute based on: https://stats.oarc.ucla.edu/stata/faq/how-can-i-do-factor-analysis-with-missing-data-in-stata/
		
		* Reverting positive statements
		local num 2 7 
		foreach n of local num	{
			mi passive: gen W`n'fault=1 	if W`n'Fat1YPnm==4
			mi passive: replace W`n'fault=2 if W`n'Fat1YPnm==3
			mi passive: replace W`n'fault=3 if W`n'Fat1YPnm==2
			mi passive: replace W`n'fault=4 if W`n'Fat1YPnm==1

			mi passive: gen W`n'decide=1 		if W`n'Fat5YPnm==4
			mi passive: replace W`n'decide=2 if W`n'Fat5YPnm==3
			mi passive: replace W`n'decide=3 if W`n'Fat5YPnm==2
			mi passive: replace W`n'decide=4 if W`n'Fat5YPnm==1
			
			mi passive: gen W`n'work=1 		if W`n'Fat8YPnm==4
			mi passive: replace W`n'work=2 	if W`n'Fat8YPnm==3
			mi passive: replace W`n'work=3 	if W`n'Fat8YPnm==2
			mi passive: replace W`n'work=4 	if W`n'Fat8YPnm==1
			
			mi passive: gen W`n'luck=1 		if W`n'Fat8YPnm==1
			mi passive: replace W`n'luck=2 	if W`n'Fat8YPnm==2
			mi passive: replace W`n'luck=3 	if W`n'Fat8YPnm==3
			mi passive: replace W`n'luck=4 	if W`n'Fat8YPnm==4
		}
		
		* Sum score
		mi passive: egen LOCUSW2=rowtotal(W2fault W2decide W2work W2luck), missing
		mi passive: egen LOCUSW7=rowtotal(W7fault W7decide W7work W7luck), missing 
		
		* Factor analysis
		misstable summarize W7luck W7decide W7work W7fault W2luck W2decide W2work W2fault
		count
		* 3,217
		corr W7luck W7decide W7work W7fault, cov
		
		* 2,260
		corr W2luck W2decide W2work W2fault, cov
		* 1,828
	
		mi register regular 	W7Fat1YPnm W7Fat5YPnm W7Fat7YPnm W7Fat8YPnm W2Fat1YPnm W2Fat5YPnm W2Fat7YPnm W2Fat8YPnm
		mi register imputed 	W7decide W7work W7fault W7luck W2decide W2work W2fault W2luck
		
		* LOC w7 
		mi impute mvn W7decide W7work W7fault, emonly rseed(1234)
		matrix cov_em = r(Sigma_em)
		matrix list cov_em
		factormat cov_em, n(2260) ml
		rotate, varimax normalize blanks(.2) 
		predict pf_locw7
		mi passive: egen stdfa_locw7=std(pf_locw7)
		
		* LOC w2
		mi impute mvn W2decide W2work W2fault, emonly rseed(1234)
		matrix cov_em = r(Sigma_em)
		matrix list cov_em
		factormat cov_em, n(1828) ml
		rotate, varimax normalize blanks(.2) 
		predict pf_locw2
		mi passive: egen stdfa_locw2=std(pf_locw2)
		
* Checking patterns of missing 
		misstable summarize LOCUSW2 $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols ///
							wrk_chris wrk_easter LOCUSW7
		
		* Register imputed data
		mi register imputed stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols wrk_chris wrk_easter cathr_chris cathr_easter stdfa_locw7
		
		* Impute the missing information
		mi impute chained (regress) W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w7science w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2 stdfa_locw7 wrk_chris wrk_easter, add(20) rseed(1234) 
		
		tempfile data
		save `data'
		
		log using "$MyProject/scripts/logs/mi_engage2.log", replace
		* Estimate with imputed data
		mi estimate: svy: reg stdfa_locw7 wrk_chris W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2
		
		mi estimate: svy: reg stdfa_locw7 wrk_easter W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2
		
		log close
		