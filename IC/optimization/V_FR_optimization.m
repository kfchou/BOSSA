% do gradient ascent to maximuze STOI measures, as a function of voltage-FR
% parameters.
%
% IC voltage-FR parameters to vary
slope = 0.03;
center = -20;
thresh = -68.2381;
theta0 = [slope center thresh];

addpath('IC')
addpath('IC\optimization')
addpath('ObjectiveMeasure')
addpath('Recon')
inputLoc = 'IC\optimization\';
wavLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\006 wav library\';
inputs = ls([inputLoc '*.mat']);
tgtWavs = ls([wavLoc '*target.wav']);
tgtSptWavs = ls([wavLoc '*target_conv.wav']);
mixedWavs = ls([wavLoc '*mixed.wav']);

alpha = [.5 5 10]; %learning rate
nRuns = 10;

% initial calculation of cost function
out = cost(theta0,inputs,wavLoc,tgtWavs,tgtSptWavs,mixedWavs);
initCost = 3-sum(mean(out)); %initial cost

% optimize
theta = theta0*1.1;
currentCost = initCost;
tic
for j = 1:nRuns
    for i = 1:length(theta0)
        out = cost(theta(j,:),inputs,wavLoc,tgtWavs,tgtSptWavs,mixedWavs);
        newCost(j,i) = 3-sum(mean(out));
        theta(j+1,i) = theta(j,i) - alpha(i)*(newCost(j,i)-currentCost);
        currentCost = newCost(j,i);
    end
    runtime(j) = toc;
end

%% Alternatively, brute force it
slopes =  0.01:0.02:0.4;
centers = -60:5:0;
for slope = 1:length(slopes)
    for center = 1:length(centers)
%         theta = [slopes(slope),centers(center),thresh];
%         out(slope,center).st = cost(theta,inputs,wavLoc,tgtWavs,tgtSptWavs,mixedWavs);
        newCost(slope,center) = 3-sum(mean(out(slope,center).st));
    end
end

% best parameters so far
slope = 0.03;
center = 0;