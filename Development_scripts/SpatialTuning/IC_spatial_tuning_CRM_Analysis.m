addpath(genpath('C:\Users\Kenny\Dropbox\Sen Lab\m-toolboxes\plotting utils'))
fileLoc = 'C:\Users\Kenny\Desktop\GitHub\PISPA2.0\IC\Data\SpatialTuningData 64Chan200-8000hz\CRM talker4';
sourcePositions = [-90:5:90];
azList = [-90,-60,-45,-30,0,30,45,60,90];
nPositions = length(sourcePositions);
numTrials = 1;

for trial = 1:numTrials
    for i = 1:length(sourcePositions)
        fileName = ls([fileLoc filesep sprintf('*_set_%02i*_%02d_*.mat',trial,sourcePositions(i))])
        spks(i) = load([fileLoc filesep fileName],'spk_IC');
    end

    for j = 1:length(azList)
        for i = 1:nPositions
            numSpk(i,j,trial) = sum(sum(spks(i).spk_IC(:,:,j)));
        end
    end
end

figure;
plot(sourcePositions,mean(numSpk,3));
ylabel('spike count (all freq channels)')
xlabel('azimuth')
title('mean total spike count v noise location, masker at 90 deg')
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