% runs recon_eval on IC spikes
% tests various methods of reconstruction methods
% plot STOIs
cd('C:\Users\Kenny\Desktop\GitHub\PISPA2.0');
addpath('Plotting')
addpath('Peripheral')
addpath('C:\Users\Kenny\Desktop\GitHub\SpatialAttentionNetwork\dependencies')
addpath('ObjectiveMeasure')
addpath('Recon')

spkLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\007 ITD fixed spk library 64Chan200-8000hz 64Chan200-8000hz\CRM talker4\';
spks = ls([spkLoc '*SpkIC*.mat']);
tgtWavs = ls([spkLoc '*target.wav']);
tgtSptWavs = ls([spkLoc '*target_conv.wav']);
mixedWavs = ls([spkLoc '*mixed.wav']);
fs = 40000;
load([spkLoc spks(1,:)],'fcoefs','cf')
params.fcoefs = fcoefs;
params.cf = cf;
params.fs = fs;
params.tau = 0.03;
params.spatialChan = 3;

clear out rstim
ii = 1;
% ratios = [0,0.26:.02:0.46]
ratios = [0,0.05:0.02:0.4];
tic
for ratio = ratios
    params.maskRatio = ratio;
    for j = 1:size(spks,1)
        targetLoc = [spkLoc strtrim(tgtWavs(j,:))];
        targetSpatializedLoc = [spkLoc strtrim(tgtSptWavs(j,:))];
        mixedLoc = [spkLoc strtrim(mixedWavs(j,:))];
        load([spkLoc spks(j,:)])
        [out{ii,j},rstim(ii,j)] = recon_eval(spk_IC,targetLoc,targetSpatializedLoc,mixedLoc,params);
    end
    ii = ii+1;
end
toc
disp('finished')

%% plot
figure;
for i = 1:5
temp = cell2mat(out(:,i));
scatter(ratios,temp(:,4),'linewidth',2); hold on;
xlabel('ratios')
ylabel('STOI')
legend(cellstr(num2str((1:5)')))
% title('CRM 2 masker sets, mask-filtered')
title('CRM 2 masker sets, post-processed')
end

%% save audio
[~,bestidx]=min(abs(ratios-0.25));
for i = 1:5
    wav1 = rstim(bestidx,i).r1d;
    name1 = sprintf('%srecon_2_masker_set_%02i_00_90_filt_minusOffChanMask.wav',spkLoc,i);
    audiowrite(name1,wav1/max(abs(wav1)),fs);
    wav2 = rstim(bestidx,i).r4pp;
    name2 = sprintf('%srecon_2_masker_set_%02i_00_90_filtMixVocPP_minusOffChanMask.wav',spkLoc,i);
    audiowrite(name2,wav2/max(abs(wav2)),fs);
    wav3 = rstim(1,i).r1d;
    name3 = sprintf('%srecon_2_masker_set_%02i_00_90_filt.wav',spkLoc,i);
    audiowrite(name3,wav3/max(abs(wav3)),fs);
    wav4 = rstim(1,i).r4pp;
    name4 = sprintf('%srecon_2_masker_set_%02i_00_90_filtMixVocPP.wav',spkLoc,i);
    audiowrite(name4,wav4/max(abs(wav4)),fs);
end

%%
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