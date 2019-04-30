% calculate ITDs for each freq channel
% =================== ITD calculation is not correct ===================
addpath('..\scripts')

%peripheral filtering
low_freq = 200; %min freq of the filter
high_freq = 5000;
numChannel = 36;
[nf,cf,bw] = getFreqChanInfo('erb',numChannel,low_freq,high_freq);
fcoefs=MakeERBFilters(40000,cf,low_freq);

azs = [-90 -45 0 45 90];
ITD = zeros(36,5); %numChannel x azs
for jj = 1:length(azs)
    keystr = sprintf('*_%i_0*',azs(jj));
    hrtf_list = ls(keystr);
    load(strtrim(hrtf_list(1,:)));
    HRTF_L = ERBFilterBank(hrir_left,fcoefs);
    HRTF_R = ERBFilterBank(hrir_right,fcoefs);
    for i = 1:size(HRTF_L,1)
        [~,locsL] = findpeaks(HRTF_L(i,:),'SortStr','descend');
        [~,locsR] = findpeaks(HRTF_R(i,:),'SortStr','descend');
        ITD(i,jj) = (locsL(1)-locsR(1));
    end
end
ITD = round(ITD/fs*10e6); %microseconds

