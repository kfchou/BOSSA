% compareIC:
% this script compares the new and old voltage->FR curve. Is a higher
% dynamic range better for our purposes? My hypothesis is actually no,
% since our reconstruction treats spike rasters as TF-masks. Let's compare
% the rasters at the IC stage and see.

oldSpkLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\006 old IC spk library 64Chan200-8000hz\CRM talker4\';
newSpkLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\006 FRv3 IC spk library 64Chan200-8000hz\CRM talker4\';
oldSpks = ls([oldSpkLoc '*SpkIC*.mat']);
newSpks = ls([newSpkLoc '*SpkIC*.mat']);
tgtWavs = ls([oldSpkLoc '*target.wav']);
tgtSptWavs = ls([oldSpkLoc '*target_conv.wav']);
mixedWavs = ls([oldSpkLoc '*mixed.wav']);
fs = 40000;
load([oldSpkLoc oldSpks(1,:)],'fcoefs','cf')
params.fcoefs = fcoefs;
params.cf = cf;
params.fs = fs;

addpath('C:\Users\Kenny\Desktop\GitHub\SpatialAttentionNetwork\dependencies')
addpath('ObjectiveMeasure')
addpath('Recon')
tic
plotting = 1;
for j = 1:size(oldSpks,1)
    load([oldSpkLoc oldSpks(j,:)])
    targetLoc = [oldSpkLoc strtrim(tgtWavs(j,:))];
    targetSpatializedLoc = [oldSpkLoc strtrim(tgtSptWavs(j,:))];
    mixedLoc = [oldSpkLoc strtrim(mixedWavs(j,:))];
    if plotting
        figure;
        for i = 1:5
            subplot(2,5,i)
            icSpikes = logical(squeeze(spk_IC(:,:,i))'); 
            plotSpikeRasterFs(icSpikes, 'PlotType','vertline', 'Fs',40000);
            xlim([0 2000])
            if i==1, ylabel('Old IC Spikes'); end
            set(gca,'Ytick',[1:64],'YtickLabel',cf)
        end
    end
    [oldOut(j,:),rstim1o(j).wav,rstim2o(j).wav,rstim3o(j).wav] = recon_eval(spk_IC(:,:,3),targetLoc,targetSpatializedLoc,mixedLoc,params);

    load([newSpkLoc newSpks(j,:)])
    if plotting
        for i = 1:5
            subplot(2,5,i+5)
            icSpikes = logical(squeeze(spk_IC(:,:,i))'); 
            plotSpikeRasterFs(icSpikes, 'PlotType','vertline', 'Fs',40000);
            xlim([0 2000])
            if i==1, ylabel('New IC spikes'); end
            set(gca,'Ytick',[1:64],'YtickLabel',cf)
        end
    end
    [newOut(j,:),rstim1n(j).wav,rstim2n(j).wav,rstim3n(j).wav] = recon_eval(spk_IC(:,:,3),targetLoc,targetSpatializedLoc,mixedLoc,params);

end
toc

figure;
scatter(oldOut(:,1),newOut(:,1),'filled'); 
hold on;
scatter(oldOut(:,2),newOut(:,2),'filled'); 
scatter(oldOut(:,3),newOut(:,3),'filled');
xlabel('STOI - Fischer IC')
ylabel('STOI - Modified IC')
legend('Filt','Env','Voc','y = x')
xlim([0.4 0.75])
ylim([0.4 0.75])
line([0 1],[0 1])