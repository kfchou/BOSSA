% reorganize spiking data into freq x STN x stimulus location
dataLoc = 'J:\Data\spatial tuning upto 20khz';
filenames = ls([dataLoc filesep '*.mat']);
for i = 1:size(filenames,1)
    load([dataLoc filesep filenames(i,:)]);
    spks(:,:,i) = sum(spk_IC); %collapse along the time dimension -> freq x STN
end

%% plot1 total firing rate vs WGN location
addpath(genpath('C:\Users\Kenny\Dropbox\Sen Lab\m-toolboxes\plotting utils'))
figure;
plot(sourcePositions,squeeze(sum(spks))')
xlabel('WGN location')
ylabel('total firing activity')
cmap = cubehelix(length(azList),1.16,2.56,1.93,1.1,[.29,.68],[.21,.83]);
hline = findobj(gcf,'type','line');
for i = 1:length(hline)
    hline(i).Color = cmap(i,:);
    hline(i).LineWidth = 3;
end
title('total firing activity')
set(gca,'FontSize',12)
hleg = legend(cellstr(num2str(azList')));
hleg.NumColumns = 1;
hleg.Orientation = 'vertical';
hleg.Title.String = {'Neuron','preferred','locatoin','(deg az)'};
hleg.Position = [0.1295 0.4113 0.3144 0.4057];
hleg.EdgeColor = [1 1 1];

%% plot2 
addpath('C:\Users\Kenny\Desktop\GitHub\PISPA2.0\Peripheral')
low_freq = 200; %min freq of the filter
high_freq = 20000;
numChannel = 64;
fs = 44100;
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
freqs = [15670,8478,4835,1484,508,255];
[~,idx] = min(abs((cf-freqs)));

j = 1;
for f = idx
    subplot(length(freqs),1,j);
    h = plot(sourcePositions,squeeze(spks(f,:,:))');
    set(gca,'FontSize',12)
    hline = findobj(h,'type','line');
    for i = 1:length(hline)
        hline(i).Color = cmap(i,:);
        hline(i).LineWidth = 3;
    end
    ylabel([num2str(round(cf(f))) 'Hz'])
    j = j+1;
end

%% plot FR
for i = 1:9
    subplot(3,3,i)
    imagesc(squeeze(spks(:,i,:)));
    xlabel('WGN location')
    ylabel('Frequency')
    xticklabels('')
    yticklabels('')
end