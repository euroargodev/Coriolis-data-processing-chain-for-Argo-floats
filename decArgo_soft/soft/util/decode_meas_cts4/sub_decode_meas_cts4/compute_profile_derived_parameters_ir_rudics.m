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

% sensor list
global g_decArgo_sensorMountedOnFloat;

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts4;
global g_decArgo_decoderIdListNkeCts5Usea;


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
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profOptode.cycleNumber, ...
               profOptode.profileNumber, ...
               profOptode.direction);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
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
   
   if (ismember('ECO2', g_decArgo_sensorMountedOnFloat))
      
      % compute ECO2 derived parameters
      idSensor3 = find((profInfo(:, 2) == 3) & (profInfo(:, 3) == 0));
      for idP = 1:length(idSensor3)
         profEco2 = a_tabProfiles(profInfo(idSensor3(idP), 1));
         
         % look for the associated CTD profile
         profCtd = [];
         idF = find((profInfo(:, 2) == 0) & ...
            (profInfo(:, 4) == profEco2.cycleNumber) & ...
            (profInfo(:, 5) == profEco2.profileNumber) & ...
            (profInfo(:, 6) == profEco2.phaseNumber));
         if (length(idF) == 1)
            profCtd = a_tabProfiles(profInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute BBP parameter for ''%c'' profile of ECO2 sensor - BBP data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco2.cycleNumber, ...
                  profEco2.profileNumber, ...
                  profEco2.direction);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute BBP parameter for ''%c'' profile of ECO2 sensor - BBP data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco2.cycleNumber, ...
                  profEco2.profileNumber, ...
                  length(idF), ...
                  profEco2.direction);
            end
         end
         a_tabProfiles(profInfo(idSensor3(idP), 1)) = compute_profile_derived_parameters_for_ECO2( ...
            profEco2, profCtd);
      end
      
   elseif (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
      
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
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute BBP parameter for ''%c'' profile of ECO3 sensor - BBP data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco3.cycleNumber, ...
                  profEco3.profileNumber, ...
                  profEco3.direction);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute BBP parameter for ''%c'' profile of ECO3 sensor - BBP data set to fill value\n', ...
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
   end
   
   % compute SUNA derived parameters
   idSensor6 = find((profInfo(:, 2) == 6) & (profInfo(:, 3) == 0));
   for idP = 1:length(idSensor6)
      profCtd = [];
      profSuna = a_tabProfiles(profInfo(idSensor6(idP), 1));
      
      % FOR PROVOR CTS4 and CTS5_USEA
      % associated PTS values are provided with the NITRATE data when in "APF
      % frame"; however we use the PTS profile of the CTD sensor (better
      % reliability for SUNA measurement pressures that will be shifted by
      % the SUNA vertical pressure offset).
      % If CTD sensor profile is not available, we will use (in following
      % sub-function) the NITRATE associated PTS values.
      % FOR PROVOR CTS5_OSEAN:
      % the CTD PTS values are provided with the SUNA data. As P values come
      % from the CTD, they differ from the SUNA measurement ones. We then
      % decided to store PTS in a dedicated profile and to set the VSS to
      % 'Secondary sampling: discrete [CTD measurements concurrent with SUNA
      % measurements, just slightly offset in time]'
      % thus the PTS data sent with SUNA data are stored in a dedicated profile
      % associated to sensor number 6
      % these data are used only if CTD sensor profile is not available
      % (see above explanations for CTS4)
      paramNameList = {profSuna.paramList.name};
      if (ismember(a_decoderId, [g_decArgo_decoderIdListNkeCts4 g_decArgo_decoderIdListNkeCts5Usea]))
         % PROVOR CTS4 and CTS5_USEA float
         % look for the CTD profile
         idF = find((profInfo(:, 2) == 0) & ...
            (profInfo(:, 4) == profSuna.cycleNumber) & ...
            (profInfo(:, 5) == profSuna.profileNumber) & ...
            (profInfo(:, 6) == profSuna.phaseNumber));
         if (length(idF) == 1)
            profCtd = a_tabProfiles(profInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute NITRATE parameter for ''%c'' profile of SUNA sensor - we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  profSuna.cycleNumber, ...
                  profSuna.profileNumber, ...
                  profSuna.direction);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute NITRATE parameter for ''%c'' profile of SUNA sensor - we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  profSuna.cycleNumber, ...
                  profSuna.profileNumber, ...
                  length(idF), ...
                  profSuna.direction);
            end
         end
      else
         % PROVOR CTS5_OSEAN float
         if (~isempty(find(strcmp('TEMP', paramNameList) == 1, 1)))
            % it is the PTS profile reported by the SUNA sensor (we stored
            % a dedicated PTS profile with SensorNumber = 6)
            continue % so that the next one with SensorNumber = 6 contains the NITRATE data
         end
         % look for the associated CTD profile
         idF = find((profInfo(:, 2) == 0) & ...
            (profInfo(:, 4) == profSuna.cycleNumber) & ...
            (profInfo(:, 5) == profSuna.profileNumber) & ...
            (profInfo(:, 6) == profSuna.phaseNumber));
         if (length(idF) == 1)
            profCtd = a_tabProfiles(profInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute NITRATE parameter for ''%c'' profile of SUNA sensor - we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  profSuna.cycleNumber, ...
                  profSuna.profileNumber, ...
                  profSuna.direction);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute NITRATE parameter for ''%c'' profile of SUNA sensor - we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  profSuna.cycleNumber, ...
                  profSuna.profileNumber, ...
                  length(idF), ...
                  profSuna.direction);
            end
            
            % look for the SUNA associated CTD profile
            idF = find((profInfo(:, 2) == 6) & ...
               (profInfo(:, 4) == profSuna.cycleNumber) & ...
               (profInfo(:, 5) == profSuna.profileNumber) & ...
               (profInfo(:, 6) == profSuna.phaseNumber));
            % idSensor6(idP) is the current profile (with NITRATE data)
            % idF contains all SUNA profiles (with NITRATE data and with
            % associated PTS)
            idF = setdiff(idF, idSensor6(idP)); % to select SUNA profile with associated PTS
            if (length(idF) == 1)
               profCtd = a_tabProfiles(profInfo(idF, 1));
            else
               if (isempty(idF))
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the SUNA PTS data to compute NITRATE parameter for ''%c'' profile of SUNA sensor - NITRATE data set to fill value\n', ...
                     g_decArgo_floatNum, ...
                     profSuna.cycleNumber, ...
                     profSuna.profileNumber, ...
                     profSuna.direction);
               end
            end
         end
      end
      a_tabProfiles(profInfo(idSensor6(idP), 1)) = compute_profile_derived_parameters_for_SUNA( ...
         profSuna, profCtd, a_decoderId);
   end
   
   % compute TRANSISTOR_PH derived parameters
   idSensorPh = [];
   if (a_decoderId <= 120)
      % PROVOR CTS4 float => sensor #4
      if (ismember('TRANSISTOR_PH', g_decArgo_sensorMountedOnFloat))
         idSensorPh = find((profInfo(:, 2) == 4) & (profInfo(:, 3) == 0));
      end
   else
      % PROVOR CTS5 float => sensor #7
      idSensorPh = find((profInfo(:, 2) == 7) & (profInfo(:, 3) == 0));
   end
   for idP = 1:length(idSensorPh)
      profTransPh = a_tabProfiles(profInfo(idSensorPh(idP), 1));
      
      % look for the associated CTD profile
      profCtd = [];
      idF = find((profInfo(:, 2) == 0) & ...
         (profInfo(:, 4) == profTransPh.cycleNumber) & ...
         (profInfo(:, 5) == profTransPh.profileNumber) & ...
         (profInfo(:, 6) == profTransPh.phaseNumber));
      if (length(idF) == 1)
         profCtd = a_tabProfiles(profInfo(idF, 1));
      else
         if (isempty(idF))
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL parameters for ''%c'' profile of TRANSISTOR_PH sensor - PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profTransPh.cycleNumber, ...
               profTransPh.profileNumber, ...
               profTransPh.direction);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL parameters for ''%c'' profile of TRANSISTOR_PH sensor - PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profTransPh.cycleNumber, ...
               profTransPh.profileNumber, ...
               length(idF), ...
               profTransPh.direction);
         end
      end
      a_tabProfiles(profInfo(idSensorPh(idP), 1)) = ...
         compute_profile_derived_parameters_for_TRANSISTOR_PH( ...
         profTransPh, profCtd);
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return

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
global g_decArgo_qcNoQc;


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
      
      downIrr380 = compute_DOWN_IRRADIANCE380_105_to_112_121_to_127( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profOcr.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profOcr.data(:, end+1) = ones(size(a_profOcr.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profOcr.dataQc))
            a_profOcr.dataQc = ones(size(a_profOcr.data, 1), length(a_profOcr.paramList))*g_decArgo_qcDef;
         else
            a_profOcr.dataQc(:, end+1) = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profOcr.paramList = [a_profOcr.paramList derivedParam];
         derivedParamId = size(a_profOcr.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profOcr.data(:, derivedParamId) = downIrr380;
      downIrr380Qc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr380Qc(find(downIrr380 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profOcr.dataQc(:, derivedParamId) = downIrr380Qc;
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
      
      downIrr412 = compute_DOWN_IRRADIANCE412_105_to_112_121_to_127( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profOcr.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profOcr.data(:, end+1) = ones(size(a_profOcr.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profOcr.dataQc))
            a_profOcr.dataQc = ones(size(a_profOcr.data, 1), length(a_profOcr.paramList))*g_decArgo_qcDef;
         else
            a_profOcr.dataQc(:, end+1) = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profOcr.paramList = [a_profOcr.paramList derivedParam];
         derivedParamId = size(a_profOcr.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profOcr.data(:, derivedParamId) = downIrr412;
      downIrr412Qc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr412Qc(find(downIrr412 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profOcr.dataQc(:, derivedParamId) = downIrr412Qc;
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
      
      downIrr490 = compute_DOWN_IRRADIANCE490_105_to_112_121_to_127( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profOcr.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profOcr.data(:, end+1) = ones(size(a_profOcr.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profOcr.dataQc))
            a_profOcr.dataQc = ones(size(a_profOcr.data, 1), length(a_profOcr.paramList))*g_decArgo_qcDef;
         else
            a_profOcr.dataQc(:, end+1) = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profOcr.paramList = [a_profOcr.paramList derivedParam];
         derivedParamId = size(a_profOcr.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profOcr.data(:, derivedParamId) = downIrr490;
      downIrr490Qc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr490Qc(find(downIrr490 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profOcr.dataQc(:, derivedParamId) = downIrr490Qc;
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
      
      downPar = compute_DOWNWELLING_PAR_105_to_112_121_to_127( ...
         a_profOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profOcr.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profOcr.data(:, end+1) = ones(size(a_profOcr.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profOcr.dataQc))
            a_profOcr.dataQc = ones(size(a_profOcr.data, 1), length(a_profOcr.paramList))*g_decArgo_qcDef;
         else
            a_profOcr.dataQc(:, end+1) = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profOcr.paramList = [a_profOcr.paramList derivedParam];
         derivedParamId = size(a_profOcr.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profOcr.data(:, derivedParamId) = downPar;
      downParQc = ones(size(a_profOcr.data, 1), 1)*g_decArgo_qcDef;
      downParQc(find(downPar ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profOcr.dataQc(:, derivedParamId) = downParQc;
   end
end

% update output parameters
a_profOcr.derived = 1;
o_profOcr = a_profOcr;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO2 sensor.
%
% SYNTAX :
%  [o_profEco2] = compute_profile_derived_parameters_for_ECO2( ...
%    a_profEco2, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profEco2   : input ECO2 profile structure
%   a_profCtd    : input CTD profile structure
%
% OUTPUT PARAMETERS :
%   o_profEco2 : output ECO2 profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profEco2] = compute_profile_derived_parameters_for_ECO2( ...
   a_profEco2, a_profCtd)

% output parameters initialization
o_profEco2 = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profEco2.paramList.name};

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
      
      chla = compute_CHLA_105_to_112_121_to_127_1121_to_28_1322_1323( ...
         a_profEco2.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profEco2.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profEco2.data(:, end+1) = ones(size(a_profEco2.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profEco2.dataQc))
            a_profEco2.dataQc = ones(size(a_profEco2.data, 1), length(a_profEco2.paramList))*g_decArgo_qcDef;
         else
            a_profEco2.dataQc(:, end+1) = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profEco2.paramList = [a_profEco2.paramList derivedParam];
         derivedParamId = size(a_profEco2.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profEco2.data(:, derivedParamId) = chla;
      chlaQc = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profEco2.dataQc(:, derivedParamId) = chlaQc;
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
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profEco2.paramList.name}, derivedParamList{idP}), 1);
         if (isempty(idFDerivedParam))
            a_profEco2.data(:, end+1) = ones(size(a_profEco2.data, 1), 1)*derivedParam.fillValue;
            if (isempty(a_profEco2.dataQc))
               a_profEco2.dataQc = ones(size(a_profEco2.data, 1), length(a_profEco2.paramList))*g_decArgo_qcDef;
            else
               a_profEco2.dataQc(:, end+1) = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profEco2.paramList = [a_profEco2.paramList derivedParam];
         end
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
            a_profEco2.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_profEco2.data(:, 1), ...
            700, ...
            ctdMeasData, ...
            a_profEco2);
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profEco2.paramList.name}, derivedParamList{idP}), 1);
         if (isempty(idFDerivedParam))
            a_profEco2.data(:, end+1) = ones(size(a_profEco2.data, 1), 1)*derivedParam.fillValue;
            if (isempty(a_profEco2.dataQc))
               a_profEco2.dataQc = ones(size(a_profEco2.data, 1), length(a_profEco2.paramList))*g_decArgo_qcDef;
            else
               a_profEco2.dataQc(:, end+1) = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profEco2.paramList = [a_profEco2.paramList derivedParam];
            derivedParamId = size(a_profEco2.data, 2);
         else
            derivedParamId = idFDerivedParam;
         end
         
         if (~isempty(bbp700))
            a_profEco2.data(:, derivedParamId) = bbp700;
            bbp700Qc = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profEco2.dataQc(:, derivedParamId) = bbp700Qc;
         end
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
            a_profEco2.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_profEco2.data(:, 1), ...
            532, ...
            ctdMeasData, ...
            a_profEco2);
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profEco2.paramList.name}, derivedParamList{idP}), 1);
         if (isempty(idFDerivedParam))
            a_profEco2.data(:, end+1) = ones(size(a_profEco2.data, 1), 1)*derivedParam.fillValue;
            if (isempty(a_profEco2.dataQc))
               a_profEco2.dataQc = ones(size(a_profEco2.data, 1), length(a_profEco2.paramList))*g_decArgo_qcDef;
            else
               a_profEco2.dataQc(:, end+1) = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profEco2.paramList = [a_profEco2.paramList derivedParam];
            derivedParamId = size(a_profEco2.data, 2);
         else
            derivedParamId = idFDerivedParam;
         end
         
         if (~isempty(bbp532))
            a_profEco2.data(:, derivedParamId) = bbp532;
            bbp532Qc = ones(size(a_profEco2.data, 1), 1)*g_decArgo_qcDef;
            bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profEco2.dataQc(:, derivedParamId) = bbp532Qc;
         end
      end
   end
end

% update output parameters
a_profEco2.derived = 1;
o_profEco2 = a_profEco2;

return

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
global g_decArgo_qcNoQc;


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
      
      chla = compute_CHLA_105_to_112_121_to_127_1121_to_28_1322_1323( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profEco3.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profEco3.dataQc))
            a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
         else
            a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profEco3.paramList = [a_profEco3.paramList derivedParam];
         derivedParamId = size(a_profEco3.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profEco3.data(:, derivedParamId) = chla;
      chlaQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profEco3.dataQc(:, derivedParamId) = chlaQc;
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
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profEco3.paramList.name}, derivedParamList{idP}), 1);
         if (isempty(idFDerivedParam))
            a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
            if (isempty(a_profEco3.dataQc))
               a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
            else
               a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profEco3.paramList = [a_profEco3.paramList derivedParam];
         end
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
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profEco3.paramList.name}, derivedParamList{idP}), 1);
         if (isempty(idFDerivedParam))
            a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
            if (isempty(a_profEco3.dataQc))
               a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
            else
               a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profEco3.paramList = [a_profEco3.paramList derivedParam];
            derivedParamId = size(a_profEco3.data, 2);
         else
            derivedParamId = idFDerivedParam;
         end
         
         if (~isempty(bbp700))
            a_profEco3.data(:, derivedParamId) = bbp700;
            bbp700Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profEco3.dataQc(:, derivedParamId) = bbp700Qc;
         end
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
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profEco3.paramList.name}, derivedParamList{idP}), 1);
         if (isempty(idFDerivedParam))
            a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
            if (isempty(a_profEco3.dataQc))
               a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
            else
               a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profEco3.paramList = [a_profEco3.paramList derivedParam];
            derivedParamId = size(a_profEco3.data, 2);
         else
            derivedParamId = idFDerivedParam;
         end
         
         if (~isempty(bbp532))
            a_profEco3.data(:, derivedParamId) = bbp532;
            bbp532Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
            bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profEco3.dataQc(:, derivedParamId) = bbp532Qc;
         end
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
      
      cdom = compute_CDOM_105_to_107_110_112_121_to_127_1121_to_28_1322_1323( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      % for CTS5 floats the derived parameter could be already in the list of
      % parameters => we should first look for it
      
      idFDerivedParam = find(strcmp({a_profEco3.paramList.name}, derivedParamList{idP}), 1);
      if (isempty(idFDerivedParam))
         a_profEco3.data(:, end+1) = ones(size(a_profEco3.data, 1), 1)*derivedParam.fillValue;
         if (isempty(a_profEco3.dataQc))
            a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
         else
            a_profEco3.dataQc(:, end+1) = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profEco3.paramList = [a_profEco3.paramList derivedParam];
         derivedParamId = size(a_profEco3.data, 2);
      else
         derivedParamId = idFDerivedParam;
      end
      
      a_profEco3.data(:, derivedParamId) = cdom;
      cdomQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profEco3.dataQc(:, derivedParamId) = cdomQc;
   end
end

% update output parameters
a_profEco3.derived = 1;
o_profEco3 = a_profEco3;

return

% ------------------------------------------------------------------------------
% Compute BBP from the data provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_BBP] = compute_profile_BBP( ...
%    a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
%    a_BBP_fillValue, ...
%    a_BBP_pres, ...
%    a_lambda, ...
%    a_ctdData, ...
%    a_profEco3)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING            : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fillValue : fill value for input BETA_BACKSCATTERING
%                                      data
%   a_BBP_fillValue                 : fill value for output BBP data
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
   a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
   a_BBP_fillValue, ...
   a_BBP_pres, ...
   a_lambda, ...
   a_ctdData, ...
   a_profEco3)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fillValue;


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
   ctdIntData = compute_interpolated_CTD_measurements( ...
      ctdDataNoDef, a_BBP_pres, a_profEco3.direction);
   if (~isempty(ctdIntData))
      
      idNoDef = find((ctdIntData(:, 2) ~= paramTemp.fillValue) & (ctdIntData(:, 3) ~= paramPsal.fillValue));
      
      if (a_lambda == 700)
         o_BBP(idNoDef) = compute_BBP700_105_to_112_121_to_127_1121_to_28_1322_1323( ...
            a_BETA_BACKSCATTERING(idNoDef), ...
            a_BETA_BACKSCATTERING_fillValue, ...
            a_BBP_fillValue, ...
            ctdIntData(idNoDef, :), ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue);
      elseif (a_lambda == 532)
         o_BBP(idNoDef) = compute_BBP532_108_109( ...
            a_BETA_BACKSCATTERING(idNoDef), ...
            a_BETA_BACKSCATTERING_fillValue, ...
            a_BBP_fillValue, ...
            ctdIntData(idNoDef, :), ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue);
      else
         fprintf('WARNING: Float #%d Cycle #%d Profile #%d: BBP processing not implemented yet for lambda = %g - BBP data set to fill value in ''%c'' profile of ECO3 sensor\n', ...
            g_decArgo_floatNum, ...
            a_profEco3.cycleNumber, ...
            a_profEco3.profileNumber, ...
            a_lambda, ...
            a_profEco3.direction);
         
         % update output parameters
         o_BBP = [];
      end
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute BBP parameter for ''%c'' profile of ECO3 sensor - BBP data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profEco3.cycleNumber, ...
         a_profEco3.profileNumber, ...
         a_profEco3.direction);
      
      % update output parameters
      o_BBP = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute BBP parameter for ''%c'' profile of ECO3 sensor - BBP data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profEco3.cycleNumber, ...
      a_profEco3.profileNumber, ...
      a_profEco3.direction);
   
   % update output parameters
   o_BBP = [];
   
