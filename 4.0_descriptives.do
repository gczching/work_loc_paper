* Descriptive statistics about:
	* BG char of those who work vs not
	* LOC difference between those who work vs not
	* LOC difference between university subjects 
*--------------------------------------------------			

* Preamble (unnecessary when executing run.do)
*do "$MyProject/scripts/programs/_config.do"
	global MyProject "C:\Users\User\Dropbox\PhD Research\Paper_2\stata_folder\"

	use "$MyProject/processed/clean_processed.dta", clear
		
	svyset [pweight=W7finwt], psu(samppsu_w1) strata(sampstratum_w1) singleunit(centered)
	svydescribe

	set graphics off
	g double wt=round(W7finwt*100)
	
	* Hours of work
	*==============
	
	ta wrk_period2 if sampleterm==1
	ta wrk_holiday if samplerethol==1
	

	* FIGURE A3: Science subject, by sex
	label define science_L 0 "Non-science" 1"Science", replace
	label values w7science science_L
		
	set graphics off
	graph bar wrk_term [fw=wt], over(sex) by(w7science, note("")) 	ylabel(0(0.2)1) name(sexsubterm, replace) ytitle(Proportion in term-time work) scheme(s1mono) blabel(bar, position(outside) format(%9.2f) color(black) size(medlarge))
	graph bar wrk_vac [fw=wt], over(sex) by(w7science, note("")) 	ylabel(0(0.2)1) name(sexsubvac, replace) ytitle(Proportion in Summer work)  scheme(s1mono) blabel(bar, position(outside) format(%9.2f) color(black) size(medlarge))
	graph bar wrk_chris [fw=wt], over(sex) by(w7science, note("")) 	ylabel(0(0.2)1) name(sexsubchris, replace) ytitle(Proportion in Christmas work)  scheme(s1mono) blabel(bar, position(outside) format(%9.2f) color(black) size(medlarge))
	graph bar wrk_easter [fw=wt], over(sex) by(w7science, note("")) ylabel(0(0.2)1) name(sexsubeas, replace) ytitle(Proportion in Easter work)  scheme(s1mono) blabel(bar, position(outside) format(%9.2f) color(black) size(medlarge))
	set graphics on
	graph combine sexsubterm sexsubvac sexsubchris sexsubeas, scheme(s1mono) scale(*1.2)
	
	graph export "$MyProject/results/figures/FigA3.tif", as(tif) replace
	graph export "$MyProject/results/figures/Fig. A3.svg", as(svg) replace
	
	* Changes in LOC
	*===============
	
	g changeLOC=0 if locusw2==locusw7
	replace changeLOC=1 if locusw2<locusw7
	replace changeLOC=2 if locusw2>locusw7
	label var changeLOC "How LOC changed between waves 2 and 7"
	label define changeLOC_L 0"No change" 1"Increase" 2"Decrease"
	label values changeLOC changeLOC_L
	svy: ta changeLOC if sampleuni==1
	svy: ta changeLOC if wrk_term==1
	svy: ta changeLOC if wrk_term==0
	
	tabstat locusw2 locusw7 [w=W7finwt], stat(p50 mean sd)
	tabstat W2work W7work W2decide W7decide W2luck W7luck W2fault W7fault , stat(p50 mean sd)
	graph box stdfa_locw7 stdfa_locw2 [fw=wt], ytitle("locus of control")  scheme(s1mono)
	
	preserve
	keep NSID W7finwt locusw2 locusw7 
	reshape long locusw, i(NSID) j(wave)
	su locusw if wave==2 | wave==7 [w=W7finwt] //SD==1.63
	restore 
	
	* Histogram of hours worked
	*===========================
	set graphics off
	graph set window fontface arial
	
	twoway hist hr_term if hr_term>0 & sampleuni==1 [fw=wt], percent scheme(s1mono) ///
	xlab(0(10)70, valuelabel) xtitle("") discrete scale(*1.5) ///
	title("(a) Term-time", size(medium)) name(hr_term, replace)
	 
	twoway hist hr_vac if hr_vac>0 & sampleuni==1 [fw=wt], percent scheme(s1mono) ///
	xlab(0(10)70, valuelabel) ytitle("") xtitle("") discrete scale(*1.5) ///
	title("(b) Summer", size(medium)) name(hr_vac, replace)
	
	twoway hist hr_easter if hr_easter>0 & sampleuni==1 [fw=wt], percent scheme(s1mono) ///
	xlab(0(10)70, valuelabel) discrete xtitle("Average hours worked per week") scale(*1.5) ///
	title("(c) Easter", size(medium)) name(hr_easter, replace)
	
	twoway hist hr_chris if hr_chris>0 & sampleuni==1 [fw=wt], percent scheme(s1mono) ///
	xlab(0(10)70, valuelabel) ytitle("")  discrete xtitle("Average hours worked per week") scale(*1.5) ///
	title("(c) Christmas", size(medium)) name(hr_chris, replace)
	
	set graphics on
	graph combine hr_term hr_vac hr_easter hr_chris, scheme(s1mono) ycommon
	graph export "$MyProject/results/figures/wrkhours.tif", as(tif) replace
	graph export "$MyProject/results/figures/wrkhours.svg", as(svg) replace
	

	* GLOBAL THE CONTROLS 
	*---------------------
	global bgcontrols_cnt	sex ethnic W7Disabv1 unigrant uniwave   
	global bgcontrols_bin	W7Russell mparent_educ fam_cmp numsib 
	global controls_sub		w7science
	global priorcontrols	w1_hhmanage received_ema schoolatt2 ownhouse
		*-----------------------------------------------------------------------------------------------------------------
		
	* Check characteristics of missings
	*===================================
	est clear
	
	preserve
	
	g sampletest=1 if sampleterm==1
	replace sampletest=0 if sampletermdk==1 & sampletest==.
	
	*T-test by sample
	eststo test_n: estpost ttest wrk_uni wrk_term wrk_vac  $bgcontrols_cnt $bgcontrols_bin, by(sampletest) unequal
	
	* Word export 
	esttab test_n using "$MyProject/results/tables/test_diffdk.rtf", modelwidth(10 15) ///
	cell("mu_1(fmt(2)) mu_2(fmt(2)) b(star fmt(3))") wide label nonumber replace
	
	g sampletest2=1 		if samplerethol==1
	replace sampletest2=0 	if sampleretholdk==1 & sampletest2==.
	
	*T-test by sample
	eststo test_n: estpost ttest wrk_chris wrk_easter $bgcontrols_cnt $bgcontrols_bin, by(sampletest2) unequal
	
	* Word export 
	esttab test_n using "$MyProject/results/tables/test_diffdk.rtf", modelwidth(10 15) ///
	cell("mu_1(fmt(2)) mu_2(fmt(2)) b(star fmt(3))") wide label nonumber append
		
	replace sampleterm=0 if sampleterm!=1
	
	eststo test_n: estpost ttest wrk_uni wrk_term wrk_vac wrk_chris wrk_easter $bgcontrols_cnt $bgcontrols_bin, by(sampleterm) unequal
		
	esttab test_n using "$MyProject/results/tables/test_diffdk.rtf", modelwidth(10 15) ///
	cell("mu_1(fmt(2)) mu_2(fmt(2)) b(star fmt(3))") wide label nonumber append
	
	restore
	
	* Background characteristics of those who work vs not
	*===============================================================
		* TOTAL (EVER WORKED)
	preserve
		est clear
		keep if sampleterm==1 
		estpost su pf_locw7 locusw7 wrk_uni $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols   if wrk_uni==0 [w=W7finwt]
		est store nowork
		
		estpost su pf_locw7 locusw7 wrk_uni $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols   if wrk_uni==1 [w=W7finwt]
		est store work 
		
		eststo diff: estpost ttest ///
		pf_locw7 locusw7 wrk_uni $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols, by(wrk_uni) unequal 
		
		* Word export 
			esttab nowork work diff using "$MyProject/results/tables/table_controls.rtf", modelwidth(10 15) ///
			mtitle("Not worked" "Worked term-time" "Diff") ///
			cell("mean(pattern(1 1 1) fmt(2)) b(star pattern(0 0 1) fmt(2))") wide label nonumber replace
		
	restore
		
		* Term-time and Summer work
		est clear
		keep if sampleterm==1
		
		estpost su  locusw7 pf_locw7 wrk_term hr_term $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols   if wrk_term==1 [w=W7finwt]
		est store twork	
		estpost su  locusw7 pf_locw7 wrk_term hr_term $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols    if wrk_term==0 [w=W7finwt]
		est store notwork
		eststo tdiff: estpost ttest ///
		pf_locw7 locusw7 wrk_term hr_term $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols , by(wrk_term) unequal 
		
		
		estpost su  locusw7 pf_locw7 wrk_vac hr_vac $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols   if wrk_vac==1  [w=W7finwt]
		est store vwork		
		estpost su  locusw7 pf_locw7 wrk_vac hr_vac $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols    if wrk_vac==0  [w=W7finwt]
		est store novwork
		eststo sdiff: estpost ttest ///
		pf_locw7 locusw7 wrk_vac hr_vac $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols , by(wrk_vac) unequal 
		
		* Word export 
			esttab  notwork twork tdiff using "$MyProject/results/tables/table_term.rtf", modelwidth(10 15) ///
			mtitle("Not Worked" "worked" "Diff") ///
			cell("mean(pattern(1 1 1) fmt(2)) b(star pattern(0 0 1) fmt(2))") wide label nonumber replace
			
			esttab  novwork vwork sdiff using "$MyProject/results/tables/table_summer.rtf", modelwidth(10 15) ///
			mtitle("Not Worked" "worked" "Diff") ///
			cell("mean(pattern(1 1 1) fmt(2)) b(star pattern(0 0 1) fmt(2))") wide label nonumber replace
			
			
		* Christmas and Easter
		keep if samplerethol==1

		estpost su pf_locw7 locusw7 wrk_easter hr_easter $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols    if wrk_easter==1 [w=W7finwt]
		est store ework	
		estpost su pf_locw7 locusw7 wrk_easter hr_easter $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols     if wrk_easter==0 [w=W7finwt]
		est store enotwork
		
		eststo ediff: estpost ttest ///
		pf_locw7 locusw7 wrk_chris hr_chris $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols , by(wrk_easter) unequal 
				
		estpost su pf_locw7 locusw7 wrk_chris hr_chris $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols     if wrk_chris==1 [w=W7finwt]
		est store cwork		
		estpost su pf_locw7 locusw7 wrk_chris hr_chris $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols    if wrk_chris==0 [w=W7finwt]
		est store cnotwork
		
		eststo cdiff: estpost ttest ///
		pf_locw7 locusw7 wrk_chris hr_chris $bgcontrols_cnt w7science $bgcontrols_bin $priorcontrols, by(wrk_chris) unequal 
		
			
			esttab  cnotwork cwork cdiff using "$MyProject/results/tables/table_chris.rtf", modelwidth(10 15) ///
			mtitle("Not worked" "worked" "Diff") ///
			cell("mean(pattern(1 1 1) fmt(2)) b(star pattern(0 0 1) fmt(2))") wide label nonumber replace
			
			esttab  enotwork ework ediff using "$MyProject/results/tables/table_easter.rtf", modelwidth(10 15) ///
			mtitle("Not worked" "worked" "Diff") ///
			cell("mean(pattern(1 1 1) fmt(2)) b(star pattern(0 0 1) fmt(2))") wide label nonumber replace
			
		restore

