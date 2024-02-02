% ------------------------------------------------------------------------------
% Compute RTQC data for CHLA parameter and adjust CHLA data.
%
% SYNTAX :
% [o_profChlaQc, o_profChlaAdj, o_profChlaAdjQc, ...
%   o_profChlaFluoQc, o_profChlaFluoAdj, o_profChlaFluoAdjQc, o_chlaAdjInfo] = ...
%   add_chla_rtqc_to_profile_file( ...
%   a_floatNum, a_julD, a_cyNum, ...
%   a_profPresFluoChla, a_profPresFluoChlaQc, a_presFluoChlaDataFillValue, ...
%   a_profFluoChla, a_profFluoChlaQc, a_fluoChlaDataFillValue, ...
%   a_profChla, a_profChlaQc, a_chlaDataFillValue, ...
%   a_profChlaAdj, a_profChlaAdjQc, a_chlaDataAdjFillValue, ...
%   a_profChlaFluo, a_profChlaFluoQc, a_chlaFluoDataFillValue, ...
%   a_profChlaFluoAdj, a_profChlaFluoAdjQc, a_chlaFluoDataAdjFillValue, ...
%   a_darkChla, a_scaleChla, a_prelimDarkChla, ...
%   a_profPres, a_profPresQc, a_presDataFillValue, ...
%   a_profTemp, a_profTempQc, a_tempDataFillValue, ...
%   a_profPsal, a_profPsalQc, a_psalDataFillValue, ...
%   a_lon, a_lat)
%
% INPUT PARAMETERS :
%   a_floatNum                  : float WMO number
%   a_julD                      : profile JULD
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
%   a_profChlaFluo              : CHLA_FLUORESCENCE parameter profile
%   a_profChlaFluoQc            : Qcs of the CHLA_FLUORESCENCE parameter profile
%   a_chlaDataFluoFillValue     : fill value of the CHLA_FLUORESCENCE parameter
%   a_profChlaFluoAdj           : CHLA_FLUORESCENCE_ADJUSTED parameter profile
%   a_profChlaFluoAdjQc         : Qcs of the CHLA_FLUORESCENCE_ADJUSTED parameter profile
%   a_chlaFluoDataAdjFillValue  : fill value of the CHLA_FLUORESCENCE_ADJUSTED parameter
%   a_darkChla                  : launch DARK_CHLA calibration coefficient
%   a_scaleChla                 : launch SCALE_CHLA calibration coefficient
%   a_prelimDarkChla            : list of 5 first FLUORESCENCE_CHLA profile min
%                                 values
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
%   o_profChlaQc        : Qcs of the CHLA parameter profile
%   o_profChlaAdj       : CHLA_ADJUSTED parameter profile
%   o_profChlaAdjQc     : Qcs of the CHLA_ADJUSTED parameter profile
%   o_profChlaFluoQc    : Qcs of the CHLA_FLUORESCENCE parameter profile
%   o_profChlaFluoAdj   : CHLA_FLUORESCENCE_ADJUSTED parameter profile
%   o_profChlaFluoAdjQc : Qcs of the CHLA_FLUORESCENCE_ADJUSTED parameter profile
%   o_chlaAdjInfo       : output information on CHLA adjustment
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [ ...
   o_profChlaQc, o_profChlaAdj, o_profChlaAdjQc, ...
   o_profChlaFluoQc, o_profChlaFluoAdj, o_profChlaFluoAdjQc, o_chlaAdjInfo] = ...
   add_chla_rtqc_to_profile_file( ...
   a_floatNum, a_julD, a_cyNum, ...
   a_profPresFluoChla, a_profPresFluoChlaQc, a_presFluoChlaDataFillValue, ...
   a_profFluoChla, a_profFluoChlaQc, a_fluoChlaDataFillValue, ...
   a_profChla, a_profChlaQc, a_chlaDataFillValue, ...
   a_profChlaAdj, a_profChlaAdjQc, a_chlaDataAdjFillValue, ...
   a_profChlaFluo, a_profChlaFluoQc, a_chlaFluoDataFillValue, ...
   a_profChlaFluoAdj, a_profChlaFluoAdjQc, a_chlaFluoDataAdjFillValue, ...
   a_darkChla, a_scaleChla, a_prelimDarkChla, ...
   a_profPres, a_profPresQc, a_presDataFillValue, ...
   a_profTemp, a_profTempQc, a_tempDataFillValue, ...
   a_profPsal, a_profPsalQc, a_psalDataFillValue, ...
   a_lon, a_lat)

