% ------------------------------------------------------------------------------
% Compute RTQC data for CHLA parameter and adjust CHLA data.
%
% SYNTAX :
%  [o_profChlaQc, o_profChlaAdj, o_profChlaAdjQc, o_chlaAdjInfo] = ...
%    add_chla_rtqc_to_profile_file(a_floatNum, a_cyNum, ...
%    a_profPresFluoChla, a_profPresFluoChlaQc, a_presFluoChlaDataFillValue, ...
%    a_profFluoChla, a_profFluoChlaQc, a_fluoChlaDataFillValue, ...
%    a_profChla, a_profChlaQc, a_chlaDataFillValue, ...
%    a_profChlaAdj, a_profChlaAdjQc, a_chlaDataAdjFillValue, ...
%    a_darkChla, a_scaleChla, a_lastDarkChla, ...
%    a_profPres, a_profPresQc, a_presDataFillValue, ...
%    a_profTemp, a_profTempQc, a_tempDataFillValue, ...
%    a_profPsal, a_profPsalQc, a_psalDataFillValue, ...
%    a_lon, a_lat)
%
% INPUT PARAMETERS :
%   a_floatNum                  : float WMO number
%   a_cyNum                     : cycle number
%   a_profPresFluoChla          : pressures of the FLUORESCENCE_CHLA parameter
%                                 profile
%   a_profPresFluoChlaQc        : pressure Qcs of the FLUORESCENCE_CHLA
%                                 parameter profile
%   a_presFluoChlaDataFillValue : fill value of the PRES parameter
%   a_profFluoChla              : FLUORESCENCE_CHLA parameter profile
%   a_profFluoChlaQc            : Qcs of the FLUORESCENCE_CHLA parameter profile
%   a_fluoChlaDataFillValue     : fill value of the FLUORESCENCE_CHLA parameter
%   a_profChla                  : CHLA parameter profile
%   a_profChlaQc                : Qcs of the CHLA parameter profile
%   a_chlaDataFillValue         : fill value of the CHLA parameter
%   a_profChlaAdj               : CHLA_ADJUSTED parameter profile
%   a_profChlaAdjQc             : Qcs of the CHLA_ADJUSTED parameter profile
%   a_chlaDataAdjFillValue      : fill value of the CHLA_ADJUSTED parameter
%   a_darkChla                  : launch DARK_CHLA calibration coefficient
%   a_scaleChla                 : launch SCALE_CHLA calibration coefficient
%   a_lastDarkChla              : last adjusted value of the DARK_CHLA
%                                 calibration coefficient
%   a_profPres                  : pressures of the CTD profile
%   a_profPresQc                : pressure Qcs of the CTD profile
%   a_presDataFillValue         : fill value of the PRES parameter
%   a_profTemp                  : temperatures of the CTD profile
%   a_profTempQc                : temperature Qcs of the CTD profile
%   a_tempDataFillValue         : fill value of the TEMP parameter
%   a_profPsal                  : salinities of the CTD profile
%   a_profPsalQc                : salinity Qcs of the CTD profile
%   a_psalDataFillValue         : fill value of the PSAL parameter
%   a_lon                       : longitude of the profile
%   a_lat                       : latitude of the profile
%
% OUTPUT PARAMETERS :
%   o_profChlaQc    : Qcs of the CHLA parameter profile
%   o_profChlaAdj   : CHLA_ADJUSTED parameter profile
%   o_profChlaAdjQc : Qcs of the CHLA_ADJUSTED parameter profile
%   o_chlaAdjInfo   : output information on CHLA adjustment
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/05/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profChlaQc, o_profChlaAdj, o_profChlaAdjQc, o_chlaAdjInfo] = ...
   add_chla_rtqc_to_profile_file(a_floatNum, a_cyNum, ...
   a_profPresFluoChla, a_profPresFluoChlaQc, a_presFluoChlaDataFillValue, ...
   a_profFluoChla, a_profFluoChlaQc, a_fluoChlaDataFillValue, ...
   a_profChla, a_profChlaQc, a_chlaDataFillValue, ...
   a_profChlaAdj, a_profChlaAdjQc, a_chlaDataAdjFillValue, ...
   a_darkChla, a_scaleChla, a_lastDarkChla, ...
   a_profPres, a_profPresQc, a_presDataFillValue, ...
   a_profTemp, a_profTempQc, a_tempDataFillValue, ...
   a_profPsal, a_profPsalQc, a_psalDataFillValue, ...
   a_lon, a_lat)

