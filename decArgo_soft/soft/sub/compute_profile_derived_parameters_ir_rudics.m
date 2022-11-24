% ------------------------------------------------------------------------------
% Compute derived parameters and add them in the profile structures.
%
% SYNTAX :
%  [o_tabProfiles] = compute_profile_derived_parameters_ir_rudics(a_tabProfiles, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_profile_derived_parameters_ir_rudics(a_tabProfiles, a_decoderId)

% output parameters initialization
o_tabProfiles = [];

% current float WMO number
global g_decArgo_floatNum;


% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   profInfo = [profInfo;
      idProf profile.sensorNumber profile.derived profile.cycleNumber profile.profileNumber profile.phaseNumber];
end

% compute derived parameters for some sensors
if (~isempty(profInfo))
   
   % compute OPTODE derived parameters
   idSensor1 = find((profInfo(:, 2) == 1) & (profInfo(:, 3) == 0));
   for idP = 1:length(idSensor1)
      profOptode = a_tabProfiles(profInfo(idSensor1(idP), 1));
      
      % look for the associated CTD profile
      profCtd = [];
      idF = find((profInfo(:, 2) == 0) & ...
         (profInfo(:, 4) == profOptode.cycleNumber) & ...
         (profInfo(:, 5) == profOptode.profileNumber) & ...
         (profInfo(:, 6) == profOptode.phaseNumber));
      if (length(idF) == 1)
         profCtd = a_tabProfiles(profInfo(idF, 1));
      else
         if (isempty(idF))
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute DOXY parameter for ''%c'' profile of OPTODE sensor => DOXY data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profOptode.cycleNumber, ...
               profOptode.profileNumber, ...
               profOptode.direction);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute DOXY parameter for ''%c'' profile of OPTODE sensor => DOXY data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profOptode.cycleNumber, ...
               profOptode.profileNumber, ...
               length(idF), ...
               profOptode.direction);
         end
      end
      a_tabProfiles(profInfo(idSensor1(idP), 1)) = compute_profile_derived_parameters_for_OPTODE( ...
         profOptode, profCtd, a_decoderId);
   end
   
   % compute OCR derived parameters
   idSensor2 = find((profInfo(:, 2) == 2) & (profInfo(:, 3) == 0));
   for idP = 1:length(idSensor2)
      a_tabProfiles(profInfo(idSensor2(idP), 1)) = compute_profile_derived_parameters_for_OCR(a_tabProfiles(profInfo(idSensor2(idP), 1)));
   end
   
   % compute ECO3 derived parameters
   % V1 START
   %       idSensor3 = find((profInfo(:, 2) == 3) & (profInfo(:, 3) == 0));
   %       for idP = 1:length(idSensor3)
   %          a_tabProfiles(profInfo(idSensor3(idP), 1)) = compute_profile_derived_parameters_for_ECO3_V1(a_tabProfiles(profInfo(idSensor3(idP), 1)));
   %       end
   % V1 END
   idSensor3 = find((profInfo(:, 2) == 3) & (profInfo(:, 3) == 0));
   for idP = 1:length(idSensor3)
      profEco3 = a_tabProfiles(profInfo(idSensor3(idP), 1));
      
      % look for the associated CTD profile
      profCtd = [];
      idF = find((profInfo(:, 2) == 0) & ...
         (profInfo(:, 4) == profEco3.cycleNumber) & ...
         (profInfo(:, 5) == profEco3.profileNumber) & ...
         (profInfo(:, 6) == profEco3.phaseNumber));
      if (length(idF) == 1)
         profCtd = a_tabProfiles(profInfo(idF, 1));
      else
         if (isempty(idF))
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute BBP parameter for ''%c'' profile of ECO3 sensor => BBP data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profEco3.cycleNumber, ...
               profEco3.profileNumber, ...
               profEco3.direction);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute BBP parameter for ''%c'' profile of ECO3 sensor => BBP data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profEco3.cycleNumber, ...
               profEco3.profileNumber, ...
               length(idF), ...
               profEco3.direction);
         end
      end
      a_tabProfiles(profInfo(idSensor3(idP), 1)) = compute_profile_derived_parameters_for_ECO3( ...
         profEco3, profCtd);
   end
   
   % compute SUNA derived parameters
   idSensor6 = find((profInfo(:, 2) == 6) & (profInfo(:, 3) == 0));
   for idP = 1:length(idSensor6)
      profCtd = [];
      profSuna = a_tabProfiles(profInfo(idSensor6(idP), 1));
      % the CTD PTS values are provided with the data when in "APF frame" mode
      % if we are not in "APF frame" mode, we need the associated CTD profile
      % (for better reliability, we prefer to check the "APF frame" mode from
      % the received data than from the SUNA configuration)
      paramNameList = {profSuna.paramList.name};
      if (isempty(find(strcmp('TEMP', paramNameList) == 1, 1)))
         % look for the associated CTD profile
         idF = find((profInfo(:, 2) == 0) & ...
            (profInfo(:, 4) == profSuna.cycleNumber) & ...
            (profInfo(:, 5) == profSuna.profileNumber) & ...
            (profInfo(:, 6) == profSuna.phaseNumber));
         if (length(idF) == 1)
            profCtd = a_tabProfiles(profInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute NITRATE parameter for ''%c'' profile of SUNA sensor => NITRATE data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profSuna.cycleNumber, ...
                  profSuna.profileNumber, ...
                  profSuna.direction);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute NITRATE parameter for ''%c'' profile of SUNA sensor => NITRATE data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profSuna.cycleNumber, ...
                  profSuna.profileNumber, ...
                  length(idF), ...
                  profSuna.direction);
            end
         end
      end
      a_tabProfiles(profInfo(idSensor6(idP), 1)) = compute_profile_derived_parameters_for_SUNA( ...
         profSuna, profCtd);
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return;

% ------------------------------------------------------------------------------
% Compute derived parameters for the OCR sensor.
%
% SYNTAX :
%  [o_profOcr] = compute_profile_derived_parameters_for_OCR(a_profOcr)
%
% INPUT PARAMETERS :
%   a_profOcr : input OCR profile structure
%
% OUTPUT PARAMETERS :
%   o_profOcr : output OCR profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profOcr] = compute_profile_derived_parameters_for_OCR(a_profOcr)

