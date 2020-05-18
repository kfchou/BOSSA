addpath('IRM')

% first, calculate IRM or IBM
targFilt = ERBFilterBank(target_wav(:,1),fcoefs);
[IBMsig,IRM,IBM] = calcIRM(targFilt,mixedFiltL);

maskParam.kernel = 'alpha';
maskParam.tau = params.tau;
params.maskRatio = 0.5;
delays = 0;
for i = 1:length(delays)
    maskParam.delay = delays(i);
    masks = calcSpkMask(spks,fs,maskParam);

    centerM = masks(:,:,3);
    rightM1 = masks(:,:,5);
    rightM2 = masks(:,:,4);
    leftM1 = masks(:,:,1); 
    leftM2 = masks(:,:,2);
    
    % cross hemisphere suppression
    mask1 = max(rightM1-leftM1,0);
    mask2 = max(leftM1-rightM1,0);
    mask3 = max(rightM2-leftM2,0);
    mask4 = max(leftM2-rightM2,0);
    diffMask = max(centerM-mask1-mask2-mask3-mask4,0.001);
    [rstimCrossMask, maskedWav] = applyMask(diffMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stCross(i) = runStoi(rstimCrossMask,target,fs,fs)

    %side masks inhibit center (old implementation)
    spkMask = centerM-params.maskRatio.*(rightM1+leftM1+leftM2+rightM2);
    spkMask(spkMask<0)=0;
    [rstimDiffMask, maskedWav] = applyMask(spkMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stDiff(i) = runStoi(rstimDiffMask,target,fs,fs)
    
    [mval,midx] = max(masks,[],3);
    temp = midx==3;
    iceburgMask = centerM.*temp;
    [rstim1dual, maskedWav] = applyMask(iceburgMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stIceburg(i) = runStoi(rstim1dual,target,fs,fs)


    ratioMask = centerM./(sum(masks,3)+0.0001);
    ratioMask(ratioMask<0.5) = 0;
    [rstim1dual, maskedWav] = applyMask(ratioMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stRatio = runStoi(rstim1dual,target,fs,fs)
    
    combinedMask = ratioMask+diffMask/max(max(diffMask));
    [rstim1dual, maskedWav] = applyMask(combinedMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stCombine = runStoi(rstim1dual,target,fs,fs)

end

addpath('plotting')
subplot(2,3,1); plot_db(targFilt,80); title('target')
subplot(2,3,2); imagesc(IRM); title('IRM')
subplot(2,3,3); imagesc(spkMask); title('cross-hemisphere mask')
subplot(2,3,4); imagesc(diffMask); title('diffMask')
subplot(2,3,5); imagesc(iceburgMask); title('iceburgMask')
subplot(2,3,6); imagesc(ratioMask); title('ratioMask')

