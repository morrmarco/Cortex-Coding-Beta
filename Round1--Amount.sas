**********************************************************************************************

                                               Warning!

      Please note that you need to change the user ID (u58717790) to your own user ID!
      To do so, use CTRL+F, and find and replace all the instances of the user ID.

                                   
*********************************************************************************************;

* Create libraries 
 ==================;
libname cortex '/home/u58717790/my_shared_file_links/u39842936/Cortex Data Sets';
libname results '/home/u58717790/results';

 
 
* Merge datasets 'hist' and 'target_rd1'
===========================================================================;
DATA model_rd1;
   MERGE cortex.hist cortex.target_rd1;
   BY ID;
run;

 
* Delete missing values
============================================================================;
* You should come up with your own strategy to handle missing values;

* In this case, we are deleting all missing values;
data results.model_rd1;
set model_rd1;
if not cmiss(of _numeric_);
run;

* Split the data randomly (srs) into 2 samples: train = 0.6 and validation=0.4
=============================================================================;

proc surveyselect data=results.model_rd1 rate=0.6
out=  donor_select outall
method=srs
seed =1234;
run;

data results.train_rd1 results.test_rd1;
set donor_select;
if selected =1 then output results.train_rd1;
else output results.test_rd1;
run;

 
* Build models
=============================================================================;

******************* GLM model *********************;

ods graphics off;
proc glmselect data=results.train_rd1 testdata=results.test_rd1;
model AmtThisYear = Age Salary Seniority GaveLastYear;
title 'Regression of donation this year '
'Predictors';
code file='/home/u58717790/results/regression_1.sas';
run;

 
***************** Regression tree model **********;

proc arboretum data= results.train_rd1;
target AmtThisYear / level=interval;
input Age Salary Seniority/ level=interval;
input GaveLastYear /level=nominal;
score data=results.test_rd1 role=valid OUT=_NULL_ OUTFIT=results.DT_stat_rd1;
code file='/home/u58717790/results/decisiontree_1.sas' ;
quit;

 
*********Prepare the data for scoring***************;

*Merge datasets'score' and 'score_rd1';
DATA score_rd1;
   MERGE cortex.score cortex.score_rd1;
   BY ID;
run;

*Preform the same strategy for handling missing values for the score dataset;
*In this case, 'Delete missing values';
data results.score_rd1;
set score_rd1;
if not cmiss(of _numeric_);
run;

 
 
* Score new data based on your champion model
=============================================================================;

* In this case, based on ASE (Average Squared Error) criteria,
  the linear regression model performed better than the regression tree;
* Please refer to results tab for more details;

data results.result_rd1 (keep= id p_amtthisyear);
set results.score_rd1;
%include '/home/u58717790/results/regression_1.sas';
run;

 
 
* Export data in descending order of 'predicted amount this year'
=============================================================================;

* Sort data;
PROC SORT DATA=results.result_rd1;
    BY descending p_amtthisyear;
RUN;

*Export data to an xlsx file;
proc export data=results.result_rd1
outfile="/home/u58717790/results/Round1 Output.xlsx" dbms=xlsx
replace;
run;

 
* Download 'Round1 Output.xlsx' to your local PC.
To do so, choose your file (Round1 Output.xlsx) in the results folder, and from the panel above click on
download arrow;


