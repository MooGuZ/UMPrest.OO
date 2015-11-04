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

### Patch Module in MotionMaterial
**patchSize** set to **NaN** as default, which means disable patch module. In this case, output frame should be in the same dimension of input data.

#### Auto-Load System with cache
Input dimension (**dimin**) is fixed when patch module is off to ensure output dimension (**dimout**) be consist. Function **loadData** would check the dimension of loaded data to enfore this requirement.

#### MotionMaterial.istraversed
This function would check whether or not the input data is traversed. However, this property would update itself for next round after you check the value of it. So, if you call this function twice after you traversed a dataset, the first would return TRUE, while the other return FALSE.
