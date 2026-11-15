// TECHNICAL REPORT| QUARTERLY LABOUR FORCE SURVEY 
//COMPARATIVE ANALYSIS QLFS QUARTER 1
// NOVEMBER 11 2026
 version 19.5
 clear all
 cap log close
 set more off
 set varabbrev off
 cd "C:\Users\tawon\Documents\DATA WORKSHOP\2025 DATA"
	log using "Quarterly Labour Force Survey (Q1)", replace text
	use qlfs-2025-q1-worker-v1.dta
	
//SMALL BUSINESSES AND EMPLOYMENT CREATION
codebook Weight STRATUM UQNO
*--------------------------------------------------------------------
* Restrict to working-age population
gen working_age = (Q14AGE >= 15)
label define workingage 0 "Below 15" 1 "15 years and older"
label values working_age workingage

keep if working_age == 1

*--------------------------------------------------------------------
* Survey design
svyset UQNO [pweight=Weight], strata(STRATUM) singleunit(centered)

* Check survey design
svydescribe

* Employment status
codebook Status
gen employed = (Status == 1) if !missing(Status)
label define employedlbl 0 "Not employed" 1 "Employed"
label values employed employedlbl

* Female
codebook Q13GENDER
gen female = (Q13GENDER == 2) if !missing(Q13GENDER)
label define femalelbl 0 "Male" 1 "Female"
label values female femalelbl

* Youth
* South African/standard policy definition: 15–34 years
gen youth = inrange(Q14AGE,15,34) if !missing(Q14AGE)
label define youthlbl 0 "35 years and older" 1 "Youth 15–34"
label values youth youthlbl

* Broad age groups
gen agegrp = .
replace agegrp = 1 if inrange(Q14AGE,15,24)
replace agegrp = 2 if inrange(Q14AGE,25,34)
replace agegrp = 3 if inrange(Q14AGE,35,44)
replace agegrp = 4 if inrange(Q14AGE,45,54)
replace agegrp = 5 if inrange(Q14AGE,55,64)
replace agegrp = 6 if Q14AGE >= 65

label define agegrplbl ///
    1 "15–24" ///
    2 "25–34" ///
    3 "35–44" ///
    4 "45–54" ///
    5 "55–64" ///
    6 "65+"

label values agegrp agegrplbl

*--------------------------------------------------------------------
* Employer/business size
*--------------------------------------------------------------------
codebook Q416NRWORKERS
gen firm_size = .
replace firm_size = 0 if Q416NRWORKERS == 0
replace firm_size = 1 if Q416NRWORKERS == 1
replace firm_size = 2 if Q416NRWORKERS == 2
replace firm_size = 3 if Q416NRWORKERS == 3
replace firm_size = 4 if Q416NRWORKERS == 4
replace firm_size = 5 if Q416NRWORKERS == 5
replace firm_size = 6 if Q416NRWORKERS == 6
label define firmsize ///
    0 "0 employees" ///
    1 "1 employee" ///
    2 "2–4 employees" ///
    3 "5–9 employees" ///
    4 "10–19 employees" ///
    5 "20–49 employees" ///
    6 "50+ employees"
label values firm_size firmsize

*--------------------------------------------------------------------
* Small business: <50 employees
*--------------------------------------------------------------------
gen small_business = inlist(firm_size,0,1,2,3,4,5) ///
    if !missing(firm_size)
label define smalllbl ///
    0 "Large business (50+)" ///
    1 "Small business (<50)"

label values small_business smalllbl

*--------------------------------------------------------------------
* Alternative size classification
* Useful for robustness checks
*----------------------------------------------------------------
gen micro = inlist(firm_size,0,1,2) if !missing(firm_size)
gen small10 = inlist(firm_size,0,1,2,3) if !missing(firm_size)
gen medium_large = firm_size >= 4 if !missing(firm_size)

///RQ1: To what extent do small businesses contribute to employment creation in South Africa?
*The first analysis should establish the number and percentage of employed people working in businesses of different sizes.
*Employment distribution by business size
*-----------------------------------------------------------------

