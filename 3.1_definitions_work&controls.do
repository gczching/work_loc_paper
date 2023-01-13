* Defining the concepts of :
	* 1. Work while in university - term time and vacation time 
	* 2. Control variables of interest 
	
	* Note:
	* - I am using a more broad definition of work
	* - More specific definitions will be used for robustness checks
*------------------------------------------------------------------		
global MyProject "C:\Users\User\Dropbox\PhD Research\Paper_2/stata_folder/"

* Preamble (unnecessary when executing run.do)
do "$MyProject/scripts/programs/_config.do"

	use "$MyProject/processed/clean.dta", clear
	set graphics off 
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1)
	
	*===================================================
	* Remove all refused to answer
	g miss=1 if W7PdwrkYP0a<1 & W7PdwrkYP0b<1 & W7PdwrkYP0c<1 & W7JobYP<1 & W7HETermYP<1
	drop if miss==1
	
	* Flag those who are missing employment history 
	g flag_term=1	if  W7JobYP==1 & W7HETermYP==2
	label var flag_term "Missing employment history: has a job and term has not finished"
	
	* Flag those who answered current job (regardless if in term) but emp history refused/dk/NA
	g flag_rta=1 	if W7JobYP==2 & W7PdwrkYP0a<1 & W7PdwrkYP0b<1 & W7PdwrkYP0c<1
	label var flag_rta "Refused/DK/NA emp history: no current job regardless of term"
	
	g flag_cur=1	if W7JobYP<1 & (W7PdwrkYP0a>=1 | W7PdwrkYP0b>=1 | W7PdwrkYP0c>=1)
	label var flag_cur "Refused current job, but worked before"

 
	* 1. Definitions of work in university in TERM-TIME:
	*===================================================
		* Retrospective info: Asked if finished academic term | not finished term + no job 
		
		*------------------------------------------
		* Extensive margin: whether worked or not 
		*------------------------------------------
			* All inclusive definition
			g wrk_term=1 				if 	W7PdwrkYP0c==1 				// ever done paid work since starting uni
			replace wrk_term=1 			if  W7JobYP==1 & W7HETermYP==2 	// 279 currently in term w a job
			replace wrk_term=0 			if 	W7PdwrkYP0c==2 				// no to "ever done paid work since starting uni"
			replace wrk_term=0			if  W7JobYP==2 & W7HETermYP==-1 // no current job, don't know if term ended= 8 ended 

			label var wrk_term "Ever worked during term-time" 				
				// Does not include "DK if term ended" and has job/refused = 5
				// 29 missing from W7PdwrkYP0c 
				// 5 missing term did not end & refused to answer if doing paid work 
			label define wrk_term 0"Did not work term-time" 1"Worked term-time"
			label values wrk_term wrk_term 
			
			* Keeping only those whose term has not ended 
			g wrk_term_ret=1 		if 	W7PdwrkYP0c==1 
			replace wrk_term_ret=0 	if 	W7PdwrkYP0c==2 
			label var wrk_term_ret "Retrospective: worked during term-time" 
			
			svy: mean wrk_term
			svy: mean wrk_term_ret
			
			// >70% are reporting retrospective information 
			// 12 DK if they worked during term-time and 21 RTA
			// 14 DK if term ended
		
		*-----------------------------------------------------------------------
		* QUESTION ROUTING
		
		* CHECKING if question routing is working: in term-time and currently have a job 
			ta W7PdwrkYP0c 	if W7JobYP==1 & W7HETermYP==2
			ta W7DWrkHrs3YP if W7JobYP==1 & W7HETermYP==2
			ta W7PdwrkYP0a 	if W7JobYP==1 & W7HETermYP==2
			ta W7PdwrkYP0b 	if W7JobYP==1 & W7HETermYP==2
				// 279 students who are working during term-time at time of interview do not have
				// emp history about christmas or easter 
		*-----------------------------------------------------------------------
		*------------------------------------------		
		* Intensive margin: Hours worked 
		*------------------------------------------			
				
				* Confirms that hours worked is N/A for those who currently have a job and in term 
					ta W7DWrkHrs1YP if W7JobYP==1 & W7HETermYP==2
					ta W7DWrkHrs2YP if W7JobYP==1 & W7HETermYP==2
					* This is the same for Christmas and Easter hours 
				
				* CHECKING if there are differences between students who are in term vs not currently in term 
				bys W7HETermYP: ta dateintw7 
				ta dateintw7, gen(d_int7)
				* Those who are still in term are mostly interviewed in May
				* The rest are interviewed in June and July
				
				bys W7HETermYP: ta uniwave 
				* Both were already in university at wave 6
				* This means I am losing some information about previous work for those who currently have a job and are in term time 
				
				tabstat d_int71 d_int72 d_int73 d_int74 d_int75 uniwave, by(W7HETermYP) stat(mean n)
					drop d_int7*
				/* Note: Separate hours reported for :
				* W7PdwrkYP0c and W7JobYP==1 & W7HETermYP==2
				*/
			
			*  HOURS REPORTED
			*-----------------
			* Histogram of the distribution of hours 
			*mvdecode W7DWrkHrs3YP, mv(-1=.d)

			label var W7DWrkHrs3YP "Avg weekly hours worked in a normal week during term-time"
			hist W7DWrkHrs3YP 	if W7DWrkHrs3YP>=-1, percent xtitle(,size(large)) ytitle(,size(large)) ///
			xlabel(,labsize(large)) ylabel(,labsize(large)) discrete
			*graph export "$MyProject/results/figures/tt_hrreport.png", as(png) replace
			
				* Checking hours reported for those who currently have a job and term has not ended
				label var W7Hours1YP "Amount of hours usually worked each week"
				hist W7Hours1YP 	if W7Hours1YP>=-1 & (W7JobYP==1 & W7HETermYP==2),  ///
				xtitle(,size(large)) ytitle(,size(large)) xlabel(,labsize(large)) ylabel(,labsize(large))
				*graph export "$MyProject/results/figures/tt_curhrreport.png", as(png) replace
				
			* Generating all-inclusive hours worked during term-time 
			g hr_term=W7DWrkHrs3YP 			if W7DWrkHrs3YP>-1 	& wrk_term==1
				replace hr_term=W7Hours1YP  if W7Hours1YP>-1 	& wrk_term==1
				// 75 hours missing
				
			* Generating retrospective only term hours worked 
			g hr_term_ret=W7DWrkHrs3YP if W7DWrkHrs3YP>-1 & wrk_term_ret==1

				ta hr_term_ret
				count if W7DWrkHrs3YP==-1 | W7Hours1YP==-1 & (W7JobYP==1 & W7HETermYP==2)
				// 7.7% reported DK n=98. 4 Refused.
				count if hr_term>=50 & hr_term<.
				// 2 reported working more than 50 hours 
				ta W7WHrsChk3YP if hr_term>=50 & hr_term<.
				// 1 of 2 who report more than 50 hours a week confirm that it is correct.
				su hr_term if hr_term>-1, det
				xtile quart = hr_term if hr_term>-1, nq(4)
					su hr_term if quart==1
					su hr_term if quart==2
					su hr_term if quart==3
					su hr_term if quart==4
				// 8 and below  : 25%
				// 9-11			: 50%
				// 12-16		: 75%
				// 17 and above : 100%
				
			*-----------------------------------
			* CATEGORICAL HOURS REPORTED FOR DK
			*-----------------------------------
			ta W7Avr23YP if  W7DWrkHrs3YP==-1 //81 who DK reported av hours
			
			**** THEN, WHAT TO DO WITH DK?
			* OPTION 1: Re-categorise the "accurate" data with categorical one
			replace hr_term=4  		if W7Avr23YP==1 & W7DWrkHrs3YP==-1
			replace hr_term=12 		if W7Avr23YP==2 & W7DWrkHrs3YP==-1
			replace hr_term=23 		if W7Avr23YP==3 & W7DWrkHrs3YP==-1
			replace hr_term=40		if W7Avr23YP==4 & W7DWrkHrs3YP==-1
			// 25 hours missing for those with wrk_term==1
			// 16 worked but reported 0 hours
			
			replace hr_term_ret=4  		if W7Avr23YP==1 & W7DWrkHrs3YP==-1
			replace hr_term_ret=12 		if W7Avr23YP==2 & W7DWrkHrs3YP==-1
			replace hr_term_ret=23 		if W7Avr23YP==3 & W7DWrkHrs3YP==-1
			replace hr_term_ret=40		if W7Avr23YP==4 & W7DWrkHrs3YP==-1
			
			* NOTE: Do not have proxies for DK for W7JobYP==1 & W7HETermYP==2
			
			* OPTION 2: Re-categorise the "inaccurate" data with more precise one
				* Problem, does not fit with distribution of the categorical data 
						
			* Add zeroes to hours worked
			replace hr_term=0 if wrk_term==0
			replace hr_term_ret=0 if wrk_term_ret==0
	
				su hr_term hr_term_ret
				su wrk_term wrk_term_ret
				
			label var hr_term "Avg weekly hours worked during term-time"
			hist hr_term if hr_term>0, percent xtitle(,size(large)) ytitle(,size(large)) ///
			xlabel(,labsize(large)) ylabel(,labsize(large)) discrete
			*graph export "$MyProject/results/figures/hr_term_hist.png", as(png) replace
			
			*-------
			* Questions below only applicable to those who worked during term-time
			* i.e. wrk_term==1
			* Works regularly
			g reg_term=1 		if W7WrkregYP==1 & wrk_term==1
			replace reg_term=0 	if W7WrkregYP==2 & wrk_term==1 | W7WrkregYP==-1 & wrk_term==1
			label var reg_term "Works regularly during term-time"
			
			* Whether work interferes with studying 
			g work_interfere=1 if W7PtwrkYP==1
			replace work_interfere=0 if W7PtwrkYP==2
			replace work_interfere=.b if W7PtwrkYP==-1
			replace work_interfere=.a if W7PtwrkYP==-91
				label var work_interfere "Work interferes with studying"
			
	* 2. Definitions of work in university in CHRISTMAS AND EASTER:
	*===============================================================
		* NOTE: ONLY AVAILABLE FOR THOSE WHO HAVE FINISHED TERM OR HAVE A JOB AND HAVE NOT FINISHED TERM 
		* 91.2% of the sample
		
		* INCIDENCE OF WORK 	
			* Worked during Christmas
			g wrk_chris=1 			if 	W7PdwrkYP0a==1 
			replace wrk_chris=0 	if 	W7PdwrkYP0a==2 
			label var wrk_chris "Worked during Christmas" 
			
			* Worked during Easter
			g wrk_easter=1 			if W7PdwrkYP0b==1
			replace wrk_easter=0	if W7PdwrkYP0b==2
			label var wrk_easter "Worked during Easter"
				
		label define wrk_chris 0"Did not work in Christmas" 1"Worked in Christmas"
		label values wrk_chris wrk_chris
		label define wrk_easter 0"Did not work in Easter" 1"Worked in Easter"
		label values wrk_easter wrk_easter
			
		
		* AVERAGE HOURS WORKED 
		* CHRISTMAS
		*-----------
			* Generating hours worked during term-time 
			g hr_chris=W7DWrkHrs1YP if W7DWrkHrs1YP>-1 & wrk_chris==1
				
				ta W7DWrkHrs1YP if W7DWrkHrs1YP==-1
				// DK=108
				count if hr_chris>=50 & hr_chris<.
				// 21 reported working more than 50 hours 
				ta W7WHrsChk1YP if hr_chris>=50 & hr_chris<.
				// 7 of those who report more than 50 hours a week confirm that it is correct.
				
		
			* CATEGORICAL HOURS REPORTED FOR DK
			*-----------------------------------
			ta W7Avr21YP if  W7DWrkHrs1YP==-1 //19 of the 108 who DK reported
			label var W7Avr21YP "Avg working hours/week, Christmas"
			catplot W7Avr21YP if W7DWrkHrs1YP==-1, scale(*1.2)
			
			* Re-categorise the "accurate" data with categorical one
			replace hr_chris=4  	if W7Avr21YP==1 & W7DWrkHrs1YP==-1
			replace hr_chris=12 	if W7Avr21YP==2 & W7DWrkHrs1YP==-1
			replace hr_chris=23 	if W7Avr21YP==3 & W7DWrkHrs1YP==-1
			replace hr_chris=40		if W7Avr21YP==4 & W7DWrkHrs1YP==-1
				
				* Add zeroes to hours worked 
				replace hr_chris=0 if wrk_chris==0
				label var hr_chris "Avg weekly hours worked in a normal week during Christmas"
				ta hr_chris if wrk_chris==1, m
				// 19 missing for Christmas hours
				
		* EASTER
		*-------
			* Generating hours worked during term-time 
			g hr_easter=W7DWrkHrs2YP if W7DWrkHrs2YP>-1 & wrk_easter==1
				
				ta W7DWrkHrs2YP if W7DWrkHrs2YP==-1
				// DK=88
				count if hr_easter>=50 & hr_easter<.
				// 22 reported working more than 50 hours 
				ta W7WHrsChk2YP if hr_easter>=50 & hr_easter<.
				// 8 of those who report more than 50 hours a week confirm that it is correct.
				
			
			* CATEGORICAL HOURS REPORTED FOR DK
			*-----------------------------------
			ta W7Avr22YP if  W7DWrkHrs2YP==-1 //19 of the 108 who DK reported
			label var W7Avr22YP "Avg working hours/week, Easter"
			catplot W7Avr22YP if W7DWrkHrs2YP==-1, scale(*1.2)
			
			* Re-categorise the "accurate" data with categorical one
			replace hr_easter=4  	if W7Avr22YP==1 & W7DWrkHrs2YP==-1
			replace hr_easter=12 	if W7Avr22YP==2 & W7DWrkHrs2YP==-1
			replace hr_easter=23 	if W7Avr22YP==3 & W7DWrkHrs2YP==-1
			replace hr_easter=40	if W7Avr22YP==4 & W7DWrkHrs2YP==-1
				
				* Add zeroes to hours worked 
				replace hr_easter=0 if wrk_easter==0
				label var hr_easter "Avg weekly hours worked in a normal week during Easter"
				ta hr_easter if wrk_easter==1, m
				// 14 missing for Easter
				
		* 3. Students who are currently working during vacation and off term time
		*=========================================================================
			// Anyone currently working at time of interview, off term-time
			g wrk_vac=1 		if W7JobYP==1 & W7HETermYP==1
			replace wrk_vac=0 	if W7JobYP==2 & W7HETermYP==1 | W7HETermYP==2
				// v.s. anyone who is still in term OR someone who does not currently have a job & term ended
				ta wrk_vac, m
				label var wrk_vac "Work during Summer"
				// 18 missing because 7 RTA for Job
				// 3 don't know if term ended, has a job
				// 8 don't know if term ended, does not have a job
		label define wrk_vac 0"Did not work in Summer" 1"Worked in Summer"
		label values wrk_vac wrk_vac
			
			
			g hr_vac=W7Hours1YP if wrk_vac==1
			replace hr_vac=0 	if wrk_vac==0
			replace hr_vac=. 	if hr_vac<0 | hr_vac==99
			hist hr_vac if hr_vac>0, discrete
			label var hr_vac "Amount of hours usually worked each week" 
				// 93 missing ; 70 DK and 19 RTA
				
			* Pay  
			g pay_vac=W7PayWkMain_Banded if W7PayWkMain_Banded>0 & wrk_vac==1
			label var pay_vac "Average weekly pay main job, banded"
			label values pay_vac W7PayWkMain_Banded
			// 148 missing pay information for those in work 
			
			// EVER WORKED
			
			g wrk_uni=1				if wrk_term==1 | wrk_chris==1 | wrk_easter==1 | wrk_vac==1
			replace wrk_uni=0		if wrk_term==0 & wrk_chris==0 & wrk_easter==0 & wrk_vac==0
				replace wrk_uni=1	if W7JobYP==1 & W7HETermYP==-1 
				//include those who ever worked but don't know term
			label var wrk_uni "Ever worked during uni"
			ta wrk_uni, m
				//27 refused
			
		* Creating cut-off thresholds of hours of work
		*=============================================
		label define cathr 0"None" 1"1-8" 2"9-15" 3"16-20" 4">20"
		foreach v in term vac chris easter	{
		g cathr_`v'=0 if hr_`v'==0
		replace cathr_`v'=1 if hr_`v'>0 & hr_`v'<=8
		replace cathr_`v'=2 if hr_`v'>8 & hr_`v'<=15
		replace cathr_`v'=3 if hr_`v'>15 & hr_`v'<=20
		replace cathr_`v'=4 if hr_`v'>20
		label values cathr_`v' cathr
		}
	
	* 4. Definitions of controls used 
	*=================================
	
	/* Controls I am interested in :
	- Sex, ethnicity, LT health
	- Subject studied in University 
	- Year or wave enrolled
	- Parental education, NS-SEC of family, whether living with family
	- Whether receiving financial aid 
	
	* Then add these "propensity to work" characteristics
	- Attitudes towards school (waves 1, 2)
	- Whether received EMA during high school
	- Parental income and finance management (pooled during teen years) 
	*/
	
	* Sex, ethnicity
		g sex=1 		if W2SexYP==1 	//male
		replace sex=0 	if W2SexYP==2	//female
		label define sex_L 0"Female" 1"Male", replace
		label values sex sex_L
		label var sex "Sex: Male"
		
		g ethnic=1 			if W1ethgrpYP==1
		replace ethnic=0 	if W1ethgrpYP>1 & W1ethgrpYP<.
		label var ethnic "Ethnicity: White"
		label define ethnic_L 1"White" 0"Non-white"
		label values ethnic ethnic_L 
		ta ethnic, m

	* Parental and family background
		
		* Family composition
		g fam_cmp=0 if W1famtyp==1 | W1famtyp==2
		replace fam_cmp=1 if W1famtyp>=3 & W1famtyp<=5
		label var fam_cmp "Lone parent/no parent family"
		ta fam_cmp, m
		

		* Highest qualification in the family by main parent
		* Wave 1
		g mp_qualw1=1 		if W1hiqualgMP==1
		replace mp_qualw1=2 if W1hiqualgMP==2
		replace mp_qualw1=3	if W1hiqualgMP>=3 & W1hiqualgMP<=4
		replace mp_qualw1=4	if W1hiqualgMP>=5 & W1hiqualgMP<=6
		replace mp_qualw1=5	if W1hiqualgMP==7 | W1hiqualgMP==-996  //putting those w/o parents under "None" as n is few, and essentially means parents with no qualifications 
		replace mp_qualw1=.a	if W1hiqualgMP<0 & W1hiqualgMP>-996	 // not interviewed or insufficient information
			label values mp_qualw1 family_qual_L
			label var mp_qualw1 "Highest qualification held by main parent"	
			
			ta mp_qualw1, m //156 missing 
			
		* Wave 2 
		g mp_qualw2=1 		if W2hiqualgMP==1
		replace mp_qualw2=2 if W2hiqualgMP==2
		replace mp_qualw2=3	if W2hiqualgMP>=3 & W2hiqualgMP<=4
		replace mp_qualw2=4	if W2hiqualgMP>=5 & W2hiqualgMP<=6
		replace mp_qualw2=5	if W2hiqualgMP==7 | W2hiqualgMP==-996  //putting those w/o parents under "None" as n is few, and essentially means parents with no qualifications 
		replace mp_qualw2=.a	if W2hiqualgMP<0 & W2hiqualgMP>-996	 // not interviewed or insufficient information
			* Replace with wave 1 if missing  (since W4 uses a derived W1 and W2 version)
			replace mp_qualw2=mp_qualw1 if mp_qualw2==.a
			label values mp_qualw2 family_qual_L
			label var mp_qualw2 "Highest qualification held by main parent"	
			
			ta mp_qualw2, m //15 missing 
	
	* Main parent's highest qualification
		g mparent_educ=1 		if mp_qualw2>=1 & mp_qualw2<=2
		replace mparent_educ=0 	if mp_qualw2>=3 & mp_qualw2<=5
		label var mparent_educ "Main parent has higher education"
		ta mp_qualw2, gen(mpqual)
				
	* Number of siblings
		g numsib=W1NoldsibHS+W1NoldBroHS if W1NoldsibHS>=0 & W1NoldBroHS>=0
		ta numsib, m
		label var numsib "Number of siblings"

	* Whether has health problem or disability
		mvdecode W7Disabv1, mv(-1=.b \-92=.a)
		recode W7Disabv1 (2=0)
		label var W7Disabv1 "Health problem or disability at Wave 7"
		
	* University: Cambridge and Oxford Flag
		ta W7Oxbridge
		mvdecode W7Oxbridge, mv(-1=.b)
		recode W7Oxbridge (2=0)
	
	* University: Russell Group
		ta W7Russell
		mvdecode W7Russell, mv(-1=.b)
		recode W7Russell (2=0)
		label var W7Russell "Attending a Russell Group University"
		
	* Subject studied in University 
		ta W7HESubGroup, m
		g w7subject=W7HESubGroup 	if W7HESubGroup>0 & W7HESubGroup<7
		replace w7subject=7 		if W7HESubGroup>=7 & W7HESubGroup<=8 	// Engineering and Technologies together 
		forval i=9/13	{
		local j=`i'-1
		replace w7subject=`j'	if W7HESubGroup==`i'
		}
		replace w7subject=13 if W7HESubGroup>=14 & W7HESubGroup<=16 //Putting linguistics and languages together 
		replace w7subject=14 if W7HESubGroup==17
		replace w7subject=15 if W7HESubGroup==18
		replace w7subject=16 if W7HESubGroup==19
		replace w7subject=17 if W7HESubGroup==20
		replace w7subject=.a if W7HESubGroup==-1 
		label define subject_L 1"Medicine and dentistry" 2"Subjects allied to medicine" 3"Biological sciences" ///
		4"Veterinary sciences, agri & related" 5"Physical sciences" 6"Mathematical and computer sciences" ///
		7"Engineering & Technologies" 8"Architecture, building and planning" 9"Social studies" 10"Law" ///
		11"Business and Admin studies" 12"Mass communications & documentation" 13"Languages" 14"Historical and Philosophical studies" ///
		15"Creative arts and design" 16"Education" 17"Other" , replace
		label values w7subject subject_L 
	
	* Creating Science-subject and Non-science subject areas, defined by HESA 
		g w7science=1 		if W7HESubGroup>=1 & W7HESubGroup<=7
		replace w7science=0	if W7HESubGroup>=8 & W7HESubGroup<=19
		replace w7science=.a	if W7HESubGroup==-1 | W7HESubGroup==20
		label define w7science_L 0"Non-science subject" 1"Science subject", replace  
		label values w7science w7science_L 
		label var w7science "Subject at wave 7 by HESA science grouping" 
		
	* When enrolled in university
		ta uniwave, m
		
	* Whether lives at home during term-time
		mvdecode W7HEHomeYP, mv(-1=.b)
		recode W7HEHomeYP (2=0)
		label var W7HEHomeYP "Lives at home during term-time"
	
	* Attitudes towards school
		g schoolatt4=W4schatYP if W4schatYP>=0
		label var schoolatt4 "Attitude towards school, wave 4"			
			
		g schoolatt1=W1yschat1 if W1yschat1>=0
		label var schoolatt1 "Attitude towards school, age 14/15"	
			
		g schoolatt2=W2yschat1 if W2yschat1>=0
		label var schoolatt2 "Attitude towards school, age 15/16"
		replace schoolatt2=W1yschat1 if schoolatt2==. & W1yschat1>=0
				
	* Whether received EMA or not
		g received_ema=1 		if W3emasuYP==1 | W4EMA1YP==1 | W5EMA1YP==1 | W5EMA2BYP==1
		replace received_ema=0 	if received_ema==.
		label var received_ema "Ever received EMA" 

	* Housing tenure
		g ownhouse=1 		if W1hous12HH==1 | W1hous12HH==2 | W1hous12HH==3
		replace ownhouse=0 	if W1hous12HH>=4 & W1hous12HH<=8
		label define ownhouse_L 1"Owned/mortgage/shared ownership" 2"Rented/other" 
		label values ownhouse ownhouse_L 
		kabel var ownhouse "House is owned/on mortgage/shared ownership"
			
	* Wave 1 how well household is managing on income
		g w1_hhmanage=1 		if W1managhhMP==1
		replace w1_hhmanage=0 	if W1managhhMP==2 | W1managhhMP==3 | W1managhhMP==-1
		label var w1_hhmanage "Household managing quite well with income, age 14/15"
		
	*LOC 
		* Drop the LOC measures, adding the ones later
		drop W2Fat1YP W2Fat5YP W2Fat7YP W2Fat8YP ///
		W7Fat1YP W7Fat5YP W7Fat7YP W7Fat8YP
					
		* MERGE WITH LOC VARS 
			
		merge 1:1 NSID using "$MyProject/processed/clean_loc.dta", nogen
			
		*----------------------------------------------------------------------------------------------------------------
			ta w7subject, gen(unisub)
			label var unisub1 "Medicine and dentistry"
			label var unisub2 "Subjects allied to medicine"
			label var unisub3 "Biological sciences"
			label var unisub4 "Veterinary sciences, agri & related"
			label var unisub5 "Physical sciences"
			label var unisub6 "Mathematical and computer sciences"
			label var unisub7 "Engineering & Technologies"
			label var unisub8 "Architecture, building, and planning"
			label var unisub9 "Social studies"
			label var unisub10 "Law"
			label var unisub11 "Business and Admin studies"
			label var unisub12 "Mass communications & documentation"
			label var unisub13 "Languages"
			label var unisub14 "Historical and Philosophical studies"
			label var unisub15 "Creative arts and design"
			label var unisub16 "Education"
			label var unisub17 "Other"
			
