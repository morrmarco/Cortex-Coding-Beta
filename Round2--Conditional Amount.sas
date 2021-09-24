*****************************************************************************************

                                                Warning!

      Please note that you need to change the user ID (u58717790) to your own user ID!

                                   
*****************************************************************************************;

 
* Create libraries 
 ==================;
libname cortex '/home/u58717790/my_shared_file_links/u39842936/Cortex Data Sets';
libname results '/home/u58717790/results';

 
* Merge datasets 'hist' and 'target_rd1'. Also, you need to filter the data
===========================================================================;

* Keep only the information of those who GavethisYear;
DATA model_rd2_amt;
   MERGE cortex.hist cortex.target_rd2;
   BY ID;
   if Gavethisyear=1;
run;

 
* Delete missing values
============================================================================;
* You should come up with your own strategy to handle missing values;

data results.model_rd2_amt;
set model_rd2_amt;
if not cmiss(of _numeric_);
run;

 
* Split the data randomly (srs) into 2 samples: train = 0.6 and validation=0.4
=============================================================================;
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

 
* Build models
=============================================================================;

******************* GLM model *********************;

ods graphics off;
proc glmselect data=results.train_rd2_amt testdata=results.test_rd2_amt;
model amtThisYear=Age Salary Seniority GaveLastYear contact/ selection=none;
title 'Regression of donation this year '
'Predictors';
code file='/home/u58717790/results/regression_2_amt.sas';
run;

 
***************** Regression tree model **********;

proc arboretum data= results.train_rd2_amt;
target AmtThisYear / level=interval;
input Age Salary / level=interval;
input GaveLastYear Seniority contact/level=nominal;
score data=results.test_rd2_amt role=valid OUT=_NULL_ OUTFIT=results.DT_stat_rd2_amount;
code file='/home/u58717790/results/decisiontree_2_amt.sas';
quit;

 
*********Prepare the data for scoring***************;

*Merge datasets 'score' and 'score_rd2_contact';

DATA contact_rd2;
   MERGE cortex.score cortex.score_rd2_contact;
   BY ID;
run;

*Preform the same strategy for handling missing values for the score dataset;
*In this case, 'Delete missing values';

data results.contact_rd2;
set contact_rd2;
if not cmiss(of _numeric_);
run;

 
* Score new data based on your champion model for members who where contacted
===============================================================================;

* In this case, based on ASE criteria,
  the linear regression model performed better than the regression tree;
* Please refer to RESULTS tab for more details;


/*Predict amount this year for members who were contacted*/
data results.amtcontact (keep= id p_amtthisyear rename=(p_amtthisyear=AmtContact));
set results.contact_rd2;
%include '/home/u58717790/results/regression_2_amt.sas';
run;


* Score new data based on your champion model for members who where not contacted
=================================================================================;

/*Merge datasets 'score' and 'score_rd2_nocontact*/
DATA nocontact_rd2;
   MERGE cortex.score cortex.SCORE_RD2_NOCONTACT;
   BY ID;
run;

/*Delete missing values*/
data results.nocontact_rd2;
set nocontact_rd2;
if not cmiss(of _numeric_);
run;

/*Predict amount this year for members who were not contacted*/
data results.amtnoncontact (keep= id p_amtthisyear rename=(p_amtthisyear=AmtNoContact));
set results.nocontact_rd2;
%include '/home/u58717790/results/regression_2_amt.sas';
run;

 
/* Merge data*/
DATA results.rd2_output_amt;
   MERGE results.amtcontact results.amtnoncontact ;
   BY ID;
run;


/* Export data*/
proc export data=results.rd2_output_amt
outfile="/home/u58717790/results/Round2 Output amt.xlsx" dbms=xlsx
replace;
run;


