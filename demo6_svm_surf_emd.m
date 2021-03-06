%% Image Classification
% Bag of Visual Words(HOG + kmeans) + SVM(EMD kernel)
% Data set: Caltech 101
% Load Images
% The calculation of EMD kernel matrix is extremely time-comsuming

% Huayu Zhang, May 2015

addpath('utils');
addpath('imagefeatures');
addpath('svmdesign');
addpath('pcas');
run(fullfile('vlfeat','toolbox','vl_setup.m'));

%% parameters
% file I/O 
rootFolder = fullfile('../data','Caltech','101_ObjectCategories');
istrim = true;
% random 
rng(1);
% classes
NumberSelect = 6; 
% ClassIndices = randperm(size(classes,1),NumberSelect);
ClassIndices = [1,2,4,5,7,96]; % 200+
% feature extraction
BoWParams = struct('DetectorName','SURF','DescriptorName','SURF',...
    'DescriptorParams',struct('SURFSize',128),'k',200,'MaxFeatures',200,'type','tf');
% KPCA
th = 0.95;
% SVM Design
percentage = [0.4]; % percentage for training
svmOptions = templateSVM('BoxConstraint', 1, 'KernelFunction', 'linear',...
    'standardize',1);

%% Load Images
imgSets = loadImages(rootFolder, ClassIndices, istrim);
dispSamples(imgSets, 1); % display sample

%% Learning
% division
[trainingSets, testingSets] = partition(imgSets, percentage, 'randomize');
% feature extration
[trainingFeatures, trainingLabels, testingFeatures, ...
    testingLabels, C] = bagOfVisualWords(trainingSets,testingSets,BoWParams);
% KPCA
D = groundDistMat(C);
kernelFuncParams = struct('D',D,'type','auto','A',100);
[Ktrain, Ktest] = emdkernel(trainingFeatures, testingFeatures, kernelFuncParams);
[trainingKPCAs, testingKPCAs] = kernelPCA(Ktrain, Ktest, th);
% SVM training
SVMMdl = fitcecoc(trainingKPCAs, trainingLabels,'Learners',svmOptions);
% cross validation
CVMdl = crossval(SVMMdl);
oosLoss = kfoldLoss(CVMdl);
fprintf('Cross Validation Error: %f.\n',oosLoss);
% prediction
trainingPredictions = predict(SVMMdl,trainingKPCAs);
testingPredictions = predict(SVMMdl,testingKPCAs);
% confusion matrix
Ctrain = confusionmat(trainingLabels,trainingPredictions);
Ctest = confusionmat(testingLabels,testingPredictions);
dispConfusionMatrices(Ctrain,Ctest);