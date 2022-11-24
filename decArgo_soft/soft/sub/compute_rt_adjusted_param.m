% ------------------------------------------------------------------------------
% Perform real time adjustment on parameter profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_param( ...
%    a_tabProfiles, a_launchDate, a_notOnlyDoxyFlag, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles     : input profile structures
%   a_launchDate      : float launch date
%   a_notOnlyDoxyFlag : 0: if only DOXY adjustment should be done
%                       1: if other BGC parameters should be adjusted
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_rt_adjusted_param( ...
   a_tabProfiles, a_launchDate, a_notOnlyDoxyFlag, a_decoderId)

% output parameters initialization
o_tabProfiles = a_tabProfiles;


% perform DOXY RT adjustment
[o_tabProfiles] = compute_rt_adjusted_doxy(o_tabProfiles, a_decoderId);

if (a_notOnlyDoxyFlag)
   % perform CHLA RT adjustment
   [o_tabProfiles] = compute_rt_adjusted_chla(o_tabProfiles);
   
   % perform NITRATE RT adjustment
   [o_tabProfiles] = compute_rt_adjusted_nitrate(o_tabProfiles, a_launchDate);
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on DOXY profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_doxy(a_tabProfiles, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_rt_adjusted_doxy(a_tabProfiles, a_decoderId)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;

% global default values
global g_decArgo_dateDef;
global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;
global g_decArgo_janFirst1950InMatlab;

% to store information on DOXY adjustment
global g_decArgo_paramAdjInfo;


% look for DOXY profiles
noDoxyProfile = 1;
for idProf = 1:length(o_tabProfiles)
   if (any(strcmp({o_tabProfiles(idProf).paramList.name}, 'DOXY')))
      noDoxyProfile = 0;
      break
   end
end
if (noDoxyProfile)
   return
end

% retrieve information on DOXY adjustement in RT_OFFSET information of META.json file
doSlope = '';
doOffset = '';
doDate = '';
doAdjError = '';
doAdjErrorStr = '';
doAdjErrMethod = '';
if (~isempty(g_decArgo_rtOffsetInfo))
   for idF = 1:length(g_decArgo_rtOffsetInfo.param)
      if (strcmp(g_decArgo_rtOffsetInfo.param{idF}, 'DOXY'))
         % mandatory fields
         doSlope = g_decArgo_rtOffsetInfo.slope{idF};
         doOffset = g_decArgo_rtOffsetInfo.value{idF};
         doDate = g_decArgo_rtOffsetInfo.date{idF};
         % not mandatory fields
         if (isfield(g_decArgo_rtOffsetInfo, 'adjError'))
            doAdjError = g_decArgo_rtOffsetInfo.adjError{idF};
            doAdjErrorStr = g_decArgo_rtOffsetInfo.adjErrorStr{idF}{:};
            doAdjErrMethod = g_decArgo_rtOffsetInfo.adjErrorMethod{idF};
         end
         break
      end
   end
end

% adjust DOXY profiles
if (~isempty(doSlope))
   firstAdj = 1;
   for idProf = 1:length(o_tabProfiles)
      profile = o_tabProfiles(idProf);
      if (any(strcmp({profile.paramList.name}, 'DOXY')) && ...
            (profile.date ~= g_decArgo_dateDef) && ...
            ((profile.date + g_decArgo_nbHourForProfDateCompInRtOffsetAdj/24) >= doDate))
         
         % retrieve associated profiles (needed for 'real' BGC floats since
         % PTS are in separate profiles)
         idProfs = find(([o_tabProfiles.outputCycleNumber] == profile.outputCycleNumber) & ...
            ([o_tabProfiles.direction] == profile.direction) & ...
            ([o_tabProfiles.sensorNumber] < 100)); % AUX profiles should not be considered
         
         % adjust DOXY for this profile
         [ok, profile] = adjust_doxy_profile(profile, o_tabProfiles(setdiff(idProfs, idProf)), doSlope, doOffset, doAdjError, a_decoderId);
         if (ok)
            o_tabProfiles(idProf) = profile;
            
            % fill structure to store DOXY adjustment information
            if (firstAdj)
               g_decArgo_paramAdjInfo.DOXY = [];
               firstAdj = 0;
            end
            if (profile.direction == 'A')
               direction = 2;
            else
               direction = 1;
            end
            
            equation = 'PPOX_DOXY_ADJUSTED = PPOX_DOXY * SLOPE + OFFSET';
            coefficient = sprintf('SLOPE = %g, OFFSET = %g', doSlope, doOffset);
            comment = '';
            if (~isnan(doAdjError))
               switch (doAdjErrMethod)
                  case '1_1'
                     comment = sprintf(['DOXY_ADJUSTED is computed from an adjustment ' ...
                        'of in water PSAT or PPOX float data at surface by comparison to WOA PSAT ' ...
                        'climatology or WOA PPOX in using PSATWOA and TEMP and PSALfloat at 1 atm, ' ...
                        'DOXY_ADJUSTED_ERROR is computed from a PPOX_ERROR of %s mbar'], doAdjErrorStr);
                  case '2_1'
                     comment = sprintf(['DOXY_ADJUSTED is estimated from an adjustment ' ...
                        'of in air PPOX float data by comparison to NCEP reanalysis, ' ...
                        'DOXY_ADJUSTED_ERROR is recomputed from a PPOX_ERROR = %s mbar.'], doAdjErrorStr);
                  case '3_1'
                     comment = sprintf(['DOXY_ADJUSTED is estimated from the last valid cycle ' ...
                        'with DM adjustment, DOXY_ADJUSTED_ERROR is recomputed from a ' ...
                        'PPOX_ERROR = %s mbar.'], doAdjErrorStr);
                  otherwise
                     fprintf('ERROR: Float #%d Cycle #%d%c: input CALIB_RT_ADJ_ERROR_METHOD (''%s'') of DOXY adjustment is not implemented yet - SCIENTIFIC_CALIB_COMMENT of DOXY parameter not set\n', ...
                        g_decArgo_floatNum, ...
                        profile.outputCycleNumber, profile.direction, doAdjErrMethod);
               end
            end
            date = datestr(doDate+g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

            g_decArgo_paramAdjInfo.DOXY = [g_decArgo_paramAdjInfo.DOXY;
               profile.outputCycleNumber direction {equation} {coefficient} {comment} {date}];
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on one DOXY profile data.
%
% SYNTAX :
%  [o_ok, o_profile] = adjust_doxy_profile(a_profile, a_tabProfiles, ...
%    a_slope, a_offset, a_adjError, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profile     : input DOXY profile structure
%   a_tabProfiles : profile structures with the same cycle number and
%                   direction as the DOXY one
%   a_slope       : slope to be used for PPOX_DOXY adjustment
%   a_offset      : offset to be used for PPOX_DOXY adjustment
%   a_adjError    : error on PPOX_DOXY adjusted values
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ok      : 1 if the adjustment has been performed, 0 otherwise
%   o_profile : output DOXY profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/03/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_profile] = adjust_doxy_profile(a_profile, a_tabProfiles, ...
   a_slope, a_offset, a_adjError, a_decoderId)

% output parameters initialization
o_ok = 0;
o_profile = [];

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% lists of managed decoders
global g_decArgo_decoderIdListBgcFloatAll;


% involved parameter information
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
paramDoxy = get_netcdf_param_attributes('DOXY');

% retrieve or interpolate PTS measurements
presValues = [];
tempValues = [];
psalValues = [];
doxyValues = [];
idPres = find(strcmp({a_profile.paramList.name}, 'PRES'));
idTemp = find(strcmp({a_profile.paramList.name}, 'TEMP'));
idPsal = find(strcmp({a_profile.paramList.name}, 'PSAL'));
idDoxy = find(strcmp({a_profile.paramList.name}, 'DOXY'));

if (~ismember(a_decoderId, g_decArgo_decoderIdListBgcFloatAll))

   % case of a PTSO float
   presValues = a_profile.data(:, idPres);
   tempValues = a_profile.data(:, idTemp);
   psalValues = a_profile.data(:, idPsal);
   doxyValues = a_profile.data(:, idDoxy);
else
   
   % case of a 'real' BGC float
   
   % create a PTS profile by concatenating the near-surface and the primary
   % sampling profiles
   idNssProf = [];
   idPsProf = [];
   for idProf = 1:length(a_tabProfiles)
      profile = a_tabProfiles(idProf);
      if (strncmp(profile.vertSamplingScheme, 'Near-surface sampling:', length('Near-surface sampling:')))
         idNssPres = find(strcmp({profile.paramList.name}, 'PRES'));
         idNssTemp = find(strcmp({profile.paramList.name}, 'TEMP'));
         idNssPsal = find(strcmp({profile.paramList.name}, 'PSAL'));
         if (~isempty(idNssPres) && ~isempty(idNssTemp) && ~isempty(idNssPsal))
            idNssProf = idProf;
         end
      elseif (strncmp(profile.vertSamplingScheme, 'Primary sampling:', length('Primary sampling:')))
         idPsPres = find(strcmp({profile.paramList.name}, 'PRES'));
         idPsTemp = find(strcmp({profile.paramList.name}, 'TEMP'));
         idPsPsal = find(strcmp({profile.paramList.name}, 'PSAL'));
         if (~isempty(idPsPres) && ~isempty(idPsTemp) && ~isempty(idPsPsal))
            idPsProf = idProf;
         end
      end
      if (~isempty(idNssProf) && ~isempty(idPsProf))
         break
      end
   end

   if (~isempty(idNssProf) && ~isempty(idPsProf))
      ctdPresData = [a_tabProfiles(idPsProf).data(:, idPsPres); a_tabProfiles(idNssProf).data(:, idNssPres)];
      ctdTempData = [a_tabProfiles(idPsProf).data(:, idPsTemp); a_tabProfiles(idNssProf).data(:, idNssTemp)];
      ctdPsalData = [a_tabProfiles(idPsProf).data(:, idPsPsal); a_tabProfiles(idNssProf).data(:, idNssPsal)];
   elseif (~isempty(idPsProf))
      ctdPresData = a_tabProfiles(idPsProf).data(:, idPsPres);
      ctdTempData = a_tabProfiles(idPsProf).data(:, idPsTemp);
      ctdPsalData = a_tabProfiles(idPsProf).data(:, idPsPsal);
   elseif (~isempty(idNssProf))
      ctdPresData = a_tabProfiles(idNssProf).data(:, idNssPres);
      ctdTempData = a_tabProfiles(idNssProf).data(:, idNssTemp);
      ctdPsalData = a_tabProfiles(idNssProf).data(:, idNssPsal);
   else
      ctdPresData = [];
      ctdTempData = [];
      ctdPsalData = [];
   end
      
   % clean fill values
   idNoDefPts = find((ctdPresData ~= paramPres.fillValue) & ...
      (ctdTempData ~= paramTemp.fillValue) & ...
      (ctdPsalData ~= paramPsal.fillValue));
   
   ctdPresData = ctdPresData(idNoDefPts);
   ctdTempData = ctdTempData(idNoDefPts);
   ctdPsalData = ctdPsalData(idNoDefPts);
   
   if (~isempty(ctdPresData))
      
      % interpolate and extrapolate the PTS data at the pressures of the
      % DOXY measurements
      ctdIntData = compute_interpolated_CTD_measurements(...
         [ctdPresData ctdTempData ctdPsalData], a_profile.data(:, idPres), a_profile.direction);
      
      presValues = ctdIntData(:, 1);
      tempValues = ctdIntData(:, 2);
      psalValues = ctdIntData(:, 3);
      doxyValues = a_profile.data(:, idDoxy);
   else
      fprintf('WARNING: Float #%d Cycle #%d%c: unable to find the associated CTD profile to adjust DOXY parameter - DOXY data cannot be adjusted\n', ...
         g_decArgo_floatNum, ...
         a_profile.outputCycleNumber, a_profile.direction);
   end
end

if (~isempty(presValues))
   
   % adjust DOXY data
   [doxyAdjValues, doxyAdjErrValues] = compute_DOXY_ADJUSTED( ...
      presValues, tempValues, psalValues, doxyValues, ...
      paramPres.fillValue, paramTemp.fillValue, paramPsal.fillValue, paramDoxy.fillValue, ...
      a_slope, a_offset, a_adjError, a_profile);
   
   % create array for adjusted data
   profile = a_profile;
   paramFillValue = [];
   for idParam = 1:length(profile.paramList)
      paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
      paramFillValue = [paramFillValue paramInfo.fillValue];
   end
   if (isempty(profile.dataAdj))
      profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
   end
   if (isempty(profile.dataAdjQc))
      profile.dataAdjQc = ones(size(profile.dataAdj))*g_decArgo_qcDef;
   end
   if (isempty(profile.dataAdjError) && ~isempty(doxyAdjErrValues))
      profile.dataAdjError = repmat(double(paramFillValue), size(profile.data, 1), 1);
   end
   
   % store adjusted data
   idNoDef = find(doxyAdjValues ~= paramDoxy.fillValue);
   profile.dataAdj(:, idDoxy) = doxyAdjValues;
   profile.dataAdjQc(idNoDef, idDoxy) = g_decArgo_qcNoQc;
   if (~isempty(doxyAdjErrValues))
      profile.dataAdjError(:, idDoxy) = doxyAdjErrValues;
   end
   
   % output parameters
   o_ok = 1;
   o_profile = profile;
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on CHLA profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_chla(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_rt_adjusted_chla(a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% to store information on CHLA adjustment
global g_decArgo_paramAdjInfo;
g_decArgo_paramAdjInfo.CHLA = [];


% adjust CHLA data
for idProf = 1:length(o_tabProfiles)
   profile = o_tabProfiles(idProf);
   if (any(strcmp({profile.paramList.name}, 'CHLA')))
      
      % create array for adjusted data
      if (isempty(profile.dataAdj))
         if (~isempty(profile.paramNumberWithSubLevels))
            paramFillValue = [];
            for idParam = 1:profile.paramNumberWithSubLevels-1
               paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
               paramFillValue = [paramFillValue paramInfo.fillValue];
            end
            idParam = profile.paramNumberWithSubLevels;
            paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
            paramFillValue = [paramFillValue repmat(paramInfo.fillValue, 1, profile.paramNumberOfSubLevels)];
            for idParam = profile.paramNumberWithSubLevels+1:length(profile.paramList)
               paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
               paramFillValue = [paramFillValue paramInfo.fillValue];
            end
         else
            paramFillValue = [];
            for idParam = 1:length(profile.paramList)
               paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
               paramFillValue = [paramFillValue paramInfo.fillValue];
            end
         end
         profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
         profile.dataAdjQc = ones(size(profile.dataAdj))*g_decArgo_qcDef;
      end
      
      % retrieve and adjust CHLA data
      idChla = find(strcmp({profile.paramList.name}, 'CHLA'));
      if (~isempty(profile.paramNumberWithSubLevels))
         if (idChla > profile.paramNumberWithSubLevels)
            idChla = idChla + profile.paramNumberOfSubLevels - 1;
         end
      end
      chlaData = profile.data(:, idChla);
      paramChla = get_netcdf_param_attributes('CHLA');
      idNoDef = find(chlaData ~= paramChla.fillValue);
      
      chlaDataAdj = chlaData;
      chlaDataAdj(idNoDef) = chlaDataAdj(idNoDef)/2;
      profile.dataAdj(:, idChla) = chlaDataAdj;
      profile.dataAdjQc(idNoDef, idChla) = g_decArgo_qcNoQc;
      o_tabProfiles(idProf) = profile;
      
      % fill structure to store CHLA adjustment information
      if (profile.direction == 'A')
         direction = 2;
      else
         direction = 1;
      end
      g_decArgo_paramAdjInfo.CHLA = [g_decArgo_paramAdjInfo.CHLA;
         profile.outputCycleNumber direction ...
         {'CHLA_ADJUSTED = CHLA/2'} ...
         {''} ...
         {'Real-time CHLA adjustment following recommendations of Roesler et al., 2017 (https://doi.org/10.1002/lom3.10185)'}];
   end
end

return

% ------------------------------------------------------------------------------
% Perform real time adjustment on NITRATE profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_nitrate(a_tabProfiles, a_launchDate)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_launchDate  : float launch date
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/28/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_rt_adjusted_nitrate(a_tabProfiles, a_launchDate)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% to store information on NITRATE adjustment
global g_decArgo_paramAdjInfo;
g_decArgo_paramAdjInfo.NITRATE = [];

% verbose mode flag
VERBOSE_MODE = 0;


% look for NITRATE profiles
noNitrateProfile = 1;
for idProf = 1:length(a_tabProfiles)
   if (any(strcmp({a_tabProfiles(idProf).paramList.name}, 'NITRATE')))
      noNitrateProfile = 0;
      break
   end
end
if (noNitrateProfile)
   return
end

% number of days after launch date to update med_Offset value
TWO_MONTH_IN_DAYS = double(365/6);

% minimum number of offsets expected in the median
NB_OFFSET_MIN = 5;

paramPres = get_netcdf_param_attributes('PRES');
paramNitrate = get_netcdf_param_attributes('NITRATE');

% collect information on profiles
profInfo = [];
nbOffset = 0;
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   if (any(strcmp({profile.paramList.name}, 'NITRATE')))
      
      if (profile.direction == 'A')
         direction = 2;
      else
         direction = 1;
      end
      
      idPres = find(strcmp({profile.paramList.name}, 'PRES'));
      if (~isempty(profile.paramNumberWithSubLevels))
         if (idPres > profile.paramNumberWithSubLevels)
            idPres = idPres + profile.paramNumberOfSubLevels;
         end
      end
      presData = profile.data(:, idPres);
      
      idNitrate = find(strcmp({profile.paramList.name}, 'NITRATE'));
      if (~isempty(profile.paramNumberWithSubLevels))
         if (idNitrate > profile.paramNumberWithSubLevels)
            idNitrate = idNitrate + profile.paramNumberOfSubLevels - 1;
         end
      end
      nitrateData = profile.data(:, idNitrate);
      rmsErrorData = profile.rmsError;
      
      idNoDef = find((presData ~= paramPres.fillValue) & (nitrateData ~= paramNitrate.fillValue));
      if (isempty(idNoDef))
         continue
      end
      [presWoa, idMax] = max(presData(idNoDef) - 100);
      nitratePresWoa = nitrateData(idNoDef(idMax));
      
      getValueFlag = 0;
      rmsError = rmsErrorData(idNoDef(idMax));
      if (rmsError < 0.003)
         if (profile.date ~= g_decArgo_dateDef)
            if (profile.date - a_launchDate <= TWO_MONTH_IN_DAYS)
               getValueFlag = 1;
               nbOffset = nbOffset + 1;
            elseif (nbOffset < NB_OFFSET_MIN)
               getValueFlag = 1;
               nbOffset = nbOffset + 1;
            end
         else
            getValueFlag = -2;
         end
      else
         getValueFlag = -1;
      end
      profInfo = [profInfo; ...
         [idProf profile.outputCycleNumber direction ...
         profile.date profile.locationLon profile.locationLat ...
         presWoa nitratePresWoa paramNitrate.fillValue getValueFlag]];
   end
end

if (~isempty(profInfo))
   
   % retrieve data from World Ocean Atlas 2013
   profInfo = get_WOA_data(profInfo);
   
   if (isempty(profInfo)) % if an error occured during acces to World Ocean Atlas
      return
   end
   
   woaNitrateValues = profInfo(:, 9);
   idNoDef = find(woaNitrateValues ~= paramNitrate.fillValue);
   if (length(idNoDef) >= NB_OFFSET_MIN)
      
      offsetTab = [];
      medOffset = [];
      for idP = 1:size(profInfo, 1)
         profInfoCur = profInfo(idP, :);
         idProf = profInfoCur(1);
         profile = a_tabProfiles(idProf);
         
         if (profInfoCur(10) == -1)
            fprintf('WARNING: Float #%d Cycle #%d%c: RMS error too large - NITRATE data cannot be adjusted\n', ...
               g_decArgo_floatNum, ...
               profile.outputCycleNumber, profile.direction);
            continue
         end
         
         if (profInfoCur(10) == -2)
            fprintf('WARNING: Float #%d Cycle #%d%c: the profile is not dated - NITRATE data cannot be adjusted\n', ...
               g_decArgo_floatNum, ...
               profile.outputCycleNumber, profile.direction);
            continue
         end
         
         % compute med_Offset
         if (profInfoCur(9) ~= paramNitrate.fillValue)
            offset = profInfoCur(8) - profInfoCur(9);
            offsetTab = [offsetTab offset];
         end
         medOffset = median(offsetTab);
         
         % create array for adjusted data
         if (isempty(profile.dataAdj))
            if (~isempty(profile.paramNumberWithSubLevels))
               paramFillValue = [];
               for idParam = 1:profile.paramNumberWithSubLevels-1
                  paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
                  paramFillValue = [paramFillValue paramInfo.fillValue];
               end
               idParam = profile.paramNumberWithSubLevels;
               paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
               paramFillValue = [paramFillValue repmat(paramInfo.fillValue, 1, profile.paramNumberOfSubLevels)];
               for idParam = profile.paramNumberWithSubLevels+1:length(profile.paramList)
                  paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
                  paramFillValue = [paramFillValue paramInfo.fillValue];
               end
            else
               paramFillValue = [];
               for idParam = 1:length(profile.paramList)
                  paramInfo = get_netcdf_param_attributes(profile.paramList(idParam).name);
                  paramFillValue = [paramFillValue paramInfo.fillValue];
               end
            end
            profile.dataAdj = repmat(double(paramFillValue), size(profile.data, 1), 1);
            profile.dataAdjQc = ones(size(profile.dataAdj))*g_decArgo_qcDef;
            profile.dataAdjError = repmat(double(paramFillValue), size(profile.data, 1), 1);
         end
         
         % retrieve and adjust NITRATE data
         idNitrate = find(strcmp({profile.paramList.name}, 'NITRATE'));
         if (~isempty(profile.paramNumberWithSubLevels))
            if (idNitrate > profile.paramNumberWithSubLevels)
               idNitrate = idNitrate + profile.paramNumberOfSubLevels - 1;
            end
         end
         nitrateData = profile.data(:, idNitrate);
         idNoDef = find(nitrateData ~= paramNitrate.fillValue);
         
         nitrateDataAdj = nitrateData;
         nitrateDataAdj(idNoDef) = nitrateDataAdj(idNoDef) - medOffset;
         profile.dataAdj(:, idNitrate) = nitrateDataAdj;
         profile.dataAdjQc(idNoDef, idNitrate) = g_decArgo_qcNoQc;
         profile.dataAdjError(idNoDef, idNitrate) = 5;
         a_tabProfiles(idProf) = profile;
         
         % fill structure to store NITRATE adjustment information
         if (profile.direction == 'A')
            direction = 2;
         else
            direction = 1;
         end
         nitrateEquation = 'NITRATE_ADJUSTED = NITRATE - OFFSET; OFFSET = med[NITRATE(PRES_WOA)-n_an(PRES_WOA) cumulated over two months after the deployment]';
         if (profInfoCur(10) == 1)
            nitrateCoefficient = sprintf('OFFSET=%g, NITRATE(PRES_WOA)=%g, n_an(PRES_WOA)=%g', medOffset, profInfoCur(8:9));
         else
            nitrateCoefficient = sprintf('OFFSET=%g', medOffset);
         end
         nitrateComment = 'OFFSET is the median of NITRATE(PRES_WOA)-n_an(PRES_WOA) cumulated over two months after the deployment; PRES_WOA=Profile pressure-100; n_an(LATITUDE,LONGITUDE) (closest neighbour) from WOA annual file (ftp://ftp.nodc.noaa.gov/pub/data.nodc/woa/WOA13/DATA)';
         g_decArgo_paramAdjInfo.NITRATE = [g_decArgo_paramAdjInfo.NITRATE;
            profile.outputCycleNumber direction ...
            {nitrateEquation} ...
            {nitrateCoefficient} ...
            {nitrateComment}];
         
         if (VERBOSE_MODE)
            fprintf('Float #%d Cycle #%d%c:\n', ...
               g_decArgo_floatNum, ...
               profile.outputCycleNumber, profile.direction);
            fprintf('   * (profile_date - launch_date) = (%s - %s) = %g days\n', ...
               julian_2_gregorian_dec_argo(profile.date), ...
               julian_2_gregorian_dec_argo(a_launchDate), ...
               profile.date - a_launchDate);
            if (profInfoCur(10) == 1)
               fprintf('   * PRES_WOA = %g; float_NITRATE(PRES_WOA) = %g; WOA_NITRATE(PRES_WOA) = %g\n', ...
                  profInfoCur(7:9));
               fprintf('   * OFFSET = float_NITRATE(PRES_WOA) - WOA_NITRATE(PRES_WOA) = %g\n', ...
                  profInfoCur(8)-profInfoCur(9));
            end
            fprintf('   * TAB_OFFSET = [');
            fprintf(' %g', offsetTab);
            fprintf(' ]\n');
            fprintf('   * MED_OFFSET = median(TAB_OFFSET) = %g\n', medOffset);
         end
      end
   else
      fprintf('WARNING: Float #%d: not enough offset to compute med_offset (%d offsets while at least %d are expected) - NITRATE data cannot be adjusted\n', ...
         g_decArgo_floatNum, ...
         length(idNoDef), NB_OFFSET_MIN);
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return
