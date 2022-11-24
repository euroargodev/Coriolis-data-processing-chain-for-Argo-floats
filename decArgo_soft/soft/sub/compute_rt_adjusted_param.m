% ------------------------------------------------------------------------------
% Perform real time adjustment on parameter profile data.
%
% SYNTAX :
%  [o_tabProfiles] = compute_rt_adjusted_param(a_tabProfiles, a_launchDate)
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
function [o_tabProfiles] = compute_rt_adjusted_param(a_tabProfiles, a_launchDate)

% output parameters initialization
o_tabProfiles = a_tabProfiles;


% perform CHLA RT adjustment
[o_tabProfiles] = compute_rt_adjusted_chla(o_tabProfiles);


% perform NITRATE RT adjustment
[o_tabProfiles] = compute_rt_adjusted_nitrate(o_tabProfiles, a_launchDate);

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
paramChla = get_netcdf_param_attributes('CHLA');
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
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
      idNoDef = find(chlaData ~= paramChla.fillValue);
      
      chlaDataAdj = chlaData;
      chlaDataAdj(idNoDef) = chlaDataAdj(idNoDef)/2;
      profile.dataAdj(:, idChla) = chlaDataAdj;
      profile.dataAdjQc(idNoDef, idChla) = g_decArgo_qcNoQc;
      a_tabProfiles(idProf) = profile;
      
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

% update output parameters
o_tabProfiles = a_tabProfiles;

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


% number of days after launch date to update med_Offset value
TWO_MONTH_IN_DAYS = double(365/6);

paramPres = get_netcdf_param_attributes('PRES');
paramNitrate = get_netcdf_param_attributes('NITRATE');

% collect information on profiles
profInfo = [];
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
      
      idNoDef = find((presData ~= paramPres.fillValue) & (nitrateData ~= paramNitrate.fillValue));
      if (isempty(idNoDef))
         continue
      end
      [presWoa, idMax] = max(presData(idNoDef) - 100);
      nitratePresWoa = nitrateData(idNoDef(idMax));
      
      getValueFlag = 0;
      if (profile.date ~= g_decArgo_dateDef)
         if (profile.date - a_launchDate <= TWO_MONTH_IN_DAYS)
            getValueFlag = 1;
         end
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
   
   if (isempty(profInfo))
      return
   end
   
   offsetTab = [];
   medOffset = [];
   for idP = 1:size(profInfo, 1)
      profInfoCur = profInfo(idP, :);
      idProf = profInfoCur(1);
      profile = a_tabProfiles(idProf);
            
      if (profile.date ~= g_decArgo_dateDef)
         
         % compute med_Offset
         if (profile.date - a_launchDate <= TWO_MONTH_IN_DAYS)
            if (profInfoCur(9) ~= paramNitrate.fillValue)
               offset = profInfoCur(8) - profInfoCur(9);
               offsetTab = [offsetTab offset];
            end
            medOffset = median(offsetTab);
         end
         
         if (isempty(offsetTab))
            fprintf('WARNING: Float #%d Cycle #%d%c: no offset to compute med_offset => NITRATE data cannot be adjusted\n', ...
               g_decArgo_floatNum, ...
               profile.outputCycleNumber, profile.direction);
            continue
         end
         
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
         
      else
         fprintf('WARNING: Float #%d Cycle #%d%c: the profile is not dated => NITRATE data cannot be adjusted\n', ...
            g_decArgo_floatNum, ...
            profile.outputCycleNumber, profile.direction);
      end
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return
