% function gen_spk_IC_v4(subjectNum)
% Script for processing each blocks according to the conditions given
% v4 - removed IRM cases
% v4a - instead of applying gain independently (which destroys ILDs), apply
%       equal gain to both L and R channels. Previous implementation was OK
%       as long as the L and R channels were balanced (i.e. have talkers
%       on both sides).
% v4b - resample audio to x kHz before processing

subjectNum = 21;
% cd('C:\Users\kfcho\Documents\GitHub\PISPA2.0')
cd('C:\Users\Kenny\Desktop\GitHub\PISPA2.0')
stimLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\BOSSAlgo\';
addpath('Peripheral')
addpath('HRTF')
addpath('IC')
addpath('Development_scripts')

blockFolderLoc = sprintf('%sExperiment Stimuli/subject %03i/',stimLoc,subjectNum);
blockFolders = dir(blockFolderLoc);
blockFolders(2) = [];
blockFolders(1) = [];
load([blockFolderLoc blockFolders(1).name '/stimuli_info.mat']);

%peripheral filtering
low_freq = 150; %min freq of the filter
high_freq = 8000;
numChannel = 64;
fs = 44100;
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);
       
%input gain for IC - need some kind of a gain-control
ICgain = 500; % based on CRM, assuming original sentences have 0.1 rms before HRTF filtering

%data storage info
exp = '010 resample to 16k';
storeLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\010';
%% process each block
for block = 3%1:data.exp.nBlocks
    currentBlockFolderLoc = [blockFolderLoc blockFolders(block).name filesep];
    load([currentBlockFolderLoc 'stimuli_info.mat']);
    numTrials = length(data.stim.tmr);
    % process all non-KEMAR blocks
    % cond 0 = TARGET
    % cond 1 = KEMAR
    % cond 2 = BEAMAR
    % cond 3, 4, & 5 process with algorithm
    disp(['processing block ' num2str(block)])
    if data.stim.cond == 0, continue; end %training
    if data.stim.cond == 1, continue; end %KEMAR
    if data.stim.cond == 2, continue; end %BEAMAR
      
    %%%%%%%%% Other cases: run peripheral IC model using CISPA2.0 %%%%%%%%%%
    for trial = 1%1:numTrials
        mixName = ls([currentBlockFolderLoc sprintf('wavdata trial%02i*.mat',trial)]);
        myfile = load([currentBlockFolderLoc strtrim(mixName)],'Fs','mixed','target');
        target = myfile.target;
        mixed = myfile.mixed;
        Fs = myfile.Fs;
        mixed = resample(mixed,fs,Fs);
        target = resample(target,fs,Fs);
        disp(['processing mixed file: ' mixName])
        
        % Peripheral model
        s_filt = struct();
        s_filt.band = 'narrow';
        s_filt.BW = bw;
        s_filt.flist = cf;
        s_filt.nf = nf;
        s_filt.lowFreq = low_freq;
        s_filt.highFreq = high_freq;
        s_filt.sL = ERBFilterBank(mixed(:,1),fcoefs)*ICgain; %freq*time
        s_filt.sR = ERBFilterBank(mixed(:,2),fcoefs)*ICgain;
        s_filt.fs = fs;

        % IC model
        randonmess = 0;
        azList = [-60,-30,0,30,60];
        tic;
        [spk_IC, firingrate] = ICmodel(s_filt,azList,randonmess);
        toc
        storeBlock = fullfile(storeLoc,sprintf('block %02i',block));
        if ~exist(storeBlock,'dir'),mkdir(storeBlock);end
        mySave(sprintf('%strial_%02i_SpkIC.mat',storeBlock,trial),spk_IC,cf,fcoefs,azList,fs,length(mixed));
        
        spks = spkTime2Train(spk_IC,fs,length(target));
        params = struct();
        params.fcoefs = fcoefs;
        params.cf = cf;
        params.fs = fs;
        params.spatialChan = 3;
        params.delay = 0;

        % spkMask
        params.type = 1;
        params.maskRatio = 0.5;
        params.tau = 0.018;
        [st,rstim] = recon_eval(spks,target,mixed,params);
        pesq_mex(resample(target,16000,fs),resample(rstim.r1d,16000,fs),16000,'narrowband')
        soundsc(rstim.r1d,fs);
        audiowrite([storeLoc filesep 'cc1us_recon100khz.wav'],rstim.r1d*5,fs);
    end
end

disp('IC spike generation complete')

