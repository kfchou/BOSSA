function recon = runF0(rstim4,fs)

% the syntax uses an older version of voicebox
addpath('C:\Users\Kenny\Dropbox\Sen Lab\phase_estimation_temp\voicebox')

% parameters
hamSize = 6;
maskingParams.nHarmonics = 20;
maskingParams.smoothing = hamming(hamSize);
maskingParams.attenuation = 0.00001;
maskingParams.region = 'all';
maskingParams.fcutoff = 1500;
debugParam.plotting = 0;

%% perform postprocessing
tempL = f0_emphasis(rstim4(:,1),fs,maskingParams,debugParam);
tempR = f0_emphasis(rstim4(:,2),fs,maskingParams,debugParam);
n = min(length(tempL),length(tempR));
recon = [tempL(1:n) tempR(1:n)];
