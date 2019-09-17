% This script is a demo of what is needed to process a single sentence
% mixture with the Physiologically Inspired Spatial Processing Algorithm,
% aka the Biologically Oriented Sound Segregation Algorithm.

% First, set up your stimuli
% Your stimuli to be processed must have be binaural (two channels)

target = [targetL targetR]; %target, for reference
mixed = [mixedL mixedR]; % sound mixture

% ====================== Peripheral model ======================
% The first part of BOSS is the peripheral filtering:
% mixedL and mixedR are the two channels of the sound mixture, with
% sampling frequency fs

%peripheral filter parameters
addpath('peripheral')
low_freq = 200; %min freq of the filter
high_freq = 8000;
numChannel = 64;
IC_param = sprintf('%iChan%i-%ihz',numChannel,low_freq,high_freq);
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(40000,cf,low_freq);

s_filt.sL=ERBFilterBank(mixedL,fcoefs); %freq*time
s_filt.sR=ERBFilterBank(mixedR,fcoefs);
s_filt.band = 'narrow';
s_filt.BW = bw;
s_filt.flist = cf;
s_filt.nf = nf;
s_filt.fs = fs;
s_filt.lowFreq = low_freq;
s_filt.highFreq = high_freq;

% ===================== Fischer's IC model ======================
% The second part of BOSS takes the filtered sound mixture and computes
% neural responses that correspond to each spatial location and frequency
addpath('IC')

% inputs: filtered L and R input channels and other parameters above
randonmess = 1;
azList = [-60,-30,0,30,60]; % Neuron preferred directions
tic
[spk_IC, firingrate] = ICmodel(s_filt,randonmess);
toc

% ===================== Reconstruction ======================
% outputs: 
%   rstim - reconstructed stimulus
%   stoi - objective score
addpath('recon')
addpath('ObjectiveMeasure')

% convert spike time cell array into binary
spks = spkTime2Train(spk_IC,fs,length(target));

% reconstruction parameters
params = struct();
params.fcoefs = fcoefs;
params.cf = cf;
params.fs = fs;
params.spatialChan = 3;
params.delay = 0;
cond = [3,4]; %conditions; reconstruction method to use.

% method 1: 0-deg FR mask.
if ismember(3,cond)
    params.type = 1;
    params.maskRatio = 0;
    params.tau = 0.018;
    [stoi,rstim] = recon_eval(spks,sum(target,2),target,mixed,params);
    wav1 = rstim.r1d;
    st1 = stoi.r1;
end

% method 2: difference-mask
if ismember(4,cond)
    params.type = 1;
    params.maskRatio = 0.5;
    params.tau = 0.02;
    [stoi,rstim] = recon_eval(spks,sum(target,2),target,mixed,params);
    wav2 = rstim.r1d;
    st2 = stoi.r2;
end


