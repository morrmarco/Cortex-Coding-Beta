

* Please dont forget to change 'u58717790' by your own user Number;

libname cortex '/home/u58717790/my_shared_file_links/u39842936/Cortex Data Sets';
libname results '/home/u58717790/Results';


/* merge dataset hist and target_rd2*/
DATA model_rd2_prob; 
   MERGE cortex.hist cortex.target_rd2;
   BY ID;
run;

data results.model_rd2_prob; /*drop na*/
set model_rd2_prob;
if not cmiss(of _numeric_);
run;

/* data partition*/
proc surveyselect data=results.model_rd2_prob rate=0.6 
out=  donor_select outall
method=srs
seed =1234; 
run;

data results.train_rd2_prob results.test_rd2_prob; 
set donor_select; 
if selected =1 then output results.train_rd2_prob; 
else output results.test_rd2_prob; 
run;


* Please dont forget to change 'u58717790' by your own user Number;

/* glm model*/
ods graphics off;
proc glmselect data=results.train_rd2_prob testdata=results.test_rd2_prob;
model gaveThisYear=Age Salary Seniority GaveLastYear contact;
title 'Regression of donation this year '
'Predictors';
code file='/home/u58717790/Results/regression_2_prob.sas';
run;


* Please dont forget to change 'u58717790' by your own user Number;

/* decision tree model*/
proc arboretum data= results.train_rd2_prob;
target GaveThisYear / level=nominal;
input Age Salary / level=interval;
input GaveLastYear Seniority contact/level=nominal;
score data=results.test_rd2_prob role=valid OUT=_NULL_ OUTFIT=results.DT_stat_rd2_prob;
code file='/home/u58717790/Results/decisiontree_2_prob.sas';
quit;

/* scoring the data*/

/* predict givenextyear given contacted */
DATA contact_rd2;
   MERGE cortex.score cortex.score_rd2_contact;
   BY ID;
run;

data results.contact_rd2; /*drop na*/
set contact_rd2;
if not cmiss(of _numeric_);
run;


* Please dont forget to change 'u58717790' by your own user Number;

data results.predcontact (keep= id p_gavethisyear rename=(p_gavethisyear=PContact));
set results.contact_rd2;
%include '/home/u58717790/Results/regression_2_prob.sas';
run;

/* predict givenextyear given not contacted */

DATA nocontact_rd2;
   MERGE cortex.score cortex.SCORE_RD2_NOCONTACT;
   BY ID;
run;

data results.nocontact_rd2; /*drop na*/
set nocontact_rd2;
if not cmiss(of _numeric_);
run;


* Please dont forget to change 'u58717790' by your own user Number;

data results.prednoncontact (keep= id p_gavethisyear rename=(p_gavethisyear=PNoContact));
set results.nocontact_rd2;
%include '/home/u58717790/Results/regression_2_prob.sas';
run;


/* Export data*/

DATA results.rd2_output_prob;
   MERGE results.predcontact results.prednoncontact;
   BY ID;
run; 


* Please dont forget to change 'u58717790' by your own user Number;

proc export data=results.rd2_output_prob
outfile="/home/u58717790/Results/Round2 Output prob.csv" dbms=csv
replace;
run;


