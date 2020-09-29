////////////////////////////////////////////////////////////////////////////////
//
//		Gender identity and wives’ labor market outcomes
//		in West and East Germany between 1983 and 2016
//
//		--	Insheet parts of FAST income tax data based on official routine  --
//
//		Maximilian Sprengholz
//		maximilian.sprengholz@hu-berlin.de
//
////////////////////////////////////////////////////////////////////////////////

/* ---------------------------------------------------------------------------------------------------------------------------------------

   1. Programmname: einleseroutine_stata.do
   
   2. Autor: Stefanie Uhrich(email: stefanie.uhrich@destatis.de, Tel.: 0611-754234) 
   
   3. Programmziel: Einlesen und Labeln des Scientific-Use-Files der FAST 2010, das als Text-Datei mit Semikolons als Trennzeichen vorliegt.
   
   4. Programmstatus: Getestet mit Stata/SE 14.0 for Windows unter Windows 7 Professional Version 2009, Service Pack 1, 01.02.2017
   
   5. Programmstruktur:
      (i) Einlesen mit dem Insheet-Kommando. Da in der ersten Zeile der Text-Datei die Variablennamen stehen, müssen diese nicht 
          angegeben werden.
     (ii) Definition der Variablenlabels.
    (iii) Definition der Wertelabels.
     (iv) Zuweisung der Wertelabels zu den Variablen.
      (v) Speichern als Stata-Datei.
	  
   6. Erforderliche Anpassungen: 
      (i) Verzeichnis, in dem sich die Text-Daten befinden.
     (ii) Verzeichnis, in dem die Stata-Datei gespeichert werden soll.
    
------------------------------------------------------------------------------------------------------------------------------------------- */

/* (i): Einlesen. Hier den Verzeichnisnamen anpassen. */

/*
	Splitted due to RAM limits.
*/

import delimited using "${FAST}suf2010.csv", delimiter(";") colrange(:38)
save "${dir_data}source/temp/fast2010_pt1.dta", replace
clear

import delimited using "${FAST}suf2010.csv", delimiter(";") colrange(525:775)
save "${dir_data}source/temp/fast2010_pt2.dta", replace
clear

import delimited using "${FAST}suf2010.csv", delimiter(";") colrange(900:955)
save "${dir_data}source/temp/fast2010_pt3.dta", replace
clear

import delimited using "${FAST}suf2010.csv", delimiter(";") colrange(402:420)
save "${dir_data}source/temp/fast2010_pt4.dta", replace
clear

/* merge */
use "${dir_data}source/temp/fast2010_pt1.dta", clear
merge 1:1 _n using "${dir_data}source/temp/fast2010_pt2.dta", nogen
merge 1:1 _n using "${dir_data}source/temp/fast2010_pt3.dta", nogen
merge 1:1 _n using "${dir_data}source/temp/fast2010_pt4.dta", nogen

/* (ii): Definition der Variablenlabels. */

label variable 	samplingweight "Hochrechnungsfaktor" 
label variable 	ef0 "laufende Nummer" 
label variable 	ef1 "Merker" 
label variable 	ef8 "Geschlecht" 
label variable 	ef10 "Steuerklasse" 
label variable 	ef11 "Soziale Gliederung - Mann" 
label variable 	ef12 "Soziale Gliederung - Frau" 
label variable 	ef13 "Religion - Mann" 
label variable 	ef14 "Religion - Frau" 
label variable 	ef18 "Veranlagungsart" 
label variable 	ef22 "GKZ - Mann" 
label variable 	ef23 "GKZ - Frau" 
label variable 	ef19 "Grund-/ Splittingtabelle" 
label variable 	ef48 "Steuerklassen/ -kombinationen" 
label variable 	ef58 "Freie Berufe Mann (klassiert)" 
label variable 	ef59 "Freie Berufe Mann (Dummy)" 
label variable 	ef60 "Freie Berufe Frau (klassiert)" 
label variable 	ef61 "Freie Berufe Frau (Dummy)" 
label variable 	ef62 "Bundesland" 
label variable 	ef63 "Region" 
label variable 	ef64 "Alter Mann" 
label variable 	ef65 "Alter Mann in fünf Jahre klassifiziert" 
label variable 	ef66 "Alter Mann in zehn Jahre klassifiziert" 
label variable 	ef67 "Alter Mann in zwei Altersgruppen klassifiziert" 
label variable 	ef68 "Alter Frau" 
label variable 	ef69 "Alter Frau in fünf Jahre klassifiziert" 
label variable 	ef70 "Alter Frau in zehn Jahre klassifiziert" 
label variable 	ef71 "Alter Frau in zwei Altersgruppen klassifiziert" 
label variable 	ef72 "Anzahl Kinder (max. 4)" 
label variable 	ef73 "Alter erstes Kind" 
label variable 	ef74 "Alter zweites Kind" 
label variable 	ef75 "Alter drittes Kind" 
label variable 	ef76 "Bedeutung Gewinneinkünfte" 
label variable 	ef77 "Bedeutung Einkünfte aus nichtselbständiger Arbeit" 
label variable 	ef78 "Bedeutung Überschusseinkünfte" 
label variable 	ef79 "Anonymisierungsbereich" 
label variable 	ef80 "Anzahl der Riester-Verträge Mann" 
label variable 	ef81 "Anzahl der Riester-Verträge Frau"

