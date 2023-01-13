* Multiple imputation

global MyProject "C:/Users/User/Dropbox/PhD Research/Paper_2/stata_folder/"

* Preamble (unnecessary when executing run.do)
do "$MyProject/scripts/programs/_config.do"

	use "$MyProject/processed/clean.dta", clear
			
	keep NSID W7finwt samppsu_w1 sampstratum_w1 ///
	W7Fat1YP W7Fat5YP W7Fat7YP W7Fat8YP  ///
	W2Fat1YP W2Fat5YP W2Fat7YP W2Fat8YP ///
	W7JobYP W7HETermYP W7PdwrkYP0a W7PdwrkYP0b W7PdwrkYP0c ///
	W7DWrkHrs1YP W7DWrkHrs2YP W7DWrkHrs3YP ///
	W2SexYP W1ethgrpYP W1famtyp W1NoldsibHS W1NoldBroHS ///
	W7Disabv1 W7Russell W7HESubGroup  W6UnivYP W7HEQualSameYP W7HEHomeYP ///
	W1yschat1 W2yschat1 W3emasuYP W4EMA1YP W5EMA1YP W5EMA2BYP ///
	W1hous12HH W1managhhMP W1hiqualgMP W2hiqualgMP  ///
	W7GrantRecYP0a W7GrantRecYP0b W7GrantRecYP0c ///
	W2nssecfam W7Hours1YP W7Avr23YP
	
	* Controls that I'm keeping....
		global bgcontrols_cnt	sex ethnic W7Disabv1 unigrant uniwave   
		global bgcontrols_bin	W7Russell mparent_educ fam_cmp numsib 
		global controls_sub		w7science
		global priorcontrols	w1_hhmanage received_ema schoolatt2 ownhouse
		
	misstable summarize
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)	
	
	mi set wide
	mi svyset 
	
	* Sex
		mi passive: gen sex=1 		if W2SexYP==1 	//male
		mi passive: replace sex=0 	if W2SexYP==2	//female
		label define sex_L 0"Female" 1"Male", replace
		label values sex sex_L
		label var sex "Sex: Male"
	* Ethnicity	
		mi passive: g ethnic=1 			if W1ethgrpYP==1
		mi passive: replace ethnic=0 	if W1ethgrpYP>1 & W1ethgrpYP<.
		label var ethnic "Ethnicity: White"
		label define ethnic_L 1"White" 0"Non-white"
		label values ethnic ethnic_L 
		ta ethnic, m

	* Parental and family background
	* Family composition
		mi passive: g fam_cmp=0 if W1famtyp==1 | W1famtyp==2
		mi passive: replace fam_cmp=1 if W1famtyp>=3 & W1famtyp<=5
		label var fam_cmp "Lone parent/no parent family"
		ta fam_cmp, m
	
	* Main parent's education
	
		mi passive: g mp_qualw1=1 		if W1hiqualgMP==1
		mi passive: replace mp_qualw1=2 if W1hiqualgMP==2
		mi passive: replace mp_qualw1=3	if W1hiqualgMP>=3 & W1hiqualgMP<=4
		mi passive: replace mp_qualw1=4	if W1hiqualgMP>=5 & W1hiqualgMP<=6
		mi passive: replace mp_qualw1=5	if W1hiqualgMP==7 | W1hiqualgMP==-996  
		mi passive: replace mp_qualw1=.a	if W1hiqualgMP<0 & W1hiqualgMP>-996	
			
		mi passive: g mp_qualw2=1 		if W2hiqualgMP==1
		mi passive: replace mp_qualw2=2 if W2hiqualgMP==2
		mi passive: replace mp_qualw2=3	if W2hiqualgMP>=3 & W2hiqualgMP<=4
		mi passive: replace mp_qualw2=4	if W2hiqualgMP>=5 & W2hiqualgMP<=6
		mi passive: replace mp_qualw2=5	if W2hiqualgMP==7 | W2hiqualgMP==-996  
		mi passive: replace mp_qualw2=.a	if W2hiqualgMP<0 & W2hiqualgMP>-996	 
		mi passive: replace mp_qualw2=mp_qualw1 if mp_qualw2==.a
		label values mp_qualw2 family_qual_L
		label var mp_qualw2 "Highest qualification held by main parent"		
		
		mi passive: g mparent_educ=1 		if mp_qualw2>=1 & mp_qualw2<=2
		mi passive: replace mparent_educ=0 	if mp_qualw2>=3 & mp_qualw2<=5
		label var mparent_educ "Main parent has higher education"
				
	* Number of siblings
		mi passive: g numsib=W1NoldsibHS+W1NoldBroHS if W1NoldsibHS>=0 & W1NoldBroHS>=0
		label var numsib "Number of siblings"

	* Whether has health problem or disability
		mvdecode W7Disabv1, mv(-1=. \-92=.)
		recode W7Disabv1 (2=0)
		label var W7Disabv1 "Health problem or disability at Wave 7"
		
	* University: Russell Group
		mvdecode W7Russell, mv(-1=.)
		recode W7Russell (2=0)
		label var W7Russell "Attending a Russell Group University"
	
	* Received grant for university 
	g unigrant=1 		if W7GrantRecYP0a==1 | W7GrantRecYP0b==1 | W7GrantRecYP0c==1 
	replace unigrant=0 	if W7GrantRecYP0a==0 & W7GrantRecYP0b==0 & W7GrantRecYP0c==0
	label var unigrant "Receives a financial help with university costs"
			
	* Creating Science-subject and Non-science subject areas, defined by HESA 
		mi passive: g w7science=1 		if W7HESubGroup>=1 & W7HESubGroup<=7
		mi passive: replace w7science=0	if W7HESubGroup>=8 & W7HESubGroup<=19
		mi passive: replace w7science=.	if W7HESubGroup==-1 | W7HESubGroup==20
		label define w7science_L 0"Non-science subject" 1"Science subject", replace  
		label values w7science w7science_L 
		label var w7science "Subject at wave 7 by HESA science grouping" 
		
	* When enrolled in university
		mi passive: g uniwave=1 if W6UnivYP==1
		mi passive: replace uniwave=0 if W6UnivYP==2
		mi passive: replace uniwave=0 if W7HEQualSameYP==2 //those who changed qualifications, assumed to start in wave 7 
			label define uniwave_L 1"Wave 6" 0"Wave 7", replace 
			label values uniwave uniwave_L
			label var uniwave "Wave enrolled in university" 
			
	* Whether lives at home during term-time
		mvdecode W7HEHomeYP, mv(-1=.b)
		recode W7HEHomeYP (2=0)
		label var W7HEHomeYP "Lives at home during term-time"
	
	* Attitude towards school
		mi passive:	g schoolatt2=W2yschat1 if W2yschat1>=0
			label var schoolatt2 "Attitude towards school, age 15/16"
		mi passive:	replace schoolatt2=W1yschat1 if schoolatt2==. & W1yschat1>=0
		
	* Whether received EMA or not
		mi passive:	g received_ema=1 		if W3emasuYP==1 | W4EMA1YP==1 | W5EMA1YP==1 | W5EMA2BYP==1
		mi passive:	replace received_ema=0 	if received_ema==.
			label var received_ema "Ever received EMA" 
				
	* Housing tenure
		mi passive:	g ownhouse=1 		if W1hous12HH==1 | W1hous12HH==2 | W1hous12HH==3
		mi passive:	replace ownhouse=0 	if W1hous12HH>=4 & W1hous12HH<=8
			label define ownhouse_L 1"Owned/mortgage/shared ownership" 2"Rented/other" 
			label values ownhouse ownhouse_L 
			label var ownhouse "House is owned/on mortgage/shared ownership"
			
	* Wave 1 how well household is managing on income
		mi passive:	g w1_hhmanage=1 		if W1managhhMP==1
		mi passive:	replace w1_hhmanage=0 	if W1managhhMP==2 | W1managhhMP==3 | W1managhhMP==-1
			label var w1_hhmanage "Household managing quite well with income, age 14/15"	
	
