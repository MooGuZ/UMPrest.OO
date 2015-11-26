# TO-DO List

## Nov 23, 2015
- [x] add TO-DO List
- [x] verify implementation of motion code of comodel with mathematical formula in the paper, and then create task on HPC to learn motion code with pure ICA model with different settings. [->] HPC seems have problem with GPU and license of new version MATLAB, run the program on desktop instead. The process approximately runs 4000 iterations per hour.
- [x] add a new class 'VideoInMAT'
- [x] implement function 'gradientCheck' [->] use function 'derivativeCheck' from package 'minFunc' instead
- [ ] implement function 'info'
- [ ] design draft of 'status'
- [x] add support to train specific layer in LearnerStack
- [x] add function 'statsample' to Dataset protocol
- [R] add function 'verifysample' to Dataset protocol -> implement in learner
- [] add support to process multiple video in the same time to comodel

## Nov 24, 2015
- [ ] check possibility to integrate 'derivateCheck' elegantly. If negative, implement a general form in 'tools'
- [x] add function 'restateDataBlock' to 'VideoDataset', and use it revise 'traverse'
- [x] add resolution information in sample from video dataset
- [ ] check result of motion learner with different distribution description of noise
- [x] rewrite 'VideoInMAT' to ensure the type-safety in using
- [x] check assistant information passing in the whole process -> copy all the information at this time, complexer solution is not necessary
- [x] replace randomlized mechanism with accurate count in dataset output methods when output in patch
