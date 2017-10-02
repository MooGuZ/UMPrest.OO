# Separated Recurrent Model for NPLab3D

![material/DesignPlot.png](Network Design)

This experiment tries to test PHLSTM-Codec's power on 3D motion dataset. Before it, I have tried original PHLSTM-Codec on NPLab3D dataset, and obtained frame-mean as prediction. However, even earlier, I tested *RecCO* model on NPLab3D and obtained predictions that can get a sense of motion (very weak though). This time, I would like to combine them together. This design is essential a codec for *RecCO* unit.

Mon Oct  2 14:39:10 EDT 2017
After about 60 hours training, model run 70k iterations (batchsize = 32). The result I get can reconstruct a better result than *RecCO* model. It can correctly predict the transformation of objects (opposite to background). So in scaling and rotation with object away from center I can get a good sense of motion in the model prediction of 15 frames based on 15 frames input. However, the reconstruction of background (most of time is the ground in 3D scenes) is quite noisy and cannot preserve its motion pattern. This is easy to understand. Because the texture on the ground is very weak and can not make big difference in terms of MSE in reconstruction. So, the objective function I used in training pretend to make trade-off on it. Besides, there is underlying overfitting problem in this model. Currently, effective dimension (after whitening) of a frame is 269, while only 20k sequence used in training, and I don't make separation of training and testing set here.

Mon Oct  2 18:06:00 EDT 2017
Use Dual-PHLSTM (DPHLSTM) to continue the optimization process on NPLab3D dataset.