*----------------------------------------------------------------------------------------------------
	* Definitions of work in university in TERM-TIME:
	* All inclusive definition
	mi passive: gen wrk_term=1 				if 	W7PdwrkYP0c==1 				// ever done paid work since starting uni
	mi passive: replace wrk_term=1 			if  W7JobYP==1 & W7HETermYP==2 	// 279 currently in term w a job
	mi passive: replace wrk_term=0 			if 	W7PdwrkYP0c==2 				// no to "ever done paid work since starting uni"
	mi passive:	replace wrk_term=0			if  W7JobYP==2 & W7HETermYP==-1 // no current job, don't know if term ended= 8 ended 
						
	* Students who are currently working during vacation and off term time
	// Anyone currently working at time of interview, off term-time
	mi passive: gen wrk_vac=1 		if W7JobYP==1 & W7HETermYP==1
	mi passive: replace wrk_vac=0 	if W7JobYP==2 & W7HETermYP==1 | W7HETermYP==2
	// v.s. anyone who is still in term OR someone who does not currently have a job & term ended
	label var wrk_vac "Work during Summer"
		
	* Worked during Christmas
	g wrk_chris=1 			if 	W7PdwrkYP0a==1 
	replace wrk_chris=0 	if 	W7PdwrkYP0a==2 
	label var wrk_chris "Worked during Christmas" 
			
	* Worked during Easter
	g wrk_easter=1 			if W7PdwrkYP0b==1
	replace wrk_easter=0	if W7PdwrkYP0b==2
	label var wrk_easter "Worked during Easter"
			
	* EVER WORKED <--- using this as independentvar for now
	mi passive: gen wrk_uni=1		if wrk_term==1 | wrk_chris==1 | wrk_easter==1 | wrk_vac==1
	mi passive: replace wrk_uni=0		if wrk_term==0 & wrk_chris==0 & wrk_easter==0 & wrk_vac==0
	mi passive: replace wrk_uni=1	if W7JobYP==1 & W7HETermYP==-1 
	//include those who ever worked but don't know term
	label var wrk_uni "Ever worked during uni"
	
	pwcorr $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols wrk_uni wrk_term wrk_chris wrk_vac wrk_easter
	
