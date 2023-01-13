* Date: 01 July 2021
* Try to describe university students' types of work using APS
*--------------------------------------------------------------			

* Preamble (unnecessary when executing run.do)
global MyProject "C:/Users/Radrie/Dropbox/PhD Research/Paper_2/stata_folder/"
global rootdata "D:\Data\APS\"
// APS survey (Jan-Dec)
global 	aps09	"$rootdata\UKDA-6514-stata11\stata11\apsp_jd09_eul.dta"
global	aps10	"$rootdata\\UKDA-6809-stata11\stata11\apsp_jd10_eul_inclu_smoking.dta"
// APS survey (Oct 09 - Sep 10)
global 	apsos 	"$rootdata\\UKDA-6754-stata11\stata11\apsp_o09s_eul.dta"
// APS survey (Jul 09 - Jun 10)
global 	apsjj 	"$rootdata\\UKDA-6656-stata11\stata11\apsp_j09j_eul.dta"
// APS household survey (Jan - Dec)
global 	haps09	"$rootdata\\UKDA-7151-stata11\stata11\apsh_jd09_eul.dta"
global 	haps10 	"$rootdata\\UKDA-7152-stata11\stata11\apsh_jd10_eul.dta"

use $haps10, clear
 
* Jan - Dec 09
*--------------
use $aps09, clear
// Identify only university students 
keep if course==4
keep if age>=19 & age<=21
	
	keep 	idref REFDTE refwkm refwky prxrel lfssamp PWTA14 thiswv ///
			age sex attend hallres country govtof conmon conmpy cry01 ethwh nation ///
			ilodefr inecac05 ftpt wrking ///
			acthr bacthr bushr inds07l inds07m inde07m sc2klmj sc2klmn sc2kmmj sc2kmmn jobtmp ///
			redpaid redund redylft sc2klmj sc2klmn wnleft ///
			ed13wk look4
	* Note: be sure not to include those in training with education bc they would be in different form of educ
	
ta attend
// mostly still attending FT university/college

ta hallres
// Few living in halls of residence 

ta sex
// 50-50 split of sex

ta country
// The majority here are English
ta govtof

ta ilodefr
// 34% in employment, 6.7% unemployed, 59.26% inactive
ta ftpt
// Majority in part-time work
ta wrking
// 30% were working in current week

ta inde07m
/*
         Industry sector in main job |      Freq.     Percent        Cum.
-------------------------------------+-----------------------------------
                      Does not apply |      2,388       66.22       66.22
                           No answer |         11        0.31       66.53
   Agriculture, forestry and fishing |          6        0.17       66.69
                    Energy and water |          5        0.14       66.83
                       Manufacturing |         24        0.67       67.50
                        Construction |         12        0.33       67.83
Distribution, hotels and restaurants |        779       21.60       89.43
         Transport and communication |         27        0.75       90.18
                 Banking and finance |         72        2.00       92.18
  Public admin, education and health |        160        4.44       96.62
                      Other services |        122        3.38      100.00
-------------------------------------+-----------------------------------
                               Total |      3,606      100.00
*/

ta sc2kmmj

