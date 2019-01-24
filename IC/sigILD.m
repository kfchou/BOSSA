function S=sigILD(z,P)
%S=sigILD(z,P)
%   z: extracted energy differences with time
%   P: parameters

%Sizes of vectors
Lt=length(z);
N=size(P,1);

%Form sigmoids
%Eq Gi on mid-left panel, page 3?
%Difference of sigmoids, not sum??
R1=((P(:,1)*ones(1,Lt))./(1+exp(-(ones(N,1)*z-(P(:,2)*ones(1,Lt)))./...
    (P(:,3)*ones(1,Lt)))))+(P(:,4)*ones(1,Lt));
R2=((P(:,5)*ones(1,Lt))./(1+exp(-(ones(N,1)*z-(P(:,6)*ones(1,Lt)))./...
    (P(:,7)*ones(1,Lt)))))+(P(:,8)*ones(1,Lt));                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   

%Add to get input current
S=R1+R2;

% -------------------- for debugging -------------------
% figure;
% plot(z,R1,'o','color','b')
% hold on
% plot(z,R2,'o','color','g')
% plot(z,S,'o','color','r')
% %
% zz = -1:.01:1;
% Lt=length(zz);
% 
% r1=((P(:,1)*ones(1,Lt))./(1+exp(-(ones(N,1)*zz-(P(:,2)*ones(1,Lt)))./...
%     (P(:,3)*ones(1,Lt)))))+(P(:,4)*ones(1,Lt));
% r2=((P(:,5)*ones(1,Lt))./(1+exp(-(ones(N,1)*zz-(P(:,6)*ones(1,Lt)))./...
%     (P(:,7)*ones(1,Lt)))))+(P(:,8)*ones(1,Lt));
% s = r1+r2;
% plot(zz,r1,'--'); hold on;
% plot(zz,r2,'--','Color','g')
% plot(zz,s,'--','color','r')
% legend('R1','R2','S_z','r1','r2','ild')
% xlim([-1, 1])
% 