*----------------------------------------------------------------------------------------------------	
	* LOC
	* Impute based on: https://stats.oarc.ucla.edu/stata/faq/how-can-i-do-factor-analysis-with-missing-data-in-stata/
		
		* Reverting positive statements
		local num 2 7 
		foreach n of local num	{
			mi passive: gen W`n'fault=1 	if W`n'Fat1YP==4
			mi passive: replace W`n'fault=2 if W`n'Fat1YP==3
			mi passive: replace W`n'fault=3 if W`n'Fat1YP==2
			mi passive: replace W`n'fault=4 if W`n'Fat1YP==1

			mi passive: gen W`n'decide=1 		if W`n'Fat5YP==4
			mi passive: replace W`n'decide=2 if W`n'Fat5YP==3
			mi passive: replace W`n'decide=3 if W`n'Fat5YP==2
			mi passive: replace W`n'decide=4 if W`n'Fat5YP==1
			
			mi passive: gen W`n'work=1 		if W`n'Fat8YP==4
			mi passive: replace W`n'work=2 	if W`n'Fat8YP==3
			mi passive: replace W`n'work=3 	if W`n'Fat8YP==2
			mi passive: replace W`n'work=4 	if W`n'Fat8YP==1
		}
		
		* Negative statements 
		mi passive: gen W2luck=W2Fat7YP if W2Fat7YP>0
		mi passive: gen W7luck=W7Fat7YP if W7Fat7YP>0
		
		* Sum score
		mi passive: egen LOCUSW2=rowtotal(W2fault W2decide W2work W2luck), missing
		mi passive: egen LOCUSW7=rowtotal(W7fault W7decide W7work W7luck), missing 
		
		* Factor analysis
		misstable summarize W7luck W7decide W7work W7fault W2luck W2decide W2work W2fault
		count
		
		* 3,543
		corr W7luck W7decide W7work W7fault, cov
		* 3,197
		corr W2luck W2decide W2work W2fault, cov
		* 2,812
	
		mi register regular 	W7Fat1YP W7Fat5YP W7Fat7YP W7Fat8YP W2Fat1YP W2Fat5YP W2Fat7YP W2Fat8YP
		mi register imputed 	W7decide W7work W7fault W7luck W2decide W2work W2fault W2luck
		
		* LOC w7 
		mi impute mvn W7decide W7work W7fault, emonly rseed(1234)
		matrix cov_em = r(Sigma_em)
		matrix list cov_em
		factormat cov_em, n(3349) ml
		rotate, varimax normalize blanks(.2) 
		predict pf_locw7
		mi passive: egen stdfa_locw7=std(pf_locw7)
		
		* LOC w2
		mi impute mvn W2decide W2work W2fault, emonly rseed(1234)
		matrix cov_em = r(Sigma_em)
		matrix list cov_em
		factormat cov_em, n(3176) ml
		rotate, varimax normalize blanks(.2) 
		predict pf_locw2
		mi passive: egen stdfa_locw2=std(pf_locw2)
		
*----------------------------------------------------------------------------------------------------
* Checking patterns of missing 
		misstable summarize LOCUSW2 $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols ///
							wrk_uni LOCUSW7
		
		* Register imputed data
		mi register imputed stdfa_locw2 $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols wrk_uni wrk_term wrk_vac wrk_chris wrk_easter stdfa_locw7
		
		* Impute the missing information
		mi impute chained (regress) W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w7science w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2 stdfa_locw7 wrk_uni wrk_term wrk_vac, add(20) rseed(1234) 
		
		tempfile data
		save `data'
		
		log using "$MyProject/scripts/logs/mi_engage.log", replace
		* Estimate with imputed data
		* Engagement in work
		mi estimate: svy: reg stdfa_locw7 wrk_uni W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2
		
		mi estimate: svy: reg stdfa_locw7 wrk_term W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2
		
		mi estimate: svy: reg stdfa_locw7 wrk_vac W7Russell mparent_educ fam_cmp numsib sex ethnic W7Disabv1 unigrant uniwave w1_hhmanage received_ema ownhouse stdfa_locw2 schoolatt2
		
		log close
		