/*
      Major occupation group (main job) |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
                         Does not apply |      2,388       66.22       66.22
                              No answer |          3        0.08       66.31
        1 Managers and Senior Officials |         22        0.61       66.92
             2 Professional occupations |         27        0.75       67.67
 3 Associate Professional and Technical |         75        2.08       69.74
       4 Administrative and Secretarial |         82        2.27       72.02
           5 Skilled Trades Occupations |         28        0.78       72.80
         6 Personal Service Occupations |        105        2.91       75.71
7 Sales and Customer Service Occupation |        473       13.12       88.82
8 Process, Plant and Machine Operatives |         15        0.42       89.24
               9 Elementary Occupations |        388       10.76      100.00
----------------------------------------+-----------------------------------
                                  Total |      3,606      100.00
*/
tempfile data09
save `data09'

use $aps10, clear
keep if course==4 
keep if age>=19 & age<=21
	keep 	idref REFDTE refwkm refwky prxrel lfssamp PWTA14 thiswv ///
			age sex attend enroll hallres country govtof conmon conmpy cry01 ethwh ntnlty ///
			ilodefr inecac05 ftpt wrking ///
			acthr bacthr bushr ttushr inds07l inds07m inde07m sc2klmj sc2klmn sc2kmmj sc2kmmn jobtyp ///
			redpaid redund redylft sc2klmj sc2klmn wnleft ///
			ed13wk look4 ///
			relbus ownbus
	
	recode inde07m (-8=-9)
	recode inde07m (-9=.)
	ta inde07m, gen(industry)
	g occupations=sc2kmmj if sc2kmmj>0 & sc2kmmj<.
	label values occupations sc2kmmj
	ta occupations, gen(occ)
	
	recode attend (2=0)
	g inemp=1 if ilodefr==1
	replace inemp=0 if ilodefr>=2 & ilodefr<=3
	label define inemp_L 0"Not employed" 1"Employed"
	label values inemp inemp_L 
	
	g pttm=1 		if ftpt==2 
	replace pttm=0 	if ftpt==1
	
	replace hallres=. if hallres==-9
	recode hallres (2=0)
	
	ta country, gen(cty)
				
	g nomiss_sample=1 if occ1!=. & occ2!=. & occ3!=. & occ4!=. & occ5!=. & occ6!=. ///
						& occ7!=. & occ8!=. & occ9!=. & industry1!=. & industry2!=. & industry3!=. ///
						& industry4!=. & industry5!=. & industry6!=. & industry7!=. & industry8!=. ///
						& industry9!=. & sex!=. & inemp==1 & relbus!=1 & ownbus!=1
	
	est clear
	estpost su 	attend age inemp cty1 cty2 cty3 cty4 cty5 if sex==1 [w=PWTA14]
				est store male_general
	
	estpost su 	attend age inemp pttm cty1 cty2 cty3 cty4 cty5 if sex==2 [w=PWTA14]
				est store female_general 
			
	estpost su	pttm ttushr occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
				industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
				if sex==1 & nomiss_sample==1 [w=PWTA14]
				est store desc_male
				
	estpost su	pttm ttushr occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
				industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
				if sex==2 & nomiss_sample==1 [w=PWTA14]
				est store desc_female
		
	estpost ttest pttm ttushr occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
				industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
				if nomiss_sample==1, by(sex)
				est store ttest_sex
				
			esttab male_general female_general desc_male desc_female ttest_sex using "$MyProject/results/tables/apswork_bysex.rtf", modelwidth(10 15) ///
			mtitle("Male" "Female" "Male" "Female" "t-test") ///
			cell("mean(pattern(1 1 1 1 0) fmt(3)) b(star pattern(0 0 0 0 1) fmt(2))") wide label nonumber replace

	* Checking differences during term-time and during "holidays"/waiting for term to restart

	bys attend: ta(ilodefr)
	// 		Majority are in term (n=2915)
	//		In term, 31.56% are employed 
	//		Waiting for term to restart, 44.28% are employed (n=691)
	
	bys attend: ta sc2kmmj if ilodefr==1
	// 		In both periods, the vast majority are still working in sales and customer service operations/elementary occupations
	
	eststo all: estpost su occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
					industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
					if nomiss_sample==1 [w=PWTA14]
					
	eststo interm: estpost su occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
					industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
					if nomiss_sample==1 & attend==1 [w=PWTA14]
	
	eststo offterm: estpost su occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
					industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
					if nomiss_sample==1 & attend==0 [w=PWTA14]
	
	eststo diff: estpost ttest occ1 occ2 occ3 occ4 occ5 occ6 occ7 occ8 occ9 ///
					industry1 industry2 industry3 industry4 industry5 industry6 industry7 industry8 industry9 ///
					if nomiss_sample==1, by(attend) unequal 
	
			esttab all interm offterm diff using "$MyProject/results/tables/apswork_byattend.rtf", modelwidth(10 15) ///
			mtitle("All" "In term" "Off term" "Diff") ///
			cell("mean(pattern(1 1 1 0) fmt(2)) b(star pattern(0 0 0 1) fmt(2))") wide label nonumber replace
		
			x
			
ta inde07m
	// Majority also working in distribution, hotels, and restaurants 
ta sc2kmmj
	// Majority are sales/customer service occupation

	* For male
	ta inde07m attend if sex==1 & inde07m>0 [w=PWTA14]
	* For female
	ta inde07m attend if sex==2 & inde07m>0 [w=PWTA14]
		// Slightly more females in public administration, education and health
	
	* For male
	ta sc2kmmn attend if sex==1 & sc2kmmj>0 [w=PWTA14]
	* For female
	ta sc2kmmn attend if sex==2 & sc2kmmj>0 [w=PWTA14]
		/// Most of students are in elementary occupations but slightly more females in personal service occupations, 
		/// and slightly more males in associate, professional and technical
