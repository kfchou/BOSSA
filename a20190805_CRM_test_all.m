% signal through encoder, process via network
% 20190411 - works with variable spatial tuning parameters, for modeling
%            neurons with different spatial preferences
% 20190821 - this file works on the SCC

% --- paths for linux based systems ---
% addpath('~/BOSS_algo_psychoacoustics/Peripheral');
% addpath('HRTF_40k');
% addpath('~/BOSS_algo_psychoacoustics/IC');
% addpath('~/BOSS_algo_psychoacoustics/Recon')
% experiment_name = 'CRM_SymmetricalMaskers';

% --- paths for windows based systems ---
addpath('../Peripheral');
addpath('C:\Users\Kenny\Desktop\GitHub\PISPA2.0\HRTF');
addpath('../IC');
addpath('../Recon')
experiment_name = 'CRM_SymmetricalMaskers';

%======================== set parameters =======================
dataDir = 'SimDebug';

% Stimulus parameters
% Each cell element is a trial
speakerIdxs = 1:20;
% speakerIdxs = {{'030105'}};
talkers = 4;
% azs = {[0],[90], [0 90]};
% azs = {[0,90,-90]};
m1pos = 90:-5:-90;
m2pos = -90:5:90;
tpos = zeros(length(m1pos),1);
azs = num2cell([tpos m1pos' m2pos'],2)';
% azs = num2cell(zeros(1,20)); %for-loop vector must be horizontal. Fun fact.
% azs = num2cell(-90:10:90);
% azs = num2cell([90]);
experiment_setup = sprintf('CRM talker%d',talkers);

%peripheral filter parameters
low_freq = 200; %min freq of the filter
high_freq = 20000;
numChannel = 64;
IC_param = sprintf('%iChan%i-%ihz',numChannel,low_freq,high_freq);

%other parameters...
fs = 40000; %CRM sampling freq
input_gain = 500;
snr = 1;
numTrials = 1;
freqGainNorm = 0;

%==============================================================

dataLoc = sprintf('%s/Data/%s %s/%s/',dataDir,experiment_name,IC_param,experiment_setup);
if ~exist(dataLoc,'dir'), mkdir(dataLoc); end

%make backup of current script
FileName=mfilename;
newbackup=sprintf('%s%s_backup.m',dataLoc,mfilename);
currentfile=strcat(FileName, '.m');
copyfile(currentfile,newbackup);

%peripheral filtering parameters
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

parfor ii = 1:length(azs)
    az = azs{ii};
    
    for speakerIdx = speakerIdxs
        disp(['currently procesing idx: ' num2str(speakerIdx)])
        if iscell(speakerIdx)
            if length(az) ~= length(speakerIdx{1}), error('undefined configuration');end
            binnum = str2num(cell2mat(speakerIdx{1}'))';
            trial_id = sprintf(['%d_masker' repmat('_%06d',1,length(speakerIdx{1})) '_pos' repmat('_%02d',1,length(az)) 'degAz'],length(az)-1,binnum,az)
            [s_mixed, s_original] = stimulus_setup(talkers,speakerIdx{1},az,input_gain,snr);
        else
            trial_id = sprintf(['%d_masker_set_%02d_pos' repmat('_%02d',1,length(az)) 'degAz'],length(az)-1,speakerIdx,az)
            [s_mixed, s_original] = stimulus_setup(talkers,speakerIdx,az,input_gain,snr);
        end
        mixed = [s_mixed.sL s_mixed.sR];
        mixed = mixed/max(max(abs(mixed)));
        audiowrite(sprintf('%s%s_mixed.wav',dataLoc,trial_id),mixed,fs);

        %reference signals = original filtered signal = target in STOI
        ref = [];
        refC = [];
        speaker_id = {'target.wav','masker1.wav','masker2.wav'};
        speaker_conv_id = {'target_conv.wav','masker1_conv.wav','masker2_conv.wav'};
        for i = 1:length(s_original)
            ref = s_original(i).wav;
            audiowrite(sprintf('%s%s_%s',dataLoc,trial_id,speaker_id{i}),ref,fs);

            refC = [s_original(i).convolvedL s_original(i).convolvedR];
            refC = refC/max(max(abs(refC)));
            audiowrite(sprintf('%s%s_%s',dataLoc,trial_id,speaker_conv_id{i}),refC,fs);
        end

        % run model

        % Peripheral model
        % plot_filterbankSupport;
        s_filt = struct();
        s_filt.sL=ERBFilterBank(s_mixed.sL,fcoefs); %freq*time
        s_filt.sR=ERBFilterBank(s_mixed.sR,fcoefs);
        s_filt.band = 'narrow';
        s_filt.BW = bw;
        s_filt.flist = cf;
        s_filt.nf = nf;
        s_filt.fs = s_mixed.fs;
        s_filt.lowFreq = low_freq;
        s_filt.highFreq = high_freq;

        %frequency gain normalization across channels
        frgain = 1;
        if freqGainNorm
            temp = mean(abs(s_filt.sL),2); %mean of each freq channel
            frgain = 1./(temp/max(temp));
            frgain = frgain*ones(1,length(s_filt.sL));
            s_filt.sL = s_filt.sL.*frgain;
            s_filt.sR = s_filt.sR.*frgain;
            save(sprintf('%s%s_frgains.mat',dataLoc,trial_id),'frgain');
        end

        % Fischer's IC model
        randomness = 1;
        azList = [-90,-45,0,45,90];
        tic
        [spk_IC, firingrate] = ICmodel(s_filt,azList,randomness);
        toc
        mysaveSpks(sprintf('%s%s_SpkIC.mat',dataLoc,trial_id),spk_IC,freqGainNorm,input_gain,cf,fcoefs);
        
        % mask calculation
        spks = spkTime2Train(spk_IC,fs,length(mixed));
        maskParam = struct();
        maskParam.kernel = 'alpha';
        maskParam.tau = 0.02;
        maskParam.delay = 0;
        maskParam.maskRatio = 0;
        masks = calcSpkMask(spks,fs,maskParam);
        masksNorm = zeros(size(masks));
        if ndims(masks) == 3
            % normalize masks
            for i = 1:size(masks,3)
                masksNorm(:,:,i) = masks(:,:,i)/max(max(masks(:,:,i)));
            end

            % remove side channels
            centerM = masksNorm(:,:,3);
            rightM1 = masksNorm(:,:,5);
            rightM2 = masksNorm(:,:,4);
            leftM1 = masksNorm(:,:,1);
            leftM2 = masksNorm(:,:,2);
            spkMask = centerM-maskParam.maskRatio.*(rightM1+leftM1+leftM2+rightM2);
            spkMask(spkMask<0)=0; %half wave rectify
        else
            spkMask = masks;
        end
        spkMask = spkMask./max(max(abs(spkMask))); %normalize to [0,1]
        
        % Reconstruction
        [rstim1dual, ~] = applyMask(spkMask,s_filt.sL,s_filt.sR,frgain,'filt');
        audiowrite(sprintf('%s%s_recon.wav',dataLoc,trial_id),rstim1dual/max(max(rstim1dual))*.99,fs)
        
        % Calculate scores
        st = zeros(1,3);
        for jj = 1:3
            st(jj) = runStoi(rstim1dual,s_original(jj).wav,fs,fs);
        end
        stFilename = sprintf('%s%s_stoi.mat',dataLoc,trial_id);
        mysaveSTOI(stFilename,st);
    end
end
disp('job finished')
