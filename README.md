# Gender Identity in West and East Germany

Open Materials for the paper: 'Gender identity and wives’ labor market outcomes
in West and East Germany between 1983 and 2016' by [Maximilian Sprengholz](mailto:maximilian.sprengholz@hu-berlin.de), Anna Wieber, and Elke Holst, _Socio-Economic Review_, https://doi.org/10.1093/ser/mwaa048.

## Project organization

```
.
├── .gitignore
├── LICENSE.md
├── README.md
├── ado                <- Altered external Stata programs
├── data               <- Final data set for modeling at root level
│   ├── source         <- Open source data (provided); processed closed source data (not provided)
│   └── temp           <- Intermediate data that has been transformed.
├── do                 <- Source code
├── graphs             <- Altered external Stata programs
├── tables             <- Source code
└── docs               <- LaTeX source and output to reproduce paper results and appendix

```

## Data requirements

### SOEP
The main data used in this project is the Socio-Economic Panel v33.1, [doi:10.5684/soep.v33.1](https://doi:10.5684/soep.v33.1). The SOEP data is free of charge but has to be requested according to the following [conditions](https://www.diw.de/en/diw_02.c.242211.en/criteria_fdz_soep.html). You have to have access to the WIDE and LONG standard files in order to run the code. Moreover, you need to have access to regional data (Kreiskennzahlen) in order to merge the county-level unemployment data (see below). Ususally, the access to regional data is only granted on-site.

### FAST
To address income heaping in the SOEP data, we also use administrative income data (FAST) from 2010, [doi:10.21242/73111.2010.00.00.3.1.0](https://doi:10.21242/73111.2010.00.00.3.1.0). This data can be requested [here](https://www.forschungsdatenzentrum.de/de/zugang).

### County-level unemployment data
Monthly values have been collected and processed manually based on spredsheets provided by the [Bundesagentur für Arbeit (BA)](https://statistik.arbeitsagentur.de/). These files are provided in this repository.

### WVS
We use the openly available WVS waves [1995-1998](http://www.worldvaluessurvey.org/WVSDocumentationWV3.jsp) and [2010-2014](http://www.worldvaluessurvey.org/WVSDocumentationWV6.jsp) to compare agreement to the statement 'If a woman earns more money than her husband, it's almost certain to cause problems.'

## Software requirements

This project was implemented in [Stata 15.1](https://www.stata.com/), but should run in version 14, too. You find the master file under `do/gi_master.do`.

The following user-written programs need to be installed in order to run the full code (see installation instructions in the linked documentations):

- [grstyle](http://repec.sowi.unibe.ch/stata/grstyle/index.html): Jann, B. (2018) ‘Customizing Stata Graphs Made Easy (Part 1)’, The Stata Journal: Promoting communications on statistics and Stata, 18, 491–502.
- Only for appendix: [estout](http://repec.sowi.unibe.ch/stata/estout/index.html): Jann, B. (2007) ‘Making Regression Tables Simplified’, The Stata Journal: Promoting communications on statistics and Stata, 7, 227–244.
- Only for appendix: [xtabond2](http://www.stata-journal.com/article.html?article=st0159): Roodman, D. (2009) ‘How to Do Xtabond2: An Introduction to Difference and System GMM in Stata’, Stata Journal, 9, 86–136.
- Only for appendix: [xtlsdvc](https://journals.sagepub.com/doi/10.1177/1536867X0500500401): Bruno, G. S. (2005) ‘Estimation and Inference in Dynamic Unbalanced Panel-Data Models with a Small Number of Individuals’, The Stata Journal, 5, 473–500.


The following user-written programs have been altered to serve the present purpose; the .ado files are provided in the `ado` dir:

- [DCdensity](https://eml.berkeley.edu/~jmccrary/DCdensity/): McCrary, J. (2008) ‘Manipulation of the Running Variable in the Regression Discontinuity Design: A Density Test’, Journal of Econometrics, 142, 698–714.
- [frmttable](https://econpapers.repec.org/software/bocbocode/s375201.htm): Gallup, J. L. (2012) ‘A Programmer’s Command to Build Formatted Statistical Tables’, Stata Journal, 12, 655–673.


## License

This project is licensed under the terms of the [MIT License](/LICENSE.md).

## Citation

Please [cite this project as described here](/CITATION.md).