svy, subpop(if employed == 1): proportion firm_size
svy, subpop(if employed == 1): tabulate firm_size, percent format(%9.2f)

tab firm_size [pw=Weight] if employed == 1, percent

* Estimated Number of Workers Employed by Small Businesses| This estimates the weighted number of employed people working in small businesses. To obtain the percentage:
svy, subpop(if employed == 1): total small_business
svy, subpop(if employed == 1): proportion small_business

/// Comparing large versus small businesses
svy, subpop(if employed == 1): proportion small_business
svy, subpop(if employed == 1): mean small_business

//Employment contribution by firms size and sector
svy, subpop(if employed == 1): tabulate firm_size sector1, ///
    row percent format(%9.2f)
	
* Employment contribution by formal/informal sector 
svy, subpop(if employed == 1): tabulate small_business sector1, ///
    row percent format(%9.2f)

* This is particularly important because small businesses are likely to have a substantial presence in informal employment
// RQ2: What factors determine whether small businesses employ additional workers? This question should focus on business owners/self-employed persons, rather than all workers.
// The variable Q45WRK4WHOM provides an excellent basis for this: - Own account worker — no employees. - Employer — employing one or more employees. Therefore, define:
* Employer status among self-employed persons
codebook Q45WRK4WHOM
gen employer = .
replace employer = 0 if Q45WRK4WHOM == 3
replace employer = 1 if Q45WRK4WHOM == 2
label define employerlbl ///
    0 "Own-account worker" ///
    1 "Employer"
label values employer employerlbl
// Restrict the analysis to self-employed persons
gen selfemployed = inlist(Q45WRK4WHOM,3,2) & !missing(Q45WRK4WHOM)
label values selfemployed employerlbl
browse Q45WRK4WHOM selfemployed

// Explanatory variables for RQ2
gen age2 = Q14AGE^2
tab Q17EDUCATION
label list Q17EDUCATION
*--------------------------------------------------------------
* 1. Group Q17EDUCATION into 5 categories
recode Q17EDUCATION ///
    (98 = 1 "No schooling") ///
    (0/7 = 2 "Primary (Grade R–7)") ///
    (8/11 = 3 "Secondary incomplete (Grade 8–11)") ///
    (12/13 = 4 "Matric / Grade 12") ///
    (14/29 = 5 "Post-secondary / Tertiary") ///
    (30 31 = .) ///          /* Other & Don't know → missing */
    , gen(EducLevel)

label var EducLevel "Education level (5 categories)"
tab EducLevel, missing

*--------------------------------------------------------------
* 2. Approximate years of schooling
gen educ_years = .
replace educ_years = 0  if Q17EDUCATION == 98          // No schooling
replace educ_years = 0  if Q17EDUCATION == 0           // Grade R/0
replace educ_years = 1  if Q17EDUCATION == 1           // Grade 1
replace educ_years = 2  if Q17EDUCATION == 2           // Grade 2
replace educ_years = 3  if Q17EDUCATION == 3           // Grade 3
replace educ_years = 4  if Q17EDUCATION == 4           // Grade 4
replace educ_years = 5  if Q17EDUCATION == 5           // Grade 5
replace educ_years = 6  if Q17EDUCATION == 6           // Grade 6
replace educ_years = 7  if Q17EDUCATION == 7           // Grade 7
replace educ_years = 8  if Q17EDUCATION == 8           // Grade 8
replace educ_years = 9  if Q17EDUCATION == 9           // Grade 9
replace educ_years = 10 if Q17EDUCATION == 10          // Grade 10
replace educ_years = 11 if Q17EDUCATION == 11          // Grade 11
replace educ_years = 12 if inlist(Q17EDUCATION,12,13)  // Matric (both types)
* N-courses / vocational
replace educ_years = 10 if Q17EDUCATION == 14          // N1 / NTC I
replace educ_years = 11 if Q17EDUCATION == 15          // N2 / NTC II
replace educ_years = 12 if Q17EDUCATION == 16          // N3 / NTC III
replace educ_years = 13 if Q17EDUCATION == 17          // N4
replace educ_years = 14 if Q17EDUCATION == 18          // N5
replace educ_years = 15 if Q17EDUCATION == 19          // N6
* Certificates & Diplomas
replace educ_years = 11 if Q17EDUCATION == 20          // Cert < Grade 12
replace educ_years = 12 if Q17EDUCATION == 21          // Dip  < Grade 12
replace educ_years = 13 if Q17EDUCATION == 22          // Cert with Grade 12
replace educ_years = 14 if Q17EDUCATION == 23          // Dip  with Grade 12
replace educ_years = 15 if Q17EDUCATION == 24          // Higher Diploma
replace educ_years = 16 if Q17EDUCATION == 25          // Post Higher Diploma
* Degrees
replace educ_years = 15 if Q17EDUCATION == 26          // Bachelor's
replace educ_years = 16 if Q17EDUCATION == 27          // Bachelor's + PG Dip
replace educ_years = 16 if Q17EDUCATION == 28          // Honours
replace educ_years = 18 if Q17EDUCATION == 29          // Masters / PhD
* Other / Don't know → missing
replace educ_years = . if inlist(Q17EDUCATION,30,31)
label var educ_years "Approximate years of schooling"
summarize educ_years
tab educ_years, missing
tab female
tab Province