end

return

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
global g_decArgo_qcNoQc;


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
      
      chla = compute_CHLA_105_to_112_121_to_127_1121_to_28_1322_1323( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = chla;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
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
      
      bbp700 = compute_BBP700_105_to_112_121_to_127_1121_to_28_1322_1323_V1( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = bbp700;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
      end
      bbp700Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
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
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
      end
      bbp532Qc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
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
      
      cdom = compute_CDOM_105_to_107_110_112_121_to_127_1121_to_28_1322_1323( ...
         a_profEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profEco3.data(:, end+1) = cdom;
      if (isempty(a_profEco3.dataQc))
         a_profEco3.dataQc = ones(size(a_profEco3.data, 1), length(a_profEco3.paramList))*g_decArgo_qcDef;
      end
      cdomQc = ones(size(a_profEco3.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profEco3.dataQc(:, end+1) = cdomQc;
      
      a_profEco3.paramList = [a_profEco3.paramList derivedParam];
   end
end

% update output parameters
a_profEco3.derived = 1;
o_profEco3 = a_profEco3;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the SUNA sensor.
%
% SYNTAX :
%  [o_profSuna] = compute_profile_derived_parameters_for_SUNA(a_profSuna, a_profCtd, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profSuna  : input SUNA profile structure
%   a_profCtd   : input CTD profile structure
%   a_decoderId : float decoder Id
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
function [o_profSuna] = compute_profile_derived_parameters_for_SUNA(a_profSuna, a_profCtd, a_decoderId)

% output parameters initialization
o_profSuna = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts5Usea;

% to manage fitlm function for NITRATE processin
global g_temp_fitlmNotAvailable;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = g_temp_fitlmNotAvailable;


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

% if the fitlm Matlab function is available, compute NITRATE data from
% transmitted spectrum and add them in the profile structure
if (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
   if (~ismember(a_decoderId, [110, 113, 127]))
      
      % compute NITRATE
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
            
            [nitrate, rmsError] = compute_profile_NITRATE_105_to_109_111_112_114_115_121_to_126( ...
               a_profSuna.data(:, idF1:idF1+a_profSuna.paramNumberOfSubLevels-1), ...
               a_profSuna.data(:, idF2), ...
               paramToDerive1.fillValue, ...
               paramToDerive2.fillValue, ...
               derivedParam.fillValue, ...
               a_profSuna.data(:, 1), ctdMeasData, ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_profSuna, a_decoderId);
            
            % store NITRATE
            a_profSuna.data(:, end+1) = nitrate;
            if (isempty(a_profSuna.dataQc))
               a_profSuna.dataQc = ones(size(a_profSuna.data, 1), length(a_profSuna.paramList))*g_decArgo_qcDef;
            end
            nitrateQc = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
            nitrateQc(find(nitrate ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profSuna.dataQc(:, end+1) = nitrateQc;
            
            a_profSuna.paramList = [a_profSuna.paramList derivedParam];
            a_profSuna.rmsError = rmsError;
         end
      end
   else
      
      % compute NITRATE and BISULFIDE
      paramToDeriveList = [ ...
         {'UV_INTENSITY_NITRATE'} {'UV_INTENSITY_DARK_NITRATE'} ...
         ];
      derivedParamList = [ ...
         {'NITRATE'} {'BISULFIDE'} ...
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
            derivedParam1 = get_netcdf_param_attributes(derivedParamList{idP, 1});
            derivedParam2 = get_netcdf_param_attributes(derivedParamList{idP, 2});
            
            [nitrate, bisulfide, rmsError] = compute_profile_NITRATE_BISULFIDE_from_spectrum_110_113_127( ...
               a_profSuna.data(:, idF1:idF1+a_profSuna.paramNumberOfSubLevels-1), ...
               a_profSuna.data(:, idF2), ...
               paramToDerive1.fillValue, ...
               paramToDerive2.fillValue, ...
               derivedParam1.fillValue, ...
               derivedParam2.fillValue, ...
               a_profSuna.data(:, 1), ctdMeasData, ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_profSuna);
            
            % store NITRATE
            a_profSuna.data(:, end+1) = nitrate;
            if (isempty(a_profSuna.dataQc))
               a_profSuna.dataQc = ones(size(a_profSuna.data, 1), length(a_profSuna.paramList))*g_decArgo_qcDef;
            end
            nitrateQc = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
            nitrateQc(find(nitrate ~= derivedParam1.fillValue)) = g_decArgo_qcNoQc;
            a_profSuna.dataQc(:, end+1) = nitrateQc;
            
            a_profSuna.paramList = [a_profSuna.paramList derivedParam1];
            a_profSuna.rmsError = rmsError;
            
            % store BISULFIDE
            a_profSuna.data(:, end+1) = bisulfide;
            if (isempty(a_profSuna.dataQc))
               a_profSuna.dataQc = ones(size(a_profSuna.data, 1), length(a_profSuna.paramList))*g_decArgo_qcDef;
            end
            bisulfideQc = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
            bisulfideQc(find(bisulfide ~= derivedParam2.fillValue)) = g_decArgo_qcNoQc;
            a_profSuna.dataQc(:, end+1) = bisulfideQc;
            
            a_profSuna.paramList = [a_profSuna.paramList derivedParam2];
         end
      end
   end
else
   
   if (~ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5Usea))
      
      % if the fitlm Matlab function is not available, compute NITRATE data from
      % transmitted MOLAR_NITRATE and add them in the profile structure
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
            
            nitrate = compute_prof_NITRATE_from_MOLAR_1xx_5_to_9_11_12_14_21_to_25( ...
               a_profSuna.data(:, idF), ...
               paramToDerive.fillValue, derivedParam.fillValue, ...
               a_profSuna.data(:, 1), ctdMeasData, ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_profSuna);
            
            % for CTS5 floats the derived parameter could be already in the list of
            % parameters => we should first look for it
            
            idFDerivedParam = find(strcmp({a_profSuna.paramList.name}, derivedParamList{idP}), 1);
            if (isempty(idFDerivedParam))
               a_profSuna.data(:, end+1) = ones(size(a_profSuna.data, 1), 1)*derivedParam.fillValue;
               a_profSuna.paramList = [a_profSuna.paramList derivedParam];
               if (isempty(a_profSuna.dataQc))
                  a_profSuna.dataQc = ones(size(a_profSuna.data, 1), length(a_profSuna.paramList))*g_decArgo_qcDef;
               else
                  a_profSuna.dataQc(:, end+1) = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
               end
               derivedParamId = size(a_profSuna.data, 2);
               derivedParamQcId = size(a_profSuna.dataQc, 2);
            else
               if (isempty(a_profSuna.paramNumberWithSubLevels))
                  derivedParamId = idFDerivedParam;
                  derivedParamQcId = size(a_profSuna.dataQc, 2);
               else
                  idF = find(a_profSuna.paramNumberWithSubLevels < idFDerivedParam);
                  if (isempty(idF))
                     derivedParamId = idFDerivedParam;
                  else
                     derivedParamId = idFDerivedParam + sum(a_profSuna.paramNumberOfSubLevels(idF)) - length(idF);
                  end
                  derivedParamQcId = size(a_profSuna.dataQc, 2);
               end
            end
            
            a_profSuna.data(:, derivedParamId) = nitrate;
            nitrateQc = ones(size(a_profSuna.data, 1), 1)*g_decArgo_qcDef;
            nitrateQc(find(nitrate ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profSuna.dataQc(:, derivedParamQcId) = nitrateQc;
         end
      end
   end
end

% update output parameters
a_profSuna.derived = 1;
o_profSuna = a_profSuna;

return

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
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profOptode.paramList.name};

if (~ismember(a_decoderId, [106, 107, 109, 110, 111, 112, 113, 114, 115])) % without PPOX_DOXY
   
   if (isempty(a_profCtd))
      
      % we have not been able to retrieve the associated CTD profile
      if (ismember('C1PHASE_DOXY', paramNameList) && ...
            ismember('C2PHASE_DOXY', paramNameList) && ...
            ismember('TEMP_DOXY', paramNameList))
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
            
            % for CTS5 floats the derived parameter could be already in the list of
            % parameters => we should first look for it
            
            idFDerivedParam = find(strcmp({a_profOptode.paramList.name}, derivedParamList{idP}), 1);
            if (isempty(idFDerivedParam))
               a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
               if (isempty(a_profOptode.dataQc))
                  a_profOptode.dataQc = ones(size(a_profOptode.data, 1), length(a_profOptode.paramList))*g_decArgo_qcDef;
               else
                  a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
               end
               a_profOptode.paramList = [a_profOptode.paramList derivedParam];
               derivedParamId = size(a_profOptode.data, 2);
            else
               if (isempty(a_profOptode.paramNumberWithSubLevels))
                  derivedParamId = idFDerivedParam;
               else
                  idF = find(a_profOptode.paramNumberWithSubLevels < idFDerivedParam);
                  if (isempty(idF))
                     derivedParamId = idFDerivedParam;
                  else
                     derivedParamId = idFDerivedParam + sum(a_profOptode.paramNumberOfSubLevels(idF)) - length(idF);
                  end
               end
            end
            
            if (~isempty(doxy))
               a_profOptode.data(:, derivedParamId) = doxy;
               doxyQc = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
               doxyQc(find(doxy ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
               a_profOptode.dataQc(:, derivedParamId) = doxyQc;
            end
         end
      end
   end
   
else % with PPOX_DOXY
   
   if (isempty(a_profCtd))
      
      % we have not been able to retrieve the associated CTD profile
      if (ismember('C1PHASE_DOXY', paramNameList) && ...
            ismember('C2PHASE_DOXY', paramNameList) && ...
            ismember('TEMP_DOXY', paramNameList))
         derivedParamList = [ ...
            {'DOXY'} ...
            {'PPOX_DOXY'} ...
            ];
         for idP = 1:length(derivedParamList)
            derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
            a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_profOptode.dataQc))
               a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profOptode.paramList = [a_profOptode.paramList derivedParam];
         end
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
         {'PPOX_DOXY'} ...
         ];
      
      idF1 = find(strcmp(paramToDeriveList{1}, paramNameList) == 1, 1);
      idF2 = find(strcmp(paramToDeriveList{2}, paramNameList) == 1, 1);
      idF3 = find(strcmp(paramToDeriveList{3}, paramNameList) == 1, 1);
      if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
         paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{1});
         paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{2});
         paramToDerive3 = get_netcdf_param_attributes(paramToDeriveList{3});
         derivedParam1 = get_netcdf_param_attributes(derivedParamList{1});
         derivedParam2 = get_netcdf_param_attributes(derivedParamList{2});
         
         % compute DOXY values
         [doxy, ppoxDoxy] = compute_profile_DOXY_PPOX_DOXY( ...
            a_profOptode.data(:, idF1), ...
            a_profOptode.data(:, idF2), ...
            a_profOptode.data(:, idF3), ...
            paramToDerive1.fillValue, ...
            paramToDerive2.fillValue, ...
            paramToDerive3.fillValue, ...
            derivedParam1.fillValue, ...
            derivedParam2.fillValue, ...
            a_profOptode.data(:, 1), ...
            ctdMeasData, ...
            a_profOptode, a_decoderId);
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam = find(strcmp({a_profOptode.paramList.name}, derivedParamList{1}), 1);
         if (isempty(idFDerivedParam))
            a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam1.fillValue;
            if (isempty(a_profOptode.dataQc))
               a_profOptode.dataQc = ones(size(a_profOptode.data, 1), length(a_profOptode.paramList))*g_decArgo_qcDef;
            else
               a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profOptode.paramList = [a_profOptode.paramList derivedParam1];
            derivedParamId = size(a_profOptode.data, 2);
         else
            if (isempty(a_profOptode.paramNumberWithSubLevels))
               derivedParamId = idFDerivedParam;
            else
               idF = find(a_profOptode.paramNumberWithSubLevels < idFDerivedParam);
               if (isempty(idF))
                  derivedParamId = idFDerivedParam;
               else
                  derivedParamId = idFDerivedParam + sum(a_profOptode.paramNumberOfSubLevels(idF)) - length(idF);
               end
            end
         end
         
         if (~isempty(doxy))
            a_profOptode.data(:, derivedParamId) = doxy;
            doxyQc = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
            doxyQc(find(doxy ~= derivedParam1.fillValue)) = g_decArgo_qcNoQc;
            a_profOptode.dataQc(:, derivedParamId) = doxyQc;
         end
         
         if (~isempty(ppoxDoxy))
            a_profOptode.data(:, end+1) = ppoxDoxy;
            ppoxDoxyQc = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
            ppoxDoxyQc(find(ppoxDoxy ~= derivedParam2.fillValue)) = g_decArgo_qcNoQc;
            a_profOptode.dataQc(:, end+1) = ppoxDoxyQc;
            a_profOptode.paramList = [a_profOptode.paramList derivedParam2];
         end
      end
   end
   
end

% update output parameters
a_profOptode.derived = 1;
o_profOptode = a_profOptode;

return

% ------------------------------------------------------------------------------
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_profile_DOXY( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_DOXY_fillValue, ...
%    a_DOXY_pres, a_ctdData, ...
%    a_profOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY            : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY            : input C2PHASE_DOXY data
%   a_TEMP_DOXY               : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fillValue : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fillValue : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fillValue    : fill value for input TEMP_DOXY data
%   a_DOXY_fillValue         : fill value for output DOXY data
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
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_DOXY_fillValue, ...
   a_DOXY_pres, a_ctdData, ...
   a_profOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;


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
   ctdIntData = compute_interpolated_CTD_measurements( ...
      ctdDataNoDef, a_DOXY_pres, a_profOptode.direction);
   if (~isempty(ctdIntData))
      
      idNoDef = find((ctdIntData(:, 2) ~= paramTemp.fillValue) & (ctdIntData(:, 3) ~= paramPsal.fillValue));
      
      switch (a_decoderId)
                     
         case {121, 122, 124, 126, 127}
            
            % compute DOXY values using the Stern-Volmer equation
            o_DOXY(idNoDef) = compute_DOXY_107_109_to_111_113_to_115_121_122_124_126_127( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               ctdIntData(idNoDef, 2), ...
               ctdIntData(idNoDef, 3), ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_DOXY_fillValue, ...
               a_profOptode);
            
         case {123, 125}
            
            % compute DOXY values using the Aanderaa standard calibration method
            % + an additional two-point adjustment
            o_DOXY(idNoDef) = compute_DOXY_112_123_125( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               ctdIntData(idNoDef, 2), ...
               ctdIntData(idNoDef, 3), ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_DOXY_fillValue, ...
               a_profOptode);
            
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
               g_decArgo_floatNum, ...
               a_profOptode.cycleNumber, ...
               a_profOptode.profileNumber, ...
               a_decoderId, ...
               a_profOptode.direction);
            
            % update output parameters
            o_DOXY = [];
            
      end
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profOptode.cycleNumber, ...
         a_profOptode.profileNumber, ...
         a_profOptode.direction);
      
      % update output parameters
      o_DOXY = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber, ...
      a_profOptode.direction);
   
   % update output parameters
   o_DOXY = [];
   
end

return

% ------------------------------------------------------------------------------
% Compute DOXY and PPOX_DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY, o_PPOX_DOXY] = compute_profile_DOXY_PPOX_DOXY( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_DOXY_fillValue, a_PPOX_DOXY_fillValue, ...
%    a_DOXY_pres, a_ctdData, ...
%    a_profOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY            : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY           : input C2PHASE_DOXY data
%   a_TEMP_DOXY              : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fillValue : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fillValue : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fillValue    : fill value for input TEMP_DOXY data
%   a_DOXY_fillValue         : fill value for output DOXY data
%   a_PPOX_DOXY_fillValue    : fill value for output PPOX_DOXY data
%   a_DOXY_pres              : pressure levels of DOXY data
%   a_ctdData                : ascociated CTD (P, T, S) data
%   a_profOptode             : input OPTODE profile structure
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_DOXY      : output DOXY data
%   o_PPOX_DOXY : output PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY, o_PPOX_DOXY] = compute_profile_DOXY_PPOX_DOXY( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_DOXY_fillValue, a_PPOX_DOXY_fillValue, ...
   a_DOXY_pres, a_ctdData, ...
   a_profOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fillValue;
o_PPOX_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_PPOX_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;


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
   ctdIntData = compute_interpolated_CTD_measurements( ...
      ctdDataNoDef, a_DOXY_pres, a_profOptode.direction);
   if (~isempty(ctdIntData))
      
      idNoDef = find((ctdIntData(:, 2) ~= paramTemp.fillValue) & (ctdIntData(:, 3) ~= paramPsal.fillValue));
      
      switch (a_decoderId)
         
         case {106}
            
            % compute DOXY values using the Aanderaa standard calibration method
            o_DOXY(idNoDef) = compute_DOXY_106_301( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               ctdIntData(idNoDef, 2), ...
               ctdIntData(idNoDef, 3), ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_DOXY_fillValue, ...
               a_profOptode);
            
            % compute PPOX_DOXY values using the Aanderaa standard calibration method
            o_PPOX_DOXY(idNoDef) = compute_PPOX_DOXY_106( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               paramPres.fillValue, ...
               a_PPOX_DOXY_fillValue, ...
               a_profOptode);
            
         case {107, 109, 110, 111, 113, 114, 115}
            
            % compute DOXY values using the Stern-Volmer equation
            o_DOXY(idNoDef) = compute_DOXY_107_109_to_111_113_to_115_121_122_124_126_127( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               ctdIntData(idNoDef, 2), ...
               ctdIntData(idNoDef, 3), ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_DOXY_fillValue, ...
               a_profOptode);
            
            % compute PPOX_DOXY values using the Stern-Volmer equation
            o_PPOX_DOXY(idNoDef) = compute_PPOX_DOXY_107_109_to_111_113_to_115_121_122_124_126_127( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               paramPres.fillValue, ...
               a_PPOX_DOXY_fillValue, ...
               a_profOptode);
            
         case {112}
            
            % compute DOXY values using the Aanderaa standard calibration method
            % + an additional two-point adjustment
            o_DOXY(idNoDef) = compute_DOXY_112_123_125( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               ctdIntData(idNoDef, 2), ...
               ctdIntData(idNoDef, 3), ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_DOXY_fillValue, ...
               a_profOptode);
            
            % compute PPOX_DOXY values using the Aanderaa standard calibration method
            % + an additional two-point adjustment
            o_PPOX_DOXY(idNoDef) = compute_PPOX_DOXY_112( ...
               a_C1PHASE_DOXY(idNoDef), ...
               a_C2PHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_C1PHASE_DOXY_fillValue, ...
               a_C2PHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               paramPres.fillValue, ...
               a_PPOX_DOXY_fillValue, ...
               a_profOptode);
            
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
               g_decArgo_floatNum, ...
               a_profOptode.cycleNumber, ...
               a_profOptode.profileNumber, ...
               a_decoderId, ...
               a_profOptode.direction);
            
            % update output parameters
            o_DOXY = [];
            
      end
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profOptode.cycleNumber, ...
         a_profOptode.profileNumber, ...
         a_profOptode.direction);
      
      % update output parameters
      o_DOXY = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute DOXY parameter for ''%c'' profile of OPTODE sensor - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber, ...
      a_profOptode.direction);
   
   % update output parameters
   o_DOXY = [];
   
end

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the TRANSISTOR_PH sensor.
%
% SYNTAX :
%  [o_profTransPh] = compute_profile_derived_parameters_for_TRANSISTOR_PH( ...
%    a_profTransPh, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profTransPh : input TRANSISTOR_PH profile structure
%   a_profCtd     : input CTD profile structure
%
% OUTPUT PARAMETERS :
%   o_profTransPh : output TRANSISTOR_PH profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/23/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profTransPh] = compute_profile_derived_parameters_for_TRANSISTOR_PH( ...
   a_profTransPh, a_profCtd)

% output parameters initialization
o_profTransPh = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profTransPh.paramList.name};

if (isempty(a_profCtd))
   
   % we have not been able to retrieve the associated CTD profile
   if (ismember('VRS_PH', paramNameList))
      derivedParamList = [ ...
         {'PH_IN_SITU_FREE'} ...
         {'PH_IN_SITU_TOTAL'} ...
         ];
      for idP = 1:length(derivedParamList)
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         a_profTransPh.data(:, end+1) = ones(size(a_profTransPh.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_profTransPh.dataQc))
            a_profTransPh.dataQc(:, end+1) = ones(size(a_profTransPh.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profTransPh.paramList = [a_profTransPh.paramList derivedParam];
      end
   end
else
   
   % get the CTD profile data
   paramNameListCtd = {a_profCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);
   
   % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data and add them in the
   % profile structure
   paramToDeriveList = [ ...
      {'VRS_PH'} ...
      ];
   derivedParamList = [ ...
      {'PH_IN_SITU_FREE'} ...
      {'PH_IN_SITU_TOTAL'} ...
      ];
   for idP = 1:size(paramToDeriveList, 1)
      idF = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
         derivedParam1 = get_netcdf_param_attributes(derivedParamList{idP, 1});
         derivedParam2 = get_netcdf_param_attributes(derivedParamList{idP, 2});
         
         [phInSituFree, phInSituTotal] = compute_profile_PH( ...
            a_profTransPh.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam1.fillValue, ...
            derivedParam2.fillValue, ...
            a_profTransPh.data(:, 1), ...
            ctdMeasData, ...
            a_profTransPh);
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam1 = find(strcmp({a_profTransPh.paramList.name}, derivedParamList{idP, 1}), 1);
         if (isempty(idFDerivedParam1))
            a_profTransPh.data(:, end+1) = ones(size(a_profTransPh.data, 1), 1)*derivedParam1.fillValue;
            if (isempty(a_profTransPh.dataQc))
               a_profTransPh.dataQc = ones(size(a_profTransPh.data, 1), length(a_profTransPh.paramList))*g_decArgo_qcDef;
            else
               a_profTransPh.dataQc(:, end+1) = ones(size(a_profTransPh.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profTransPh.paramList = [a_profTransPh.paramList derivedParam1];
            derivedParam1Id = size(a_profTransPh.data, 2);
         else
            if (isempty(a_profTransPh.paramNumberWithSubLevels))
               derivedParam1Id = idFDerivedParam1;
            else
               idF = find(a_profTransPh.paramNumberWithSubLevels < idFDerivedParam1);
               if (isempty(idF))
                  derivedParam1Id = idFDerivedParam1;
               else
                  derivedParam1Id = idFDerivedParam1 + sum(a_profTransPh.paramNumberOfSubLevels(idF)) - length(idF);
               end
            end
         end
         
         idFDerivedParam2 = find(strcmp({a_profTransPh.paramList.name}, derivedParamList{idP, 2}), 1);
         if (isempty(idFDerivedParam2))
            a_profTransPh.data(:, end+1) = ones(size(a_profTransPh.data, 1), 1)*derivedParam2.fillValue;
            if (isempty(a_profTransPh.dataQc))
               a_profTransPh.dataQc = ones(size(a_profTransPh.data, 1), length(a_profTransPh.paramList))*g_decArgo_qcDef;
            else
               a_profTransPh.dataQc(:, end+1) = ones(size(a_profTransPh.data, 1), 1)*g_decArgo_qcDef;
            end
            a_profTransPh.paramList = [a_profTransPh.paramList derivedParam2];
            derivedParam2Id = size(a_profTransPh.data, 2);
         else
            if (isempty(a_profTransPh.paramNumberWithSubLevels))
               derivedParam2Id = idFDerivedParam2;
            else
               idF = find(a_profTransPh.paramNumberWithSubLevels < idFDerivedParam2);
               if (isempty(idF))
                  derivedParam2Id = idFDerivedParam2;
               else
                  derivedParam2Id = idFDerivedParam2 + sum(a_profTransPh.paramNumberOfSubLevels(idF)) - length(idF);
               end
            end
         end
         
         if (~isempty(phInSituFree))
            a_profTransPh.data(:, derivedParam1Id) = phInSituFree;
            phInSituFreeQc = ones(size(a_profTransPh.data, 1), 1)*g_decArgo_qcDef;
            phInSituFreeQc(find(phInSituFree ~= derivedParam1.fillValue)) = g_decArgo_qcNoQc;
            a_profTransPh.dataQc(:, derivedParam1Id) = phInSituFreeQc;
         end
         
         if (~isempty(phInSituTotal))
            a_profTransPh.data(:, derivedParam2Id) = phInSituTotal;
            phInSituFreeQc = ones(size(a_profTransPh.data, 1), 1)*g_decArgo_qcDef;
            phInSituFreeQc(find(phInSituTotal ~= derivedParam2.fillValue)) = g_decArgo_qcNoQc;
            a_profTransPh.dataQc(:, derivedParam2Id) = phInSituFreeQc;
         end
      end
   end
end

% update output parameters
a_profTransPh.derived = 1;
o_profTransPh = a_profTransPh;

return

% ------------------------------------------------------------------------------
% Compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL from the data provided by the
% TRANSISTOR_PH sensor.
%
% SYNTAX :
%  [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_profile_PH( ...
%    a_VRS_PH, ...
%    a_VRS_PH_fillValue, ...
%    a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue, ...
%    a_VRS_PH_pres, a_ctdData, ...
%    a_profTransPh)
%
% INPUT PARAMETERS :
%   a_VRS_PH                     : input VRS_PH data
%   a_VRS_PH_fillValue           : fill value for input VRS_PH data
%   a_PH_IN_SITU_FREE_fillValue  : fill value for output PH_IN_SITU_FREE data
%   a_PH_IN_SITU_TOTAL_fillValue : fill value for output PH_IN_SITU_TOTAL data
%   a_VRS_PH_pres                : pressure levels of VRS_PH data
%   a_ctdData                    : ascociated CTD (P, T, S) data
%   a_profTransPh                : input TRANSISTOR_PH profile structure
%
% OUTPUT PARAMETERS :
%   o_PH_IN_SITU_FREE  : output PH_IN_SITU_FREE data
%   o_PH_IN_SITU_TOTAL : output PH_IN_SITU_TOTAL data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/23/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_profile_PH( ...
   a_VRS_PH, ...
   a_VRS_PH_fillValue, ...
   a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue, ...
   a_VRS_PH_pres, a_ctdData, ...
   a_profTransPh)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_PH_IN_SITU_FREE = ones(length(a_VRS_PH), 1)*a_PH_IN_SITU_FREE_fillValue;
o_PH_IN_SITU_TOTAL = ones(length(a_VRS_PH), 1)*a_PH_IN_SITU_TOTAL_fillValue;


paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');
idNoDef = find((a_ctdData(:, 1) ~= paramPres.fillValue) & ...
   (a_ctdData(:, 2) ~= paramTemp.fillValue) & ...
   (a_ctdData(:, 3) ~= paramPsal.fillValue));
ctdDataNoDef = a_ctdData(idNoDef, :);
if (~isempty(ctdDataNoDef))
   
   % interpolate and extrapolate the CTD data at the pressures of the
   % TRANSISTOR_PH measurements
   ctdIntData = compute_interpolated_CTD_measurements( ...
      ctdDataNoDef, a_VRS_PH_pres, a_profTransPh.direction);
   if (~isempty(ctdIntData))
      
      idNoDef = find((ctdIntData(:, 2) ~= paramTemp.fillValue) & (ctdIntData(:, 3) ~= paramPsal.fillValue));
      
      % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL values
      [o_PH_IN_SITU_FREE(idNoDef), o_PH_IN_SITU_TOTAL(idNoDef)] = compute_PH_111_113_114_115_123( ...
         a_VRS_PH(idNoDef), ...
         a_VRS_PH_fillValue, ...
         ctdIntData(idNoDef, 1), ...
         ctdIntData(idNoDef, 2), ...
         ctdIntData(idNoDef, 3), ...
         paramPres.fillValue, ...
         paramTemp.fillValue, ...
         paramPsal.fillValue, ...
         a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue, ...
         a_profTransPh);
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL parameters for ''%c'' profile of TRANSISTOR_PH sensor - PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profTransPh.cycleNumber, ...
         a_profTransPh.profileNumber, ...
         a_profTransPh.direction);
      
      % update output parameters
      o_PH_IN_SITU_FREE = [];
      o_PH_IN_SITU_TOTAL = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL parameters for ''%c'' profile of TRANSISTOR_PH sensor - PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profTransPh.cycleNumber, ...
      a_profTransPh.profileNumber, ...
      a_profTransPh.direction);
   
   % update output parameters
   o_PH_IN_SITU_FREE = [];
   o_PH_IN_SITU_TOTAL = [];
   
end

return
