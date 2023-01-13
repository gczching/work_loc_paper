******************************************************************
* OVERVIEW
*   This script generates tables and figures for the paper:
*       "My Project" 
*	All temporary data files are outputted to /processed
*   All tables are outputted to /results/tables
*   All figures are outputted to /results/figures
*
*	Author				: Grace Chang
*	Date last modified	: January 2023
*	Check log for more accurate information of last process.
* Contents: 1. Project description
*           2. Overview, log file
*           3. Do files
*				1. data merging 
*				2. data cleaning
*				3. definitions
*				4. descriptive statistics
*				5. regression analysis
*				6. robustness
*				7. multiple imputation
*				8. IPW
******************************************************************

* 1. Project description
	/*
	Using Next Steps data, mainly focusing on wave 7 (but using waves 1 to 6 for background characteristics)
	I am analysing how engaging in paid work during university affects students' locus of control	
	*/
	
* 2. Overview, log file:
global MyProject "/Users//`=c(username)'/Dropbox/PhD Research/Paper_2/stata_folder/"

* Confirm that the globals for the project root directory have been defined
assert !missing("$MyProject")

	*----------------------------------------------
	* Initialize log and record system parameters
	clear
	set more off
	cap mkdir "$MyProject/scripts/logs"
	cap log close
	local datetime : di %tcCCYY.NN.DD!-HH.MM.SS `=clock("$S_DATE $S_TIME", "DMYhms")'
	local logfile "$MyProject/scripts/logs/`datetime'.log.txt"
	log using "`logfile'", text

	di "Begin date and time: $S_DATE $S_TIME"

	* All required Stata packages are available in the /libraries/stata folder
	*adopath ++ "$MyProject/scripts/libraries/stata"
	*mata: mata mlib index

	* R packages can be installed manually (see README) or installed automatically by uncommenting the following line
	* if "$DisableR"!="1" rscript using "$MyProject/scripts/programs/_install_R_packages.R"

	* Stata programs and R scripts are stored in /programs
	*adopath ++ "$MyProject/scripts/programs"

	* Create directories for output files
	cap mkdir "$MyProject/processed"
	cap mkdir "$MyProject/results"
	cap mkdir "$MyProject/results/figures"
	cap mkdir "$MyProject/results/intermediate"
	cap mkdir "$MyProject/results/tables"
	*----------------------------------------------
	
* 3. Do files:

** Data merging and cleaning
*===========================
	do "$MyProject/scripts/Finalised/1.0_merge_data.do"
	do "$MyProject/scripts/Finalised/2.0_clean_data.do"
	
** Defining variables
*=============================
	// Consists of all the LOC measures (W2, W7 for checks) 
	do "$MyProject/scripts/Finalised/3.0_definitions_loc.do"
	
	do "$MyProject/scripts/Finalised/3.1_definitions_work&controls.do"

**	Descriptive statistics
*============================

	do "$MyProject/scripts/Finalised/4.0_descriptives.do"  
	
	do "$MyProject/scripts/Finalised/4.1_descriptivesAPS.do"

** Regression analysis
*============================
	// Main estimates	
	do "$MyProject/scripts/Finalised/5.0_regressions.do"
	
	do "$MyProject/scripts/Finalised/6.0_robust.do"
	
** Multiple imputation
*============================
	do "$MyProject/scripts/Finalised/7.0_mi_impute.do"
	
	do "$MyProject/scripts/Finalised/7.1_mi_impute.do"

** IPW
*=================================
	do "$MyProject/scripts/Finalised/8.0_IPW.do"

* End log
di "End date and time: $S_DATE $S_TIME"
log close

** EOF
