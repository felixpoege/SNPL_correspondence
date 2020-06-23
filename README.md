# Science area - technology class correspondences
Correspondence between Web of Science subject areas and various patent technology classes, based on scientific non-patent literature citations in patents. This is a probabilistic crosswalk, based on empirical data.

Currently, CPC class and subclass [1] as well as area34 [2] and their correspondence to Web of Science subject codes as well as OECD fields of science [3] are considered. If extensions are required, please add an issue in this repository.

The original data construction is described in https://advances.sciencemag.org/content/5/12/eaay7323 and the supplementary material. Please cite that article when using data from this repository. Generally speaking, a high-quality match between non-patent literature references in USPTO and EPO as well as WIPO patents was executed. Here patents in the 1980-2012 time range are considered. All data is aggregated at the level of patent families and only patent families with at least one granted member at the USPTO or EPO are considered.

### Usage

The data files in orig/ contain fractional patent counts for technology/science combinations. They can be formed flexibly in different formats. An example script is provided. 

Run the create_concordence.do file in Stata. If you are using a different programming language, it should be easy to adjust the code. Otherwise, add an issue in the repository.

### Suggested citation

Poege, Felix, Dietmar Harhoff, Fabian Gaessler, and Stefano Baruffaldi. “Science Quality and the Value of Inventions.” Science Advances 5, no. 12 (December 1, 2019): eaay7323. https://doi.org/10.1126/sciadv.aay7323.

### References

[1] https://www.cooperativepatentclassification.org/index

[2] http://www.wipo.int/export/sites/www/ipstats/en/statistics/patents/pdf/wipo_ipc_technology.pdf

[3] https://www.oecd.org/science/inno/38235147.pdf