% output parameters initialization
o_profChlaQc = [];
o_profChlaAdj = [];
o_profChlaAdjQc = [];
o_profChlaFluoQc = [];
o_profChlaFluoAdj = [];
o_profChlaFluoAdjQc = [];
o_chlaAdjInfo = [];

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_janFirst1950InMatlab;

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


MIN_PROF_DEPTH_FOR_DARK_ESTIMATION_1 = 950;
MIN_PROF_DEPTH_FOR_DARK_ESTIMATION_2 = 5;

SPECIFICATION_DOI_1 = 'http://dx.doi.org/10.13155/35385';
SPECIFICATION_DOI_2 = 'https://doi.org/10.1002/lom3.10185';
MLD_LIMIT = 0.03;

zMaxFluo = '';
chlaNPQ = '';

if (isempty(a_darkChla) || isempty(a_scaleChla))
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: Empty DARK_CHLA/SCALE_CHLA: unable to process RTQC CHLA\n', ...
      a_floatNum, a_cyNum);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update CHLA_QC
o_profChlaQc = a_profChlaQc;
idNoDef = find(a_profChla ~= a_chlaDataFillValue);
o_profChlaQc(idNoDef) = set_qc(o_profChlaQc(idNoDef), g_decArgo_qcStrCorrectable);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update CHLA_FLUORESCENCE_QC
o_profChlaFluoQc = a_profChlaFluoQc;
idNoDef = find(a_profChlaFluo ~= a_chlaFluoDataFillValue);
o_profChlaFluoQc(idNoDef) = set_qc(o_profChlaFluoQc(idNoDef), g_decArgo_qcStrGood);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DARK ESTIMATION

% fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: DARK ESTIMATION\n', ...
%    a_floatNum, a_cyNum);

% process current cycle
idNoDef = find((a_profPresFluoChla ~= a_presFluoChlaDataFillValue) & ...
   (a_profFluoChla ~= a_fluoChlaDataFillValue));
