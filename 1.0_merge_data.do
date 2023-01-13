************
* PURPOSE: processes the main dataset in preparation for analysis
************

* Preamble (unnecessary when executing run.do)
do "$MyProject/scripts/programs/_config.do"

* Global paths 
global dtao		C:\Data\Next Steps\UKDA-5545-stata13\stata\stata13\eul

* Young person
	global w7yp			wave_seven_lsype_young_person_2020
	global w6yp			wave_six_lsype_young_person_2020
	global w5yp			wave_five_lsype_young_person_2020
	global w4yp			wave_four_lsype_young_person_2020
	global w3yp			wave_three_lsype_young_person_2020
	global w2yp 		wave_two_lsype_young_person_2020
	global w1yp			wave_one_lsype_young_person_2020
	* Activity History
		global w47_mainactivity lsype_main_activity_w4-7_nov2011_suppressed.dta
			* Family Background
			global w1fb wave_one_lsype_family_background_2020
			global w2fb wave_two_lsype_family_background_2020
			global w3fb wave_three_lsype_family_background_2020
			global w4fb wave_four_lsype_family_background_2020
			global w5fb	wave_five_lsype_family_background_2020
			
************
* Code begins
************

 * Full longitudinal sample
 *-------------------------
	 forval i=1/7	{
	 use NSID using "$dtao\\${w`i'yp}", clear
	 g inwave`i'=1
	 tempfile wave`i'
	 save `wave`i''
	 }
	 
	  forval i=1/7	{
	  qui merge 1:1 NSID using `wave`i'', nogen
	  }
	
	
	*---- There are 249 skippers in wave 5 ----* 
	* But present in all other waves 
	ta inwave5
		g inwave123467=1 if inwave1==1 & inwave2==1 & inwave3==1 & inwave4==1 & inwave6==1 & inwave7==1
		replace inwave123467=0 if inwave123467==.
		
		g w5skippers=1 if inwave5==. & inwave123467==1
		replace w5skippers=0 if w5skippers==.
		label var w5skippers "Skipped wave 5 but present in waves 1 to 7"
	*-------------------------------------------*	
		
	* 8,682 present in wave 7, cross-sectional
		ta inwave7
		count if inwave7==1 & inwave6==1
		* All present in wave 7 were present in wave 6
	
	* 8,222 Present in ALL waves 
	g wave1234567=1 if inwave1==1 & inwave2==1 & inwave3==1 & inwave4==1 & inwave5==1 & inwave6==1 & inwave7==1
	replace wave1234567=0 if wave1234567==.
		label var wave1234567 "Present in all waves"
	
	*------------ Sample I expect to get, including skippers --------*
	* 8,481 Present in wave 2, 4 and 7
	g wave247=1 if inwave2==1 & inwave4==1 & inwave7==1
		replace wave247=0 if wave247==.
		ta wave247
		label var wave247 "Present in waves 2,4 and 7 regardless of skippers inbetween"
	*----------------------------------------------------------------*	
	
	* So the total number present in waves 2, 4, 5 and 7 are 8,232:
	count if inwave2==1 & inwave4==1 & inwave5==1 & inwave7==1
		// Or 8,481-249=8,232
	
	keep NSID w5skippers
	save "$MyProject/processed/wave_checks", replace