/* (iii): Definition der Wertelabels. */
#delimit;

label define Merker
 01 "Veranlagung" 
 02 "keine Veranlagung (manuelle)"; 
label define Gesch 
 0 "Antragsteller männlich" 
 1 "Antragsteller weiblich"; 
label define SozialG 
 0 "keine Einkünfte/keine soziale Gliederung"
 1 "überwiegend nichtselbständig mit gekürzter Vorsorgepauschale" 
 2 "überwiegend nichtselbständig mit ungekürzter Vorsorgepauschale" 
 3 "überwiegend Versorgungsempfänger mit gekürzter Vorsorgepauschale" 
 4 "überwiegend Versorgungsempfänger mit ungekürzter Vorsorgepauschale" 
 5 "überwiegend selbständig mit Bruttolohn" 
 6 "überwiegend selbständig ohne Bruttolohn"; 
label define Reli 
 01 "evangelisch"
 02 "katholisch" 
 03 "sonstige" 
 04 "ohne Konfession"; 
label define Veran 
 1 "getrennte Veranlagung"
 2 "Zusammenveranlagung (ohne Witwen/Witwer)"
 3 "Einzelveranlagung (ohne getrennte V.)"
 4 "übrige Veranlagung (Witwen/Witwer)";
label define Tabelle 
 1 "Grundtabelle" 
 2 "Splittingtabelle"; 
label define Klasse 
 0 "kein Bruttolohn" 
 1 "Steuerklasse I" 
 2 "Steuerklasse II" 
 3 "Steuerklasse III (ohne V)" 
 4 "Steuerklasse IV/IV" 
 5 "Steuerklasse III/V oder V/III" 
 6 "nichtveranlagte Splittingfälle der Steuerklassen III, IV, V"; 
/*label define GKZ 
 A "Land- und Forstwirtschaft, Fischerei und Fischzucht"
 BC "Bergbau und Verarbeitendes Gewerbe"
 DE "Energie- und Wasserversorgung" 
 F "Baugewerbe"
 G "Handel"
 H "Verkehr und Lagerei"
 I "Gastgewerbe"
 J "Information und Kommunikation"
 K "Finanz- und Versicherungsdienstleistungen"
 L "Grundstück- und Wohnungswesen"
 M "Freiberufl., wissenschaftl. und techn. Dienstl."
 N "Sonst. wirt. Dienstleistungen"
 OP "Öffentliche Verwaltung, Erziehung"
 Q "Gesundheits- und Sozialwesen"
 R "Kunst, Unterhaltung, Erholung" 
 S "Sonst. Dienstleistungen"
 X "Sonstige"; */
label define FreieK 
 01 "technische Beratung; Forschung; Architekten; Ingenieur"
 02 "Rechtsanwalt; Notar" 
 03 "Wirtschaftsprüfer; -berater" 
 04 "Ärzte" 
 05 "sonst. Gesundheitsberufe" 
 06 "Werbung; Foto; Kunst und Kultur" 
 07 "Schriftberufe" 
 08 "Schule" 
 09 "Sonstige"; 
label define FreieD 
 0 "nein" 
 1 "ja"; 
label define Land 
 01 "Schleswig-Holstein"
 02 "Hamburg" 
 03 "Niedersachsen" 
 04 "Bremen" 
 05 "Nordrhein-Westfalen" 
 06 "Hessen" 
 07 "Rheinland-Pfalz" 
 08 "Baden-Württemberg" 
 09 "Bayern" 
 10 "Saarland" 
 11 "Berlin" 
 12 "Brandenburg" 
 13 "Mecklenburg-Vorpommern" 
 14 "Sachsen" 
 15 "Sachsen-Anhalt" 
 16 "Thüringen"; 
label define Region 
 1 "West" 
 2 "Ost" ; 
label define AlterF 
 1 "< 15 Jahre" 
 2 ">= 15 - < 20" 
 3 ">= 20 - < 25" 
 4 ">= 25 - < 30" 
 5 ">= 30 - < 35" 
 6 ">= 35 - < 40" 
 7 ">= 40 - < 45" 
 8 ">= 45 - < 50" 
 9 ">= 50 - < 55" 
 10 ">= 55 - < 60" 
 11 ">= 60 - < 65" 
 12 ">= 65 - < 70" 
 13 ">= 70"; 
