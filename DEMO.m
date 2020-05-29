% This script is a demo of what is needed to process a single sentence
% mixture with the Physiologically Inspired Spatial Processing Algorithm,
% aka the Biologically Oriented Sound Segregation Algorithm.

% First, set up your stimuli
% Your stimuli to be processed must have be binaural (two channels)

target = [targetL targetR]; %target, for reference
mixed = [mixedL mixedR]; % sound mixture

ICrms = 100; %input gain
mixed = mixed./mean(rms(mixed)).*ICrms; %adjust average rms of mixture

% ====================== Peripheral model ======================
% The first part of BOSS is the peripheral filtering:
% mixedL and mixedR are the two channels of the sound mixture, with
% sampling frequency fs

%peripheral filter parameters
addpath('peripheral')
low_freq = 200; %min freq of the filter
high_freq = 8000;
numChannel = 64;
fs = 44100;
IC_param = sprintf('%iChan%i-%ihz',numChannel,low_freq,high_freq);
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

% resample inputs if necessary
% do here

% inputs before filtering should have rms of ~150;
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
randomness = 1;
azList = [-60,-30,0,30,60]; % Neuron preferred directions
tic
[spk_IC, firingrate] = ICmodel(s_filt,azList,randomness);
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
params.delay = 0;
cond = [3,4]; %conditions; reconstruction method to use.

data = struct();
params.maskRatio = 0.5;
params.tau = 0.02;
masks = calcSpkMask(spks,fs,params);

% method 1: difference-mask
if ismember(4,cond)
    [rstim, maskedWav] = applyMask(masks.diffMask,s_filt.sL,s_filt.sR,1,'filt');
    st = runStoi(rstim,target,fs);
    data(end+1).type = 'DiffMask';
    data(end).recon = rstim;
    data(end).st = st;
end

% method 2: cross-channel-mask
if ismember(4,cond)
    [rstim, maskedWav] = applyMask(masks.xMask,s_filt.sL,s_filt.sR,1,'filt');
    st = runStoi(rstim,target,fs);
    data(end+1).type = 'CrossMask';
    data(end).recon = rstim;
    data(end).st = st;
end

% ===================== compare to IRM =======================%
mixedERB_L = ERBFilterBank(mixed(:,1),fcoefs); 
mixedERB_R = ERBFilterBank(mixed(:,2),fcoefs); 
targERB_L = ERBFilterBank(target(:,1),fcoefs);
targERB_R = ERBFilterBank(target(:,2),fcoefs);
[IRMwavL,IRM,IBM] = calcIRM(targERB_L,mixedERB_L);
[IRMwavR,IRM,IBM] = calcIRM(targERB_R,mixedERB_R);
stoi.IRM = runStoi(target,[IRMwavL IRMwavR],fs);

% soundsc([IRMwavL; IRMwavR],fs)

% ======================= debugging/visualization =====================%
% plot spike rasters
addpath('C:\Users\Kenny\Desktop\GitHub\Plotting')

figure;
for i = 1:5
    subplot(1,5,i)
    icSpikes = logical(squeeze(spk_IC(:,:,i))');
    plotSpikeRasterFs(icSpikes, 'PlotType','vertline', 'Fs',40000);
    xlim([0 2000])
    if i==1, ylabel('IC spikes'); end
    set(gca,'Ytick',[1:64],'YtickLabel',cf)
end

% plot spectrograms
h = figure;
subplot(1,4,1)
plot_vspgram(target(:,1),Fs)
ylabel('Frequency (kHz)')
xlabel('time (s)')
title('target')
set(gca,'fontsize',12)
caxis([-150 10])

subplot(1,4,2)
plot_vspgram(sum(mixed,2)/2,Fs)
title('Mixed')
caxis([-0 150])

addpath('IRM')
subplot(1,4,3)
plot_vspgram(IRMwavL,Fs)
title('IRMed')
caxis([-150 10])
text(0.25,7500,{['STOI: ' num2str(round(stoi.IRM,2))]})

subplot(1,4,4)
plot_vspgram(data(3).recon(:,1),Fs)
title('DiffMask')
caxis([-100 150])
text(0.25,7500,{['STOI: ' num2str(round(data(3).st,2))]})

for i = 1:3
    subplot(1,4,i+1)
    set(gca,'yticklabel',[])
    set(gca,'xticklabel',[])
    xlabel('time (s)')
    set(gca,'fontsize',12)
end