use "$dtao//$w6yp", clear
 keep 	NSID W6finwt_cross W6lsypewt W6lsypew4wt Samppsu Sampstratum ///
		W6IntMonth W6IntYear W6UnivYP W6TCurrentAct W6HEApplyYP W6OffersYP W6AcceptYP W6HETermYP W6SubPrefYP W6SubPref2YP W6SubPrefNoYP0a-W6SubPrefNoYP0g ///
		W6InstPrefYP W6InstPrefNoYP0a- W6InstPrefNoYP0l ///
		W6ActStMYP W6ActStYYP W6HEFlag W6HEFlag2 W6AlevUniYP W6HEqualcomb ///
		W6HEFullYP W6HEQual2YP W6HEHomeYP W6Oxbridge W6Russell ///
		W6HEweighYP W6HEelseYP W6GradebetYP W6UnibetYP W6UnipictYP W6Unipict2YP0a-W6Unipict2YP0o W6DecisYP ///
		W6HeAcptNoYP0a-W6HeAcptNoYP0p W6HENotYP0a-W6HENotYP0s ///
		W6JobYP W6PdwrkYP W6WrkregYP ///
		W6WrkHrsYP W6WHrsChkYP W6Avr2YP ///
		W6PtwrkYP W6Vacwrk3YP W6HESubGroup2 ///
		W6DifFYP W6GrantRecYP0a W6GrantRecYP0b W6GrantRecYP0c ///
		W6FundstudYP0a-W6FundstudYP0i ///
		W6HEApplyYP W6AcceptYP W6HEAcpt2YP W6GapYrYP W6GapdecYP ///
		W6NowgapYP0a W6NowgapYP0b W6NowgapYP0c W6NowgapYP0d W6NowgapYP0e W6NowgapYP0f W6NowgapYP0g ///
		W6DebtattYP ///
		W6PaystatYP0a W6PaystatYP0b W6PaystatYP0c W6PaystatYP0d W6PaystatYP0e W6PaystatYP0f W6PaystatYP0g
	
	sort NSID
	tempfile w6
	save `w6'

use "$dtao//$w7yp", clear 
keep 	NSID W7Mode W7_lsype_wt W7_lsype_wt_skiponly W7finwt ///
		W7IntMonth W7TCurrentAct W7ActContYP W7HETermYP W7ActStillYP W7StillEdChkYP ///
		W7AlevUniYP W7HEApplyYP W7HEQualComb W7HEFlag W7HEFlag2 W7HEFullYP W7HEFullSameYP ///
		W7SubPrefYP W7SubPref2YP W7SubPrefNoYP W7GradebetYP ///
		W7HEQualSameYP W7HEQual2YP W7HECheckYP ///
		W7Disabv1 W7HealthYP W7ACQNo ///
		W7HESubGroup W7HESubSameYP W7HEInstType W7Oxbridge W7Russell ///
		W7HEHomeYP W7HEHomeWYP0a-W7HEHomeWYP0p W7WrkregYP ///
		W7Vacwrk3YP W7PdwrkYP0a W7PdwrkYP0b W7PdwrkYP0c ///
		W7DWrkHrs1YP W7WHrsChk1YP W7Avr21YP W7DWrkHrs2YP W7WHrsChk2YP W7Avr22YP W7DWrkHrs3YP W7Avr23YP W7WHrsChk3YP W7DPayHrAll ///
		W7VolunteerOYP W7VolOFreqYP W7VlWrkhrsYP W7PtwrkYP ///
		W7VolWhyYP0a-W7VolWhyYP0q ///
		W7DifFYP W7GrantRecYP0a W7GrantRecYP0b W7GrantRecYP0c W7StuLoanYP0a W7StuLoanYP0b ///
		W7FundstudYP0a W7FundstudYP0b W7FundstudYP0c W7FundstudYP0d W7FundstudYP0e ///
		W7FundstudYP0f W7FundstudYP0g W7FundstudYP0h W7FundstudYP0k ///
		W7Fat1YP W7Fat5YP W7Fat7YP W7Fat8YP ///
		W7IncomeSourcesYP0a- W7IncomeSourcesYP0j ///
		W7JobYP W7Hours1YP W7HrsChkYP ///
		W7DPay1YP W7PayChkYP W7DPayHrMain W7DPayWkMain W7DPayYrMain W7PayHrMain_Banded W7PayWkMain_Banded W7PayYrMain_Banded ///
		W7HEelseYP W7UnibetYP W7DecisYP W7UnipictYP ///
		W7PaystatYP0a W7PaystatYP0b W7PaystatYP0c W7PaystatYP0d W7PaystatYP0e W7PaystatYP0f W7PaystatYP0g W7Pla16YP ///
		W7NextYearYP W7ImpJobYP W7ImpFamYP0a W7ImpFamYP0b ///
		W7JobEnd2YP W7JobEndSICB W7JobEndSOCB 
	
	/*
		W7PayHrAll_Banded W7PayWkAll_Banded W7PayYrAll_Banded // W7DNoJob2YP W7FixhrYP W7DiffhrsYP W7DFixraYP ///
		W7DPay1YP W7DPay2YP W7DPayHrAll W7DPayHrMain W7DPayWkAll W7DPayWkMain W7DPayYrAll W7DPayYrMain ///
		W7TothrsYP W7TothrschkYP W7TotPayChkYP W7TotPayYP W7NMWMain ///
		*/
		
	merge 1:1 NSID using `w6'
	
