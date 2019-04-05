addpath('Plotting')
addpath('Peripheral')
addpath('C:\Users\Kenny\Desktop\GitHub\SpatialAttentionNetwork\dependencies')
addpath('ObjectiveMeasure')
addpath('Recon')

spkLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\CISPA2.0\Data\006 FRv4 IC spk library 64Chan200-8000hz optimized\CRM 3source talker4\';
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

ii = 1;
% ratios = [0,0.26:.02:0.46]
ratios = [0,0.26:.02:0.46, 0.48:0.02:0.6];
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
disp('finished')

%% plot
figure;
for i = 1:5
temp = cell2mat(out(:,i));
scatter(ratios,temp(:,3),'linewidth',2); hold on;
xlabel('ratios')
ylabel('STOI')
legend(cellstr(num2str((1:5)')))
title('CRM 2 masker sets, post-processed after vocoding')
end

%% save audio
for i = 1:5
    wav1 = rstim(12,4).r1d;
    name1 = sprintf('%srecon_2_masker_set_%02i_00_90_filt_minusOffChanMask.wav',spkLoc,i);
    audiowrite(name1,wav1,fs);
    wav2 = rstim(12,4).r4pp;
    name2 = sprintf('%srecon_2_masker_set_%02i_00_90_filtMixVocPP_minusOffChanMask.wav',spkLoc,i);
    audiowrite(name2,wav2,fs);
end