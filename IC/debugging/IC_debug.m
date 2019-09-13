% Debugging IC model
% set directory to CISPAA
cd('Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0')
addpath('Peripheral')
addpath('IC')
[target,fs] = audioread('Data\001 IC_spk 64Chan150-8000hz\TM at 0_90 -FreqGainNorm talker4\TM_00_90_set_01_mixed.wav');

%%
low_freq = 150; %min freq of the filter
high_freq = 8000;
numChannel = 64;
 
%apply peripheral filters
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

%%
% set up struct for IC model
s_filt.sL=ERBFilterBank(target(:,1)*1500,fcoefs); %freq*time
s_filt.sR=ERBFilterBank(target(:,2)*1500,fcoefs);
s_filt.band = 'narrow';
s_filt.BW = bw;
s_filt.flist = cf;
s_filt.nf = nf;
s_filt.fs = fs;

% IC model module. [spk, firingrate] = ICmodel(s_filt,randomness)
randomness = 1;

nf = s_filt.nf;
n_signal = length(s_filt.sL);
       
[preferredITD, np, side] = SetLocalizationParameters(3, nf);
[spk_IC, firingrate, s_filt] = ICcl(s_filt,nf,preferredITD,np,side,randomness);

sum(sum(spk_IC))
%%
t = 0:1/fs:100/1000;
A = t.*exp(-t/0.05);
mask = conv2(spk_IC',A,'same');
figure;imagesc(mask); title('spk-mask')

%%
temp = db(s_filt.sL);
temp(temp<-80) = -80;
figure;imagesc(temp); title('ERB-filtered stimulus')

%% what does mask sound like? pretty good :)
addpath('Recon');
A = t.*exp(-t/0.007);
mask = conv2(spk_IC',A,'same');
recon = vocode(mask,cf,'tone');
soundsc(recon,fs);