% output parameters initialization
o_profOcr = [];

% global default values
global g_decArgo_qcDef;


% list of parameters of the profile
paramNameList = {a_profOcr.paramList.name};

% compute DOWN_IRRADIANCE380 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE380'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE380'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr380 = compute_DOWN_IRRADIANCE380_105_to_109( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profOcr.data(:, end+1) = downIrr380;
      if (isempty(a_profOcr.dataQc))
         a_profOcr.dataQc = ones(size(a_profOcr.data, 1), size(a_profOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downIrr380Qc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr380Qc(find(downIrr380 ~= derivedParam.fillValue)) = 0;
      a_profOcr.dataQc(:, end+1) = downIrr380Qc;
      
      a_profOcr.paramList = [a_profOcr.paramList derivedParam];
   end
end

% compute DOWN_IRRADIANCE412 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE412'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE412'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr412 = compute_DOWN_IRRADIANCE412_105_to_109( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profOcr.data(:, end+1) = downIrr412;
      if (isempty(a_profOcr.dataQc))
         a_profOcr.dataQc = ones(size(a_profOcr.data, 1), size(a_profOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downIrr412Qc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr412Qc(find(downIrr412 ~= derivedParam.fillValue)) = 0;
      a_profOcr.dataQc(:, end+1) = downIrr412Qc;
      
      a_profOcr.paramList = [a_profOcr.paramList derivedParam];
   end
end

% compute DOWN_IRRADIANCE490 data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_IRRADIANCE490'} ...
   ];
derivedParamList = [ ...
   {'DOWN_IRRADIANCE490'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downIrr490 = compute_DOWN_IRRADIANCE490_105_to_109( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profOcr.data(:, end+1) = downIrr490;
      if (isempty(a_profOcr.dataQc))
         a_profOcr.dataQc = ones(size(a_profOcr.data, 1), size(a_profOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downIrr490Qc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr490Qc(find(downIrr490 ~= derivedParam.fillValue)) = 0;
      a_profOcr.dataQc(:, end+1) = downIrr490Qc;
      
      a_profOcr.paramList = [a_profOcr.paramList derivedParam];
   end
end

% compute DOWNWELLING_PAR data and add them in the profile structure
paramToDeriveList = [ ...
   {'RAW_DOWNWELLING_PAR'} ...
   ];
derivedParamList = [ ...
   {'DOWNWELLING_PAR'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      downPar = compute_DOWNWELLING_PAR_105_to_109( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profOcr.data(:, end+1) = downPar;
      if (isempty(a_profOcr.dataQc))
         a_profOcr.dataQc = ones(size(a_profOcr.data, 1), size(a_profOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downParQc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downParQc(find(downPar ~= derivedParam.fillValue)) = 0;
      a_profOcr.dataQc(:, end+1) = downParQc;
      
      a_profOcr.paramList = [a_profOcr.paramList derivedParam];
   end
end

% update output parameters
a_profOcr.derived = 1;
o_profOcr = a_profOcr;

return;

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO3 sensor.
%
% SYNTAX :
%  [o_profEco3] = compute_profile_derived_parameters_for_ECO3( ...
%    a_profEco3, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profEco3   : input ECO3 profile structure
%   a_profCtd    : input CTD profile structure
%
% OUTPUT PARAMETERS :
%   o_profEco3 : output ECO3 profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/08/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profEco3] = compute_profile_derived_parameters_for_ECO3( ...
   a_profEco3, a_profCtd)

% output parameters initialization
o_profEco3 = [];

% global default values
global g_decArgo_qcDef;


% list of parameters of the profile
paramNameList = {a_profEco3.paramList.name};

% compute CHLA data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_CHLA'} ...
   ];
derivedParamList = [ ...
   {'CHLA'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      chla = compute_CHLA_105_to_109( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = chla;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = 0;
      a_profEco3.dataQc(:, end+1) = chlaQc;
      
      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

if (isempty(a_profCtd))
   
   % we have not been able to retrieve the associated CTD profile
   paramToDeriveList = [ ...
      {'BETA_BACKSCATTERING700'} ...
      {'BETA_BACKSCATTERING532'} ...
      ];
   derivedParamList = [ ...
      {'BBP700'} ...
      {'BBP532'} ...
      ];
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_profEco3.dataQc))
            a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profEco3.paramList = [a_profEco3.paramList derivedParam];
      end
   end
   
else
   
   % get the CTD profile data
   paramNameListCtd = {a_profCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);
   
   % compute BBP700 data and add them in the profile structure
   paramToDeriveList = [ ...
      {'BETA_BACKSCATTERING700'} ...
      ];
   derivedParamList = [ ...
      {'BBP700'} ...
      ];
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         
         % compute BBP700 values
         bbp700 = compute_profile_BBP( ...
            a_profEco3.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_profEco3.data(:, 1), ...
            700, ...
            ctdMeasData, ...
            a_profEco3);
         
         if (~isempty(bbp700))
            a_profEco3.data(:, end+1) = bbp700;
            if (isempty(a_profEco3.dataQc))
               a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp700Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = 0;
            a_profEco3.dataQc(:, end+1) = bbp700Qc;
         else
            a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_profEco3.dataQc))
               a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_profEco3.paramList = [a_profEco3.paramList derivedParam];
      end
   end
   
   % compute BBP532 data and add them in the profile structure
   paramToDeriveList = [ ...
      {'BETA_BACKSCATTERING532'} ...
      ];
   derivedParamList = [ ...
      {'BBP532'} ...
      ];
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         
         % compute BBP532 values
         bbp532 = compute_profile_BBP( ...
            a_profEco3.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_profEco3.data(:, 1), ...
            532, ...
            ctdMeasData, ...
            a_profEco3);
         
         if (~isempty(bbp532))
            a_profEco3.data(:, end+1) = bbp532;
            if (isempty(a_profEco3.dataQc))
               a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp532Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = 0;
            a_profEco3.dataQc(:, end+1) = bbp532Qc;
         else
            a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_profEco3.dataQc))
               a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_profEco3.paramList = [a_profEco3.paramList derivedParam];
      end
   end
end

% compute CDOM data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_CDOM'} ...
   ];
derivedParamList = [ ...
   {'CDOM'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      cdom = compute_CDOM_105_to_107( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = cdom;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      cdomQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = 0;
      a_profEco3.dataQc(:, end+1) = cdomQc;
      
      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

% update output parameters
a_profEco3.derived = 1;
o_profEco3 = a_profEco3;

return;

% ------------------------------------------------------------------------------
% Compute BBP from the data provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_BBP] = compute_profile_BBP( ...
%    a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fill_value, ...
%    a_BBP_fill_value, ...
%    a_BBP_pres, ...
%    a_lambda, ...
%    a_ctdData, ...
%    a_profEco3)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING            : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fill_value : fill value for input BETA_BACKSCATTERING
%                                      data
%   a_BBP_fill_value                 : fill value for output BBP data
%   a_BBP_pres                       : pressure levels of BBP data
%   a_lambda                         : wavelength of the ECO3
%   a_ctdData                        : ascociated CTD (P, T, S) data
%   a_profEco3                       : input ECO3 profile structure
%
% OUTPUT PARAMETERS :
%   o_BBP : output BBP data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/08/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_BBP] = compute_profile_BBP( ...
   a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fill_value, ...
   a_BBP_fill_value, ...
   a_BBP_pres, ...
   a_lambda, ...
   a_ctdData, ...
   a_profEco3)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fill_value;


paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
idNoDef = find((a_ctdData(:, 1) ~= paramPres.fillValue) & ...
   (a_ctdData(:, 2) ~= paramTemp.fillValue) & ...
   (a_ctdData(:, 3) ~= paramPsal.fillValue));
ctdDataNoDef = a_ctdData(idNoDef, :);
if (~isempty(ctdDataNoDef))
   
   % interpolate and extrapolate the CTD data at the pressures of the ECO3
   % measurements
   ctdIntData = compute_interpolated_CTD_measurements(ctdDataNoDef, a_BBP_pres, 1);
   if (~isempty(ctdIntData))
      
      idNoNan = find(~(isnan(ctdIntData(:, 2)) | isnan(ctdIntData(:, 3))));
      
      if (a_lambda == 700)
         o_BBP(idNoNan) = compute_BBP700_105_to_109( ...
            a_BETA_BACKSCATTERING(idNoNan), ...
            a_BETA_BACKSCATTERING_fill_value, ...
            a_BBP_fill_value, ...
            ctdIntData(idNoNan, :), ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue);
      elseif (a_lambda == 532)
         o_BBP(idNoNan) = compute_BBP532_108_109( ...
            a_BETA_BACKSCATTERING(idNoNan), ...
            a_BETA_BACKSCATTERING_fill_value, ...
            a_BBP_fill_value, ...
            ctdIntData(idNoNan, :), ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue);
      else
         fprintf('WARNING: Float #%d Cycle #%d Profile #%d: BBP processing not implemented yet for lambda = %g => BBP data set to fill value in ''%c'' profile of ECO3 sensor\n', ...
            g_decArgo_floatNum, ...
            a_profEco3.cycleNumber, ...
            a_profEco3.profileNumber, ...
            a_lambda, ...
            a_profEco3.direction);
         
         % update output parameters
         o_BBP = [];
      end
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute BBP parameter for ''%c'' profile of ECO3 sensor => BBP data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profEco3.cycleNumber, ...
         a_profEco3.profileNumber, ...
         a_profEco3.direction);
      
      % update output parameters
      o_BBP = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute BBP parameter for ''%c'' profile of ECO3 sensor => BBP data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profEco3.cycleNumber, ...
      a_profEco3.profileNumber, ...
      a_profEco3.direction);
   
   % update output parameters
   o_BBP = [];
   
end

return;

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO3 sensor.
%
% SYNTAX :
%  [o_profEco3] = compute_profile_derived_parameters_for_ECO3(a_profEco3)
%
% INPUT PARAMETERS :
%   a_profEco3   : input ECO3 profile structure
%
% OUTPUT PARAMETERS :
%   o_profEco3   : output ECO3 profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profEco3] = compute_profile_derived_parameters_for_ECO3_V1(a_profEco3)

% output parameters initialization
o_profEco3 = [];

% global default values
global g_decArgo_qcDef;


% list of parameters of the profile
paramNameList = {a_profEco3.paramList.name};

% compute CHLA data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_CHLA'} ...
   ];
derivedParamList = [ ...
   {'CHLA'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      chla = compute_CHLA_105_to_109( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = chla;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = 0;
      a_profEco3.dataQc(:, end+1) = chlaQc;
      
      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

% compute BBP700 data and add them in the profile structure
paramToDeriveList = [ ...
   {'BETA_BACKSCATTERING700'} ...
   ];
derivedParamList = [ ...
   {'BBP700'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      bbp700 = compute_BBP700_105_to_109_V1( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = bbp700;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      bbp700Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = 0;
      a_profEco3.dataQc(:, end+1) = bbp700Qc;
      
      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

% compute BBP532 data and add them in the profile structure
paramToDeriveList = [ ...
   {'BETA_BACKSCATTERING532'} ...
   ];
derivedParamList = [ ...
   {'BBP532'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      bbp532 = compute_BBP532_108_109_V1( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = bbp532;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      bbp532Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = 0;
      a_profEco3.dataQc(:, end+1) = bbp532Qc;
      
      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

% compute CDOM data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_CDOM'} ...
   ];
derivedParamList = [ ...
   {'CDOM'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      cdom = compute_CDOM_105_to_107( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = cdom;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), size(a_profEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      cdomQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = 0;
      a_profEco3.dataQc(:, end+1) = cdomQc;

      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

% update output parameters
a_profEco3.derived = 1;
o_profEco3 = a_profEco3;

return;

% ------------------------------------------------------------------------------
% Compute derived parameters for the SUNA sensor.
%
% SYNTAX :
%  [o_profSuna] = compute_profile_derived_parameters_for_SUNA(a_profSuna, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profSuna : input SUNA profile structure
%   a_profCtd  : input CTD profile structure
%
% OUTPUT PARAMETERS :
%   o_profSuna : output SUNA profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profSuna] = compute_profile_derived_parameters_for_SUNA(a_profSuna, a_profCtd)

% output parameters initialization
o_profSuna = [];

% global default values
global g_decArgo_qcDef;


% list of parameters of the profile
paramNameList = {a_profSuna.paramList.name};

% retrieve measured CTD data
if (isempty(a_profCtd))
   presId = find(strcmp('PRES', paramNameList) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameList) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameList) == 1, 1);
   ctdMeasData = a_profSuna.data(:, [presId tempId psalId]);
else
   paramNameListCtd = {a_profCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);
end

% compute NITRATE data and add them in the profile structure
paramToDeriveList = [ ...
   {'MOLAR_NITRATE'} ...
   ];
derivedParamList = [ ...
   {'NITRATE'} ...
   ];
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      nitrate = compute_profile_NITRATE_105_to_109( ...
         a_profSuna.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue, ...
         a_profSuna.data(:, 1), ctdMeasData, ...
         paramPres.fillValue, ...
         paramTemp.fillValue, ...
         paramPsal.fillValue);
      
      a_profSuna.data(:, end+1) = nitrate;
      if (isempty(a_profSuna.dataQc))
         a_profSuna.dataQc = ones(size(a_profSuna.data, 1), size(a_profSuna.data, 2)-1)*g_decArgo_qcDef;
      end
      nitrateQc = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
      nitrateQc(find(nitrate ~= derivedParam.fillValue)) = 0;
      a_profSuna.dataQc(:, end+1) = nitrateQc;
      
      a_profSuna.paramList = [a_profSuna.paramList derivedParam];
   end
end

% compute NITRATE data and add them in the profile structure
if (0)
   paramToDeriveList = [ ...
      {'UV_INTENSITY_NITRATE'} {'UV_INTENSITY_DARK_NITRATE'} ...
      ];
   derivedParamList = [ ...
      {'NITRATE'} ...
      ];
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramPsal = get_netcdf_param_attributes('PSAL');
   for idP = 1:size(paramToDeriveList, 1)
      idF1 = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
      idF2 = find(strcmp(paramToDeriveList{idP, 2}, paramNameList) == 1, 1);
      if (~isempty(idF1) && ~isempty(idF2))
         paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
         paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idP, 2});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         
         nitrate = compute_profile_NITRATE_BIS_105_to_109( ...
            a_profSuna.data(:, idF1:idF1+a_profSuna.paramNumberOfSubLevels-1), ...
            a_profSuna.data(:, idF2), ...
            paramToDerive1.fillValue, ...
            paramToDerive2.fillValue, ...
            derivedParam.fillValue, ...
            a_profSuna.data(:, 1), ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_profSuna);
         
         a_profSuna.data(:, end+1) = nitrate;
         if (isempty(a_profSuna.dataQc))
            a_profSuna.dataQc = ones(size(a_profSuna.data, 1), size(a_profSuna.data, 2)-1)*g_decArgo_qcDef;
         end
         nitrateQc = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
         nitrateQc(find(nitrate ~= derivedParam.fillValue)) = 0;
         a_profSuna.dataQc(:, end+1) = nitrateQc;
         
         a_profSuna.paramList = [a_profSuna.paramList derivedParam];
      end
   end
end

% update output parameters
a_profSuna.derived = 1;
o_profSuna = a_profSuna;

return;

% ------------------------------------------------------------------------------
% Compute derived parameters for the OPTODE sensor.
%
% SYNTAX :
%  [o_profOptode] = compute_profile_derived_parameters_for_OPTODE( ...
%    a_profOptode, a_profCtd, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profOptode : input OPTODE profile structure
%   a_profCtd    : input CTD profile structure
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profOptode : output OPTODE profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profOptode] = compute_profile_derived_parameters_for_OPTODE( ...
   a_profOptode, a_profCtd, a_decoderId)

% output parameters initialization
o_profOptode = [];

% global default values
global g_decArgo_qcDef;


% list of parameters of the profile
paramNameList = {a_profOptode.paramList.name};

if (isempty(a_profCtd))
   
   % we have not been able to retrieve the associated CTD profile
   derivedParamList = [ ...
      {'DOXY'} ...
      ];
   for idP = 1:length(derivedParamList)
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
      if (~isempty(a_profOptode.dataQc))
         a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
      end
      a_profOptode.paramList = [a_profOptode.paramList derivedParam];
   end
   
else
   
   % get the CTD profile data
   paramNameListCtd = {a_profCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);
   
   % compute DOXY data and add them in the profile structure
   paramToDeriveList = [ ...
      {'C1PHASE_DOXY'} {'C2PHASE_DOXY'} {'TEMP_DOXY'} ...
      ];
   derivedParamList = [ ...
      {'DOXY'} ...
      ];
   for idP = 1:size(paramToDeriveList, 1)
      idF1 = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
      idF2 = find(strcmp(paramToDeriveList{idP, 2}, paramNameList) == 1, 1);
      idF3 = find(strcmp(paramToDeriveList{idP, 3}, paramNameList) == 1, 1);
      if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
         paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
         paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idP, 2});
         paramToDerive3 = get_netcdf_param_attributes(paramToDeriveList{idP, 3});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         
         % compute DOXY values
         doxy = compute_profile_DOXY( ...
            a_profOptode.data(:, idF1), ...
            a_profOptode.data(:, idF2), ...
            a_profOptode.data(:, idF3), ...
            paramToDerive1.fillValue, ...
            paramToDerive2.fillValue, ...
            paramToDerive3.fillValue, ...
            derivedParam.fillValue, ...
            a_profOptode.data(:, 1), ...
            ctdMeasData, ...
            a_profOptode, a_decoderId);
         
         if (~isempty(doxy))
            a_profOptode.data(:, end+1) = doxy;
            if (isempty(a_profOptode.dataQc))
               a_profOptode.dataQc = ones(size(a_profOptode.data, 1), size(a_profOptode.data, 2)-1)*g_decArgo_qcDef;
            end
            doxyQc = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
            doxyQc(find(doxy ~= derivedParam.fillValue)) = 0;
            a_profOptode.dataQc(:, end+1) = doxyQc;
         else
            a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_profOptode.dataQc))
               a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_profOptode.paramList = [a_profOptode.paramList derivedParam];
      end
   end
end

% update output parameters
a_profOptode.derived = 1;
o_profOptode = a_profOptode;

return;

% ------------------------------------------------------------------------------
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_profile_DOXY( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, a_TEMP_DOXY_fill_value, ...
%    a_DOXY_fill_value, ...
%    a_DOXY_pres, a_ctdData, ...
%    a_profOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY            : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY            : input C2PHASE_DOXY data
%   a_TEMP_DOXY               : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fill_value : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fill_value : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fill_value    : fill value for input TEMP_DOXY data
%   a_DOXY_fill_value         : fill value for output DOXY data
%   a_DOXY_pres               : pressure levels of DOXY data
%   a_ctdData                 : ascociated CTD (P, T, S) data
%   a_profOptode              : input OPTODE profile structure
%   a_decoderId               : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_DOXY    : output DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_profile_DOXY( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, a_TEMP_DOXY_fill_value, ...
   a_DOXY_fill_value, ...
   a_DOXY_pres, a_ctdData, ...
   a_profOptode, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fill_value;


paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
idNoDef = find((a_ctdData(:, 1) ~= paramPres.fillValue) & ...
   (a_ctdData(:, 2) ~= paramTemp.fillValue) & ...
   (a_ctdData(:, 3) ~= paramPsal.fillValue));
ctdDataNoDef = a_ctdData(idNoDef, :);
if (~isempty(ctdDataNoDef))
   
   % interpolate and extrapolate the CTD data at the pressures of the OPTODE
   % measurements
   ctdIntData = compute_interpolated_CTD_measurements(ctdDataNoDef, a_DOXY_pres, 1);
   if (~isempty(ctdIntData))
      
      idNoNan = find(~(isnan(ctdIntData(:, 2)) | isnan(ctdIntData(:, 3))));
      
      switch (a_decoderId)
         
         case {106}
            
            % compute DOXY values using the Aanderaa standard calibration method
            o_DOXY(idNoNan) = compute_DOXY_106_301( ...
               a_C1PHASE_DOXY(idNoNan), ...
               a_C2PHASE_DOXY(idNoNan), ...
               a_TEMP_DOXY(idNoNan), ...
               a_C1PHASE_DOXY_fill_value, ...
               a_C2PHASE_DOXY_fill_value, ...
               a_TEMP_DOXY_fill_value, ...
               a_DOXY_fill_value, ...
               ctdIntData(idNoNan, [1 3]), ...
               paramPres.fillValue, ...
               paramPsal.fillValue, ...
               a_profOptode);
            
         case {107, 109}
            
            % compute DOXY values using the Stern-Volmer equation
            o_DOXY(idNoNan) = compute_DOXY_107_109( ...
               a_C1PHASE_DOXY(idNoNan), ...
               a_C2PHASE_DOXY(idNoNan), ...
               a_TEMP_DOXY(idNoNan), ...
               a_C1PHASE_DOXY_fill_value, ...
               a_C2PHASE_DOXY_fill_value, ...
               a_TEMP_DOXY_fill_value, ...
               a_DOXY_fill_value, ...
               ctdIntData(idNoNan, [1 3]), ...
               paramPres.fillValue, ...
               paramPsal.fillValue, ...
               a_profOptode);
            
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
               g_decArgo_floatNum, ...
               a_profOptode.cycleNumber, ...
               a_profOptode.profileNumber, ...
               a_decoderId, ...
               a_profOptode.direction);
            
            % update output parameters
            o_DOXY = [];
            
      end
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor => DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profOptode.cycleNumber, ...
         a_profOptode.profileNumber, ...
         a_profOptode.direction);
      
      % update output parameters
      o_DOXY = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber, ...
      a_profOptode.direction);
   
   % update output parameters
   o_DOXY = [];
   
end

% return;

% ------------------------------------------------------------------------------
% START - IMPLEMENTATION OF THE PREVIOUS SPECIFICATIONS - START
% ------------------------------------------------------------------------------
% Compute derived parameters for the OPTODE sensor.
%
% SYNTAX :
%  [o_profOptode] = compute_profile_derived_parameters_for_OPTODE( ...
%    a_profOptode, a_profCtd, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profOptode : input OPTODE profile structure
%   a_profCtd    : input CTD profile structure
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profOptode : output OPTODE profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
% function [o_profOptode] = compute_profile_derived_parameters_for_OPTODE( ...
%    a_profOptode, a_profCtd, a_decoderId)
%
% % output parameters initialization
% o_profOptode = [];
%
% % global default values
% global g_decArgo_qcDef;
%
%
% if (isempty(a_profCtd))
%
%    % we have not been able to retrieve the associated CTD profile
%    derivedParamList = [ ...
%       {'DOXY'} ...
%       {'DOXY_STD'} ...
%       {'DOXY_MED'} ...
%       ];
%    for idP = 1:length(derivedParamList)
%       derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
%       if (isempty(a_profOptode.dataQc))
%          a_profOptode.dataQc = ones(size(a_profOptode.data, 1), size(a_profOptode.data, 2))*g_decArgo_qcDef;
%       end
%       a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
%       a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
%       a_profOptode.paramList = [a_profOptode.paramList derivedParam];
%    end
%
% else
%
%    % get the CTD profile data
%    paramNameList = {a_profCtd.paramList.name};
%    presId = find(strcmp('PRES', paramNameList) == 1, 1);
%    tempId = find(strcmp('TEMP', paramNameList) == 1, 1);
%    psalId = find(strcmp('PSAL', paramNameList) == 1, 1);
%    ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);
%
%    % retieve the treatment types and the corresponding thresholds from
%    % the configuration
%    [treatTypesOptode, treatThickOptode, zoneThresholdOptode] = ...
%       config_get_treatment_types_ir_rudics(a_profOptode.sensorNumber, ...
%       a_profOptode.cycleNumber, a_profOptode.profileNumber);
%    [treatTypesCtd, treatThickCtd, zoneThresholdCtd] = ...
%       config_get_treatment_types_ir_rudics(a_profCtd.sensorNumber, ...
%       a_profCtd.cycleNumber, a_profCtd.profileNumber);
%
%    % compute DOXY data and add them in the profile structure
%    paramToDeriveList = [ ...
%       {'C1PHASE_DOXY'} {'C2PHASE_DOXY'}; ...
%       {'C1PHASE_DOXY_STD'} {'C2PHASE_DOXY_STD'}; ...
%       {'C1PHASE_DOXY_MED'} {'C2PHASE_DOXY_MED'}; ...
%       ];
%    derivedParamList = [ ...
%       {'DOXY'} ...
%       {'DOXY_STD'} ...
%       {'DOXY_MED'} ...
%       ];
%    paramNameList = {a_profOptode.paramList.name};
%    for idP = 1:size(paramToDeriveList, 1)
%       idF1 = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
%       idF2 = find(strcmp(paramToDeriveList{idP, 2}, paramNameList) == 1, 1);
%       if (~isempty(idF1) && ~isempty(idF1))
%          paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
%          paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idP, 2});
%          derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
%
%          % compute DOXY and DOXY_QC values
%          [doxy, doxyQc] = compute_profile_DOXY_and_DOXY_QC( ...
%             a_profOptode.data(:, idF1), ...
%             a_profOptode.data(:, idF2), ...
%             paramToDerive1.fillValue, ...
%             paramToDerive2.fillValue, ...
%             derivedParam.fillValue, ...
%             a_profOptode.data(:, 1), ...
%             ctdMeasData, ...
%             treatTypesOptode, treatThickOptode, zoneThresholdOptode, ...
%             treatTypesCtd, treatThickCtd, zoneThresholdCtd, ...
%             a_profOptode, a_decoderId);
%
%          if (~isempty(doxy))
%             if (isempty(a_profOptode.dataQc))
%                a_profOptode.dataQc = ones(size(a_profOptode.data, 1), size(a_profOptode.data, 2))*g_decArgo_qcDef;
%             end
%             a_profOptode.data(:, end+1) = doxy;
%             a_profOptode.dataQc(:, end+1) = doxyQc;
%          else
%             if (isempty(a_profOptode.dataQc))
%                a_profOptode.dataQc = ones(size(a_profOptode.data, 1), size(a_profOptode.data, 2))*g_decArgo_qcDef;
%             end
%             a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
%             a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
%          end
%          a_profOptode.paramList = [a_profOptode.paramList derivedParam];
%       end
%    end
% end
%
% % update output parameters
% a_profOptode.derived = 1;
% o_profOptode = a_profOptode;
%
% return;
%
% ------------------------------------------------------------------------------
% Compute DOXY and DOXY_QC from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY, o_DOXY_QC] = compute_profile_DOXY_and_DOXY_QC(a_C1PHASE_DOXY, a_C2PHASE_DOXY, ...
%    a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, ...
%    a_DOXY_fill_value, ...
%    a_C1C2PHASE_DOXY_pres, a_ctdData, ...
%    a_treatTypesOptode, a_treatThickOptode, a_zoneThresholdOptode, ...
%    a_treatTypesCtd, a_treatThickCtd, a_zoneThresholdCtd, ...
%    a_profOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY            : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY            : input C2PHASE_DOXY data
%   a_C1PHASE_DOXY_fill_value : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fill_value : fill value for input C2PHASE_DOXY data
%   a_DOXY_fill_value         : fill value for output DOXY data
%   a_C1C2PHASE_DOXY_pres     : pressure levels of input C1PHASE_DOXY and
%                               C2PHASE_DOXY data
%   a_ctdData                 : ascociated CTD (P, T, S) data
%   a_treatTypesOptode        : OPTODE profile treatment types
%   a_treatThickOptode        : OPTODE profile treatment slice thicknesses
%   a_zoneThresholdOptode     : OPTODE profile depth zone thresholds
%   a_treatTypesCtd           : CTD profile treatment types
%   a_treatThickCtd           : CTD profile treatment slice thicknesses
%   a_zoneThresholdCtd        : CTD profile depth zone thresholds
%   a_profOptode              : input OPTODE profile structure
%   a_decoderId               : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_DOXY    : output DOXY data
%   o_DOXY_QC : output DOXY QC data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
% function [o_DOXY, o_DOXY_QC] = compute_profile_DOXY_and_DOXY_QC(a_C1PHASE_DOXY, a_C2PHASE_DOXY, ...
%    a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, ...
%    a_DOXY_fill_value, ...
%    a_C1C2PHASE_DOXY_pres, a_ctdData, ...
%    a_treatTypesOptode, a_treatThickOptode, a_zoneThresholdOptode, ...
%    a_treatTypesCtd, a_treatThickCtd, a_zoneThresholdCtd, ...
%    a_profOptode, a_decoderId)
%
% % global default values
% global g_decArgo_qcDef;
%
% % current float WMO number
% global g_decArgo_floatNum;
%
% % output parameters initialization
% o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fill_value;
% o_DOXY_QC = ones(length(a_C1PHASE_DOXY), 1)*g_decArgo_qcDef;
%
% % maximum interval to duplicate CTD values on each ends of the profile (in dbar)
% MAX_INTERVAL_FOR_CTD_DUPLICATION_dbar = 10;
%
% % threshold for CTD interpolation (in dbar)
% THRESHOLD_FOR_CTD_INTERPOLATION_dbar = 50;
%
% % specification #0:
% % the CTD profile is used regardless of the PSAL pumped or unpumped data
%
% % specification #1:
% % When the CTD is switched on after (resp. switched off before) the OPTODE,
% % the first (resp. last) T and S values are duplicated over a 10 dbar interval.
% % The corresponding DOXY values are computed and their QC set to 3, before
% % (resp. after) this 10 dbar interval DOXY values are not computed
%
% paramPres = get_netcdf_param_attributes('PRES');
% paramTemp = get_netcdf_param_attributes('TEMP');
% paramPsal = get_netcdf_param_attributes('PSAL');
% idNoDef = find((a_ctdData(:, 1) ~= paramPres.fillValue) & ...
%    (a_ctdData(:, 2) ~= paramTemp.fillValue) & ...
%    (a_ctdData(:, 3) ~= paramPsal.fillValue));
% ctdDataNoDef = a_ctdData(idNoDef, :);
% ctdPresNoDef = ctdDataNoDef(:, 1);
% if (~isempty(ctdPresNoDef))
%
%    doxyPres = a_C1C2PHASE_DOXY_pres;
%    idNoDef = find(doxyPres ~= paramPres.fillValue);
%
%    if (a_profOptode.direction == 'A')
%
%       idBefore = find(doxyPres(idNoDef) > ctdPresNoDef(1));
%       if (~isempty(idBefore))
%
%          for idP = 1:length(idBefore)
%             if (doxyPres(idNoDef(idBefore(idP))) - ctdPresNoDef(1) <= MAX_INTERVAL_FOR_CTD_DUPLICATION_dbar)
%                ctdDataNoDef = [doxyPres(idNoDef(idBefore(idP))) ctdDataNoDef(1, 2) ctdDataNoDef(1, 3);
%                   ctdDataNoDef];
%                o_DOXY_QC(idNoDef(idBefore(idP))) = 3;
%             end
%          end
%       end
%
%       idAfter = find(doxyPres(idNoDef) < ctdPresNoDef(end));
%       if (~isempty(idAfter))
%
%          for idP = 1:length(idAfter)
%             if (ctdPresNoDef(end) - doxyPres(idNoDef(idAfter(idP))) <= MAX_INTERVAL_FOR_CTD_DUPLICATION_dbar)
%                ctdDataNoDef = [ctdDataNoDef; ...
%                   doxyPres(idNoDef(idAfter(idP))) ctdDataNoDef(end, 2) ctdDataNoDef(end, 3)];
%                o_DOXY_QC(idNoDef(idAfter(idP))) = 3;
%             end
%          end
%       end
%
%       % sort the (possibly updated) CTD profile
%       [~, idSort] = sort(ctdDataNoDef(:, 1), 'descend');
%       ctdDataNoDef = ctdDataNoDef(idSort, :);
%
%    else
%
%       idBefore = find(doxyPres(idNoDef) < ctdPresNoDef(1));
%       if (~isempty(idBefore))
%
%          for idP = 1:length(idBefore)
%             if (ctdPresNoDef(1) - doxyPres(idNoDef(idBefore(idP)))<= MAX_INTERVAL_FOR_CTD_DUPLICATION_dbar)
%                ctdDataNoDef = [doxyPres(idNoDef(idBefore(idP))) ctdDataNoDef(1, 2) ctdDataNoDef(1, 3);
%                   ctdDataNoDef];
%                o_DOXY_QC(idNoDef(idBefore(idP))) = 3;
%             end
%          end
%       end
%
%       idAfter = find(doxyPres(idNoDef) > ctdPresNoDef(end));
%       if (~isempty(idAfter))
%
%          for idP = 1:length(idAfter)
%             if (doxyPres(idNoDef(idAfter(idP))) - ctdPresNoDef(end) <= MAX_INTERVAL_FOR_CTD_DUPLICATION_dbar)
%                ctdDataNoDef = [ctdDataNoDef; ...
%                   doxyPres(idNoDef(idAfter(idP))) ctdDataNoDef(end, 2) ctdDataNoDef(end, 3)];
%                o_DOXY_QC(idNoDef(idAfter(idP))) = 3;
%             end
%          end
%       end
%
%       % sort the (possibly updated) CTD profile
%       [~, idSort] = sort(ctdDataNoDef(:, 1), 'ascend');
%       ctdDataNoDef = ctdDataNoDef(idSort, :);
%
%    end
%
%    % specification #2:
%    % Interpolated CTD T and S measurements are used to compute DOXY at a given P
%    % level.
%    % i.e. at P(DOXY): T(DOXY) (resp. S(DOXY)) is interpolated from T(i) and
%    % T(i+1) (resp. S(i) and S(i+1)) CTD measurements.
%
%    % specification #2a:
%    % When at least one of the CTD measurements used in the interpolation has a
%    % different VSS (only in term of raw vs mean) than the DOXY measurement, the
%    % corresponding DOXY QC is set to 3 if at least one of the means is computed
%    % on a depth interval > 50 dbars
%    % i.e. if DOXY is a raw (resp. mean) data and PTS(i) or PTS(i+1) is a mean
%    % (resp.raw) data, DOXY QC = 3
%    % if max(PTS(i)_mean_depth_interval, PTS(i+1)_mean_depth_interval) > 50 dbars
%    % (resp. P(DOXY)_mean_depth_interval > 50 dbars)
%
%    % specification #2b:
%    % When at least one of the CTD P measurements used in the interpolation is far
%    % ( > 50 dbars) from the DOXY P measurement, the corresponding DOXY QC is set
%    % to 3.
%    % i.e. if max(|P(DOXY)-P(i)|, |P(DOXY)-P(i+1)|) > 50 dbars , DOXY QC = 3.
%
%    % retrieve OPTODE data treatment type
%    treatThickOptode = zeros(length(doxyPres), 1);
%    for idZ = 1:5
%       if (idZ == 5)
%          idF = find((doxyPres ~= paramPres.fillValue) & ...
%             (doxyPres > a_zoneThresholdOptode(idZ-1)));
%       elseif (idZ == 1)
%          idF = find((doxyPres ~= paramPres.fillValue) & ...
%             (doxyPres <= a_zoneThresholdOptode(idZ)));
%       else
%          idF = find((doxyPres ~= paramPres.fillValue) & ...
%             ((doxyPres > a_zoneThresholdOptode(idZ-1)) & ...
%             (doxyPres <= a_zoneThresholdOptode(idZ))));
%       end
%       if ((a_treatTypesOptode(idZ) == 1) || ...
%             (a_treatTypesOptode(idZ) == 7))
%          treatThickOptode(idF) = a_treatThickOptode(idZ);
%       end
%    end
%
%    % retrieve CTD data treatment type
%    treatThickCtd = zeros(size(ctdDataNoDef, 1), 1);
%    ctdPresNoDef = ctdDataNoDef(:, 1);
%    for idZ = 1:5
%       if (idZ == 5)
%          idF = find(ctdPresNoDef > a_zoneThresholdCtd(idZ-1));
%       elseif (idZ == 1)
%          idF = find(ctdPresNoDef <= a_zoneThresholdCtd(idZ));
%       else
%          idF = find(((ctdPresNoDef > a_zoneThresholdCtd(idZ-1)) & ...
%             (ctdPresNoDef <= a_zoneThresholdCtd(idZ))));
%       end
%       if ((a_treatTypesCtd(idZ) == 1) || ...
%             (a_treatTypesCtd(idZ) == 7))
%          treatThickCtd(idF) = a_treatThickCtd(idZ);
%       end
%    end
%
%    for idP = 1:length(o_DOXY_QC)
%       if ((a_C1PHASE_DOXY(idP) == a_C1PHASE_DOXY_fill_value) || ...
%             (a_C2PHASE_DOXY(idP) == a_C2PHASE_DOXY_fill_value) || ...
%             (doxyPres(idP) == paramPres.fillValue) || ...
%             (doxyPres(idP) < min(ctdDataNoDef(:, 1))) || ...
%             (doxyPres(idP) > max(ctdDataNoDef(:, 1))))
%          % the DOXY value cannot be computed => QC = 9 (missing value)
%          o_DOXY_QC(idP) = 9;
%       else
%          if (o_DOXY_QC(idP) == g_decArgo_qcDef)
%             % retrieve the 2 CTD measurements that will be used in the
%             % interpolation
%
%             idF1 = find(doxyPres(idP) <= ctdPresNoDef);
%             idF2 = find(doxyPres(idP) >= ctdPresNoDef);
%             if (a_profOptode.direction == 'A')
%                id1 = idF1(end);
%                id2 = idF2(1);
%             else
%                id1 = idF1(1);
%                id2 = idF2(end);
%             end
%
%             if (((treatThickOptode(idP) == 0) && ...
%                   (max(treatThickCtd(id1), treatThickCtd(id2)) > THRESHOLD_FOR_CTD_INTERPOLATION_dbar)) || ...
%                   ((treatThickOptode(idP) > THRESHOLD_FOR_CTD_INTERPOLATION_dbar) && ...
%                   (min(treatThickCtd(id1), treatThickCtd(id2)) == 0)))
%                % specification #2a
%                o_DOXY_QC(idP) = 3;
%             elseif (max(abs(doxyPres(idP)-ctdPresNoDef(id1)), abs(doxyPres(idP)-ctdPresNoDef(id2))) > THRESHOLD_FOR_CTD_INTERPOLATION_dbar)
%                % specification #2b
%                o_DOXY_QC(idP) = 3;
%             else
%                o_DOXY_QC(idP) = 1;
%             end
%          end
%       end
%    end
%
%    % interpolate the CTD data at the pressures of the OPTODE measurements
%    ctdIntData = compute_interpolated_CTD_measurements(ctdDataNoDef, a_C1C2PHASE_DOXY_pres, 0);
%    if (~isempty(ctdIntData))
%
%       idNoNan = find(~(isnan(ctdIntData(:, 2)) | isnan(ctdIntData(:, 3))));
%
%       switch (a_decoderId)
%
%          case {106}
%
%             % compute DOXY values using the Aanderaa standard calibration method
%             o_DOXY(idNoNan) = compute_DOXY_106_301( ...
%                a_C1PHASE_DOXY(idNoNan), ...
%                a_C2PHASE_DOXY(idNoNan), ...
%                a_C1PHASE_DOXY_fill_value, ...
%                a_C2PHASE_DOXY_fill_value, ...
%                a_DOXY_fill_value, ...
%                ctdIntData(idNoNan, :), ...
%                paramPres.fillValue, ...
%                paramTemp.fillValue, ...
%                paramPsal.fillValue, ...
%                a_profOptode);
%
%          case {107, 109}
%
%             % compute DOXY values using the Stern-Volmer equation
%             o_DOXY(idNoNan) = compute_DOXY_107_109( ...
%                a_C1PHASE_DOXY(idNoNan), ...
%                a_C2PHASE_DOXY(idNoNan), ...
%                a_C1PHASE_DOXY_fill_value, ...
%                a_C2PHASE_DOXY_fill_value, ...
%                a_DOXY_fill_value, ...
%                ctdIntData(idNoNan, :), ...
%                paramPres.fillValue, ...
%                paramTemp.fillValue, ...
%                paramPsal.fillValue, ...
%                a_profOptode);
%
%          otherwise
%             fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
%                g_decArgo_floatNum, ...
%                a_profOptode.cycleNumber, ...
%                a_profOptode.profileNumber, ...
%                a_decoderId, ...
%                a_profOptode.direction);
%
%             % update output parameters
%             o_DOXY = [];
%
%       end
%
%    else
%
%       fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor => DOXY data set to fill value\n', ...
%          g_decArgo_floatNum, ...
%          a_profOptode.cycleNumber, ...
%          a_profOptode.profileNumber, ...
%          a_profOptode.direction);
%
%       % update output parameters
%       o_DOXY = [];
%
%    end
%
% else
%
%    fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor => DOXY data set to fill value\n', ...
%       g_decArgo_floatNum, ...
%       a_profOptode.cycleNumber, ...
%       a_profOptode.profileNumber, ...
%       a_profOptode.direction);
%
%    % update output parameters
%    o_DOXY = [];
%
% end
%
% return;
% ------------------------------------------------------------------------------
% START - IMPLEMENTATION OF THE PREVIOUS SPECIFICATIONS - START
% ------------------------------------------------------------------------------
