
* Please dont forget to change 'u58717790' by your own user Number;

libname cortex '/home/u58717790/my_shared_file_links/u39842936/Cortex Data Sets';
libname results '/home/u58717790/Results';


/* merge dataset hist and target_rd1*/
DATA model_rd1; 
   MERGE cortex.hist cortex.target_rd1;
   BY ID;
run;

data results.model_rd1; /*drop na*/
set model_rd1;
if not cmiss(of _numeric_);
run;

/* data partition*/
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


* Please dont forget to change 'u58717790' by your own user Number;

/* glm model*/
ods graphics off;
proc glmselect data=results.train_rd1 testdata=results.test_rd1;
model AmtThisYear=Age Salary Seniority GaveLastYear;
title 'Regression of donation this year '
'Predictors';
code file='/home/u58717790/Results/regression_1.sas';
run;



* Please dont forget to change 'u58717790' by your own user Number;
/* decision tree model*/
proc arboretum data= results.train_rd1;
target AmtThisYear / level=interval;
input Age Salary / level=interval;
input GaveLastYear Seniority/level=nominal;
score data=results.test_rd1 role=valid OUT=_NULL_ OUTFIT=results.DT_stat_rd1;
code file='/home/u58717790/Results/decisiontree_1.sas' ;
quit;

/* scoring the data*/
DATA score_rd1;
   MERGE cortex.score cortex.score_rd1;
   BY ID;
run;

data results.score_rd1; /*drop na*/
set score_rd1;
if not cmiss(of _numeric_);
run;


* Please dont forget to change 'u58717790' by your own user Number;

data results.result_rd1 (keep= id p_amtthisyear);
set results.score_rd1;
%include '/home/u58717790/Results/regression_1.sas';
run;

/* Export data*/
PROC SORT DATA=results.result_rd1;
    BY descending p_amtthisyear;
RUN;

* Please dont forget to change 'u58717790' by your own user Number;

proc export data=results.result_rd1
outfile="/home/u58717790/Results/Round1 Output.xlsx" dbms=xlsx
replace;
run;
