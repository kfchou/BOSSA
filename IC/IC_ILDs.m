cd('C:\Users\kfcho\Documents\GitHub\PISPA2.0');
addpath('Peripheral')
addpath('HRTF')
addpath('IC')
addpath('C:\Users\kfcho\Dropbox\Sen Lab\m-toolboxes\plotting utils')

low_freq = 200; %min freq of the filter
high_freq = 8000;
numChannel = 64;

fs = 44100; %CRM sampling freq
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(fs,cf,low_freq);

s_filt.flist = cf;
s_filt.nf = nf;
s_filt.fs = fs;
s_filt.lowFreq = low_freq;
s_filt.highFreq = high_freq;
azList = [-90,-60,-45,-30,0,30,45,60,90];

ILDs = gen_ILD(s_filt.lowFreq,s_filt.highFreq,s_filt.nf,s_filt.fs,azList);

%% plot results
plot(ILDs)
ylabel('ILD')
xlabel('frequency (Hz)')
cmap = brewermap(length(azList),'YlOrBr');
hline = findobj(gcf, 'type', 'line');
for i = 1:length(azList)
    set(hline(i),'LineWidth',2,'color',cmap(i,:))
end

hleg = legend(cellstr(num2str(azList')));
hleg.NumColumns = 3;
hleg.Title.String = '(deg az)';
hleg.Position = [0.1295 0.4113 0.3144 0.4057];
hleg.EdgeColor = [1 1 1];