/// Sector: Using Sector 1 and Sector 2
//Business type, Q415TYPEBUSNS indicates whether the business is private enterprise, government, household, NGO, etc. For self-employed businesses, private enterprise is likely to dominate, but it should be examined before deciding whether to include this variable.
// Logistic regression for additional employment: The principle model should be: \[Pr(Employer_i=1)=f(Age,Gender,Education,Sector,Province,\ldots)\]
*--------------------------------------------------------------------
* Logistic regression: determinants of employing additional workers
*--------------------------------------------------------------------
svy, subpop(if selfemployed == 1): logit employer ///
    c.Q14AGE ///
    c.age2 ///
    i.Q13GENDER ///
    educ_years ///
    i.Province ///
    i.sector1,or
	
svy, subpop(if selfemployed == 1): logit employer ///
    c.Q14AGE ///
    c.age2 ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1, or
	
* 2. Generate predicted probabilities (only for the subpopulation)
predict pr if e(sample) & selfemployed == 1, pr
label var pr "Predicted probability of being an employer"
* 3. Area under the ROC curve (AUC)
*========================================================================
* Note: lroc / roctab do not fully incorporate survey weights.
* They are still the most common practical approach.
lroc, nograph
* or, more detailed:
roctab employer pr if selfemployed == 1

predict double pred_prob if e(sample), pr
* Restrict performance assessment to the target subpopulation
gen byte model_sample = (selfemployed == 1) ///
    if !missing(selfemployed)
summarize pred_prob if model_sample == 1
roctab employer pred_prob if model_sample == 1, graph ///
    title("ROC Curve: Employer Prediction Model") ///
    subtitle("Self-employed population") ///
    xtitle("1 - Specificity") ///
    ytitle("Sensitivity")

* Display AUC and confidence interval
roctab employer pred_prob if model_sample == 1

*-------------------------------------------------------------------
* CLASSIFICATION AT THE 0.50 PROBABILITY THRESHOLD
*-------------------------------------------------------------------
capture drop predicted_class
gen byte predicted_class = (pred_prob >= 0.50) ///
    if !missing(pred_prob) & model_sample == 1
* Confusion matrix
tabulate employer predicted_class if model_sample == 1, row column
* True positives
gen byte true_positive = ///
    (employer == 1 & predicted_class == 1) ///
    if model_sample == 1 & !missing(employer, predicted_class)
* True negatives
gen byte true_negative = ///
    (employer == 0 & predicted_class == 0) ///
    if model_sample == 1 & !missing(employer, predicted_class)
* False positives
gen byte false_positive = ///
    (employer == 0 & predicted_class == 1) ///
    if model_sample == 1 & !missing(employer, predicted_class)
* False negatives
gen byte false_negative = ///
    (employer == 1 & predicted_class == 0) ///
    if model_sample == 1 & !missing(employer, predicted_class)