% output parameters initialization
o_profChlaQc = [];
o_profChlaAdj = [];
o_profChlaAdjQc = [];
o_chlaAdjInfo = [];

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrChanged;       % '5'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'


SPECIFICATION_DOI_1 = 'http://dx.doi.org/10.13155/35385';
SPECIFICATION_DOI_2 = 'https://doi.org/10.1002/lom3.10185';
MLD_LIMIT = 0.03;
DELTA_DEPTH = 200; % in meters
DELTA_DEPTH_DARK = 50; % in meters

mldFlag = 0;
mld = '';
chlaQcValue = g_decArgo_qcStrGood;
chlaAdjQcValue = g_decArgo_qcStrGood;

if (isempty(a_darkChla) || isempty(a_scaleChla))
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: Empty DARK_CHLA/SCALE_CHLA: unable to process RTQC CHLA\n', ...
      a_floatNum, a_cyNum);
   return
end

% if no adjustement has been performed
if (isempty(a_lastDarkChla))
   a_lastDarkChla = a_darkChla;
end

% set the CHLA_QC according to previous adjustments
if (a_lastDarkChla == a_darkChla)
   chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrGood));
else
   chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrCorrectable));
end

% valid levels of the CTD profile
idNoDefAndGoodPts = [];
if (~isempty(a_profPres))
   idNoDefAndGoodPts = find((a_profPres ~= a_presDataFillValue) & ...
      (a_profPresQc ~= g_decArgo_qcStrCorrectable) & ...
      (a_profPresQc ~= g_decArgo_qcStrBad) & ...
      (a_profTemp ~= a_tempDataFillValue) & ...
      (a_profTempQc ~= g_decArgo_qcStrCorrectable) & ...
      (a_profTempQc ~= g_decArgo_qcStrBad) & ...
      (a_profPsal ~= a_psalDataFillValue) & ...
      (a_profPsalQc ~= g_decArgo_qcStrCorrectable) & ...
      (a_profPsalQc ~= g_decArgo_qcStrBad) ...
      );
end

% valid levels of the FLUORESCENCE_CHLA profile
idNoDefAndGood = find((a_profPresFluoChla ~= a_presFluoChlaDataFillValue) & ...
   (a_profPresFluoChlaQc ~= g_decArgo_qcStrCorrectable) & ...
   (a_profPresFluoChlaQc ~= g_decArgo_qcStrBad) & ...
   (a_profFluoChla ~= a_fluoChlaDataFillValue) & ...
   (a_profFluoChlaQc ~= g_decArgo_qcStrCorrectable) & ...
   (a_profFluoChlaQc ~= g_decArgo_qcStrBad) & ...
   (a_profChlaQc ~= g_decArgo_qcStrCorrectable) & ...
   (a_profChlaQc ~= g_decArgo_qcStrBad) ...
   );

newDarkChla = [];
if (~isempty(idNoDefAndGood))

   if (~isempty(idNoDefAndGoodPts))
      
      % MLD estimation
      profPres = a_profPres(idNoDefAndGoodPts);
      profTemp = a_profTemp(idNoDefAndGoodPts);
      profPsal = a_profPsal(idNoDefAndGoodPts);
      
      % compute potential density around 10 m
      [~, idMin] = min(abs(profPres-10));
      sigma10 = potential_density_gsw(profPres(idMin), profTemp(idMin), profPsal(idMin), 0, a_lon, a_lat);    
      
      % compute potential temperature and potential density
      sigma = potential_density_gsw(profPres, profTemp, profPsal, 0, a_lon, a_lat)';
      
      idF = find((sigma - sigma10) > MLD_LIMIT);
      if (~isempty(idF))
         mld = profPres(idF(1));
         %          fprintf('mld: %g\n', mld);

         profPresFluoChla = a_profPresFluoChla(idNoDefAndGood);
         profFluoChla = a_profFluoChla(idNoDefAndGood);
         
         if (profPresFluoChla(end) > mld + DELTA_DEPTH + DELTA_DEPTH_DARK)
            
            idF = find((profPresFluoChla - (profPresFluoChla(end)-DELTA_DEPTH_DARK)) >= 0);
            newDarkChlaTmp = round(median(profFluoChla(idF)));
            
            if (abs(newDarkChlaTmp - a_darkChla) <= 0.2*a_darkChla)
               newDarkChla = newDarkChlaTmp;
               %                if (newDarkChla ~= a_lastDarkChla)
               %                   fprintf('newDarkChla: %g (rounded value of median value: %g)\n', ...
               %                      newDarkChla, median(profFluoChla(idF)));
               %                else
               %                   fprintf('same darkChla: %g (rounded value of median value: %g)\n', ...
               %                      newDarkChla, median(profFluoChla(idF)));
               %                end
               if (newDarkChla ~= a_darkChla)
                  chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrCorrectable));
                  chlaAdjQcValue = char(max(chlaAdjQcValue, g_decArgo_qcStrGood));
               end
            else
               newDarkChla = a_lastDarkChla;
               chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrCorrectable));
               chlaAdjQcValue = char(max(chlaAdjQcValue, g_decArgo_qcStrCorrectable));
            end
         else
            newDarkChla = a_lastDarkChla;
            chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrProbablyGood));
            chlaAdjQcValue = char(max(chlaAdjQcValue, g_decArgo_qcStrProbablyGood));
            mldFlag = 1;
         end
      else
         newDarkChla = a_lastDarkChla;
         chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrProbablyGood));
         chlaAdjQcValue = char(max(chlaAdjQcValue, g_decArgo_qcStrProbablyGood));
         mldFlag = 1;
      end
   else
      newDarkChla = a_lastDarkChla;
      chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrProbablyGood));
      chlaAdjQcValue = char(max(chlaAdjQcValue, g_decArgo_qcStrProbablyGood));
      mldFlag = 1;
   end
