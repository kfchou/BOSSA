% Characterizes spatial tuning curve of IC model using wgn
% 2019-03-27 updated to be compatible with PISPA2.0 scripts
addpath('Peripheral')
addpath('IC')
% generate wgn
fs = 40000;
noise = wgn(1,50000,1);

% spatialize wgn
sourcePositions = [-90:5:90];
nPositions = length(sourcePositions);

% load impulse responses
% hrtfLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\HRTF\';
hrtfLoc = 'HRTF\';
for i = 1:nPositions
    hrtf_name = ['kemar_small_horiz_' num2str(sourcePositions(i)) '_0.mat'];
    load([hrtfLoc hrtf_name])
    hrtfL(:,i) = hrir_left;
    hrtfR(:,i) = hrir_right;
end

% apply impulse responses
sentencesL = fftfilt(hrtfL,noise);
sentencesR = fftfilt(hrtfR,noise);

%% frequency filtering
low_freq = 150; %min freq of the filter
high_freq = 8000;
numChannel = 64;
 
%apply peripheral filters
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

gain = 1500;
for i = 1:nPositions
    tic
    s_filt = struct();
    s_filt.sL=ERBFilterBank(sentencesL(:,i)*gain,fcoefs); %freq*time
    s_filt.sR=ERBFilterBank(sentencesR(:,i)*gain,fcoefs);
    s_filt.band = 'narrow';
    s_filt.BW = bw;
    s_filt.flist = cf;
    s_filt.nf = nf;
    s_filt.fs = fs;
    s_filt.lowFreq = low_freq;
    s_filt.highFreq = high_freq;

    % IC model module.
    randomness = 1;
    azList = [-90,-60,-45,-30,0,30,45,60,90]; %model neuron locations
    [spks(i).spk_IC, spks(i).FR] = ICmodel(s_filt,azList,randomness);
    toc
end

% save('IC_characterization_freq_tuning_30_deg.m','spk_IC','firingrate','sourcePositions');

%% activity = number of total spikes
for j = 1:length(azList)
    for i = 1:nPositions
        numSpk(i,j) = sum(sum(spks(i).spk_IC(:,:,j)));
    end
end
figure;
plot(sourcePositions,numSpk,'linewidth',2);
ylabel('spike count (all freq channels)')
xlabel('azimuth')
title('total spike count v noise location')
legend(cellstr(num2str(azList')))

%% firing rates (1)
figure;
for j = 1:length(azList)
    for i = 1:nPositions
        spkPerChan(i,:) = sum(spks(i).spk_IC(:,:,j));
    end
    subplot(3,3,j)
    imagesc(sourcePositions,cf,spkPerChan')
    ylabel('freq channel CFs')
    xlabel('noise source azimuth')
    set(gca,'ydir','normal')
    title(sprintf('%i deg az neurons',azList(j)))
end
suptitle('total firing activity per frequency channel')

% %% firing rates (2) - same as (1)
% figure;
% for j = 1:length(azList)
%     for i = 1:nPositions
%         spkPerChan(i,:) = sum(spks(i).FR(:,:,j),2)';
%     end
%     subplot(3,3,j)
%     imagesc(sourcePositions,cf,spkPerChan')
%     ylabel('freq channel CFs')
%     xlabel('noise source azimuth')
%     set(gca,'ydir','normal')
%     title(sprintf('%i deg az neurons',azList(j)))
% end
% suptitle('total firing activity per frequency channel')