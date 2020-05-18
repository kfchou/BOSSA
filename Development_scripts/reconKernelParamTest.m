% recon kernel param test
% brute force evaluation of reconstruction kernels vs stoi
rootloc = '/projectnb/binaural/kfchou/BOSS_algo_psychoacoustics/';
addpath([rootloc 'Peripheral'])
addpath([rootloc 'HRTF'])
addpath([rootloc 'IC'])
addpath([rootloc 'Recon'])

subjectNum = 011;
blocks = 2;
fs = 44100;
varyTau = [0.002,0.005,0.01:0.01:0.1]; %seconds
varyDelay = [-100:10:100]; %taps
nTau = length(varyTau);
nDelay = length(varyDelay);

for block = blocks
    blockFolderLoc = sprintf('Experiment Stimuli/subject %03i/',subjectNum);
    spks = dir(sprintf('%sblock *%02i*/*SpkIC*.mat',blockFolderLoc,block));
    wavs =  dir(sprintf('%sblock *%02i*/wavdata*.mat',blockFolderLoc,block));
    
    stDiffMask = zeros(length(spks),length(varyTau),length(varyDelay));
    
    for i = 1:15
    spkData = load([spks(i).folder filesep spks(i).name]);
    wavData = load([wavs(i).folder filesep wavs(i).name]);
    
    target = wavData.target;
    mixed = wavData.mixed;
    spk_IC = spkData.spk_IC;
    spk = spkTime2Train(spk_IC,fs,length(mixed));

        for idxTau = 1:nTau
            params = struct();
            params.fcoefs = spkData.fcoefs;
            params.cf = spkData.cf;
            params.fs = spkData.Fs;
            params.spatialChan = 3;

            params.type = 1;
            params.maskRatio = 0.5;
            for idxDelay = 1:nDelay
                params.tau = varyTau(idxTau);
                params.delay = varyDelay(idxDelay);
                params.kernel = 'hamming';

                [st2,rstim] = recon_eval(spk,target,mixed,params);
                wav2 = rstim.r1d;
                stDiffMaskHamm(i,idxTau,idxDelay) = st2.r1;

                params.kernel = 'rect';
                [st2,rstim] = recon_eval(spk,target,mixed,params);
                wav2 = rstim.r1d;
                stDiffMaskRect(i,idxTau,idxDelay) = st2.r1;

                params.kernel = 'tukey';
                [st2,rstim] = recon_eval(spk,target,mixed,params);
                wav2 = rstim.r1d;
                stDiffMaskTukey(i,idxTau,idxDelay) = st2.r1;
            end


        end
    disp('one spk complete')
    end
    save(sprintf('DevScripts/Data/reconParamTestHammRectTukey_s%02ib%02i.mat',subjectNum,block),'varyTau','varyDelay','stDiffMaskHamm','stDiffMaskRect','stDiffMaskTukey')
end
disp('finished');
% [runStoi(target,mixed,fs,fs) st1.r1 st2.r1 st3.r3]

