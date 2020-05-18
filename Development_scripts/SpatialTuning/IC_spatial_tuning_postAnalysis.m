% dataLoc = 'C:\Users\Kenny\Desktop\GitHub\PISPA2.0\IC\spatial tuning data gitignore\';
dataLoc = 'J:\Data\spatial tuning upto 20khz';
addpath('C:\Users\Kenny\Dropbox\Sen Lab\m-toolboxes\plotting utils')
filenames = ls(dataLoc);
cmap = brewermap(size(filenames,1),'YlOrBr');
figure;
for i = 1:size(filenames,1)
    loadedData = load(filenames(i,:));
    subplot(4,1,1)
    totalFiring = squeeze(sum(sum(loadedData.spk_IC)));
    plot(totalFiring); hold on;
    
    subplot(4,2,2)
end
if ~isfield(loadedData,'azList'), 
    azList = [-90,-60,-45,-30,0,30,45,60,90]; 
else
    azList = loadedData.azList;
end
if ~isfield(loadedData,'sourcePositions'), sourcePositions = [-90:5:90]; end
xticklabels(azList)
xlabel('neuron preferred location')
ylabel('total firing activity')
hline = findobj(gcf, 'type', 'line');
for i = 1:37
    set(hline(i),'LineWidth',2,'color',cmap(38-i,:))
end
title('total firing activity per neuron, two WGNs, one fixed at 90 deg')
set(gca,'FontSize',12)

hleg = legend(cellstr(num2str(sourcePositions')));
hleg.NumColumns = 3;
hleg.Title.String = 'WGN position (deg az)';
hleg.Position = [0.1295 0.4113 0.3144 0.4057];
hleg.EdgeColor = [1 1 1];
%%
for i = 1:9
    subplot(3,3,i)
    icSpikes = logical(squeeze(spk_IC(:,:,i))'); 
    plotSpikeRasterFs(icSpikes, 'PlotType','vertline', 'Fs',40000);
    xlim([0 1500])
    title(sprintf('%i deg neuron',azList(i)))
end
suptitle('rasters for each individual neurons')