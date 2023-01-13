* Date: 25 September 2020
* Cleaning merged data to:
*	1. Identify the samples of university students
*	2. Creating age and date of interviews to determine student status prior to wave 7
*---------------------------------------------------------------------------------------

* Preamble (unnecessary when executing Master.do)
do "$MyProject/scripts/programs/_config.do"

	use "$MyProject/processed/merge.dta", clear
		
		svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1)
		svydescribe
		
		* Generate sample for those who are studying for a degree in wave 7
		* And in full-time course	
			g sample_uniw7=1 if W7TCurrentAct==1 & (W7HEQualComb==1 & W7HEFullSameYP<=1)
			replace sample_uniw7=0 if sample_uniw7!=1
			ta sample_uniw7
			label var sample_uniw7 "Sample of university students in full-time course"
			
			* Keep sample of wave 7 university students
			keep if sample_uniw7==1
			
		* Check if wave 7 and wave 6 same qualification
		// Only asked to those who were in university in wave 6
		ta W7HEQualSameYP W6UnivYP
		
		* Year started current activity if was in university in wave 6
		ta W6ActStYYP if W6UnivYP==1

		* The majority of those who were in university in wave 6 started in 2008
		* Rule of thumb:
			* Second years: wave 6
			* First years: wave 7
			
		* Generate wave enrolled in university (to proxy for university year) 
		g uniwave=1 if W6UnivYP==1
		replace uniwave=0 if W6UnivYP==2
		replace uniwave=0 if W7HEQualSameYP==2 //those who changed qualifications, assumed to start in wave 7 
			label define uniwave_L 1"Wave 6" 0"Wave 7", replace 
			label values uniwave uniwave_L
			label var uniwave "Wave enrolled in university" 
			
	* 2. Creating age and date of interviews to determine student status prior to wave 7
	*------------------------------------------------------------------------------------	
		* Date of birth (from Wave 1)
		ta DobyearYP 
		g dob=ym(DobyearYP, DobmonthYP)
		label var dob "Date of birth"
		format dob %tm

		* Generate dates of interview
			* Wave 7 
			g dateintw7=ym(2010,W7IntMonth)
			format dateintw7 %tm
			ta dateintw7
			
			* Wave 6
			replace W6IntYear=. if W6IntYear==-94
			g dateintw6=ym(W6IntYear,W6IntMonth)
			format dateintw6 %tm
			ta dateintw6
		
		* Generating actual age to check against the data 
			* Wave 7
			g ageypmth=dateintw7-dob
			g ageyp_w7=round(ageypmth/12)
				drop ageypmth
				ta ageyp_w7
			
			* Wave 6
			g ageypmth=dateintw6-dob
			g ageyp_w6=round(ageypmth/12)
			drop ageypmth
				
		* Participation in university 
			* Wave 6
				ta W6UnivYP W6AcceptYP
				// Note: all those who "accepted" are not currently in university

		* Age when participated in university, if was in university at wave 6:
			ta ageyp_w6 if W6UnivYP==1
			// majority age 19, followed by age 20
			ta W6ActStYYP ageyp_w6 if W6ActStYYP>0 & W6UnivYP==1
			ta W6ActStMYP W6ActStYYP if W6UnivYP==1 
			// the majority started university in Sep/Oct 2008

		* Number of YP who took a gap year (out of those who accepted a university offer)
			ta W6GapYrYP if W6AcceptYP==1, m
			//  45% of those who accepted an offer in wave 6
		
	* Status in wave 6 when currently in uni in wave 7
			ta W6HEApplyYP, m
			ta W6GapYrYP
			ta W6TCurrentAct
			
			drop _merge 
	save "$MyProject/processed/clean.dta", replace	
	
* EOF