else
   newDarkChla = a_lastDarkChla;
   chlaQcValue = char(max(chlaQcValue, g_decArgo_qcStrCorrectable));
   chlaAdjQcValue = char(max(chlaAdjQcValue, g_decArgo_qcStrCorrectable));
end

% update CHLA_QC
o_profChlaQc = a_profChlaQc;
idNoDef = find(a_profChla ~= a_chlaDataFillValue);
o_profChlaQc(idNoDef) = set_qc(o_profChlaQc(idNoDef), chlaQcValue);

% update output parameters
o_chlaAdjInfo.newDarkChla = newDarkChla;
o_chlaAdjInfo.scaleChla = a_scaleChla;
o_chlaAdjInfo.depthNPQ = '';
o_chlaAdjInfo.chlaNPQ = '';
o_chlaAdjInfo.doi1 = SPECIFICATION_DOI_1;
o_chlaAdjInfo.doi2 = SPECIFICATION_DOI_2;
o_chlaAdjInfo.mldLimit = MLD_LIMIT;
o_chlaAdjInfo.deltaDepth = DELTA_DEPTH;
o_chlaAdjInfo.deltaDepthDark = DELTA_DEPTH_DARK;

% compute CHLA_ADJUSTED
o_profChlaAdj = ones(size(a_profChla))*a_chlaDataFillValue;
o_profChlaAdjQc = repmat(g_decArgo_qcStrDef, size(a_profFluoChlaQc));

% BEGIN - see 6900796 #83
idDef = find((a_profFluoChla == a_fluoChlaDataFillValue) & (a_profPresFluoChla ~= a_presFluoChlaDataFillValue));
o_profChlaAdjQc(idDef) = g_decArgo_qcStrMissing;
% END - see 6900796 #83

idNoDef = find(a_profFluoChla ~= a_fluoChlaDataFillValue);
o_profChlaAdj(idNoDef) = (a_profFluoChla(idNoDef) - newDarkChla)*a_scaleChla;
o_profChlaAdj(idNoDef) = o_profChlaAdj(idNoDef)/2; % recommendations of Roesler et al., 2017
o_profChlaAdjQc(idNoDef) = set_qc(a_profChlaAdjQc(idNoDef), chlaAdjQcValue);

