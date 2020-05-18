% signal through encoder, process via network
% 20190411 - works with variable spatial tuning parameters, for modeling
%            neurons with different spatial preferences

cd('C:\Users\Kenny\Desktop\GitHub\PISPA2.0')
addpath('Peripheral');
addpath('hrtf');
addpath('IC');
experiment_name = 'SpatialTuningData';
dataDir = 'C:\Users\Kenny\Desktop\GitHub\PISPA2.0\IC\';

%======================== set parameters =======================

% Stimulus parameters
% Each cell element is a trial
speakerIdxs = 1;
% speakerIdxs = {{'030105'}};
talkers = 4;

%%%% location syntax examples %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% each cell is one trial %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% each cell element describes locations of sources %%%%%%
% azs = {[0],[90], [0 90]};
% azs = {[-90,90]};
% azs = num2cell(zeros(1,20)); %for-loop vector must be horizontal. Fun fact.
% azs = num2cell(-90:5:90); % single CRM, various locations
% azs = num2cell([90]);

%two CRM senences, one varying in location, other at 90 deg
az1 = -90:5:90;
az2 = ones(1,length(az1))*90;
azs = mat2cell([az1' az2'],ones(length(az1),1),2)';

experiment_setup = sprintf('CRM talker%d',talkers);

%peripheral filter parameters
low_freq = 200; %min freq of the filter
high_freq = 8000;
numChannel = 64;
IC_param = sprintf('%iChan%i-%ihz',numChannel,low_freq,high_freq);

%other parameters...
fs = 40000; %CRM sampling freq
input_gain = 500;
snr = 1;
numTrials = 1;
freqGainNorm = 0;

%==============================================================

dataLoc = sprintf('%s\\Data\\%s %s\\%s\\',dataDir,experiment_name,IC_param,experiment_setup);
if ~exist(dataLoc,'dir'), mkdir(dataLoc); end

%peripheral filtering parameters
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

for az_cell = azs
    az = cell2mat(az_cell);
    
    for speakerIdx = speakerIdxs
        if iscell(speakerIdx)
            if length(az) ~= length(speakerIdx{1}), error('undefined configuration');end
            binnum = str2num(cell2mat(speakerIdx{1}'))';
            trial_id = sprintf(['%d_masker' repmat('_%06d',1,length(speakerIdx{1})) '_pos' repmat('_%02d',1,length(az)) 'degAz'],length(az)-1,binnum,az)
            [s_mixed, s_original] = stimulus_setup(talkers,speakerIdx{1},az,input_gain,snr);
        else
            trial_id = sprintf(['%d_masker_set_%02d_pos' repmat('_%02d',1,length(az)) 'degAz'],length(az)-1,speakerIdx,az)
            [s_mixed, s_original] = stimulus_setup(talkers,speakerIdx,az,input_gain,snr);
        end

        % run model

        % Peripheral model
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

        % Fischer's IC model
        randomness = 1;
        azList = [-90,-60,-45,-30,0,30,45,60,90];
        tic
        [spk_IC, firingrate] = ICmodel(s_filt,azList,randomness);
        toc
        save(sprintf('%s%s_SpkIC.mat',dataLoc,trial_id),'spk_IC','freqGainNorm','input_gain','cf','fcoefs');
        
    end
end

%%
% addpath('recon')
% % temp = vocode(firingrate(:,:,3)',cf,'tone');
% locs = [-90:45:90];
% figure;
% for i = 1:5
%     subplot(2,3,i)
%     mask = calcSpkMask(spk_IC(:,:,i),fs,'alpha',0.01);
%     taxis = 0:1/fs:length(mixed)/fs-1/fs;
%     imagesc(taxis,cf,mask); set(gca,'ydir','normal')
%     xlabel('time')
%     ylabel('frequency')
%     title([num2str(locs(i)) 'deg cell']);
% end
% % temp2 = vocode(mask(:,:,3),cf,'tone',fs);
% % temp3 = vocode(mask(:,:,5),cf,'tone',fs);

% %% plot spike rasters
% addpath('C:\Users\Kenny\Desktop\GitHub\SpatialAttentionNetwork\dependencies')
% figure;
% for i = 1:5
%     subplot(1,5,i)
%     icSpikes = logical(squeeze(spk_IC(:,:,i))'); 
%     plotSpikeRasterFs(icSpikes, 'PlotType','vertline', 'Fs',40000);
%     xlim([0 2000])
%     if i==1, ylabel('IC spikes'); end
%     set(gca,'Ytick',[1:64],'YtickLabel',cf)
% end