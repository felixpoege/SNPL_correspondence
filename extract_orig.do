/*
	@project SNPL_concordence
	@author Felix Poege (felix.poege@ip.mpg.de)
	
	Extract a concordence between patent classes and Web of Science
	science classes / OECD subject areas.
	Replication file - cannot be executed.
	
	The resulting files count the number of (fractional) patent families
	from a particular technology class that cite a particular Web of Science
	class. They can then be further aggregated to the desired correspondence.
*/
do "X:\Prof. Harhoff\Harhoff_INTERN\RESEARCH\NPL\NPL_paths.do"

global BASE_PATH = "<base_path>"

cap mkdir "${BASE_PATH}NPL_concordance\Output\"
cap mkdir "${BASE_PATH}NPL_concordance\orig\"

use "${DATA_NPL}npl_wos_barebone.dta", clear

// Keep only high-quality NPL links
keep if inrange(soma_class, ${SOMA_CLASS_CUTOFF}, ${SOMA_CLASS_MAX})
drop soma_class
drop soma_pattern

keep appln_id soma_item_ut
gduplicates drop

// Map the items to their subject area
// This file is a list of all WoS items between 1980 and 2013 with their key
// variables, among them the list of subject codes.
des using "${DATA_NPL}/pwox_subj_unique.dta"
rename soma_item_ut item_ut
merge m:1 item_ut using "${DATA_NPL_CITE}items_for_est.dta", keep(1 3) keepusing(item_itsu_codes)
drop if _merge == 1
drop _merge

gen N_codes = strlen(item_itsu_codes) - strlen(subinstr(item_itsu_codes, ",", "", .)) + 1

// Bring from a with-variable wide format to a long format
gen item_itsu_code1 = substr(item_itsu_codes, 1, 2)
replace item_itsu_codes = substr(item_itsu_codes, 4, .)
greshape long item_itsu_code, i(appln_id item_ut) j(idx) string
drop if missing(item_itsu_code)
drop idx

count if strlen(item_itsu_code) > 2
local to_expand = r(N)
while `to_expand' > 0 {
	qui gen item_itsu_code1 = substr(item_itsu_code, 1, 2) if strlen(item_itsu_code) > 2
	qui replace item_itsu_code = substr(item_itsu_code, 4, .) if strlen(item_itsu_code) > 2
	qui expand 2 if !missing(item_itsu_code1), gen(exp)
	qui replace item_itsu_code = item_itsu_code1 if exp == 1
	drop exp item_itsu_code1
	count if strlen(item_itsu_code) > 2
	local to_expand = r(N)
}
compress item_itsu_code
gisid appln_id item_ut item_itsu_code

// Merge OECD subject areas
rename item_itsu_code subj_wossc_code
merge m:1 subj_wossc_code using "${DATA_NPL}pwox_subj_unique.dta", keep(1 3) keepusing(subj_oecd_code)
assert subj_wossc_code == "--" if _merge == 1
drop if _merge == 1
drop _merge

// Translate appln_ids to docdb_family_ids
des using "${DATA_PATSTAT19}PATSTAT_basic_102019.dta"
merge m:1 appln_id using "${DATA_PATSTAT19}PATSTAT_basic_102019.dta", keep(1 3) keepusing(docdb_family_id appln_auth)
drop if _merge == 1
drop _merge
drop appln_id
gduplicates drop

des using "${DATA_NPL_CITE}docdb_level_patent_values.dta"
merge m:1 docdb_family_id using "${DATA_NPL_CITE}docdb_level_patent_values.dta", keep(1 3) keepusing(cpc_class cpc_subclass	area34 mainarea34)
drop if _merge == 1
drop _merge
save "${BASE_PATH}NPL_concordance\Output\tmp_link_list.dta", replace


/*
	Aggregation without considering different offices
*/
use "${BASE_PATH}NPL_concordance\Output\tmp_link_list.dta", clear
drop appln_auth
gduplicates drop
// Count the number of links per family
bys docdb_family_id item_ut: gen first = _n == 1
gegen N_links = total(first), by(docdb_family_id)
// Build fractional weights for each patent family
gen weight = 1 / N_links / N_codes
// Make sure the weights work correctly
gegen test_total = total(weight), by(docdb_family_id)
assert abs(test_total - 1) < 0.001
drop test_total
preserve
drop if missing(cpc_class)
gcollapse (sum) weight, by(subj_wossc_code subj_oecd_code cpc_class cpc_subclass)
export delimited using "${BASE_PATH}NPL_concordance\orig\freq_wos_cpc.csv", replace
restore, preserve
gcollapse (sum) weight, by(subj_wossc_code subj_oecd_code area34)
export delimited using "${BASE_PATH}NPL_concordance\orig\freq_wos_area34.csv", replace
restore

/*
	TODO: Export for individual patent offices (US, EP, WO)
*/

/*
	Export labels
*/
use "${BASE_PATH}NPL_concordance\Output\tmp_link_list.dta", clear
keep subj_wossc_code
gduplicates drop
merge m:1 subj_wossc_code using "${DATA_NPL}/pwox_subj_unique.dta", keep(1 3)
drop _merge
rename subj_wossc_code wos_code
rename subj_* *
rename wossc* wos*
order oecd*, first
export delimited using "${BASE_PATH}NPL_concordance\orig\wos_oecd_labels.csv", replace

