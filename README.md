# Gender Identity in West and East Germany

Open Materials for the paper: 'Gender identity and wives’ labor market outcomes
in West and East Germany between 1983 and 2016' by [Maximilian Sprengholz](mailto:maximilian.sprengholz@hu-berlin.de), Anna Wieber, and Elke Holst, Socio-Economic Review, https://doi.org/10.1093/ser/mwaa048.


To make this code work...

...you need the following data:

- Access to the SOEP v33.1 (wide AND long)
- Access to the SOEP v33.1 regional data (district level)
- Access to the FAST income tax data of 2010

...you need the following Stata software:

- DCdensity.ado (Altered version of the Justin McCrary (https://eml.berkeley.edu/~jmccrary/DCdensity/) version to enable graphing options, provided in the ado dir)
- frmttable (by John Gallup, part of outreg (https://econpapers.repec.org/software/bocbocode/s375201.htm), modified version provided in the .ado dir)
- grstyle (by Ben Jann, http://repec.sowi.unibe.ch/stata/grstyle/index.html)
- Only for appendix: xtabond2 (by David Roodman, http://www.stata-journal.com/article.html?article=st0159)
- Only for appendix: xtlsdvc (by Giovanni Bruno, https://journals.sagepub.com/doi/10.1177/1536867X0500500401)
- Only for appendix: estout (by Ben Jann, http://repec.sowi.unibe.ch/stata/estout/index.html)

...please use the provided repository structure as is and edit the macros below.

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

## Data
The main data used in this project are the Scientific Use Files (SUFs) 1976-2015 of the German Microsensus
(DOI: [10.21242/12211.1976.00.00.3.1.0](https://doi.org/10.21242/12211.1976.00.00.3.1.0) to [10.21242/12211.2015.00.00.3.1.0](https://doi.org/10.21242/12211.2015.00.00.3.1.0)). These files are not openly accessible and have to be [requested](https://www.forschungsdatenzentrum.de/en/request).

All other data used is part of this repository.

## Software

This project was implemented in [Stata 15.1](https://www.stata.com/), but should run in older versions, too. You find the master file under `src/mz_o_00_master.do`.

The following user-written programs need to be installed in order to run the full code (see installation instructions in the linked documentations):

- [grstyle](http://repec.sowi.unibe.ch/stata/grstyle/index.html). Jann, B. (2018) ‘Customizing Stata Graphs Made Easy (Part 1)’, The Stata Journal: Promoting communications on statistics and Stata, 18, 491–502.
- [tabout v3](http://tabout.net.au/). Watson, I. (2019).

Further external code used:

- [isei_mz_96-04.do](https://www.gesis.org/missy/files/documents/MZ/isei/isei_mz_96-04.do). Kogan, I. and Schimpl-Neimanns, B. (2006) Recodierung von ISEI auf Basis von ISCO-88 (COM). German Microdata Lab (GML), Mannheim
- [Programme zur Umsetzung der Bildungsklassifikation ISCED-1997](https://www.gesis.org/missy/materials/MZ/tools/isced), German Microdata Lab (GML), Mannheim. Used for years 1976-2013, source files under `bin/external`.

The online appendix/documentation was created in [Atom](https://github.com/atom/atom) with [Markdown Preview Enhanced](https://github.com/shd101wyy/markdown-preview-enhanced), [Pandoc](https://github.com/jgm/pandoc) and [pandoc-crossref](https://github.com/lierdakil/pandoc-crossref).


## License

This project is licensed under the terms of the [MIT License](/LICENSE.md)

## Citation

Please [cite this project as described here](/CITATION.md).