*-------------------------------------------------------------------
* SURVEY-WEIGHTED SENSITIVITY
svy, subpop(if selfemployed == 1 & employer == 1): ///
    mean true_positive
* Sensitivity = proportion of actual employers * correctly classified as employers.
*-------------------------------------------------------------------
* SURVEY-WEIGHTED SPECIFICITY
svy, subpop(if selfemployed == 1 & employer == 0): ///
    mean true_negative
* Specificity = proportion of actual non-employers * correctly classified as non-employers.
*-------------------------------------------------------------------
* BRIER SCORE
capture drop brier_score
gen double brier_score = (employer - pred_prob)^2 ///
    if model_sample == 1 & !missing(employer, pred_prob)
* Survey-weighted Brier score
svy, subpop(if model_sample == 1): mean brier_score
* Conventional unweighted Brier score for comparison
summarize brier_score if model_sample == 1
*-------------------------------------------------------------------
* CALIBRATION BY DECILES OF PREDICTED PROBABILITIES
capture drop calibration_group
xtile calibration_group = pred_prob ///
    if model_sample == 1, nq(10)
* Compare observed and predicted probabilities
svy, subpop(if model_sample == 1): ///
    mean employer pred_prob, over(calibration_group)
* Examine group sizes
tabulate calibration_group if model_sample == 1
*-------------------------------------------------------------------
* CALIBRATION INTERCEPT AND SLOPE
capture drop logit_pred
gen double logit_pred = ///
    ln(pred_prob/(1-pred_prob)) ///
    if model_sample == 1 & pred_prob > 0 & pred_prob < 1
* Calibration slope and intercept
svy, subpop(if model_sample == 1): ///
    logit employer c.logit_pred
* Examine the coefficients
estimates store calibration_model
* Calibration-in-the-large (intercept)
svy, subpop(if model_sample == 1): ///
    logit employer, offset(logit_pred)
estimates store calibration_intercept
*========================================================================
* 4. Sensitivity, Specificity & Classification table
* Default cutoff = 0.5
estat classification

* You can also request a different cutoff, e.g. 0.3:
* estat classification, cutoff(0.3)
*========================================================================
* 5. Brier Score
* Brier score = mean of (observed - predicted)^2
gen brier = (employer - pr)^2 if selfemployed == 1 & e(sample)
svy, subpop(if selfemployed == 1): mean brier
* The reported mean is the Brier score
*========================================================================
* 6. Calibration
*--- 6a. Hosmer-Lemeshow goodness-of-fit test
* (groups the predicted probabilities into deciles)
estat gof, group(10)

*--- 6b. Calibration plot (observed vs predicted by decile)
* Create deciles of predicted probability
xtile decile = pr if selfemployed == 1 & e(sample), nq(10)

* Mean observed outcome and mean predicted probability by decile
preserve
    collapse (mean) obs = employer pred = pr if selfemployed == 1, by(decile)
    
    * Scatter plot of observed vs predicted
    twoway (scatter obs pred, msymbol(O) mcolor(navy)) ///
           (function y = x, range(0 1) lcolor(red) lpattern(dash)), ///
           xtitle("Mean predicted probability") ///
           ytitle("Observed proportion of employers") ///
           title("Calibration plot (by decile)") ///
           legend(order(1 "Observed" 2 "Perfect calibration") ///
                  position(5) ring(0)) ///
           xlabel(0(0.1)1) ylabel(0(0.1)1)
restore

*--- 6c. Calibration slope & intercept (optional but informative)
* Regress the outcome on the logit of the predicted probability
gen logit_pr = logit(pr) if selfemployed == 1 & e(sample)

svy, subpop(if selfemployed == 1): logit employer logit_pr
* Intercept ≈ 0 and coefficient ≈ 1 indicate good calibration
// Because the outcome is binary, odds ratios are easier to interpret
svy, subpop(if selfemployed == 1): logistic employer ///
    c.Q14AGE ///
    c.age2 ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1
	
