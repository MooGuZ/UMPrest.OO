# TO-DO List

## Nov 23, 2015
- [x] add TO-DO List
- [x] verify implementation of motion code of comodel with mathematical formula in the paper, and then create task on HPC to learn motion code with pure ICA model with different settings. [->] HPC seems have problem with GPU and license of new version MATLAB, run the program on desktop instead. The process approximately runs 4000 iterations per hour.
- [x] add a new class 'VideoInMAT'
- [x] implement function 'gradientCheck' [->] use function 'derivativeCheck' from package 'minFunc' instead
- [x] add support to train specific layer in LearnerStack
- [x] add function 'statsample' to Dataset protocol
- [R] add function 'verifysample' to Dataset protocol -> implement in learner

## Nov 24, 2015
- [x] add function 'restateDataBlock' to 'VideoDataset', and use it revise 'traverse'
- [x] add resolution information in sample from video dataset
- [x] rewrite 'VideoInMAT' to ensure the type-safety in using
- [x] check assistant information passing in the whole process -> copy all the information at this time, more complex solution is not necessary
- [x] replace randomization mechanism with accurate count in dataset output methods when output in patch

## Nov 30, 2015
- [x] check result of motion learner with different distribution description of noise
- [x] separate AutoSave and UtilityLib
- [x] run experiment 'MotionLearnerExtend' on HPC
- [x] add property in AutoSave to support specifying object Name
- [x] change all the base class from 'hgsetget' to 'handle'
- [C] add statistic structure in VideoDataset and provide interface of statistic() in Dataset. The setup function in DPModule should be able to deal with both Dataset and samples -> 'statistic' is provided, while pure data processing module deal with samples, and learners setup with dataset.
- [x] test GPU functionality on HPC : failed, assignment of sample's subfield in GPU memory cause error.

## Dec 08, 2015
- [x] revise 'setup' function with new standard
- [x] remove output parameter of 'setup' function
- [x] enforce 'dimin' and 'dimout' to be a single number
- [x] remove 'traverse' mechanism from Datasets
- [x] add restriction of number of samples proceed at once to 'RealICA' and 'ComplexICA'
- [x] check result of experiment 'MotionLearnerExtend'
- [x] add support to process multiple samples to comodel

## Dec 09, 2015
- [x] build up standard for samples between modules, especially the assistant information part
- [C] general random number generator -> inverse transform method can not be generalized in program, just create random number generator for specific distributions

## Dec 10, 2015
- [ ] add test scripts to the project
- [ ] check possibility to integrate 'derivateCheck' elegantly. If negative, implement a general form in 'tools'

## Jan 12, 2016
- [ ] check correctness of objective function of COCBaseLearner

## Future
- [ ] implement function 'info'
- [ ] design draft of 'status'
- [ ] run experiment 'RealICADebug' on HPC
- [ ] run experiment 'SmoothPhase' on HPC
- [ ] consider the value of default implementation instead of interface in some cases, such as update@RealICA
- [ ] remove LearnerGroup and implement LearnerNetwork
- [ ] implement transform-mask model
