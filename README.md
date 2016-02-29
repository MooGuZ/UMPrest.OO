# UMPrest.OO
*Developed by MooGu Z. <hzhu@case.edu>*

### What is UMPrest.OO
UMPrest.OO is the Object-Oriented implementation of __UMPrest__ (**U**nified **M**otion re**Pres**en**T**ation) in __MATLAB__. While **UMPrest** aims at providing a programming framework to motion representation models to realize their theories with as little effort as possible. The framework deal with common parts in motion representation learning works, and provides essential application interface for new models. Normally, the implementation of a new model is equivalent to define a class in **MATLAB**.

### Typical Usage
> model = ConcreteMotionLearner(parameterOfModel);
> model.learn(ConcreteMotionMaterial(pathToMaterials));
> model.showrst();

### Fundamental Structure
**UMPrest.OO** provides two base classes : **MotionLearner** and **MotionMaterial**. The former has implemented fundamental workflow of a motion representation method, including setup and learning process. The later is the class corresponds to input video material. This class would provide an unified interface for MotionLearning to avoid complex preprocess of video data.

#### Crop Patches in MotionMatrial Objects
Field **enableCrop** in **MotionMatrial** would indicate whether or not current data source need crop to formate frames in data units. Besides, **patchSize** needed to be set when crop is enabled and it is initialized to **NaN**. Dependent field **pixelPerPatch** would calculate number of pixels in a patch according to first two element in **patchSize**.

If crop is inactivated, this program would require all input data frame in the same size. Otherwise, there is no requirement.

#### Data format
In this program, video data are stored as **uint8**, while convert to **double** (**gsingle** when GPU acceleration is enabled) before calculation.

#### Patch Module in MotionMaterial
**patchSize** set to **NaN** as default, which means disable patch module. In this case, output frame should be in the same dimension of input data.

#### Auto-Load System with cache
Input dimension (**dimin**) is fixed when patch module is off to ensure output dimension (**dimout**) be consist. Function **loadData** would check the dimension of loaded data to enfore this requirement.

#### MotionMaterial.istraversed
This function would check whether or not the input data is traversed. However, this property would update itself for next round after you check the value of it. So, if you call this function twice after you traversed a dataset, the first would return TRUE, while the other return FALSE.

#### GPU Acceleration Support
GPU acceleration support is implemented by library 'GPUModule’.  It provides interfaces ‘toGPU’ and ‘toCPU’ for subclasses to transfer variables to or gather them from GPU. In this way, MATLAB will automatically call GPU version functions in the calculations that involve these variables. A internal property named ‘enableGPU’ in this library checks the availability of GPU devices when the class is loaded in MATLAB. The implementation of this library make operations of ‘toGPU’ and ‘toCPU’ depend on ‘enableGPU’. Therefore, if there is no GPU device available, these two functions do nothing.

However, subclasses do not get GPU support for free here. They need to implement two functions : ‘clone’ and ‘gpuVariable’. The former one should create a new objects of this class, the later one is required to returns a cell array containing names of all fields that need to be transferred to GPU in calculation.

**Due to performance property, all value use *single* format in GPU, while *double* in CPU.**

#### Setup process and Statistic gathering mechanism
Setup process is definitely a pain here. It requires significant amount of data, while these data should be a good abstraction for the whole set. Besides, it is unavoidable to some data processing module (abstracted as DPModule) to be functional. Such as, whitening process. The problem happens when moving to a new dataset. Reinitialization may break some assertion, then lead to errors. However, it makes no sense to keep the same statistic information with new dataset. The solution I would like to try is let data processing modules to gather its statistic information gradually instead of an one-time setup. The problem of this solution is the speed of estimation in matching underlying statistic structure of the data in the progress and the new burden of calculation.

Current solution inject several properties and functions into DPModule without interface defined in class DPModule. Because statistic mechanism is a self-contained part should not be public to users. Besides, there is no library for it as GPUModule. Because different data processing module would focus on different statistical properties. Define a standard that can cover most of scenario may lead to more complex codes than it should be. Here, I use a methods that sampling input sample with constant probability, then update statistic property after an specific amount of samples been proceed. The update process would bias to the new comer a little bit to let the data processing module more adaptive. However, at the beginning, DPModule should take all the sample into statistic to get the initial one.

