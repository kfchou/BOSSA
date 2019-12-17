maskParam.kernel = 'alpha';
maskParam.tau = params.tau;
delays = -200:20:200;
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
    spkMask = max(centerM-mask1-mask2-mask3-mask4,0.001);

    [rstimCrossMask, maskedWav] = applyMask(spkMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stCross(i) = runStoi(rstimCrossMask,target,fs,fs);
%     figure;imagesc(spkMask); title('cross-hemisphere mask')

    %side masks inhibit center (old implementation)
    spkMask = centerM-params.maskRatio.*(rightM1+leftM1+leftM2+rightM2);
    spkMask(spkMask<0)=0;
%     figure;imagesc(spkMask); title('diffMask')
    [rstimDiffMask, maskedWav] = applyMask(spkMask,mixedFiltL,mixedFiltR,frgain,'filt');
    stDiff(i) = runStoi(rstimDiffMask,target,fs,fs);
    
    [mval,midx] = max(masks,[],3);
temp = midx==3;
iceburgMask = centerM.*temp;
[rstim1dual, maskedWav] = applyMask(iceburgMask,mixedFiltL,mixedFiltR,frgain,'filt');
stIceburg(i) = runStoi(rstim1dual,target,fs,fs)
% figure;imagesc(iceburgMask); title('iceburgMask')


iceburgMask = centerM./(sum(masks,3)+0.0001);
[rstim1dual, maskedWav] = applyMask(iceburgMask,mixedFiltL,mixedFiltR,frgain,'filt');
stRatio = runStoi(rstim1dual,target,fs,fs)
% figure;imagesc(iceburgMask); title('ratioMask')
end