label define AlterZ 
 1 "< 20 Jahre" 
 2 ">= 20 - < 30" 
 3 ">= 30 - < 40" 
 4 ">= 40 - < 50" 
 5 ">= 50 - < 60" 
 6 ">= 60 - < 70" 
 7 ">= 70"; 
label define AlterG 
 1 "< 50 Jahre"
 2 ">= 50 Jahre";
label define Bedeu 
 1 "höchste Bedeutung" 
 2 "mittlere Bedeutung" 
 3 "geringste Bedeutung" 
 0 "nicht besetzt"; 


/* (iv): Zuweisung der Wertelabels zu den Variablen. */
label value ef1 Merker;
label value ef8 Gesch;
label value ef11 SozialG;
label value ef12 SozialG;
label value ef13 Reli;
label value ef14 Reli;
label value ef18 Veran;
label value ef19 Tabelle;
/*label value ef22 GKZ;
label value ef23 GKZ;*/
label value ef48 Klasse;
label value ef58 FreieK;
label value ef60 FreieK;
label value ef59 FreieD;
label value ef61 FreieD;
label value ef62 Land;
label value ef63 Region;
label value ef65 AlterF;
label value ef69 AlterF;
label value ef66 AlterZ;
label value ef70 AlterZ;
label value ef67 AlterG;
label value ef71 AlterG;
label value ef76 Bedeu;
label value ef77 Bedeu;
label value ef78 Bedeu;
  
#delimit cr;

notes ef22: Bedeutung der Abkürzungen ///
           BC: Bergbau und Verarbeitendes Gewerbe ///
		   DE: Energie- und Wasserversorgung ///
		   F: Baugewerbe ///
		   G: Handel ///
		   H: Verkehr und Lagerei ///
		   I: Gastgewerbe ///
		   J: Information und Kommunikation /// 
		   K: Finanz- und Versicherungsdienstleistungen ///
		   L: Grundstück- und Wohnungswesen ///
		   M: Freiberufl., wissenschaftl. und techn. Dienstl. ///
		   N: Sonst. wirt. Dienstleistungen ///
		   OP: Öffentliche Verwaltung, Erziehung ///
		   Q: Gesundheits- und Sozialwesen ///
		   R: Kunst, Unterhaltung, Erholung /// 
		   S: Sonst. Dienstleistungen ///
		   X: Sonstige
notes ef23: siehe ef22


compress, nocoalesce

/* (v): Speichern der Stata-Datei. Hier den Verzeichnisnamen anpassen. */

/* create part */
keep samp* e* ///
	c47120 c48120 c65160 c65161 c65162 c65163 c65164 c65172 c65173 c65310 c65311 c65312 c65522 ///
	c66206 c66207 c71100 c71150 c71200 c72100 c72150 c72200  

label variable c65160 "Einkünfte aus nichtselbständiger Arbeit"
label variable c65161 "Einkünfte aus nichtselbständiger Arbeit Mann"
label variable c65162 "Einkünfte aus nichtselbständiger Arbeit Frau"
label variable c65163 "Bruttoarbeitslohn Mann"
label variable c65164 "Bruttoarbeitslohn Frau"
label variable c65172 "Werbungskosten Mann"
label variable c65173 "Werbungskosten Frau"
label variable c65310 "Summe der Einkünfte"
label variable c65311 "Summe der Einkünfte Mann"
label variable c65312 "Summe der Einkünfte Frau"
label variable c65522 "Zu versteuerndes Einkommen"

label var c47120 "Bruttobetrag Lohnersatzleistungen Mann"
label var c48120 "Bruttobetrag Lohnersatzleistungen Frau"

label var c71100 "Typ gesetzliche Rente 1 Mann"
label var c71150 "Typ gesetzliche Rente 2 Mann"
label var c71200 "Typ gesetzliche Rente 3 Mann"

label var c72100 "Typ gesetzliche Rente 1 Frau"
label var c72150 "Typ gesetzliche Rente 2 Frau"
label var c72200 "Typ gesetzliche Rente 3 Frau"

label var c66206 "Versorgungsbezüge Mann"
label var c66207 "Versorgungsbezüge Frau"

save "${dir_data}source/fast2010_small.dta", replace

/* erase temporary files*/
erase "${dir_data}source/temp/fast2010_pt1.dta"
erase "${dir_data}source/temp/fast2010_pt2.dta"
erase "${dir_data}source/temp/fast2010_pt3.dta"
erase "${dir_data}source/temp/fast2010_pt4.dta"
