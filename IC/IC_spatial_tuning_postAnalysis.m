dataLoc = 'C:\Users\Kenny\Desktop\GitHub\PISPA2.0\IC\spatial tuning data gitignore\';
addpath('C:\Users\Kenny\Dropbox\Sen Lab\m-toolboxes\plotting utils')
filenames = ls([dataLoc '*at 30*']);
cmap = brewermap(size(filenames,1),'YlOrBr');
figure;
for i = 1:size(filenames,1)
    load(filenames(i,:))
    temp = squeeze(sum(sum(spk_IC)));
    plot(temp); hold on;
end
azList = [-90,-60,-45,-30,0,30,45,60,90];
sourcePositions = [-90:5:90];
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