*-----------------------------------------------------------------------------------------------------------------			
		* GLOBAL THE CONTROLS 
		*---------------------
		global bgcontrols_cnt	sex ethnic W7Disabv1 unigrant uniwave   
		global bgcontrols_bin	W7Russell mparent_educ fam_cmp numsib 
		global controls_sub		unisub1-unisub10 unisub12-unisub17
		global priorcontrols	w1_hhmanage received_ema schoolatt2 ownhouse
*-----------------------------------------------------------------------------------------------------------------
		
		* FOR LOC without DK
		*====================		
	
			*Keep all non-missing LOC
				egen locmiss=rowmiss(W7fault W2fault W7decide W2decide W7work W2work W7luck W2luck)
					ta W7fault if locmiss>0, m
					ta W2fault if locmiss>0, m
					ta W7decide if locmiss>0, m 
					ta W2decide if locmiss>0, m 
					ta W7work if locmiss>0, m
					ta W2work if locmiss>0, m 
					ta W7luck if locmiss>0, m
					ta W2luck if locmiss>0, m
					
				egen locmissnm=rowmiss(W2Fat1YPnm W2Fat5YPnm W2Fat8YPnm W7Fat1YPnm W7Fat5YPnm W7Fat8YPnm W2Fat7YPnm W7Fat7YPnm)
				
			* Ever worked sample
				egen total_miss=rowmiss(stdfa_locw2 stdfa_locw7 wrk_uni $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols)
				g sampleuni=1	if total_miss==0
				label var sampleuni "Sample: Ever worked non-missing char"
				ta locusw2 if sampleuni==., m 
				ta locusw7 if sampleuni==., m
				
			* Term-time and Summer sample: work hours 
				egen total_miss2=rowmiss(stdfa_locw2 stdfa_locw7 hr_term hr_vac $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols)
				g sampleterm=1	if total_miss2==0
				label var sampleterm "Sample term and summer: non-missing char"
				drop total_miss total_miss2

				egen total_miss4=rowmiss(stdfa_locw2 stdfa_locw7 hr_term hr_vac $bgcontrols_cnt $bgcontrols_bin $priorcontrols)
				g sampletermnosub=1 if total_miss4==0
				
				* Christmas/Easter/retrospective sample
				* Only for robustness
				egen total_miss=rowmiss(stdfa_locw2 stdfa_locw7 hr_term hr_vac hr_chris hr_easter $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols)
				g samplerethol=1 		if total_miss==0 
				replace samplerethol=0 if samplerethol==.
				drop total_miss
				label var samplerethol "Total sample with no missing variables, smallest sample" 
				ta samplerethol

		*====================	
		* FOR LOC WITH DK
		*====================		
		
				egen total_miss=rowmiss(stdfa_locw2dk stdfa_locw7dk wrk_uni $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols)
				g sampleunidk=1 		if total_miss==0
				replace sampleunidk=0	if total_miss==.
				drop total_miss
				label var sampleunidk "Sample: Ever worked non-missing char (locus DK)"
				ta sampleunidk
				
			* Term-time and Summer sample: work hours			
				egen total_miss2=rowmiss(stdfa_locw2dk stdfa_locw7dk hr_term hr_vac $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols)
				g sampletermdk=1	if total_miss2==0
				label var sampletermdk "Sample term and summer: non-missing char (locus DK)"
				drop total_miss2
				ta sampleterm 
				ta sampletermdk
				
			* Christmas/Easter/retrospective sample
				* Only for robustness
				egen total_miss=rowmiss(stdfa_locw2dk stdfa_locw7dk hr_term hr_vac hr_chris hr_easter $bgcontrols_cnt $bgcontrols_bin w7science $priorcontrols)
				g sampleretholdk=1 		if total_miss==0 
				replace sampleretholdk=0 if sampleretholdk==.
				drop total_miss
				label var sampleretholdk "Total sample with no missing variables, smallest sample (locus DK)"
				ta sampleretholdk
				
	save "$MyProject/processed/clean_processed.dta", replace
			
	* EOF
