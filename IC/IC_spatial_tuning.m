% Characterizes spatial tuning curve of IC model using wgn
% 2019-03-27 updated to be compatible with PISPA2.0 scripts
cd('C:\Users\Kenny\Desktop\GitHub\PISPA2.0')
addpath('Peripheral')
addpath('IC')
% generate wgn
fs = 44100;
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
sentencesL = fftfilt(hrtfL,noise');
sentencesR = fftfilt(hrtfR,noise');

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
    
    saveLoc = 'J:\Data\spatial tuning single wgn';
    spk_IC = spks(i).spk_IC;
    FR = spks(i).FR;
    saveName = sprintf('Spatial Tuning SingleWGN Position %02i.mat',i);
    save([saveLoc filesep saveName],'spk_IC','FR','sourcePositions','azList');
    toc
end
disp('done')

%% save files
% % for i = 1:nPositions
% %     saveLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\008 IC spatial tuning\';
% %     spk_IC = spks(i).spk_IC;
% %     FR = spks(i).FR;
% %     saveName = sprintf('Spatial Tuning Spikes Source Position %02i.m',i);
% %     save([saveLoc saveName],'spk_IC','FR','sourcePositions','azList');
% % end
%% activity = number of total spikes
addpath(genpath('C:\Users\Kenny\Dropbox\Sen Lab\m-toolboxes\plotting utils'))

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
hleg = legend(cellstr(num2str(azList')));
hleg.Title.String = ['Neuron' newline 'Preferred' newline 'Location'];
hleg.EdgeColor = [1 1 1];
set(gca,'FontSize',12)
cmap = cubehelix(length(azList),1.16,2.56,1.93,1.1,[.29,.68],[.21,.83]);
hline = findobj(gcf,'type','line');
for i = 1:length(hline)
    hline(i).Color = cmap(i,:);
    hline(i).LineWidth = 3;
end

%% firing rates (1)
% figure;
% for j = 1:length(azList)
%     for i = 1:nPositions
%         spkPerChan(i,:) = sum(spks(i).spk_IC(:,:,j));
%     end
% %     figure;
%     subplot(3,3,j)
%     imagesc(sourcePositions,cf,spkPerChan')
%     ylabel('freq channel CFs')
%     xlabel('noise source azimuth')
%     set(gca,'ydir','normal')
%     title(sprintf('%i deg az neurons',azList(j)))
% end
% suptitle('total firing activity per frequency channel')

%% firing rates (2) - same as (1)
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

%% firing rate - (3) - overlap FR patterns?
% for j = [2,4,5,6,8]
%     for i = 1:nPositions
%         spkPerChan(i,:) = sum(spks(i).spk_IC(:,:,j));
%     end
%     FRthresh = spkPerChan;
%     FRthresh(FRthresh<250) = 0;
%     FRthresh(FRthresh>=250) = 1;
%     FRedge(:,:,j) = double(edge(FRthresh,'Sobel'))*j;
% end
% FRedge(FRedge==0)=nan;
% 
% figure;
% [X,Y] = meshgrid(sourcePositions,cf);
% for j = [2,4,5,6,8]
%     plot3(X,Y,FRedge(:,:,j)'); hold on;
% end
% % imagesc(sourcePositions,cf,sum(FRedge,3)')
% set(gca,'ydir','normal')
% ylabel('freq channel CFs')
% xlabel('noise source azimuth')
% set(gca,'ydir','normal')
% title(sprintf('%i deg az neurons',azList(j)))

%%
% addpath('C:\Users\Kenny\Desktop\GitHub\SpatialAttentionNetwork\dependencies')
% figure;
% for i = 1:9
%     subplot(3,3,i)
%     icSpikes = logical(squeeze(spks.spk_IC(:,:,i))'); 
%     plotSpikeRasterFs(icSpikes, 'PlotType','vertline', 'Fs',40000);
%     xlim([0 2000])
%     if i==1, ylabel('IC spikes'); end
%     set(gca,'Ytick',[1:64],'YtickLabel',cf)
% end