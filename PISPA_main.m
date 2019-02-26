% paths
% simulation params
% prep stimuli
% IC
% Network
dsPath = '..\dynasim'; % dynasim path
ICPath = '';
networkPath = '';

addpath('Peripheral');
addpath('hrtf');
addpath('IC');
dataDir = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0';

%======================== set config =======================
experiment_name = '003 spatial_tuning IC_spk debug';

% Stimulus parameters
% Each cell element is a trial
speakerIdxs = 2;
talkers = 4;
% azs = {[0],[0 90], [0 90 -90]};
% azs = {[0]};
% azs = num2cell(zeros(1,20)); %for-loop vector must be horizontal. Fun fact.
% azs = num2cell(-90:10:90);
azs = num2cell([90]);
experiment_setup = sprintf('T at 0 talker%d',talkers);

%peripheral filter parameters
low_freq = 200; %min freq of the filter
high_freq = 8000;
numChannel = 64;
IC_param = sprintf('%iChan%i-%ihz',numChannel,low_freq,high_freq);

%other parameters...
fs = 40000;
input_gain = 500;
snr = 1;
numTrials = 1;
freqGainNorm = 0;

%==============================================================

dataLoc = sprintf('%s\\Data\\%s %s\\%s\\',dataDir,experiment_name,IC_param,experiment_setup);
if ~exist(dataLoc,'dir'), mkdir(dataLoc); end

%make backup of current script
FileName=mfilename;
newbackup=sprintf('%s%s_backup.m',dataLoc,mfilename);
currentfile=strcat(FileName, '.m');
copyfile(currentfile,newbackup);

%peripheral filtering parameters
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(40000,cf,low_freq);

for az_cell = azs
    az = cell2mat(az_cell);

    for speakerIdx = speakerIdxs
        % ====================== audio inputs =======================
        trial_id = sprintf(['%d_masker_set_%02d_pos' repmat('_%02d',1,length(az)) 'degAz'],length(az)-1,speakerIdx,az)
        [s_mixed, s_original] = stimulus_setup(talkers,speakerIdx,az,input_gain,snr);
        mixed = [s_mixed.sL s_mixed.sR];
        mixed = mixed/max(max(abs(mixed)));
        audiowrite(sprintf('%s%s_mixed.wav',dataLoc,trial_id),mixed,fs);

        %reference signals = original filtered signal = target for STOI
        clear refC ref
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

        % ====================== Peripheral model ======================
        % plot_filterbankSupport;
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
        if freqGainNorm
            temp = mean(abs(s_filt.sL),2); %mean of each freq channel
            frgain = 1./(temp/max(temp));
            frgain = frgain*ones(1,length(s_filt.sL));
            s_filt.sL = s_filt.sL.*frgain;
            s_filt.sR = s_filt.sR.*frgain;
            save(sprintf('%s%s_frgains.mat',dataLoc,trial_id),'frgain');
        end

        % Fischer's IC model
        randonmess = 1;
        tic
        [spk_IC, firingrate] = ICmodel(s_filt,randonmess);
        toc
        save(sprintf('%s%s_SpkIC.mat',dataLoc,trial_id),'spk_IC','freqGainNorm','input_gain','cf','fcoefs');

    end
end
