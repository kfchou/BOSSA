% compare between different recon methods, using objective measures
addpath('Recon')
addpath('Peripheral')
addpath('ObjectiveMeasure')
wavLoc = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\BOSSalgo\';
subjectNum = 021;
blocks = 3%2:16;
fs = 44100;

stim = struct;
j = 1;
for block = blocks

    blockFolderLoc = sprintf('%sExperiment Stimuli/subject %03i/',wavLoc,subjectNum);
    targets = dir(sprintf('%sblock *%02i*/wavdata*.mat',blockFolderLoc,block));
    spkFiles = dir(sprintf('%sblock *%02i*/*SpkIC*.mat',blockFolderLoc,block));
    load([targets(1).folder filesep 'stimuli_info.mat'])
    cond = data.stim.cond;
%     if cond == 4 || cond == 5
%         recons = dir(sprintf('%sblock *%02i*/*%s%s.mat',blockFolderLoc,block,reconKeyword{data.stim.cond},reconSuffix));
%     else
%         recons = dir(sprintf('%sblock *%02i*/*%s*.mat',blockFolderLoc,block,reconKeyword{data.stim.cond}));
%     end
%     
    for i = 3%1:length(targets)
        wavs = load([targets(i).folder filesep targets(i).name]);
        trial = strsplit(targets(i).name,'trial');
        trial = str2double(trial{2}(1:2));
        
        % unprocessed
        stim(j).st = runStoi(wavs.target,wavs.mixed,fs,fs);
        tgt16 = sum(resample(wavs.target,16000,fs),2);
        recon = sum(resample(wavs.mixed,16000,fs),2);
        stim(j).pq = pesq_mex(tgt16,recon,16000,'narrowband');
        stim(j).tmr = data.stim.tmr(i);
        stim(j).type = {'KEMAR'};
        stim(j).block = block;
        stim(j).trial = trial;
        stim(j).cond = j;
        j = j+1;
        % processed
        if ismember(cond,[3 4 5])
            temp = load([spkFiles(i).folder filesep spkFiles(i).name]);
            spks = spkTime2Train(temp.spk_IC,temp.Fs,length(wavs.target));
            params = struct();
            params.fcoefs = temp.fcoefs;
            params.cf = temp.cf;
            params.fs = temp.Fs;
            params.spatialChan = 3;
            params.delay = 0;
        
            % spkMask
            params.type = 1;
            params.maskRatio = 0;
            params.tau = 0.018;
            [st,rstim] = recon_eval(spks,wavs.target,wavs.mixed,params);
            stim(j).st = st.r1;
            recon = sum(resample(rstim.r1d,16000,fs),2);
            stim(j).pq = pesq_mex(tgt16,recon,16000,'narrowband');
            stim(j).tmr = data.stim.tmr(i);
            stim(j).type = 'FRMask';
            stim(j).block = block;
            stim(j).trial = trial;
            stim(j).cond = j;
%             stim(j).rstim = rstim.r1d;
            j = j+1;
            
            % diffmask
            params.type = 1;
            params.maskRatio = 0.5;
            params.tau = 0.02;
            [st,rstim] = recon_eval(spks,wavs.target,wavs.mixed,params);
            stim(j).st = st.r1;
            recon = sum(resample(rstim.r1d,16000,fs),2);
            stim(j).pq = pesq_mex(tgt16,recon,16000,'narrowband');
            stim(j).tmr = data.stim.tmr(i);
            stim(j).type = 'DiffMask';
            stim(j).block = block;
            stim(j).trial = trial;
            stim(j).cond = j;
%             stim(j).rstim = rstim.r1d;
            j = j+1;
            
            % diffmask2
            params.type = 1;
            params.maskRatio = -1;
            params.tau = 0.02;
            [st,rstim] = recon_eval(spks,wavs.target,wavs.mixed,params);
            stim(j).st = st.r1;
            recon = sum(resample(rstim.r1d,16000,fs),2);
            stim(j).pq = pesq_mex(tgt16,recon,16000,'narrowband');
            stim(j).tmr = data.stim.tmr(i);
            stim(j).type = 'DiffMaskNew';
            stim(j).block = block;
            stim(j).trial = trial;
            stim(j).cond = j;
%             stim(j).rstim = rstim.r1d;
            j = j+1;
        end
        
        % beamar
        if isfield(wavs,'BEAMAR')
            stim(j).st = runStoi(wavs.BEAMARtgt,wavs.BEAMAR,fs,fs);
            beamTgt16 = sum(resample(wavs.BEAMARtgt,16000,fs),2);
            recon = sum(resample(wavs.BEAMAR,16000,fs),2);
            stim(j).pq = pesq_mex(beamTgt16,recon,16000,'narrowband');
            stim(j).tmr = data.stim.tmr(i);
            stim(j).type = {'BEMAR'};
            stim(j).block = block;
            stim(j).trial = trial;
            stim(j).cond = j;
            j = j+1;
        end
    end

end

