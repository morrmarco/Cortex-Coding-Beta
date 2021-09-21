
* Please dont forget to change 'u58717790' by your own user Number;

libname cortex '/home/u58717790/my_shared_file_links/u39842936/Cortex Data Sets';
libname results '/home/u58717790/Results';


/* merge dataset hist and target_rd2*/
DATA model_rd2_amt; 
   MERGE cortex.hist cortex.target_rd2;
   BY ID;
   if Gavethisyear=1;
run;

data results.model_rd2_amt; /*drop na*/
set model_rd2_amt;
if not cmiss(of _numeric_);
run;

/* data partition*/
proc surveyselect data=results.model_rd2_amt rate=0.6 
out=  donor_select outall
method=srs
seed =1234; 
run;

data results.train_rd2_amt results.test_rd2_amt; 
set donor_select; 
if selected =1 then output results.train_rd2_amt; 
else output results.test_rd2_amt; 
run;


* Please dont forget to change 'u58717790' by your own user Number;

/* glm model*/
ods graphics off;
proc glmselect data=results.train_rd2_amt testdata=results.test_rd2_amt;
model amtThisYear=Age Salary Seniority GaveLastYear contact/ selection=none;
title 'Regression of donation this year '
'Predictors';
code file='/home/u58717790/Results/regression_2_amt.sas';
run;


* Please dont forget to change 'u58717790' by your own user Number;

/* decision tree model*/
proc arboretum data= results.train_rd2_amt;
target AmtThisYear / level=interval;
input Age Salary / level=interval;
input GaveLastYear Seniority contact/level=nominal;
score data=results.test_rd2_amt role=valid OUT=_NULL_ OUTFIT=results.DT_stat_rd2_amount;
code file='/home/u58717790/Results/decisiontree_2_amt.sas';
quit;

/* scoring the data*/

/* predict amtnextyear given contacted */
DATA contact_rd2;
   MERGE cortex.score cortex.score_rd2_contact;
   BY ID;
run;

data results.contact_rd2; 
/*drop na*/
set contact_rd2;
if not cmiss(of _numeric_);
run; 


* Please dont forget to change 'u58717790' by your own user Number;

data results.amtcontact (keep= id p_amtthisyear rename=(p_amtthisyear=AmtContact));
set results.contact_rd2;
%include '/home/u58717790/Results/regression_2_amt.sas';
run;

/* predict amtnextyear given not contacted */
DATA nocontact_rd2;
   MERGE cortex.score cortex.SCORE_RD2_NOCONTACT;
   BY ID;
run;

data results.nocontact_rd2; /*drop na*/
set nocontact_rd2;
if not cmiss(of _numeric_);
run;


* Please dont forget to change 'u58717790' by your own user Number;

data results.amtnoncontact (keep= id p_amtthisyear rename=(p_amtthisyear=AmtNoContact));
set results.nocontact_rd2;
%include '/home/u58717790/Results/regression_2_amt.sas';
run;



/* Export data*/

DATA results.rd2_output_amt;
   MERGE results.amtcontact results.amtnoncontact ;
   BY ID;
run; 


* Please dont forget to change 'u58717790' by your own user Number;

proc export data=results.rd2_output_amt
outfile="/home/u58717790/Results/Round2 Output amt.xlsx" dbms=xlsx
replace;
run;
