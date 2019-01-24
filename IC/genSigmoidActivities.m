function a=genSigmoidActivities(NeuronParms,S)
% originally by Brian Fischer
% modified by Kenny Chou 2018/8/29
% changed the steepness parameter of the sigmoidal curve from 0.4122 to
% variable. Moved center of sigma from -56 to 40.

%a=genSigmoidActivities(NeuronParms,S)

%Length of time
Lt=size(S,2);
nf=size(S,1);
%Dynamic range parameter
DR=NeuronParms(:,2)*ones(nf,Lt); 

%Gain parameter
Gain=NeuronParms(:,3)*ones(nf,Lt); 

%Membrane potential
V=S.*Gain-NeuronParms(:,1)*ones(nf,Lt); 

%Firing rate - from Fischer's model
% a=DR./(1+exp(-steepness*(V+56.2153)));
% a=a.*(V>-68.2381); 

% modified firing rate
x0 = 40;
steepness = 0.04;
a=150./(1+exp(-steepness*(V-x0)));
a=a.*(V>-68.2381); 

% a = 0.9*V+30;
% a=a.*(V>-68.2381);
% a(a<0) = 0;