if (~isempty(idNoDef))
   iDarkChla = '';
   floatDarkChla = '';

   % first version
   % MIN_PROF_DEPTH_FOR_DARK_ESTIMATION = 950;
   % if (any(a_profPresFluoChla(idNoDef) > MIN_PROF_DEPTH_FOR_DARK_ESTIMATION))
   %    iDarkChla = min(a_profFluoChla(idNoDef));
   % end

   % second version
   if (any(a_profPresFluoChla(idNoDef) > MIN_PROF_DEPTH_FOR_DARK_ESTIMATION_1))
      if (any(a_profPresFluoChla(idNoDef) > MIN_PROF_DEPTH_FOR_DARK_ESTIMATION_2))
         idMeas = find(a_profPresFluoChla(idNoDef) > MIN_PROF_DEPTH_FOR_DARK_ESTIMATION_2);
         iDarkChla = min(median_filter(a_profFluoChla(idNoDef(idMeas)), 5));
      end
   end

   % if (~isempty(iDarkChla))
   %    fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: iDARK = %g\n', ...
   %       a_floatNum, a_cyNum, iDarkChla);
   % else
   %    fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: no iDARK available\n', ...
   %       a_floatNum, a_cyNum);
   % end

   if (~isempty(a_prelimDarkChla))
      if (~isempty(iDarkChla))
         if (length(a_prelimDarkChla) < 5)
            a_prelimDarkChla = [a_prelimDarkChla iDarkChla];
         end
         darkPChla = median(a_prelimDarkChla);
         if (length(a_prelimDarkChla) == 5)
            floatDarkChla = darkPChla;
         else
            chlaAdjQCValue = g_decArgo_qcStrProbablyGood;
            chlaFluoAdjQCValue = g_decArgo_qcStrProbablyGood;
         end
      else
         darkPChla = median(a_prelimDarkChla);
         chlaAdjQCValue = g_decArgo_qcStrProbablyGood;
         chlaFluoAdjQCValue = g_decArgo_qcStrProbablyGood;
      end
   else
      if (~isempty(iDarkChla))
         darkPChla = iDarkChla;
         a_prelimDarkChla = [a_prelimDarkChla iDarkChla];
         chlaAdjQCValue = g_decArgo_qcStrProbablyGood;
         chlaFluoAdjQCValue = g_decArgo_qcStrProbablyGood;
      else
         darkPChla = a_darkChla;
         chlaAdjQCValue = g_decArgo_qcStrProbablyGood;
         chlaFluoAdjQCValue = g_decArgo_qcStrProbablyGood;
      end
   end

   % fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: DARK’_CHLA  = %g\n', ...
   %    a_floatNum, a_cyNum, darkPChla);
   % 
   % if (~isempty(floatDarkChla))
   %    fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: FLOAT_DARK_CHLA = %g\n', ...
   %       a_floatNum, a_cyNum, floatDarkChla);
   % else
   %    fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: no FLOAT_DARK_CHLA available\n', ...
   %       a_floatNum, a_cyNum);
   % end

   % quality of FLOAT_DARK_CHLA
   if (~isempty(floatDarkChla))
      if (abs(floatDarkChla - a_darkChla) < 0.25*a_darkChla)
         chlaAdjQCValue = g_decArgo_qcStrGood;
         chlaFluoAdjQCValue = g_decArgo_qcStrGood;

         % fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: |FLOAT_DARK_CHLA - DARK_CHLA| < 0.25 * DARK_CHLA (|%g - %g| = %g < 0.25 * %g = %g)\n', ...
         %    a_floatNum, a_cyNum, ...
         %    floatDarkChla, a_darkChla, abs(floatDarkChla - a_darkChla), ...
         %    a_darkChla, 0.25*a_darkChla);
      else
         chlaAdjQCValue = g_decArgo_qcStrCorrectable;
         chlaFluoAdjQCValue = g_decArgo_qcStrCorrectable;
      end
   end

   % if (a_cyNum == 1)
   %    a=1
   % end

   % compute CHLA_ADJUSTED
   o_profChlaAdj = ones(size(a_profChla))*a_chlaDataFillValue;
   o_profChlaAdjQc = repmat(g_decArgo_qcStrDef, size(a_profChlaQc));

   % manage missing values
   idDef = find((a_profFluoChla == a_fluoChlaDataFillValue) & (a_profFluoChlaQc ~= g_decArgo_qcStrDef));
   o_profChlaAdjQc(idDef) = g_decArgo_qcStrMissing;

   idNoDef = find(a_profFluoChla ~= a_fluoChlaDataFillValue);
   o_profChlaAdj(idNoDef) = (a_profFluoChla(idNoDef) - darkPChla)*a_scaleChla;
   o_profChlaAdjQc(idNoDef) = set_qc(a_profChlaAdjQc(idNoDef), chlaAdjQCValue);

   % compute CHLA_FLUORESCENCE_ADJUSTED
   o_profChlaFluoAdj = ones(size(a_profChlaFluo))*a_chlaFluoDataFillValue;
   o_profChlaFluoAdjQc = repmat(g_decArgo_qcStrDef, size(a_profChlaFluoQc));

   % manage missing values
   idDef = find((a_profFluoChla == a_fluoChlaDataFillValue) & (a_profFluoChlaQc ~= g_decArgo_qcStrDef));
   o_profChlaFluoAdjQc(idDef) = g_decArgo_qcStrMissing;

   idNoDef = find(a_profFluoChla ~= a_fluoChlaDataFillValue);
   o_profChlaFluoAdj(idNoDef) = (a_profFluoChla(idNoDef) - darkPChla)*a_scaleChla;
   o_profChlaFluoAdjQc(idNoDef) = set_qc(a_profChlaFluoAdjQc(idNoDef), chlaFluoAdjQCValue);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NPQ CORRECTION

% fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: NPQ CORRECTION\n', ...
%    a_floatNum, a_cyNum);