/// Marginal effects for RQ2: We use average marginal effects, rather than relying exclusively on adds ratios
margins, dydx(*) post
margins, dydx(Q14AGE Q13GENDER) post
margins female  //Predicted probabilities by Gender
marginsplot
margins sector1 ///Predicted probability by Sector
marginsplot


///Alternative model for RQ2: number of workers employed
//The previous model asks whether a business employs at least one additional worker. You can also examine the intensity of employment creation. Create an approximate numerical employment-size variable:
codebook Q416NRWORKERS
gen nworkers = .
replace nworkers = 0 if Q416NRWORKERS == 1
replace nworkers = 1 if Q416NRWORKERS == 2
replace nworkers = 3 if Q416NRWORKERS == 3
replace nworkers = 7 if Q416NRWORKERS == 4
replace nworkers = 15 if Q416NRWORKERS == 5
replace nworkers = 30 if Q416NRWORKERS == 6
replace nworkers = 55 if Q416NRWORKERS == 7
* 50+ is open-ended and should not be assigned an arbitrary value
/// Poisson Regression
svy, subpop(if selfemployed == 1): poisson nworkers ///
    c.Q14AGE ///
    c.age2 ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1

/// Research Question 3
//RQ3: Are small businesses more likely to create temporary and insecure employment than larger enterprises? This should be analysed among employees, excluding employers and own-account workers. First define employee status:	* Paid employees
codebook Q45WRK4WHOM
gen paid_employee = ///
    Q45WRK4WHOM == 1
label define paidemplbl ///
    0 "Not paid employee" ///
    1 "Paid employee"
label values paid_employee paidemplbl

// Temporary Employment: The dataset provides Q412CONTRDURATION: - Permanent nature - Unspecified duration - Limited duration Define temporary employment: * Temporary employment
codebook Q412CONTRDURATION
gen temporary = .
replace temporary = 0 if Q412CONTRDURATION == 2
replace temporary = 1 if ///
    Q412CONTRDURATION == 1|Q412CONTRDURATION == 3
label define templbl ///
    0 "Permanent" ///
    1 "Temporary"
label values temporary templbl
tab temporary if paid_employee == 1  // Exclude unspecified duration from the binary outcome

// Compare Temporary Employment to Business Size
* Temporary employment by business size: This directly answers whether temporary employment is more prevalent among small businesses.
svy, subpop(if paid_employee == 1 & !missing(temporary)): ///
    proportion temporary, over(small_business)	
svy, subpop(if paid_employee == 1 & !missing(temporary)): ///
    tabulate small_business temporary, row percent

///Logistic regression: temporary employment
//If odds ratio of [i.small_business] greater than 1 and statistically significant, employees of small businesses have higher odds of temporary employment than employees of large businesses.
* CLUSTERING OCCUPATIONAL CATEGORIES (ISCO BASED)
* --- 1. Inspect the variable ---
label list Q42OCCUPATION
tab Q42OCCUPATION, missing

* --- 2. Generate the ISCO major-group digit ---
* For 4-digit codes, floor(code/1000) gives the major group (1-9).
* For 1-digit codes (e.g., 9999), this yields 9 correctly.
gen occ_major = floor(Q42OCCUPATION/1000)
* Handle edge cases: codes below 1000 or missing
replace occ_major = . if Q42OCCUPATION == . | Q42OCCUPATION == 9999
* (9999 = Unspecified -> we will assign to cluster 9 below)
* --- 3. Create the 9-cluster variable ---
gen occ_cluster = .
replace occ_cluster = 1 if inrange(occ_major, 1, 1)   // Managers
replace occ_cluster = 2 if inrange(occ_major, 2, 2)   // Professionals
replace occ_cluster = 3 if inrange(occ_major, 3, 3)   // Technicians & assoc. professionals
replace occ_cluster = 4 if inrange(occ_major, 4, 4)   // Clerks
replace occ_cluster = 5 if inrange(occ_major, 5, 5)   // Service & sales workers
replace occ_cluster = 6 if inrange(occ_major, 6, 6)   // Skilled agricultural & fishery
replace occ_cluster = 7 if inrange(occ_major, 7, 7)   // Craft & related trades
replace occ_cluster = 8 if inrange(occ_major, 8, 8)   // Plant & machine operators
replace occ_cluster = 9 if inrange(occ_major, 9, 9)   // Elementary occupations