% apply range test to CHLA_ADJUSTED
idToFlag = find((o_profChlaAdj(idNoDef) < -0.1) | (o_profChlaAdj(idNoDef) > 50));
if (~isempty(idToFlag))
   o_profChlaAdjQc(idNoDef(idToFlag)) = set_qc(o_profChlaAdjQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
end

% apply negative spike test to CHLA_ADJUSTED
idNoDefAndGood = find((o_profChlaAdj ~= a_chlaDataFillValue) & ...
   (o_profChlaAdjQc ~= g_decArgo_qcStrBad));
profChlaAdj = o_profChlaAdj(idNoDefAndGood);

if (length(profChlaAdj) > 4)
   resProfChlaAdjData = ones(1, length(profChlaAdj)-4)*a_chlaDataFillValue;
   idList = 3:length(profChlaAdj)-2;
   for idL = 1:length(idList)
      resProfChlaAdjData(idL) = profChlaAdj(idList(idL)) - median(profChlaAdj(idList(idL)-2:idList(idL)+2));
   end
   sortedResProfChlaAdjData = sort(resProfChlaAdjData);
   idPct10 = ceil(length(sortedResProfChlaAdjData)*0.1);
   percentile10 = sortedResProfChlaAdjData(idPct10);
   idToFlag = find(resProfChlaAdjData < 2*percentile10) + 2;
   
   if (~isempty(idToFlag))
      o_profChlaAdjQc(idNoDefAndGood(idToFlag)) = set_qc(o_profChlaAdjQc(idNoDefAndGood(idToFlag)), g_decArgo_qcStrBad);
   end
end

% Non Photochemical Quenching (NPQ) correction
if (~isempty(mld) && (mldFlag == 0))
   
   idNoDefAndGood = find((a_profPresFluoChla ~= a_presFluoChlaDataFillValue) & ...
      (a_profPresFluoChlaQc ~= g_decArgo_qcStrCorrectable) & ...
      (a_profPresFluoChlaQc ~= g_decArgo_qcStrBad) & ...
      (o_profChlaAdj ~= a_chlaDataFillValue) ...
      );
   profPresChlaAdj = a_profPresFluoChla(idNoDefAndGood);
   profChlaAdj = o_profChlaAdj(idNoDefAndGood);

   if (length(profChlaAdj) > 4)
      resProfChlaAdjData = ones(1, length(profChlaAdj)-4)*a_chlaDataFillValue;
      idList = 3:length(profChlaAdj)-2;
      for idL = 1:length(idList)
         resProfChlaAdjData(idL) = profChlaAdj(idList(idL)) - median(profChlaAdj(idList(idL)-2:idList(idL)+2));
      end
      sortedResProfChlaAdjData = sort(resProfChlaAdjData);
      idPct90 = ceil(length(sortedResProfChlaAdjData)*0.9);
      percentile90 = sortedResProfChlaAdjData(idPct90);
      idNoPosSpike = find(resProfChlaAdjData <= 2*percentile90) + 2;

      profPresChlaAdj = profPresChlaAdj(idNoPosSpike);
      profChlaAdj = profChlaAdj(idNoPosSpike);

      idF = find(profPresChlaAdj <= 0.9*mld);
      [~, idMax] = max(profPresChlaAdj(idF));
      idMld = idF(idMax);
      zMaxFluoIds = 3:min(idMld, length(profChlaAdj)-2);
      
      if (length(zMaxFluoIds) > 4)
         profMedChlaAdj = ones(1, length(zMaxFluoIds))*a_chlaDataFillValue;
         for idL = 1:length(zMaxFluoIds)
            profMedChlaAdj(idL) = median(profChlaAdj(zMaxFluoIds(idL)-2:zMaxFluoIds(idL)+2));
         end
         
         [~, idMax] = max(profMedChlaAdj);
         depthNpqId = idMax + 2;
         
         idNoDefChlaAdj = find(o_profChlaAdj ~= a_chlaDataFillValue);
         idToFlag = find(idNoDefChlaAdj <= idNoDefAndGood(idNoPosSpike(depthNpqId)));
         o_profChlaAdj(idNoDefChlaAdj(idToFlag)) = profChlaAdj(depthNpqId);
         o_profChlaAdjQc(idNoDefChlaAdj(idToFlag)) = set_qc(o_profChlaAdjQc(idNoDefChlaAdj(idToFlag)), g_decArgo_qcStrChanged);
                  
         % update CHLA_QC
         idNoDefChla = find(a_profChla ~= a_chlaDataFillValue);
         idToFlag = intersect(idNoDefChla, idNoDefChlaAdj(idToFlag));
         o_profChlaQc(idToFlag) = set_qc(o_profChlaQc(idToFlag), g_decArgo_qcStrCorrectable);

         % update output parameters
         o_chlaAdjInfo.depthNPQ = profPresChlaAdj(depthNpqId);
         o_chlaAdjInfo.chlaNPQ = profChlaAdj(depthNpqId);
      end
   end
end

% assign CHLA QC values to CHLA_ADJUSTED QC that have not been set 
idDef = find(o_profChlaAdjQc == g_decArgo_qcStrDef);
o_profChlaAdjQc(idDef) = o_profChlaQc(idDef);

return
