function [S,Sx,Sz]=genICclInputSignals_JD(yL,yR,z,Xun,Ts,p,side)

%[S,Sx,Sz]=genICclInputSignals(yL,yR,z,Xun,Ts,NP,side)
%This function gets the current inputs to the ICcl
%spiking LIF model over all frequency channels
%z = level difference
%Xun = cross correlation
%Ts = time step in ms
%NP = cell of NeuronParms at each frequency
%Assumes low pass filtering of inputs, 4ms 
%Side of the brain (-1 for left, 1 for right, 0 for both-(half and half))

NF=size(z,1); % number of frequency channels

Sx=[];
Sz=[];
for n=1:NF
%% Get ITD Input
    Sx=[Sx;Xun(n,:)];
%% Get ILD Input
    if side==-1
    E = (yR(n,:));
    elseif side==1
    E = (yL(n,:));
    elseif side==0
    E = (yR(n,:));
    end
    
    Sz=[Sz;E.*(sigILD(z(n,:),p(n,:)))]; % ILD 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
end

%Transform the inputs so that values lie roughly between -50 and 50.
Sz=2*Sz-40;
Sx=200*Sx-60;
% max_sz = max(max(Sz));
% min_sz = min(min(Sz));
% Sz = (Sz-min_sz)/(max_sz-min_sz)*60-30;
% max_sx = max(max(Sx));
% min_sx = min(min(Sx));
% Sx = (Sx-min_sx)/(max_sx-min_sx)*60-30;

%Combine ITD and ILD inputs and filter << Kenny, this is the ITD and ILD
%combination step,
% but it's done additively, no? I don't remember details, but I remember
% comparing it to the equations in Pena paper and matching. Do you want to
% look at that now?
% ok let me pull that up. I see Sx+Sz and was like... ??
S=lowpass_firstorder(Sx+Sz,4,Ts);
