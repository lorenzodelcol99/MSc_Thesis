Materials Related to Altig, Christiano, Eichenbaum, Linde, 
â€˜Firm-Specific Capital, Nominal Rigidities, and the Business Cycleâ€™.

The software related to the project is available here. You will need the 
code for the Andersen-Moore Algorithm (AndersenMoore.zip), general 
model-solving code (code2.zip), as well as the code designed 
specifically for this project (acelcode.zip). You can place  
all the files in one directory. If you place the code in three different 
directories, then run MATLAB in the directory where the model-specific 
code is located, and modify the setpath.m file to indicate the location 
of the Anderson-Moore and model-solving code.

 

You can replicate the results of the paper and execute robustness tests 
by running program main.m. The first section of this code allows the 
user to set parameters which control execution. To run the vector 
autoregression (VAR) part of the analysis, you may find it useful to 
work through this tutorial/homework assignment (vartutorial.pdf).

To analyze the equilibrium model, you may find this 
tutorial/homework useful (modelanalysis.pdf). The paper reports 
estimation results for a benchmark version of the model, as well as 
several perturbations. Detailed notes on how to reproduce these results 
can be found in the readme.m file.