* Assign residual/uncodeable cases to cluster 9
replace occ_cluster = 9 if Q42OCCUPATION == 9999 | Q42OCCUPATION == 9888
* --- 4. Label the cluster variable ---
label define occ_cluster_lbl ///
    1 "Managers & senior officials" ///
    2 "Professionals" ///
    3 "Technicians & associate professionals" ///
    4 "Clerks" ///
    5 "Service, shop & market sales workers" ///
    6 "Skilled agricultural & fishery workers" ///
    7 "Craft & related trades workers" ///
    8 "Plant & machine operators & assemblers" ///
    9 "Elementary occupations"
label values occ_cluster occ_cluster_lbl
label variable occ_cluster "Occupational cluster (ISCO-based)"
* --- 5. Validate ---
tab occ_cluster, missing
tab occ_major occ_cluster, missing
* Check that every non-missing occupation is assigned
count if occ_cluster == . & !missing(Q42OCCUPATION)
list Q42OCCUPATION if occ_cluster == . & !missing(Q42OCCUPATION)

* Determinants of temporary employment
svy, subpop(if paid_employee == 1 & !missing(temporary)): ///
    logistic temporary ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1 ///
    i.occ_cluster, or
// Contract insecurity: The dataset contains several indicators of employment protection: - Pension - Paid leave - UIF - Medical aid - Income tax. These can be used to construct an employment-insecurity measure. First recode the indicators:* Employment protection indicators
codebook Q46PENSION Q47PDLEAVE Q48UIF Q49MEDICAL Q410INCOMETAX
gen no_pension = (Q46PENSION == 2) if !missing(Q46PENSION)
gen no_leave = (Q47PDLEAVE == 2) if !missing(Q47PDLEAVE)
gen no_uif = (Q48UIF == 2) if !missing(Q48UIF)
gen no_medical = (Q49MEDICAL == 2) if !missing(Q49MEDICAL)
gen no_tax = (Q410INCOMETAX == 2) if !missing(Q410INCOMETAX)
/// Create an Insecurity Score
egen insecurity_score = rowtotal( ///
    no_pension ///
    no_leave ///
    no_uif ///
    no_medical ///
    no_tax ///
)
tab insecurity_score if paid_employee == 1
summarize insecurity_score if paid_employee == 1
/// Generating Insecurity Score using Factor Analysis
tetrachoric no_pension no_leave no_uif no_medical no_tax, posdef
return list
global N = r(N)
matrix R = r(Rho)
matrix symeigen eigenvectors eigenvalues = R 
matrix list eigenvalues
factormat R, n($N) factors(2)
rotate, varimax blanks(.3)
predict CoreBenefitsDeficit UIFNonCoverage
foreach var of varlist (CoreBenefitsDeficit UIFNonCoverage){
	quietly summarize `var'
	generate _`var' = ((`var' - r(min))/(r(max) - r(min))) * 100
}
rename (_CoreBenefitsDeficit _UIFNonCoverage)(NoEmploymentBenefits NoSocialInsurance)
summarize NoEmploymentBenefits NoSocialInsurance
xtile NEB = NoEmploymentBenefits, nq(3)
	lab define NEB 1 "Low" 2 "Moderate" 3 "High"
	lab values NEB NEB
xtile NSI = NoSocialInsurance, nq(3)
	lab define NSI 1 "Low" 2 "Moderate" 3 "High"
	lab values NSI NSI
	
xtile NEB2 = NoEmploymentBenefits, nq(2)
	lab define NEB2 1 "Low" 2 "High"
	lab values NEB2 NEB2
xtile NSI2 = NoSocialInsurance, nq(2)
	lab define NSI2 1 "Low" 2 "High"
	lab values NSI2 NSI2