% determine solar elevation
if ((a_julD ~= g_decArgo_dateDef) && (a_lon ~= g_decArgo_argosLonDef) && (a_lat ~= g_decArgo_argosLatDef))

   [~, sunAngle] = SolarAzEl(datestr(a_julD + g_decArgo_janFirst1950InMatlab, 'yyyy/mm/dd HH:MM:SS'), a_lat, a_lon, 0);

   % fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: SUN_ANGLE  = %g\n', ...
   %    a_floatNum, a_cyNum, sunAngle);
   
   if (sunAngle > 0)

      % Mixed Layer Depth estimation

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

      mld = '';
      if (~isempty(idNoDefAndGoodPts))

         % Mixed Layer Depth estimation
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
         end
      end

      % if (~isempty(mld))
      %    fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: MLD = %g\n', ...
      %       a_floatNum, a_cyNum, mld);
      % else
      %    fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: no MLD available\n', ...
      %       a_floatNum, a_cyNum);
      % end

      % valid levels of the PRES and CHLA_ADJUSTED profile
      idNoDefAndGood = find((a_profPresFluoChla ~= a_presFluoChlaDataFillValue) & ...
         (a_profPresFluoChlaQc ~= g_decArgo_qcStrCorrectable) & ...
         (a_profPresFluoChlaQc ~= g_decArgo_qcStrBad) & ...
         (o_profChlaAdj ~= a_chlaDataAdjFillValue) & ...
         (o_profChlaAdjQc ~= g_decArgo_qcStrCorrectable) & ...
         (o_profChlaAdjQc ~= g_decArgo_qcStrBad) ...
         );

      if (~isempty(idNoDefAndGood))
         if (~isempty(mld))

            profPresFluoChla = a_profPresFluoChla(idNoDefAndGood);
            profPresFluoChlaQc = a_profPresFluoChlaQc(idNoDefAndGood);
            profChlaAdj = o_profChlaAdj(idNoDefAndGood);
            profChlaAdjQc = o_profChlaAdjQc(idNoDefAndGood);

            profRes = median(diff(profPresFluoChla));
            if (profRes <= 1)
               filterSize = 11;
            elseif (profRes < 3)
               filterSize = 7;
            else
               filterSize = 5;
            end

            chlaSmooth = median_filter(profChlaAdj, filterSize);
            idPresOk = find((profPresFluoChla >= 0) & (profPresFluoChla <= 0.9*mld));

            if (~isempty(idPresOk))
               [chlaNPQ, idMax] = max(chlaSmooth(idPresOk));
               zMaxFluo = profPresFluoChla(idPresOk(idMax));

               % fprintf('RTQC_VERB: TEST063: Float #%d Cycle #%d: ZMaxFluo = %g, CHLA_SMOOTH(ZMaxFluo) = %g\n', ...
               %    a_floatNum, a_cyNum, zMaxFluo, chlaNPQ);

               idPresOk = find((a_profPresFluoChla ~= a_presFluoChlaDataFillValue) & ...
                  (a_profPresFluoChla <= zMaxFluo));

               o_profChlaAdj(idPresOk) = chlaNPQ;
               o_profChlaAdjQc(idPresOk) = set_qc(o_profChlaAdjQc(idPresOk), g_decArgo_qcStrChanged);
            end
         else
            idToFlag = find((a_profPresFluoChla ~= a_presFluoChlaDataFillValue) & ...
               (o_profChlaAdj ~= a_chlaDataAdjFillValue));
            o_profChlaAdjQc(idToFlag) = set_qc(a_profChlaAdjQc(idToFlag), g_decArgo_qcStrCorrectable);
         end
      end
   end
else
   fprintf('RTQC_WARNING: Float #%d Cycle #%d: Profile is not dated and/or located: unable to compute sun angle for NPQ correction\n', ...
      a_floatNum, a_cyNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calibration slope adjustment

idNoDef = find(o_profChlaAdj ~= a_chlaDataAdjFillValue);
if (~isempty(idNoDef))
   o_profChlaAdj(idNoDef) = o_profChlaAdj(idNoDef)/2;

   % apply range test to CHLA_ADJUSTED
   idToFlag = find((o_profChlaAdj(idNoDef) < -0.1) | (o_profChlaAdj(idNoDef) > 50));
   if (~isempty(idToFlag))
      o_profChlaAdjQc(idNoDef(idToFlag)) = set_qc(o_profChlaAdjQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
   end
end

% update output parameters
o_chlaAdjInfo.doi1 = SPECIFICATION_DOI_1;
o_chlaAdjInfo.doi2 = SPECIFICATION_DOI_2;
o_chlaAdjInfo.mldLimit = MLD_LIMIT;
o_chlaAdjInfo.chlaNPQ = chlaNPQ;
o_chlaAdjInfo.depthNPQ = zMaxFluo;
prelimDarkChlaStr = sprintf('%g,', a_prelimDarkChla);
o_chlaAdjInfo.prelimDarkChla = prelimDarkChlaStr(1:end-1);
o_chlaAdjInfo.scaleChla = a_scaleChla;

return

% ------------------------------------------------------------------------------
% Compute median values of a set of data.
%
% SYNTAX :
%  [o_outputFiltVal] = median_filter(a_inputVal, a_size)
%
% INPUT PARAMETERS :
%   a_inputVal : input set of values
%   a_size     : size of the median filter
%
% OUTPUT PARAMETERS :
%   o_outputFiltVal : median values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputFiltVal] = median_filter(a_inputVal, a_size)

% output parameters initialization
o_outputFiltVal = nan(size(a_inputVal));


halfSize = fix(a_size/2);
for id = 1:length(a_inputVal)
   id1 = max(1, id-halfSize);
   id2 = min(length(a_inputVal), id+halfSize);
   o_outputFiltVal(id) = median(a_inputVal(id1:id2));
end

return