% [stim.st]'
% addpath('C:\Users\Kenny\Desktop\GitHub\PISPA2.0\Plotting')
% plot_voicebox_spectrogram(sum(wavs.target,2),fs); title('target'); caxis([-300,0])
% plot_voicebox_spectrogram(sum(stim(3).rstim,2),fs); title('old version'); caxis([-300,0])
% plot_voicebox_spectrogram(sum(stim(4).rstim,2),fs); title('new version'); caxis([-300,0])

% save(sprintf('Experiment ObjectiveEval\\scores_s%03i_resampledPESQ.mat',subjectNum),'stim','subjectNum')

%% add DNN data
% load('Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\BOSSAlgo\Experiment ObjectiveEval\scores_s021_resampledPESQ.mat');
DBinfo.expNames = {'007','008','009','010'};
DBinfo.is_ratio_mask = {0,0,1,1};
DBinfo.feat = {'MfCCBnrl','Bnrl','MfCCBnrl','Bnrl'};
dnnRoot = 'Z:\eng_research_hrc_binauralhearinglab\kfchou\ActiveProjects\BOSSAlgo_v_DNN';

j = length(stim);
for k = 1:length(DBinfo.expNames)
    expName = DBinfo.expNames{k}
    if DBinfo.is_ratio_mask{k} == 1
        mask = 'IRM'
    else
        mask = 'IBM'
    end
    dbdir = dir(fullfile(dnnRoot,'DATA',expName,'dnn','STORE','db*'));
    load(fullfile(dnnRoot,'DATA',expName,'dnn','STORE',dbdir.name,'validation_objective_scores'))
    load(fullfile(dnnRoot,'DATA',expName,'tmpdir',[expName 'audio_test.mat']),'tmr')

    for i = 1:225%length(tmr)
        stim(j).st = est_stoi(i);
        stim(j).pq = pq.est(i);
        stim(j).tmr = tmr(i);
        stim(j).type = ['DNN: ' mask ', ' DBinfo.feat{k}];
        j = j+1;

        stim(j).st = ideal_stoi(i);
        stim(j).pq = pq.ideal(i);
        stim(j).tmr = tmr(i);
        stim(j).type = mask;
        j = j+1;

        stim(j).st = unprocessed_stoi(i);
        stim(j).pq = pq.unprocessed(i);
        stim(j).tmr = tmr(i);
        stim(j).type = 'DNN KEMAR'; %Compare with KEMAR from stimuli file
        j = j+1;
    end
end
%%
addpath('C:\Users\Kenny\Dropbox\Sen Lab\m-toolboxes\plotting utils\gramm-master')
addpath('C:\Users\kfcho\Dropbox\Sen Lab\m-toolboxes\plotting utils\gramm-master')
addpath('U:\eng_research_hrc_binauralhearinglab\kfchou\toolboxes\gramm-master')
clear g
% g(1,1)=gramm('x',[stim.tmr],'y',[stim.st],'color',[stim.type],'subset',~strcmp([stim.type],'DiffMaskNew'));
g(1,1)=gramm('x',[stim.tmr],'y',[stim.st],'color',[stim.type]);

% g(1,1)=facet_grid(stim.type,[]);
% g(1,1).geom_point();
% g(1,1).set_names('x','TMR','y','STOI');
% g(1,1).set_title('Performance v TMR');
% g(1,1).axe_property('YLim',[0 0.8]);

g(1,1).stat_boxplot();
g(1,1).set_names('x','TMR','y','STOI');
g(1,1).set_order_options('x',[-5 0 5])
g(1,1).axe_property('Xtick',[-5 0 5]);
g(1,1).set_title(sprintf('subject %03i',subjectNum));
% g(1,1).axe_property('YLim',[0 0.1]);

g(2,1)=gramm('x',[stim.tmr],'y',[stim.pq],'color',[stim.type]);
% g(1,2)=copy(g(1));

% g(1,1)=facet_grid(stim.type,[]);
% g(1,1).geom_point();
% g(1,1).set_names('x','TMR','y','STOI');
% g(1,1).set_title('Performance v TMR');
% g(1,1).axe_property('YLim',[0 0.8]);

g(2,1).stat_boxplot();
g(2,1).set_names('x','TMR','y','PESQ');
g(2,1).set_order_options('x',[-5 0 5])
g(2,1).axe_property('Xtick',[-5 0 5],'ylim',[1,2.75]);
g(2,1).set_title(sprintf('subject %03i',subjectNum));
g.draw();

%% manually calculate stats
tmrs = [-5 0 5];
% conds = unique([stim.type]);
conds = {'KEMAR','DNN KEMAR','IBM','IRM','FRMask','DiffMask', 'DNN: IBM, Bnrl', 'DNN: IBM, MfCCBnrl','DNN: IRM, Bnrl', 'DNN: IRM, MfCCBnrl','BEMAR'};
for i = 1:length(tmrs)
    for j = 1:length(conds)
        stAvgs(j,i) = mean([stim(strcmp([stim.type],conds(j)) & [stim.tmr]==tmrs(i)).st]);
    end
end

for i = 1:length(tmrs)
    for j = 1:length(conds)
        pqAvgs(j,i) = mean([stim(strcmp([stim.type],conds(j)) & [stim.tmr]==tmrs(i)).pq]);
    end
end
