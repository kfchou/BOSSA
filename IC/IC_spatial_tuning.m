% Characterizes spatial tuning curve of IC model using wgn
addpath('Peripheral')

% generate wgn
fs = 16000;
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
noises = noise' * ones(1,nPositions);
sentencesL = fftfilt(hrtfL,noises);
sentencesR = fftfilt(hrtfR,noises);
 
%% frequency filtering
low_freq = 150; %min freq of the filter
high_freq = 8000;
numChannel = 64;
 
%apply peripheral filters
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

gain = 1500;
tic
for i = 1:nPositions
    s_filt.sL=ERBFilterBank(sentencesL(:,i)*gain,fcoefs); %freq*time
    s_filt.sR=ERBFilterBank(sentencesR(:,i)*gain,fcoefs);
    s_filt.band = 'narrow';
    s_filt.BW = bw;
    s_filt.flist = cf;
    s_filt.nf = nf;
    s_filt.fs = fs;

    % IC model module. [spk, firingrate] = ICmodel(s_filt,randomness)
    randomness = 1;

    [preferredITD, np, side] = SetLocalizationParameters(3, nf);
    [spk_IC(:,:,i), firingrate(:,:,i), s_filt] = ICcl(s_filt,nf,preferredITD,np,side,randomness);
    toc
end

save('IC_characterization_freq_tuning_30_deg.m','spk_IC','firingrate','sourcePositions');
%% plot results
figure;
for i = 1:nPositions
    subplot(4,5,i); imagesc(firingrate(:,:,i));
    title(num2str(sourcePositions(i)));
    colorbar;
end

%% activity = number of total spikes
for i = 1:nPositions
    numSpk(i) = sum(sum(spk_IC(:,:,i)));
    spkPerChan(i,:) = sum(spk_IC(:,:,i));
end
plot(sourcePositions,numSpk);
ylabel('spike count (all freq channels)')
xlabel('azimuth')

figure;
imagesc(sourcePositions,cf,spkPerChan')
ylabel('freq channel CFs')
xlabel('azimuth')
set(gca,'ydir','normal')