tab1 NEB2 NSI2
codebook NEB2 NSI2
foreach var of varlist (NEB2 NSI2){
	replace `var' = 0 if `var' == 1
	replace `var' = 1 if `var' == 2
}
lab define Security 0 "Low" 1 "High"
lab values NEB2 Security
lab values NSI2 Security
/// High employment insecurity. For a binary analysis:	
//This provides a stronger test of whether small-business employment is more insecure than large-business employment.
gen high_insecurity = insecurity_score >= 3 ///
    if !missing(insecurity_score)
label define insecurelbl ///
    0 "Low/moderate insecurity" ///
    1 "High insecurity"
label values high_insecurity insecurelbl

svy, subpop(if paid_employee == 1): ///
    proportion high_insecurity, over(small_business)
	
svy, subpop(if paid_employee == 1): ///
    proportion NEB2, over(small_business)
svy, subpop(if paid_employee == 1): ///
    proportion NSI2, over(small_business)
	
svy, subpop(if paid_employee == 1): ///
    tabulate small_business NEB2, row percent
svy, subpop(if paid_employee == 1): ///
    tabulate small_business NSI2, row percent

svy, subpop(if paid_employee == 1): ///
    logistic NEB2 ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1, or

svy, subpop(if paid_employee == 1): ///
    logistic NSI2 ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1, or
// Linear Regression Analysis
svy, subpop(if paid_employee == 1): ///
    proportion NoEmploymentBenefits, over(small_business)
svy, subpop(if paid_employee == 1): ///
    proportion NoSocialInsurance, over(small_business)

svy, subpop(if paid_employee == 1): ///
    logit high_insecurity ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1, or
	
/// Research Question 4: RQ4: What is the contribution of small businesses to youth and female employment? This requires estimating small-business employment separately for: 1. Youth 2. Women
* Youth employment contribution
svy, subpop(if employed == 1 & youth == 1): ///
    proportion small_business
// This gives the proportion of employed young people working in small businesses. To compare youth and non-youth:
svy, subpop(if employed == 1): ///
    proportion small_business, over(youth)
// Female Employment
svy, subpop(if employed == 1 & female == 1): ///
    proportion small_business
svy, subpop(if employed == 1): ///
    proportion small_business, over(female) // Compare women with men

// Youth and female employment simultaneously 
gen demographic_group = .
replace demographic_group = 1 if female == 0 & youth == 0
replace demographic_group = 2 if female == 1 & youth == 0
replace demographic_group = 3 if female == 0 & youth == 1
replace demographic_group = 4 if female == 1 & youth == 1
label define demolbl ///
    1 "Male, non-youth" ///
    2 "Female, non-youth" ///
    3 "Male, youth" ///
    4 "Female, youth"
label values demographic_group demolbl
//Then 
svy, subpop(if employed == 1): ///
    tabulate demographic_group small_business, row percent
// Fourth group is Female Youth Employed in Small Businesses

//Regression analysis of youth and female employment
//Youth
svy, subpop(if employed == 1 & youth == 1): ///
    logistic small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.Province ///
    i.sector1, or
//Female Workers
svy, subpop(if employed == 1 & female == 1): ///
    logistic small_business ///
    c.Q14AGE ///
    i.EducLevel ///
    i.Province ///
    i.sector1, or
* However, these should be treated as supplementary analyses. The principal contribution measure should be the weighted proportion and estimated number of workers.


// Research Question 5. 
//RQ5: How does employment absorption by small businesses differ across provinces and economic sectors? This is one of the strongest applications of the dataset because Province and sector1 are already available.
// Province Level Employment Absorption
svy, subpop(if employed == 1): ///
    proportion small_business, over(Province)
svy, subpop(if employed == 1): ///
    tabulate Province small_business, row percent // Cross tabulation
//The row percentage tells you the proportion of employed people in each province who work for small businesses.

// Sector-Level Employment Absorption
svy, subpop(if employed == 1): ///
    proportion small_business, over(sector1)
svy, subpop(if employed == 1): ///
    tabulate sector1 small_business, row percent
///Province × sector analysis. This is particularly useful for identifying where small businesses have the greatest employment absorption.
svy, subpop(if employed == 1): ///
    tabulate Province sector1, row percent
