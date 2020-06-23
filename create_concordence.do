/*
	@project SNPL_concordence
	@author Felix Poege (felix.poege@ip.mpg.de)
	
	Extract a concordence between patent classes and Web of Science
	science classes / OECD subject areas.

	From the original data files, create an actual correspondence.
	
	Correspondences for the OECD codes can be build easily by aggregating
	the original frequencies one more level.
	
*/

// Create label files
import delimited using "orig/wos_oecd_labels.csv", clear
cap mkdir "Output/"
label var wos_code "WoS subject code"
label var wos_namefull "WoS subject full name"
label var oecd_code "OECD subject area code"
label var oecd_namefull "OECD subject area full name"
label var oecd_nameshort "OECD subject area short name"
drop wos_nameshort oecd_main
save "Output/wos_oecd_labels.dta", replace


// WoS <-> CPC 4-digit correspondence
import delimited using "orig/freq_wos_cpc.csv", clear
drop cpc_class subj_oecd_code
bys cpc_subclass: egen total_weight_cpc = total(weight)
bys subj_wossc_code: egen total_weight_wos = total(weight)
gen weight_wos_to_cpc4 = weight / total_weight_wos
gen weight_cpc4_to_wos = weight / total_weight_cpc
keep weight_wos_to_cpc4 weight_cpc4_to_wos cpc_subclass subj_wossc_code
// Test -> Plausibility
bys cpc_subclass: egen total_test = total(weight_cpc4_to_wos)
assert abs(total_test - 1) < 0.0001
drop total_test
bys subj_wossc_code: egen total_test = total(weight_wos_to_cpc4)
assert abs(total_test - 1) < 0.0001
drop total_test
cap mkdir "Output/"
rename subj_wossc_code wos_code
label var wos_code "Web of Science subject code"
label var cpc_subclass "4-digit CPC subclass"
label var weight_cpc4_to_wos "Frequency weight when translating cpc4 to wos"
label var weight_wos_to_cpc4 "Frequency weight when translating wos to cpc4"

merge m:1 wos_code using "Output/wos_oecd_labels.dta", keep(1 3) ///
	keepusing(wos_namefull oecd_code oecd_namefull oecd_nameshort)
drop _merge
save "Output/correspondence_wos_cpc_subclass.dta", replace

// CPC 3-digit correspondence
import delimited using "orig/freq_wos_cpc.csv", clear
drop cpc_subclass
collapse (sum) weight, by(subj_wossc_code subj_oecd_code cpc_class)
bys cpc_class: egen total_weight_cpc = total(weight)
bys subj_wossc_code: egen total_weight_wos = total(weight)
gen weight_wos_to_cpc3 = weight / total_weight_wos
gen weight_cpc3_to_wos = weight / total_weight_cpc
keep weight_wos_to_cpc3 weight_cpc3_to_wos cpc_class subj_wossc_code
// Test -> Plausibility
bys cpc_class: egen total_test = total(weight_cpc3_to_wos)
assert abs(total_test - 1) < 0.0001
drop total_test
bys subj_wossc_code: egen total_test = total(weight_wos_to_cpc3)
assert abs(total_test - 1) < 0.0001
drop total_test
cap mkdir "Output/"
rename subj_wossc_code wos_code
label var wos_code "Web of Science subject code"
label var cpc_class "3-digit CPC class"
label var weight_cpc3_to_wos "Frequency weight when translating cpc3 to wos"
label var weight_wos_to_cpc3 "Frequency weight when translating wos to cpc3"

merge m:1 wos_code using "Output/wos_oecd_labels.dta", keep(1 3) ///
	keepusing(wos_namefull oecd_code oecd_namefull oecd_nameshort)
drop _merge
save "Output/correspondence_wos_cpc_class.dta", replace

// Area34 correspondence
import delimited using "orig/freq_wos_area34.csv", clear
bys area34: egen total_weight_area34 = total(weight)
bys subj_wossc_code: egen total_weight_wos = total(weight)
gen weight_wos_to_area34 = weight / total_weight_wos
gen weight_area34_to_wos = weight / total_weight_area34
keep weight_wos_to_area34 weight_area34_to_wos area34 subj_wossc_code
// Test -> Plausibility
bys area34: egen total_test = total(weight_area34_to_wos)
assert abs(total_test - 1) < 0.0001
drop total_test
bys subj_wossc_code: egen total_test = total(weight_wos_to_area34)
assert abs(total_test - 1) < 0.0001
drop total_test
cap mkdir "Output/"
rename subj_wossc_code wos_code
label var wos_code "Web of Science subject code"
label var area34 "Area 34"
label var weight_area34_to_wos "Frequency weight when translating area34 to wos"
label var weight_wos_to_area34 "Frequency weight when translating wos to area34"

merge m:1 wos_code using "Output/wos_oecd_labels.dta", keep(1 3) ///
	keepusing(wos_namefull oecd_code oecd_namefull oecd_nameshort)
drop _merge
save "Output/correspondence_wos_area34.dta", replace

// Usage example
// See which science areas are typically linked to patents in the technology
// areas of IT methods and Organic Chemistry
use "Output/correspondence_wos_area34.dta" if area34 == "IT_Methods", clear
gsort -weight_area34_to_wos
list area34 weight_area34_to_wos wos_namefull in 1/5

use "Output/correspondence_wos_area34.dta" if area34 == "OrganicChem", clear
gsort -weight_area34_to_wos
list area34 weight_area34_to_wos wos_namefull in 1/5