/*	 NOTE: Fundstud:
	− Borrowing money from a bank or similar organisation. This includes credit cards or
	overdrafts etc
	− Sponsorship or financial support from an employer
	− Doing paid work during term-time
	− Doing paid work during the holidays
	− Money from parents or other family members
	− Money from friends
	− Your own savings
	− Supported by parents such as paying tuition fees, accommodation costs or other living costs
	− Money from anywhere else
*/
	keep if _merge==3 	// keeping those present in both waves only 
	drop _merge
	
	save "$MyProject/processed/wave67.dta", replace 


*--------------------------------------------------------
*** ADDING BACKGROUND CHARACTERISTICS 
	* Starting from WAVE 5, going BACKWARDS.
*--------------------------------------------------------	
	* Wave 5 - Age 17/18
	*-------------------
	use NSID W5SexYP W5actYP W5JobYP W5Hours1YP W5IntMonth W5IntYear W5HeapplyYP ///
	W5AcceptYP W5Heposs9YP W5GapyearYP W5ActStMYP W5ActStYYP W5AlevUniYP W5debtattYP ///
	Samppsu Sampstratum ///
	W5HEsub1YP-W5HEsub23YP W5Subreas1YP-W5Subreas6YP W5WhyChosYP0a- W5WhyChosYP0r ///
	W5EMA1YP W5EMA2BYP ///
	using "$dtao\\$w5yp", clear
	rename Samppsu 		samppsu_w5
	rename Sampstratum	sampstratum_w5
	tempfile wave5
	save `wave5'
	
	* No income for wave 5 family background 

	* Wave 4 - age 16/17
	*-------------------
	use NSID W4Hours1YP W4ethgrpYP W4SexYP W4MainActYP W4HarmChkYP W4schatYP W4EMA1YP ///
	using "$dtao\\$w4yp", clear
	tempfile w4yp
	save `w4yp'
	
	use "$dtao//$w4fb", clear
	
	 keep NSID W4intmonth W4intyear ///
	 w4famtyp w4lnpar ///
	 w4sibs w4sibs2 ///
	 w4hiqualgMP w4hiqualgmum w4hiqualgdad w4hiqualgfam ///
	 w4hiqualfam w4hiqualgfam w4cnssecfam w4cnsseccatfam ///
	 w4IncEstM
	 
	 //NOTE: Derived information for MP is from Wave 1 or Wave 2
	 merge 1:1 NSID using `w4yp', nogen 
	 
	 tempfile wave4
	 save `wave4'
	
	* Wave 3 - age 15/16
	*-------------------
	use "$dtao//$w3yp", clear
	keep NSID W3sexYP ///
	W3jobYP W3jobtimeYP W3jobearnYP W3jobfamYP W3famsupYP W3yschat1 ///
	W3plann16YP W3dec16aYP W3reas16aYP0a W3reas16aYP0b W3reas16aYP0c W3reas16aYP0d W3reas16aYP0e W3reas16aYP0f W3reas16aYP0g W3reas16aYP0h W3reas16aYP0i W3reas16aYP0j W3reas16aYP0k W3reas16aYP0l W3reas16aYP0m W3reas16aYP0n W3reas16aYP0o W3reas16aYP0p W3reas16aYP0q W3reas16aYP0r W3reas16aYP0s ///
	W3pladk16aYP0a W3pladk16aYP0b W3pladk16aYP0c W3pladk16aYP0d W3pladk16aYP0e W3pladk16aYP0f W3pladk16aYP0g W3pladk16aYP0h ///
	W3pladk16bYP0a W3pladk16bYP0b W3pladk16bYP0c W3pladk16bYP0d W3pladk16bYP0e W3pladk16bYP0f W3pladk16bYP0g W3pladk16bYP0h ///
	W3plan16YP W3hesubYP16 ///
	W3emaapYP W3emasuYP
		sort NSID 
		
		tempfile w3yp
		save `w3yp'
		
	use  "$dtao//$w3fb", clear
		keep NSID W2toW3nrwt W3finwt W3intmnthMP W3intyearMP W3wrkcurMP W3wrkcurSP W3wrkcurdad W3wrkcurmum ///
		W3cnsseccatfam W3cnssecfam ///
		W3incestm W3incestw W3agebd5MP W3agebd10MP W3relMP W3agebd5SP W3agebd10SP W3relSP ///
		W3agebd5mum W3agebd10mum W3agebd5dad W3agebd10dad ///
		W3depkids W3ch0_2HH W3ch3_11HH W3ch12_15HH W3ch16_17HH W3natparHH W3stepfam W3famtyp W3lnpar ///
		W3sibs urbind gor IDACIRSCORE IMDRSCORE W3incestMP
		
		merge 1:1 NSID using `w3yp', nogen 
		
	tempfile wave3
	save `wave3'
	
	* Wave 2 - age 14/15
	*--------------------
	use "$dtao//$w2yp", clear
	keep NSID SampPSU SampStratum W2Fat1YP W2Fat5YP W2Fat7YP W2Fat8YP ///
	W2ghq12scr W2ghqg W2SexYP ///
	W2jobYP W2jobYP W2JobTimeYP W2JobEarnYP W2famsupYP W2yschat1 ///
	W2plann16YP W2plast16YP W2yleav16YP0a W2yleav16YP0b W2yleav16YP0c W2yleav16YP0d W2yleav16YP0e W2yleav16YP0f W2yleav16YP0g W2yleav16YP0h W2yleav16YP0i W2yleav16YP0j ///
	W2Pladk16YP0a W2Pladk16YP0b W2Pladk16YP0c W2Pladk16YP0d W2Pladk16YP0e W2Pladk16YP0f W2Pladk2YP0a W2Pladk2YP0b W2Pladk2YP0c W2Pladk2YP0d W2Pladk2YP0e W2Pladk2YP0f W2fplan16YP W2YYS16YP ///
	W2ChPreYP0f
		sort NSID
	
	rename SampPSU 		sampw2
	rename SampStratum 	stratw2
		tempfile w2yp
		save `w2yp'
		
	use "$dtao//$w2fb", clear
	keep NSID w2intmonthMP w2intyearMP ///
	W2hiqualgMP W2hiqualMP W2hiqualgmum W2hiqualgdad W2hiqualgfam  ///
	W2nssecfam W2nsseccatfam ///
	W2famtyp W2ethgrpYP ///
	W2Inc1estMP 
		
		merge 1:1 NSID using `w2yp', nogen
		
	tempfile wave2
	save `wave2'
	
	* Wave 1 - age 13/14
	*-------------------
	use "$dtao//$w1yp", clear
	keep 	NSID DobyearYP DobmonthYP W1sexYP ///
			W1domhrsYP W1jobYP W1jobtimeYP W1jobearnYP W1famsupYP W1yschat1 ///
			W1ethgrpYP ///
			W1plann16YP W1plast16YP W1pladk16YP W1pladk2YP W1fplan16YP W1plan16YP W1pla16YP W1yys16YP ///
			W1dwhopreYP0f W1chpreYP0f	///
			SampPSU SampStratum
			
		rename SampPSU 		samppsu_w1
		rename SampStratum	sampstratum_w1
	sort NSID
		
		tempfile w1yp
		save `w1yp'
	
	use "$dtao//$w1fb", clear
	keep NSID w1intmonthMP w1intyearMP ///
	W1hiqualgMP W1hiqualgmum W1hiqualgdad ///
	W1nssecfam W1nsseccatfam W1nssecmum W1nssecdad W1nssecMP ///
	W1famtyp W1famtyp2 ///
	W1NoldsibHS W1NoldBroHS ///
	W1managhhMP W1inc1est W1inc1estMP W1SOCMajorMP W1louneMP W1hous12HH ///
	W1benchildMP W1benunempMP W1benlowincMP W1bendisMP W1benberMP W1benothMP
	
		merge 1:1 NSID using `w1yp', nogen
		
		* Merging wave 1, 2, 4, 6 & 7 
		merge 1:1 NSID using `wave2'
		keep if _merge==3
		drop _merge
		
		merge 1:1 NSID using `wave3'
		keep if _merge==1 | _merge==3
		drop _merge
		
		merge 1:1 NSID using `wave4'
		keep if _merge==3 
		// Keep those present in wave 2 and 4 only
		// If in wave 2 only -> don't see them later
		// If in wave 4 only -> boost sample
		drop _merge
		merge 1:1 NSID using `wave5'
		keep if _merge==3
		drop _merge
		
		tempfile bg_data
		save `bg_data'
		
		***** Creating one datafile up to wave 7 with wave 2 and 4 background **
		use `bg_data', clear
		merge 1:1 NSID using "$MyProject/processed/wave67.dta"
		
		// _merge=1 are those present in waves 2 and 4, not 6 and 7
		// _merge=2 are those present only in 6 and 7, not in waves 2 and 4
		// _merge=3 present in all 
		
		keep if _merge==3 
			drop _merge
			merge 1:1 NSID using "$MyProject/processed/wave_checks"
			keep if _merge==3
			save "$MyProject/processed/merge.dta", replace	
		
			
		************************************************************************ 
		** EOF
		