svy, subpop(if employed == 1): ///
    tabulate Province small_business, row percent
svy, subpop(if employed == 1): ///
    proportion small_business, over(Province sector1)

//Multivariate analysis of provincial and sectoral differences.
//A logistic model can establish whether the provincial and sectoral differences remain after controlling for individual characteristics.
svy, subpop(if employed == 1): ///
    logistic small_business ///
    i.Province ///
    i.sector1 ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.EducLevel ///
    i.agegrp, or
// Use margins to obtain adjusted probabilities
margins Province
marginsplot
//And
margins sector1
marginsplot

// Model 1: Employment contribution. Descriptive/weighted:
svy, subpop(if employed == 1): proportion small_business

// Model 2: Probability that a self-employed person employs workers
svy, subpop(if selfemployed == 1): ///
    logistic employer ///
    c.Q14AGE ///
    c.age2 ///
    i.Q13GENDER ///
    i.Q17EDUCATION ///
    i.Province ///
    i.sector1, or
	
// Model 3: Probability of temporary employment
svy, subpop(if paid_employee == 1 & !missing(temporary)): ///
    logistic temporary ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.Q17EDUCATION ///
    i.Province ///
    i.sector1 ///
    i.Q42OCCUPATION, or
	
// Model 4: Probability of insecure employment
svy, subpop(if paid_employee == 1 & !missing(high_insecurity)): ///
    logistic high_insecurity ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.Q17EDUCATION ///
    i.Province ///
    i.sector1, or

// Determinants of Small-Business Employment
svy, subpop(if employed == 1): ///
    logistic small_business ///
    i.Province ///
    i.sector1 ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.Q17EDUCATION ///
    i.agegrp, or

/// Robustness Checks
// Definition 1: <50 workers
gen sb_50 = firm_size < 6 if !missing(firm_size)

// Definition 2: <20 workers
gen sb_20 = firm_size < 5 if !missing(firm_size)

// Definition 3: <10 workers
gen sb_10 = firm_size < 4 if !missing(firm_size)

// Repeat Principal Models
svy, subpop(if employed == 1): ///
    logistic sb_20 ///
    i.Province i.sector1 ///
    c.Q14AGE i.Q13GENDER i.Q17EDUCATION
//And
svy, subpop(if employed == 1): ///
    logistic sb_10 ///
    i.Province i.sector1 ///
    c.Q14AGE i.Q13GENDER i.Q17EDUCATION

// If the substantive conclusions remain similar, this provides evidence that the findings are not driven by a particular enterprise-size threshold.





/// Descriptive Analytics
// Table 1: Characteristics of the working-age population
svy: mean Q14AGE
svy: proportion female
svy: proportion youth
svy: proportion employed

// Table 2: Employment distribution by business size
svy, subpop(if employed == 1): ///
    proportion firm_size
	
// Table 3: Small-business employment by province
svy, subpop(if employed == 1): ///
    proportion small_business, over(Province)
	
// Table 4: Small-business employment by economic sector
svy, subpop(if employed == 1): ///
    proportion small_business, over(sector1)
	
// Table 5: Small-business employment among youth and women
svy, subpop(if employed == 1): ///
    proportion small_business, over(youth)
svy, subpop(if employed == 1): ///
    proportion small_business, over(female)

// Table 6: Determinants of employing additional workers
svy, subpop(if selfemployed == 1): ///
    logistic employer ///
    c.Q14AGE c.age2 ///
    i.Q13GENDER i.Q17EDUCATION ///
    i.Province i.sector1, or
	
// Table 7: Temporary employment
svy, subpop(if paid_employee == 1 & !missing(temporary)): ///
    logistic temporary ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.Q17EDUCATION ///
    i.Province ///
    i.sector1, or

// Table 8: Employment insecurity
svy, subpop(if paid_employee == 1 & !missing(high_insecurity)): ///
    logistic high_insecurity ///
    i.small_business ///
    c.Q14AGE ///
    i.Q13GENDER ///
    i.Q17EDUCATION ///
    i.Province ///
    i.sector1, or


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

























