**However, here comes a problem. Some data processing modules, such as whitening, need to decides some input/output settings according to statistics.** Then, you cannot let it gather the information gradually. The key barrier here is model cannot easily adapted to varying dimensionality of input data. A simple (and rough) way to overcome this problem is specifying the dimensionality of whitening module in construction. However, this is method is obviously not idea at all. At the same time, to the essential of whitening process, it does not mean dimension reduction necessarily. Another way is whitening data without reducing the dimensionality gradually. Besides, add shrink and expend functionality to learning module. I prefer this solution very much.

Finally, it comes up a hybrid solution, that data processing module would have a function named 'setup', which would set the module in 'static' mode, otherwise the module would work in 'adaptive' mode.

**At last, due to the problems both in logic and programming, I have to abandon this mechanism at this time.**

#### Assistant Information Transmission Problem
According to the design, samples transferred between modules convey assistant information besides data. However, the assistant information is not general useful across all the modules. We don't want useless information contained in the samples, while we need necessary ones. Redundant information not only occupy unnecessary resources but also hurt the tightness of abstraction in the program, which leads to issues in maintenance. My solution here is let DPModule take responsibility to their output samples to make sure the sample contains all the information necessary and make the samples self-contained.

More specifically, DPModule should follow these rules:
1. modules that have nothing to do with meaning of data should bypass all the assistant information. Such as Recenter and NormDim.
2. modules that make a new representations should filter and control assistant information. Typical modules in this category is learner that convert the information into totally different space.

Because of the existence of inverse-process, the recovery of assistant information in the modules of second category is a problem. Generally speaking, my criteria is do your best effort. ~~Such as, property of 'frame resolution' in the samples from VideoDataset, when they get through DPModule whitening, this inforamtion would lost according to the meaning of whitening transformation. In the inverse-process, whitening module should add this property back to samples. Because the in-dimension and out-dimension for a specific whitening module, it can record resolution information of input samples. Furthermore, it also can check consistency of follwing input sample with it. Then, it is able to add resolution information in the inverse-process.~~ Take inverse-process as another process, and, if some property of input sample cannot recover from output sample (input sample in inverse-process), just leave it. Even though there maybe some trouble in the future, however, it makes sense in the way that this module would loss this kind of information in nature. The inverse-process would work in the whole program in logic. I would modify it when encounter concrete problem.

#### Setup Strategy of Data Processing Module (DPModule)
1. pure data processing module setup according to sample sets, the amount of it is decided outside of the class
2. data processing module with learning capabilities should setup based on dataset, not matter concrete one or virtual ones. Every concrete learning class define the setup process by itself. To different dataset, it can follow different paths. The key point here is keep setup process as simple as possible.
3. an addition mechanism is let setup function accept statistic structure from dataset in pure data processing module, and improve setup functions in learner class to support this shortcut by checking whether or not the dataset provides statistic information. Generally speaking, all the concrete dataset should provide statistic information. In this way, data processing modules should provide interface to describe the transformation of statistic features introduced by the process it provide. If the statistic of output can not be predict, this function should return NaN.


# New Design
1. Optimization is applied in the way that targeting class derived from Optimizable class, which provides API 'optimize()' and 'addGradient(grad, updatefunc)'. The minimum optimizable objects in the design is Unit. SubUnits who require optimization capability should declare an abstract property 'addGradient(grad, updatefunc)' and get access to 'wspace' of the Unit. Every objects call 'addGradient' to register their properties for optimization at first. Then, Unit call 'optimize()' to finish gradient and step size calculation process and apply update to all registered properties automatically through 'updatefunc' they provided in 'addGradient'.
2. For the connection problem, there seems no perfect solution. At this time, the design prefers to add two function handle 'fproc' and 'bproc' to class 'Connectable', then use method 'connect' to assign proper function to them according to the connection condition. Class 'Connectable' should provide several common functions for convenience. Units should set these two handle defaults to 'getData', which extract 'x' field if the input is a struct. 
