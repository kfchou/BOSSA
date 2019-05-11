function [mixed, s] = stimulus_setup(talker,pair,az,input_gain,inputAudio)
% [mixed, s] = stimulus_setup(talker,pair,az,input_gain, snr)
% loads length(az) numbers of CRM sentences
% applies HRTF according to az (azimuth) locations
% PAIR can be:
%   - a scalar, indicatding the idx number of a pre-define set of sentences
%   - 'training'
%   - 'other', and inputAudio must be defined
%   - a cell with the format {'xxxxxx','xxxxxx',...}, where each 'xxxxx'
%       indicate the name of a CRM file (without '.bin')
%
% Kenny Chou
% 2019-04-03
% Boston University, HRC
%
% future work: 
%   add option for adjusting TMR
%   add option for another corpus set

path = CRMpath;
addpath(path);

if strcmp(pair,'training')
    s.wav = audioread([path 'Talker 4' filesep 'talker4_training.wav']);
elseif strcmp(pair,'other')
    s.wav = inputAudio;
elseif iscell(pair)
    if length(pair{1}) == 6 && ischar(pair{1}) %accepts filename of CRM .bin
        for ii = 1:length(pair)
            filename = [path 'Talker ' num2str(talker) '\' pair{1} '.bin'];
            s(ii).wav = readbin(filename);
            s(ii).source = pair;
            s(ii).az = az(ii);
        end
    end
else     
%         if length(az) <= 2
%             stim_name = 'CRMnumber20pairs_Oct-25_17.mat'; %pairs of talkers from the CRM corpus, no repeated keywords in each pair. Covers all keywords.
    if length(az) <= 3
        stim_name = 'CRMnumber_3source_40pairs_Nov-22_18.mat';
    elseif length(az) == 4
        stim_name = 'CRM_4source_20pair_005c.mat';
    elseif length (az) == 5
        stim_name = 'CRMnumber_5source_20170214.mat';
    end
    load([path 'keywords.mat'])
    load([path stim_name])


    % load stimuli; 1 stimuli for each azmuth location
    if length(az) ~= length(talker)
        if length(talker) == 1
            talker = ones(size(az))*talker;
        else
            disp('talker and az must have the same length');
        end
    end
    for ii = 1:length(az)
        filename = [path 'Talker ' num2str(talker(ii)) '\' upper(crm_number{pair,ii})];
        s(ii).wav = readbin(filename);
        s(ii).source = crm_number{pair,ii};
    end
end

% assuming TMR = 0dB %

% % adjust for snr
% if length(az) > 1
%     s(1).wav = s(1).wav * snr * (length(az)-1);
% end


% apply HRTFs
% 1st loc always in front
hrtf_name = ['kemar_small_horiz_' num2str(az(1)) '_0.mat'];
load(['HRTF_40k\' hrtf_name])
mixed.sL = conv(s(1).wav,hrir_left,'same')*input_gain;
mixed.sR = conv(s(1).wav,hrir_right,'same')*input_gain;
n1=length(s(1).wav);
s(1).convolvedL = mixed.sL;
s(1).convolvedR = mixed.sR;
mixed.fs = 40000;

% 2nd-nth loc
for ii = 2:length(az)
    n2=length(s(ii).wav);
    nn=min([n1 n2]-60);
    hrtf_name = ['kemar_small_horiz_' num2str(az(ii)) '_0.mat'];
    load(['HRTF_40k\' hrtf_name])
    signal2_left = conv(s(ii).wav,hrir_left,'same')*input_gain;
    signal2_right = conv(s(ii).wav,hrir_right,'same')*input_gain;
    mixed.sL = mixed.sL(1:nn) + signal2_left(1:nn);
    mixed.sR = mixed.sR(1:nn) + signal2_right(1:nn);
    s(ii).convolvedL = signal2_left;
    s(ii).convolvedR = signal2_right;
    n1 = min(length(mixed.sL));
end
