* Date: 09 Feb 2021
* Defining the concepts of :
	* 1. Locus of control 
	
*------------------------------------------------------------------		
*global MyProject "C:/Users/User/Dropbox/PhD Research/Paper_2/stata_folder/"

* Preamble (unnecessary when executing run.do)
do "$MyProject/scripts/programs/_config.do"

	use "$MyProject/processed/w8outcomes.dta", clear 
	merge 1:1 NSID using "$MyProject/processed/clean.dta"
				
	keep if _merge==2 | _merge==3
				
	keep NSID W7finwt samppsu_w1 sampstratum_w1 ///
	W8LOCUS0A W8LOCUS0B W8LOCUS0C W8LOCUS0D ///
	W2Fat1YP W2Fat5YP W2Fat7YP W2Fat8YP ///
	W7Fat1YP W7Fat5YP W7Fat7YP W7Fat8YP
	
	set graphics off 

	* LOC items
	*===========
	
	foreach var of varlist W2Fat1YP W2Fat5YP W2Fat7YP W2Fat8YP ///
	W7Fat1YP W7Fat5YP W7Fat7YP W7Fat8YP	///
	W8LOCUS0A W8LOCUS0B W8LOCUS0C W8LOCUS0D {
		// counting the number of DK
		count if `var'==-1
		// counting YP that refused or not interviewed
		count if `var'==-92 | `var'==-97 | `var'==-99
	}
	
	* Calculate the number of respondents who answer DK to all
	count if W2Fat1YP==-1 & W2Fat5YP==-1 & W2Fat7YP==-1 & W2Fat8YP==-1
	count if W7Fat1YP==-1 & W7Fat5YP==-1 & W7Fat7YP==-1 & W7Fat8YP==-1
	// 4 and 3, not very many
			
			g flagrta_loc2=1 if W2Fat1YP<-1 & W2Fat5YP<-1 & W2Fat7YP<-1 & W2Fat8YP<-1
			// 50 refused/did not answer all questions
			g flagrta_loc7=1 if W7Fat1YP<-1 & W7Fat5YP<-1 & W7Fat7YP<-1 & W7Fat8YP<-1
			// 11 refused/did not answer all questions 
			count if flagrta_loc2==1 & flagrta_loc7==1
				// those who refused to answer in W2 responded in wave 7
				ta W7Fat5YP if flagrta_loc2==1
				ta W7Fat7YP if flagrta_loc2==1
				ta W7Fat8YP if flagrta_loc2==1
				// those who refused to answer in W2 have slightly more "internal"
				// checked for those who refused to answer in wave 7, no clear trend
	* Check the average response to the other questions if respondent answers DK 
	ta W2Fat5YP if W2Fat1YP==-1
	ta W2Fat7YP if W2Fat1YP==-1
	ta W2Fat8YP if W2Fat1YP==-1
		// most of whom answered DK for W2Fat1YP are more internal (agree to LOC statements)
		
	ta W7Fat5YP if W7Fat1YP==-1
	ta W7Fat7YP if W7Fat1YP==-1
	ta W7Fat8YP if W7Fat1YP==-1
		// again, most of whom answered DK for W7Fat1YP are more internal
	
	* I can either consider DK as respondents really "don't know" and put them in the "middle"
	* I can also just drop DK as non-responses 		
	* IN THE NEXT STEPS USER GUIDE FOR WAVE 8, THEY CALCULATE LOC BY SUMMING UP THE SCORES
	* DK IS NOT INCLUDED
	* Use that as my baseline

	/*
	STATEMENTS:
	1 If someone is not a success in life, it is usually their own fault 
	5 I can pretty much decide what will happen in my life
	7 How well you get on in this world is mostly a matter of luck
	8 If you work hard at something, you'll usually succeed
	(1=strongly agree) (4=strongly disagree)
	*/
	
	* Positive statements: I want higher number = more INTERNAL 	
	* Reverting the positive statements to indicate 4=strongly agree and 1=strongly disagree
	* Putting DK=middle number 	
	
		* Labels 
		label define loc_labeldk 1"Strongly agree" 2"Agree" 3"DK" 4"Disagree" 5"Strongly disagree" -98"RTA", replace
		label define loc_label_reversedk 1"Strongly disagree" 2"Disagree" 3"DK" 4"Agree" 5"Strongly Agree" -98"RTA", replace
		label define loc_label 1"Strongly agree" 2"Agree" 3"Disagree" 4"Strongly disagree", replace
		label define loc_label_reverse 1"Strongly disagree" 2"Disagree" 3"Agree" 4"Strongly Agree", replace

	* 1. Putting DK in middle (DK=really DK)
	*=======================================
		* Reverting Positive statements
		foreach var of varlist W2Fat1YP W2Fat5YP W2Fat8YP ///
		W7Fat1YP W7Fat5YP W7Fat8YP	{
		
			g `var'nm=. if `var'<0
			replace `var'nm=1 if `var'==4
			replace `var'nm=2 if `var'==3
			replace `var'nm=3 if `var'==-1
			replace `var'nm=4 if `var'==2
			replace `var'nm=5 if `var'==1
			replace `var'nm=-98 if `var'<-1
			label values `var'nm loc_label_reversedk 

		}
	
		* Negative statements
		foreach var of varlist W2Fat7YP W7Fat7YP	{
		g `var'nm=`var' if `var'==1 | `var'==2
			replace `var'nm=3 if `var'==-1
			replace `var'nm=4 if `var'==3
			replace `var'nm=5 if `var'==4
			replace `var'nm=-98 if `var'<-1
			label values `var'nm loc_labeldk
			
		}
		
		* Label variables
		label var W2Fat1YPnm "Fault"
		label var W2Fat5YPnm "Decide"
		label var W2Fat7YPnm "Luck"
		label var W2Fat8YPnm "Work Hard"
		label var W7Fat1YPnm "Fault"
		label var W7Fat5YPnm "Decide"
		label var W7Fat7YPnm "Luck"
		label var W7Fat8YPnm "Work Hard"
		
		* I don't consider those who did not answer LOC in wave 2 or in wave 7
		  * drop if flagrta_loc2==1 | flagrta_loc7==1	//61 observations deleted 
		* Reason: Possible that those who did not answer in wave 2 are likely to be more internal types but cannot be sure, so remove
		
		* Creating LOC index without RTA 
		foreach var of varlist W2Fat1YPnm W2Fat5YPnm W2Fat7YPnm W2Fat8YPnm ///
		W7Fat1YPnm W7Fat5YPnm W7Fat7YPnm W7Fat8YPnm	{ 
		replace `var'=. if `var'<-1
		}
		
		egen LOCUSW2dk=rowtotal(W2Fat1YPnm W2Fat5YPnm W2Fat7YPnm W2Fat8YPnm), missing
		egen LOCUSW7dk=rowtotal(W7Fat1YPnm W7Fat5YPnm W7Fat7YPnm W7Fat8YPnm), missing 
			label var LOCUSW2dk "Locus of control wave 2 incl. dk"
			label var LOCUSW7dk "Locus of control wave 7 incl. dk" 
			su LOCUSW2dk LOCUSW7dk 
			
		local num 2 7 
		foreach n of local num	{
			g onemissw`n'=1 		if W`n'Fat1YPnm==. | W`n'Fat5YPnm==. | W`n'Fat7YPnm==. | W`n'Fat8YPnm==.
			replace onemissw`n'=0 	if onemissw`n'==.
			label var onemissw`n'"At least one missing in LOCUS W`n'"
			
			g locusw`n'dk=LOCUSW`n'dk if onemissw`n'!=1
			label var locusw`n'dk "Locus of control, wave `n', no missing"
			}
		drop onemiss*
		
		
	* 2. Dropping DK
	*================
		* Rename W8 variables 
		rename W8LOCUS0A W8Fat1YP
		rename W8LOCUS0B W8Fat5YP
		rename W8LOCUS0C W8Fat7YP
		rename W8LOCUS0D W8Fat8YP
		
		* Reverting positive statements
		local num 2 7 8
		foreach n of local num	{
			g W`n'fault=1 		if W`n'Fat1YP==4
			replace W`n'fault=2 if W`n'Fat1YP==3
			replace W`n'fault=3 if W`n'Fat1YP==2
			replace W`n'fault=4 if W`n'Fat1YP==1
			label var W`n'fault "Fault"
			label values W`n'fault loc_label_reverse
		
			g W`n'decide=1 		if W`n'Fat5YP==4
			replace W`n'decide=2 if W`n'Fat5YP==3
			replace W`n'decide=3 if W`n'Fat5YP==2
			replace W`n'decide=4 if W`n'Fat5YP==1
			label var W`n'decide "Decide"
			label values W`n'decide loc_label_reverse
			
			g W`n'work=1 		if W`n'Fat8YP==4
			replace W`n'work=2 	if W`n'Fat8YP==3
			replace W`n'work=3 	if W`n'Fat8YP==2
			replace W`n'work=4 	if W`n'Fat8YP==1
			label var W`n'work "Work hard"
			label values W`n'work loc_label_reverse
		}
		
		* Negative statements 
		g W2luck=W2Fat7YP if W2Fat7YP>0
		label values W2luck loc_label
		label var W2luck "Luck"
		g W7luck=W7Fat7YP if W7Fat7YP>0
		label values W7luck loc_label
		label var W7luck "Luck"
		g W8luck=W8Fat7YP if W8Fat7YP>0
		label values W8luck loc_label
		label var W8luck "Luck"
		
		egen LOCUSW2=rowtotal(W2fault W2decide W2work W2luck), missing
		egen LOCUSW7=rowtotal(W7fault W7decide W7work W7luck), missing 
		
			label var LOCUSW2 "Locus of control wave 2, incl. missing"
			label var LOCUSW7 "Locus of control wave 7, incl. missing" 
			
			
		* Sample if has one DK or non-missing in one item 
		local num 2 7 
		foreach n of local num	{
			g onemissw`n'=1 		if W`n'fault==. | W`n'decide==. | W`n'work==. | W`n'luck==.
			replace onemissw`n'=0 	if onemissw`n'==.
			label var onemissw`n'"At least one missing in LOCUS W`n'"
			
			g locusw`n'=LOCUSW`n' if onemissw`n'!=1
			label var locusw`n' "Locus of control, wave `n', no missing"
			}
			
			su locusw2 locusw2dk locusw7 locusw7dk
			twoway kdensity locusw2 || kdensity locusw2dk
			twoway kdensity locusw7 || kdensity locusw7dk
		
		* 2.1 Creating a standardised score 
		* Standardising the LOC which does not have the "DK" items 
			foreach n of local num	{
			egen zlocw`n'=std(LOCUSW`n')
			egen stdlocw`n'=std(locusw`n')
			}
			
			twoway histogram zlocw7, discrete
			twoway histogram stdlocw7, discrete
			
			// Definitely makes more sense to have the min of 4
			

		* 2.1 Creating binary outcome for each item
			// Those who strongly agree or agree 
			local waves 2 7
			local locusitem decide fault work
			foreach w of local waves		{
			foreach v of local locusitem	{
			g W`w'`v'a=1 		if W`w'`v'==3 | W`w'`v'==4
			replace W`w'`v'a=0 	if W`w'`v'>=1 & W`w'`v'<=2
			label var W`w'`v'a "1=Agree|S.agree `v', W`w'"
			// Those who strongly agree
			g W`w'`v'sa=1		if W`w'`v'==4
			replace W`w'`v'sa=0	if W`w'`v'>=1 & W`w'`v'<=3
			label var W`w'`v'sa "1=Strongly agree `v', W`w'"
			// Those who strongly disagree or disagree 
			g W`w'`v'd=1 		 if W`w'`v'>=1 & W`w'`v'<=2
			replace W`w'`v'd=0   if W`w'`v'==3 | W`w'`v'==4
			label var W`w'`v'd "1=Disagree|S.disagree `v', W`w'"
			// Those who strongly disagree
			g W`w'`v'sd=1		if W`w'`v'==1
			replace W`w'`v'sd=0		if W`w'`v'>=2 & W`w'`v'<=4
			label var W`w'`v'sd "1=Strongly Disagree `v', W`w'"
			}

			g W`w'lucka=1			if W`w'luck>=1 & W`w'luck<=2
			replace W`w'lucka=0		if W`w'luck>=3 & W`w'luck<=4
			label var W`w'lucka "1=Agree|S.agree with luck, W`w'"
			g W`w'lucksa=1			if W`w'luck==1
			replace W`w'lucksa=0	if W`w'luck>=2 & W`w'luck<=4
			label var W`w'lucksa "1=Strongly Agree with luck, W`w'"
			g W`w'luckd=1			if W`w'luck>=3 & W`w'luck<=4
			replace W`w'luckd=0	if W`w'luck>=1 & W`w'luck<=2
			label var W`w'luckd "1=Disagree|S.disagree with luck, W`w'"
			g W`w'lucksd=1			if W`w'luck==4
			replace W`w'lucksd=0	if W`w'luck>=1 & W`w'luck<=3
			label var W`w'lucksd "1=Strongly Disagree with luck, W`w'"
			}

	* Visualising EACH ITEM, by wave 

	set graphics on
	graph set window fontface arial
	
	foreach var of varlist W2Fat1YPnm W2Fat5YPnm W2Fat7YPnm W2Fat8YPnm ///
	W7Fat1YPnm W7Fat5YPnm W7Fat7YPnm W7Fat8YPnm	{ 
	catplot `var' [aw=W7finwt], percent name(loc`var', replace) yla(0(20)100) scale(*1.2) scheme(s1mono)
	}
	
	graph combine locW2Fat1YPnm locW2Fat5YPnm locW2Fat7YPnm locW2Fat8YPnm, title(Wave 2) scheme(s1mono)
		graph export "$MyProject/results/figures/locwave2.tif", as(tif) replace 
		*graph export "$MyProject/results/figures/locwave2.png", as(png) replace 
	graph combine locW7Fat1YPnm locW7Fat5YPnm locW7Fat7YPnm locW7Fat8YPnm, scheme(s1mono)
		graph export "$MyProject/results/figures/locwave7.tif", as(tif) replace
		*graph export "$MyProject/results/figures/locwave7.svg", as(svg) replace 

	
		foreach var of varlist W2fault W2decide W2work W2luck ///
		W7fault W7decide W7work W7luck	{ 
		catplot `var' [aw=W7finwt], percent name(loc`var', replace) yla(0(20)100) scale(*1.2) scheme(s1mono)
		}
	
		graph combine locW2fault locW2decide locW2work locW2luck, title(Wave 2) scheme(s1mono)
		graph combine locW7fault locW7decide locW7work locW7luck, title(Wave 7) scheme(s1mono)
		
	* EFA LOC
	*========
		* LOC WAVE 7
		factor W7fault W7luck W7decide W7work, pf mineigen(0.1)
		factor W7fault W7decide W7work
		predict pf_locw7
		label var pf_locw7 "LOC, wave 7"
		
		factor  W7Fat1YPnm W7Fat5YPnm W7Fat8YPnm W7Fat7YPnm, pf mineigen(0.1)
		factor W7Fat1YPnm W7Fat5YPnm W7Fat8YPnm
		predict pf_locw7dk
		label var pf_locw7dk "LOC incl. DK, wave 7"
		
		* LOC WAVE 2
		factor W2fault W2decide W2work W2luck, pf mineigen(0.1)
		factor W2fault W2decide W2work, pf mineigen(0.1)
		predict pf_locw2
		label var pf_locw2 "LOC, wave 2"
		// Using factor analysis automatically drops a sum score if one of the items has a missing value
		
		factor  W2Fat1YPnm W2Fat5YPnm W2Fat8YPnm W2Fat7YPnm, pf mineigen(0.1)
		factor 	W2Fat1YPnm W2Fat5YPnm W2Fat8YPnm
		predict pf_locw2dk
		label var pf_locw2dk "LOC incl. DK, wave 2"
		
		egen stdfa_locw2=std(pf_locw2)
		egen stdfa_locw7=std(pf_locw7)
		*egen stdfa_locw8=std(pf_locw8)
		
		egen stdfa_locw2dk=std(pf_locw2dk)
		egen stdfa_locw7dk=std(pf_locw7dk)
		
		su 	stdfa_locw2 locusw2 LOCUSW2 ///
			stdfa_locw2dk locusw2dk LOCUSW2dk ///
			stdfa_locw7 locusw7 LOCUSW7 ///
			stdfa_locw7dk locusw7dk LOCUSW7dk
			
		desc stdfa_locw2 locusw2 LOCUSW2 ///
			stdfa_locw2dk locusw2dk LOCUSW2dk ///
			stdfa_locw7 locusw7 LOCUSW7 ///
			stdfa_locw7dk locusw7dk LOCUSW7dk
		
		
	* SCORES THAT I DECIDED TO KEEP:
	
				keep 	NSID locusw* ///
						W*fault* W*decide* W*work* W*luck* ///
						LOCUS* pf* stdfa* *nm ///
						pf_locw2dk pf_locw7dk ///
						locus* onemiss*
				
			save "$MyProject/processed/clean_loc.dta", replace
			
	* EOF
