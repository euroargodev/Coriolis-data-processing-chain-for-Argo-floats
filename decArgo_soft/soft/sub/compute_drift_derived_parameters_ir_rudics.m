% ------------------------------------------------------------------------------
% Compute drift derived parameters and add them in the drift measurements
% profile structures.
%
% SYNTAX :
%  [o_tabDrift] = compute_drift_derived_parameters_ir_rudics(a_tabDrift, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabDrift  : input drift measurements profile structures
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabDrift   : output drift measurements profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabDrift] = compute_drift_derived_parameters_ir_rudics(a_tabDrift, a_decoderId)

% output parameters initialization
o_tabDrift = [];

% current float WMO number
global g_decArgo_floatNum;

% sensor list
global g_decArgo_sensorMountedOnFloat;


% collect information on drift measurement profiles
driftInfo = [];
for idDrift = 1:length(a_tabDrift)
   
   profile = a_tabDrift(idDrift);
   
   driftInfo = [driftInfo;
      idDrift profile.sensorNumber profile.derived profile.cycleNumber profile.profileNumber];
end

% compute derived parameters for some sensors
if (~isempty(driftInfo))
   
   % compute OPTODE derived parameters
   idSensor1 = find((driftInfo(:, 2) == 1) & (driftInfo(:, 3) == 0));
   for idD = 1:length(idSensor1)
      driftOptode = a_tabDrift(driftInfo(idSensor1(idD), 1));
      
      % look for the associated CTD drift measurements
      driftCtd = [];
      idF = find((driftInfo(:, 2) == 0) & ...
         (driftInfo(:, 4) == driftOptode.cycleNumber) & ...
         (driftInfo(:, 5) == driftOptode.profileNumber));
      if (length(idF) == 1)
         driftCtd = a_tabDrift(driftInfo(idF, 1));
      else
         if (isempty(idF))
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute DOXY drift measurements of OPTODE sensor => DOXY drift measurements set to fill value\n', ...
               g_decArgo_floatNum, ...
               driftOptode.cycleNumber, ...
               driftOptode.profileNumber);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute DOXY drift measurements of OPTODE sensor => DOXY drift measurements set to fill value\n', ...
               g_decArgo_floatNum, ...
               driftOptode.cycleNumber, ...
               driftOptode.profileNumber, ...
               length(idF));
         end
      end
      a_tabDrift(driftInfo(idSensor1(idD), 1)) = compute_drift_derived_parameters_for_OPTODE( ...
         driftOptode, driftCtd, a_decoderId);
   end
   
   % compute OCR derived parameters
   idSensor2 = find((driftInfo(:, 2) == 2) & (driftInfo(:, 3) == 0));
   for idP = 1:length(idSensor2)
      a_tabDrift(driftInfo(idSensor2(idP), 1)) = compute_drift_derived_parameters_for_OCR(a_tabDrift(driftInfo(idSensor2(idP), 1)));
   end
   
   if (ismember('ECO2', g_decArgo_sensorMountedOnFloat))
      
      % compute ECO2 derived parameters
      idSensor3 = find((driftInfo(:, 2) == 3) & (driftInfo(:, 3) == 0));
      for idP = 1:length(idSensor3)
         profEco2 = a_tabDrift(driftInfo(idSensor3(idP), 1));
         
         % look for the associated CTD profile
         driftCtd = [];
         idF = find((driftInfo(:, 2) == 0) & ...
            (driftInfo(:, 4) == profEco2.cycleNumber) & ...
            (driftInfo(:, 5) == profEco2.profileNumber));
         if (length(idF) == 1)
            driftCtd = a_tabDrift(driftInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute BBP drift measurements of ECO2 sensor => BBP drift measurements set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco2.cycleNumber, ...
                  profEco2.profileNumber);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute BBP drift measurements of ECO2 sensor => BBP data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco2.cycleNumber, ...
                  profEco2.profileNumber, ...
                  length(idF));
            end
         end
         a_tabDrift(driftInfo(idSensor3(idP), 1)) = compute_drift_derived_parameters_for_ECO2( ...
            profEco2, driftCtd);
      end
      
   elseif (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
      
      % compute ECO3 derived parameters
      % V1 START
      %       idSensor3 = find((driftInfo(:, 2) == 3) & (driftInfo(:, 3) == 0));
      %       for idD = 1:length(idSensor3)
      %          a_tabDrift(driftInfo(idSensor3(idD), 1)) = compute_drift_derived_parameters_for_ECO3_V1(a_tabDrift(driftInfo(idSensor3(idD), 1)));
      %       end
      % V1 END
      idSensor3 = find((driftInfo(:, 2) == 3) & (driftInfo(:, 3) == 0));
      for idP = 1:length(idSensor3)
         profEco3 = a_tabDrift(driftInfo(idSensor3(idP), 1));
         
         % look for the associated CTD profile
         driftCtd = [];
         idF = find((driftInfo(:, 2) == 0) & ...
            (driftInfo(:, 4) == profEco3.cycleNumber) & ...
            (driftInfo(:, 5) == profEco3.profileNumber));
         if (length(idF) == 1)
            driftCtd = a_tabDrift(driftInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute BBP drift measurements of ECO3 sensor => BBP drift measurements set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco3.cycleNumber, ...
                  profEco3.profileNumber);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute BBP drift measurements of ECO3 sensor => BBP data set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  profEco3.cycleNumber, ...
                  profEco3.profileNumber, ...
                  length(idF));
            end
         end
         a_tabDrift(driftInfo(idSensor3(idP), 1)) = compute_drift_derived_parameters_for_ECO3( ...
            profEco3, driftCtd);
      end
   end
   
   % compute SUNA derived parameters
   idSensor6 = find((driftInfo(:, 2) == 6) & (driftInfo(:, 3) == 0));
   for idD = 1:length(idSensor6)
      driftCtd = [];
      driftSuna = a_tabDrift(driftInfo(idSensor6(idD), 1));
      
      % FOR PROVOR CTS4:
      % associated PTS values are provided with the NITRATE data when in "APF
      % frame"; however we use the PTS drift profile of the CTD sensor (to be
      % consistent with what is done for profile data).
      % If CTD sensor drift profile is not available, we will use (in following
      % sub-function) the NITRATE associated PTS values.
      % FOR PROVOR CTS5:
      % the CTD PTS values are provided with the SUNA data. As P values come
      % from the CTD, they differ from the SUNA measurement ones. We then
      % decided to store PTS in a dedicated drift profile
      % thus the PTS data sent with SUNA data are stored in a dedicated drift
      % profile associated to sensor number 6
      % these data are used only if CTD sensor drift profile is not available
      % (see above explanations for CTS4)
      paramNameList = {driftSuna.paramList.name};
      if (a_decoderId <= 120)
         % PROVOR CTS4 float
         % look for the CTD drift profile
         idF = find((driftInfo(:, 2) == 0) & ...
            (driftInfo(:, 4) == driftSuna.cycleNumber) & ...
            (driftInfo(:, 5) == driftSuna.profileNumber));
         if (length(idF) == 1)
            driftCtd = a_tabDrift(driftInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute NITRATE drift measurements of SUNA sensor => we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  driftSuna.cycleNumber, ...
                  driftSuna.profileNumber);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute NITRATE drift measurements of SUNA sensor => we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  driftSuna.cycleNumber, ...
                  driftSuna.profileNumber, ...
                  length(idF));
            end
         end
      else
         % PROVOR CTS5 float
         if (~isempty(find(strcmp('TEMP', paramNameList) == 1, 1)))
            % it is the PTS drift profile reported by the SUNA sensor (we stored
            % a dedicated PTS drift profile with SensorNumber = 6)
            continue % so that the next one with SensorNumber = 6 contains the NITRATE data
         end
         % look for the associated CTD drift profile
         idF = find((driftInfo(:, 2) == 0) & ...
            (driftInfo(:, 4) == driftSuna.cycleNumber) & ...
            (driftInfo(:, 5) == driftSuna.profileNumber));
         if (length(idF) == 1)
            driftCtd = a_tabDrift(driftInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute NITRATE drift measurements of SUNA sensor => we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  driftSuna.cycleNumber, ...
                  driftSuna.profileNumber);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute NITRATE drift measurements of SUNA sensor => we use SUNA PTS data to compute NITRATE\n', ...
                  g_decArgo_floatNum, ...
                  driftSuna.cycleNumber, ...
                  driftSuna.profileNumber, ...
                  length(idF));
            end
            
            % look for the SUNA associated CTD driftprofile
            idF = find((driftInfo(:, 2) == 6) & ...
               (driftInfo(:, 4) == driftSuna.cycleNumber) & ...
               (driftInfo(:, 5) == driftSuna.profileNumber));
            % idSensor6(idP) is the current drift profile (with NITRATE data)
            % idF contains all SUNA drift profiles (with NITRATE data and with
            % associated PTS)
            idF = setdiff(idF, idSensor6(idP)); % to select SUNA drift profile with associated PTS
            if (length(idF) == 1)
               driftCtd = a_tabDrift(driftInfo(idF, 1));
            else
               if (isempty(idF))
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the SUNA PTS data to compute NITRATE drift measurements of SUNA sensor => NITRATE data set to fill value\n', ...
                     g_decArgo_floatNum, ...
                     driftSuna.cycleNumber, ...
                     driftSuna.profileNumber);
               end
            end
         end
      end
      a_tabDrift(driftInfo(idSensor6(idD), 1)) = compute_drift_derived_parameters_for_SUNA( ...
         driftSuna, driftCtd, a_decoderId);
   end
   
   % compute TRANSISTOR_PH derived parameters
   idSensorPh = [];
   if (a_decoderId <= 120)
      % PROVOR CTS4 float => sensor #4
      if (ismember('TRANSISTOR_PH', g_decArgo_sensorMountedOnFloat))
         idSensorPh = find((driftInfo(:, 2) == 4) & (driftInfo(:, 3) == 0));
      end
   else
      % PROVOR CTS5 float => sensor #7
      idSensorPh = find((driftInfo(:, 2) == 7) & (driftInfo(:, 3) == 0));
   end
   for idD = 1:length(idSensorPh)
      driftTransPh = a_tabDrift(driftInfo(idSensorPh(idD), 1));
      
      % look for the associated CTD drift measurements
      driftCtd = [];
      idF = find((driftInfo(:, 2) == 0) & ...
         (driftInfo(:, 4) == driftTransPh.cycleNumber) & ...
         (driftInfo(:, 5) == driftTransPh.profileNumber));
      if (length(idF) == 1)
         driftCtd = a_tabDrift(driftInfo(idF, 1));
      else
         if (isempty(idF))
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL drift measurements of TRANSISTOR_PH sensor => PH_IN_SITU_FREE and PH_IN_SITU_TOTAL drift measurements set to fill value\n', ...
               g_decArgo_floatNum, ...
               driftTransPh.cycleNumber, ...
               driftTransPh.profileNumber);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL drift measurements of TRANSISTOR_PH sensor => PH_IN_SITU_FREE and PH_IN_SITU_TOTAL drift measurements set to fill value\n', ...
               g_decArgo_floatNum, ...
               driftTransPh.cycleNumber, ...
               driftTransPh.profileNumber, ...
               length(idF));
         end
      end
      a_tabDrift(driftInfo(idSensorPh(idD), 1)) = ...
         compute_drift_derived_parameters_for_TRANSISTOR_PH( ...
         driftTransPh, driftCtd);
   end
end

% update output parameters
o_tabDrift = a_tabDrift;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the OCR sensor.
%
% SYNTAX :
%  [o_driftOcr] = compute_drift_derived_parameters_for_OCR(a_driftOcr)
%
% INPUT PARAMETERS :
%   a_driftOcr : input OCR drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftOcr : output OCR drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftOcr] = compute_drift_derived_parameters_for_OCR(a_driftOcr)

% output parameters initialization
o_driftOcr = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the drift profile
paramNameList = {a_driftOcr.paramList.name};

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
      
      downIrr380 = compute_DOWN_IRRADIANCE380_105_to_112_121_to_125( ...
         a_driftOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftOcr.data(:, end+1) = downIrr380;
      if (isempty(a_driftOcr.dataQc))
         a_driftOcr.dataQc = ones(size(a_driftOcr.data, 1), size(a_driftOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downIrr380Qc = ones(size(a_driftOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr380Qc(find(downIrr380 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftOcr.dataQc(:, end+1) = downIrr380Qc;
      
      a_driftOcr.paramList = [a_driftOcr.paramList derivedParam];
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
      
      downIrr412 = compute_DOWN_IRRADIANCE412_105_to_112_121_to_125( ...
         a_driftOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftOcr.data(:, end+1) = downIrr412;
      if (isempty(a_driftOcr.dataQc))
         a_driftOcr.dataQc = ones(size(a_driftOcr.data, 1), size(a_driftOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downIrr412Qc = ones(size(a_driftOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr412Qc(find(downIrr412 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftOcr.dataQc(:, end+1) = downIrr412Qc;
      
      a_driftOcr.paramList = [a_driftOcr.paramList derivedParam];
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
      
      downIrr490 = compute_DOWN_IRRADIANCE490_105_to_112_121_to_125( ...
         a_driftOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftOcr.data(:, end+1) = downIrr490;
      if (isempty(a_driftOcr.dataQc))
         a_driftOcr.dataQc = ones(size(a_driftOcr.data, 1), size(a_driftOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downIrr490Qc = ones(size(a_driftOcr.data, 1), 1)*g_decArgo_qcDef;
      downIrr490Qc(find(downIrr490 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftOcr.dataQc(:, end+1) = downIrr490Qc;
      
      a_driftOcr.paramList = [a_driftOcr.paramList derivedParam];
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
      
      downPar = compute_DOWNWELLING_PAR_105_to_112_121_to_125( ...
         a_driftOcr.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftOcr.data(:, end+1) = downPar;
      if (isempty(a_driftOcr.dataQc))
         a_driftOcr.dataQc = ones(size(a_driftOcr.data, 1), size(a_driftOcr.data, 2)-1)*g_decArgo_qcDef;
      end
      downParQc = ones(size(a_driftOcr.data, 1), 1)*g_decArgo_qcDef;
      downParQc(find(downPar ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftOcr.dataQc(:, end+1) = downParQc;
      
      a_driftOcr.paramList = [a_driftOcr.paramList derivedParam];
   end
end

% update output parameters
a_driftOcr.derived = 1;
o_driftOcr = a_driftOcr;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO2 sensor.
%
% SYNTAX :
%  [o_driftEco2] = compute_drift_derived_parameters_for_ECO2( ...
%    a_driftEco2, a_driftCtd)
%
% INPUT PARAMETERS :
%   a_driftEco2 : input ECO2 drift profile structure
%   a_driftCtd  : input CTD drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftEco2 : output ECO3 drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftEco2] = compute_drift_derived_parameters_for_ECO2( ...
   a_driftEco2, a_driftCtd)

% output parameters initialization
o_driftEco2 = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftEco2.paramList.name};

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
      
      chla = compute_CHLA_105_to_112_121_to_125_1121_1322( ...
         a_driftEco2.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco2.data(:, end+1) = chla;
      if (isempty(a_driftEco2.dataQc))
         a_driftEco2.dataQc = ones(size(a_driftEco2.data, 1), size(a_driftEco2.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_driftEco2.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco2.dataQc(:, end+1) = chlaQc;
      
      a_driftEco2.paramList = [a_driftEco2.paramList derivedParam];
   end
end

if (isempty(a_driftCtd))
   
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
         a_driftEco2.data(:, end+1) = ones(size(a_driftEco2.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_driftEco2.dataQc))
            a_driftEco2.dataQc(:, end+1) = ones(size(a_driftEco2.data, 1), 1)*g_decArgo_qcDef;
         end
         a_driftEco2.paramList = [a_driftEco2.paramList derivedParam];
      end
   end
   
else
   
   % retrieve measured CTD data
   paramNameListCtd = {a_driftCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasDates = a_driftCtd.dates;
   ctdMeasData = a_driftCtd.data(:, [presId tempId psalId]);
   
   % compute BBP700 data and add them in the profile structure
   paramToDeriveList = [ ...
      {'BETA_BACKSCATTERING700'} ...
      ];
   derivedParamList = [ ...
      {'BBP700'} ...
      ];
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramPsal = get_netcdf_param_attributes('PSAL');
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         
         % compute BBP700 values
         bbp700 = compute_drift_BBP( ...
            a_driftEco2.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_driftEco2.dates, ...
            700, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftEco2);
         
         if (~isempty(bbp700))
            a_driftEco2.data(:, end+1) = bbp700;
            if (isempty(a_driftEco2.dataQc))
               a_driftEco2.dataQc = ones(size(a_driftEco2.data, 1), size(a_driftEco2.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp700Qc = ones(size(a_driftEco2.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_driftEco2.dataQc(:, end+1) = bbp700Qc;
         else
            a_driftEco2.data(:, end+1) = ones(size(a_driftEco2.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_driftEco2.dataQc))
               a_driftEco2.dataQc(:, end+1) = ones(size(a_driftEco2.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_driftEco2.paramList = [a_driftEco2.paramList derivedParam];
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
         bbp532 = compute_drift_BBP( ...
            a_driftEco2.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_driftEco2.dates, ...
            532, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftEco2);
         
         if (~isempty(bbp532))
            a_driftEco2.data(:, end+1) = bbp532;
            if (isempty(a_driftEco2.dataQc))
               a_driftEco2.dataQc = ones(size(a_driftEco2.data, 1), size(a_driftEco2.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp532Qc = ones(size(a_driftEco2.data, 1), 1)*g_decArgo_qcDef;
            bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_driftEco2.dataQc(:, end+1) = bbp532Qc;
         else
            a_driftEco2.data(:, end+1) = ones(size(a_driftEco2.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_driftEco2.dataQc))
               a_driftEco2.dataQc(:, end+1) = ones(size(a_driftEco2.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_driftEco2.paramList = [a_driftEco2.paramList derivedParam];
      end
   end
end

% update output parameters
a_driftEco2.derived = 1;
o_driftEco2 = a_driftEco2;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO3 sensor.
%
% SYNTAX :
%  [o_driftEco3] = compute_drift_derived_parameters_for_ECO3( ...
%    a_driftEco3, a_driftCtd)
%
% INPUT PARAMETERS :
%   a_driftEco3 : input ECO3 drift profile structure
%   a_driftCtd  : input CTD drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftEco3 : output ECO3 drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/08/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftEco3] = compute_drift_derived_parameters_for_ECO3( ...
   a_driftEco3, a_driftCtd)

% output parameters initialization
o_driftEco3 = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftEco3.paramList.name};

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
      
      chla = compute_CHLA_105_to_112_121_to_125_1121_1322( ...
         a_driftEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco3.data(:, end+1) = chla;
      if (isempty(a_driftEco3.dataQc))
         a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco3.dataQc(:, end+1) = chlaQc;
      
      a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
   end
end

if (isempty(a_driftCtd))
   
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
         a_driftEco3.data(:, end+1) = ones(size(a_driftEco3.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_driftEco3.dataQc))
            a_driftEco3.dataQc(:, end+1) = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
         end
         a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
      end
   end
   
else
   
   % retrieve measured CTD data
   paramNameListCtd = {a_driftCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasDates = a_driftCtd.dates;
   ctdMeasData = a_driftCtd.data(:, [presId tempId psalId]);
   
   % compute BBP700 data and add them in the profile structure
   paramToDeriveList = [ ...
      {'BETA_BACKSCATTERING700'} ...
      ];
   derivedParamList = [ ...
      {'BBP700'} ...
      ];
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramPsal = get_netcdf_param_attributes('PSAL');
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         
         % compute BBP700 values
         bbp700 = compute_drift_BBP( ...
            a_driftEco3.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_driftEco3.dates, ...
            700, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftEco3);
         
         if (~isempty(bbp700))
            a_driftEco3.data(:, end+1) = bbp700;
            if (isempty(a_driftEco3.dataQc))
               a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp700Qc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_driftEco3.dataQc(:, end+1) = bbp700Qc;
         else
            a_driftEco3.data(:, end+1) = ones(size(a_driftEco3.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_driftEco3.dataQc))
               a_driftEco3.dataQc(:, end+1) = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
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
         bbp532 = compute_drift_BBP( ...
            a_driftEco3.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_driftEco3.dates, ...
            532, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftEco3);
         
         if (~isempty(bbp532))
            a_driftEco3.data(:, end+1) = bbp532;
            if (isempty(a_driftEco3.dataQc))
               a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp532Qc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
            bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_driftEco3.dataQc(:, end+1) = bbp532Qc;
         else
            a_driftEco3.data(:, end+1) = ones(size(a_driftEco3.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_driftEco3.dataQc))
               a_driftEco3.dataQc(:, end+1) = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
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
      
      cdom = compute_CDOM_105_to_107_110_112_121_to_125_1121_1322( ...
         a_driftEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco3.data(:, end+1) = cdom;
      if (isempty(a_driftEco3.dataQc))
         a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      cdomQc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco3.dataQc(:, end+1) = cdomQc;
      
      a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
   end
end

% update output parameters
a_driftEco3.derived = 1;
o_driftEco3 = a_driftEco3;

return

% ------------------------------------------------------------------------------
% Compute BBP from the data provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_BBP] = compute_drift_BBP( ...
%    a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
%    a_BBP_fillValue, ...
%    a_BBP_dates, ...
%    a_lambda, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_driftEco3)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING           : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fillValue : fill value for input BETA_BACKSCATTERING
%                                     data
%   a_BBP_fillValue                 : fill value for output BBP data
%   a_BBP_dates                     : dates of BBP data
%   a_lambda                        : wavelength of the ECO3
%   a_ctdDates                      : dates of ascociated CTD (P, T, S) data
%   a_ctdData                       : ascociated CTD (P, T, S) data
%   a_PRES_fillValue                : fill value for input PRES data
%   a_TEMP_fillValue                : fill value for input TEMP data
%   a_PSAL_fillValue                : fill value for input PSAL data
%   a_driftEco3                     : input ECO3 drift profile structure
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
function [o_BBP] = compute_drift_BBP( ...
   a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
   a_BBP_fillValue, ...
   a_BBP_dates, ...
   a_lambda, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_driftEco3)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fillValue;


% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_BBP_dates);
if (~isempty(ctdLinkData))
   
   if (a_lambda == 700)
      o_BBP = compute_BBP700_105_to_112_121_to_125_1121_1322( ...
         a_BETA_BACKSCATTERING, ...
         a_BETA_BACKSCATTERING_fillValue, ...
         a_BBP_fillValue, ...
         ctdLinkData, ...
         a_PRES_fillValue, ...
         a_TEMP_fillValue, ...
         a_PSAL_fillValue);
   elseif (a_lambda == 532)
      o_BBP = compute_BBP532_108_109( ...
         a_BETA_BACKSCATTERING, ...
         a_BETA_BACKSCATTERING_fillValue, ...
         a_BBP_fillValue, ...
         ctdLinkData, ...
         a_PRES_fillValue, ...
         a_TEMP_fillValue, ...
         a_PSAL_fillValue);
   else
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: BBP processing not implemented yet for lambda = %g => BBP drift measurements set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_driftEco3.cycleNumber, ...
         a_driftEco3.profileNumber, ...
         a_lambda);
   end
   
end

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the ECO3 sensor.
%
% SYNTAX :
%  [o_driftEco3] = compute_drift_derived_parameters_for_ECO3(a_driftEco3)
%
% INPUT PARAMETERS :
%   a_driftEco3 : input ECO3 drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftEco3 : output ECO3 drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftEco3] = compute_drift_derived_parameters_for_ECO3_V1(a_driftEco3)

% output parameters initialization
o_driftEco3 = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the drift profile
paramNameList = {a_driftEco3.paramList.name};

% compute CHLA data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_CHLA'} ...
   ];
derivedParamList = [ ...
   {'CHLA'} ...
   ];
for idD = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idD}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idD});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idD});
      
      chla = compute_CHLA_105_to_112_121_to_125_1121_1322( ...
         a_driftEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco3.data(:, end+1) = chla;
      if (isempty(a_driftEco3.dataQc))
         a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco3.dataQc(:, end+1) = chlaQc;
      
      a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
   end
end

% compute BBP700 data and add them in the profile structure
paramToDeriveList = [ ...
   {'BETA_BACKSCATTERING700'} ...
   ];
derivedParamList = [ ...
   {'BBP700'} ...
   ];
for idD = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idD}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idD});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idD});
      
      bbp700 = compute_BBP700_105_to_112_121_to_125_1121_1322_V1( ...
         a_driftEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco3.data(:, end+1) = bbp700;
      if (isempty(a_driftEco3.dataQc))
         a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      bbp700Qc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
      bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco3.dataQc(:, end+1) = bbp700Qc;
      
      a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
   end
end

% compute BBP532 data and add them in the profile structure
paramToDeriveList = [ ...
   {'BETA_BACKSCATTERING532'} ...
   ];
derivedParamList = [ ...
   {'BBP532'} ...
   ];
for idD = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idD}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idD});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idD});
      
      bbp532 = compute_BBP532_108_109_V1( ...
         a_driftEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco3.data(:, end+1) = bbp532;
      if (isempty(a_driftEco3.dataQc))
         a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      bbp532Qc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
      bbp532Qc(find(bbp532 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco3.dataQc(:, end+1) = bbp532Qc;
      
      a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
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
      
      cdom = compute_CDOM_105_to_107_110_112_121_to_125_1121_1322( ...
         a_driftEco3.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftEco3.data(:, end+1) = cdom;
      if (isempty(a_driftEco3.dataQc))
         a_driftEco3.dataQc = ones(size(a_driftEco3.data, 1), size(a_driftEco3.data, 2)-1)*g_decArgo_qcDef;
      end
      cdomQc = ones(size(a_driftEco3.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftEco3.dataQc(:, end+1) = cdomQc;
      
      a_driftEco3.paramList = [a_driftEco3.paramList derivedParam];
   end
end

% update output parameters
a_driftEco3.derived = 1;
o_driftEco3 = a_driftEco3;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the SUNA sensor.
%
% SYNTAX :
%  [o_driftSuna] = compute_drift_derived_parameters_for_SUNA(a_driftSuna, a_driftCtd, a_decoderId)
%
% INPUT PARAMETERS :
%   a_driftSuna : input SUNA drift profile structure
%   a_driftCtd  : input CTD drift profile structure
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_driftSuna : output SUNA drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftSuna] = compute_drift_derived_parameters_for_SUNA(a_driftSuna, a_driftCtd, a_decoderId)

% output parameters initialization
o_driftSuna = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


% list of parameters of the drift profile
paramNameList = {a_driftSuna.paramList.name};

% retrieve measured CTD data
if (isempty(a_driftCtd))
   presId = find(strcmp('PRES', paramNameList) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameList) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameList) == 1, 1);
   ctdMeasDates = a_driftSuna.dates;
   ctdMeasData = a_driftSuna.data(:, [presId tempId psalId]);
else
   paramNameListCtd = {a_driftCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasDates = a_driftCtd.dates;
   ctdMeasData = a_driftCtd.data(:, [presId tempId psalId]);
end

% if the fitlm Matlab function is available, compute NITRATE data from
% transmitted spectrum and add them in the profile structure
if (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
   if (~ismember(a_decoderId, [110, 113]))
      
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
            
            nitrate = compute_drift_NITRATE_105_to_109_111_112_121_to_125( ...
               a_driftSuna.data(:, idF1:idF1+a_driftSuna.paramNumberOfSubLevels-1), ...
               a_driftSuna.data(:, idF2), ...
               paramToDerive1.fillValue, ...
               paramToDerive2.fillValue, ...
               derivedParam.fillValue, ...
               a_driftSuna.dates, ctdMeasDates, ctdMeasData, ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_driftSuna, a_decoderId);
            
            % store NITRATE
            a_driftSuna.data(:, end+1) = nitrate;
            if (isempty(a_driftSuna.dataQc))
               a_driftSuna.dataQc = ones(size(a_driftSuna.data, 1), size(a_driftSuna.data, 2)-1)*g_decArgo_qcDef;
            end
            nitrateQc = ones(size(a_driftSuna.data, 1), 1)*g_decArgo_qcDef;
            nitrateQc(find(nitrate ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_driftSuna.dataQc(:, end+1) = nitrateQc;
            
            a_driftSuna.paramList = [a_driftSuna.paramList derivedParam];
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
            
            [nitrate, bisulfide] = compute_drift_NITRATE_BISULFIDE_from_spectrum_110_113( ...
               a_driftSuna.data(:, idF1:idF1+a_driftSuna.paramNumberOfSubLevels-1), ...
               a_driftSuna.data(:, idF2), ...
               paramToDerive1.fillValue, ...
               paramToDerive2.fillValue, ...
               derivedParam1.fillValue, ...
               derivedParam2.fillValue, ...
               a_driftSuna.dates, ctdMeasDates, ctdMeasData, ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_driftSuna);
            
            % store NITRATE
            a_driftSuna.data(:, end+1) = nitrate;
            if (isempty(a_driftSuna.dataQc))
               a_driftSuna.dataQc = ones(size(a_driftSuna.data, 1), size(a_driftSuna.data, 2)-1)*g_decArgo_qcDef;
            end
            nitrateQc = ones(size(a_driftSuna.data, 1), 1)*g_decArgo_qcDef;
            nitrateQc(find(nitrate ~= derivedParam1.fillValue)) = g_decArgo_qcNoQc;
            a_driftSuna.dataQc(:, end+1) = nitrateQc;
            
            a_driftSuna.paramList = [a_driftSuna.paramList derivedParam1];
            
            % store BISULFIDE
            a_driftSuna.data(:, end+1) = bisulfide;
            if (isempty(a_driftSuna.dataQc))
               a_driftSuna.dataQc = ones(size(a_driftSuna.data, 1), size(a_driftSuna.data, 2)-1)*g_decArgo_qcDef;
            end
            bisulfideQc = ones(size(a_driftSuna.data, 1), 1)*g_decArgo_qcDef;
            bisulfideQc(find(bisulfide ~= derivedParam2.fillValue)) = g_decArgo_qcNoQc;
            a_driftSuna.dataQc(:, end+1) = bisulfideQc;
            
            a_driftSuna.paramList = [a_driftSuna.paramList derivedParam2];
         end
      end
   end
else
   
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
   for idD = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idD}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idD});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idD});
         
         nitrate = compute_drift_NITRATE_from_MOLAR_105_to_109_111_112_121_to_125( ...
            a_driftSuna.data(:, idF), ...
            paramToDerive.fillValue, derivedParam.fillValue, ...
            a_driftSuna.dates, ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue);
         
         a_driftSuna.data(:, end+1) = nitrate;
         if (isempty(a_driftSuna.dataQc))
            a_driftSuna.dataQc = ones(size(a_driftSuna.data, 1), size(a_driftSuna.data, 2)-1)*g_decArgo_qcDef;
         end
         nitrateQc = ones(size(a_driftSuna.data, 1), 1)*g_decArgo_qcDef;
         nitrateQc(find(nitrate ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
         a_driftSuna.dataQc(:, end+1) = nitrateQc;
         
         a_driftSuna.paramList = [a_driftSuna.paramList derivedParam];
      end
   end
end

% update output parameters
a_driftSuna.derived = 1;
o_driftSuna = a_driftSuna;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the OPTODE sensor.
%
% SYNTAX :
%  [o_driftOptode] = compute_drift_derived_parameters_for_OPTODE( ...
%    a_driftOptode, a_driftCtd, a_decoderId)
%
% INPUT PARAMETERS :
%   a_driftOptode : input OPTODE drift profile structure
%   a_driftCtd    : input CTD drift profile structure
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_driftOptode : output OPTODE drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftOptode] = compute_drift_derived_parameters_for_OPTODE( ...
   a_driftOptode, a_driftCtd, a_decoderId)

% output parameters initialization
o_driftOptode = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the drift profile
paramNameList = {a_driftOptode.paramList.name};

if (isempty(a_driftCtd))
   
   % we have not been able to retrieve the associated CTD profile
   if (ismember('C1PHASE_DOXY', paramNameList) && ...
         ismember('C2PHASE_DOXY', paramNameList) && ...
         ismember('TEMP_DOXY', paramNameList))
      derivedParamList = [ ...
         {'DOXY'} ...
         ];
      for idP = 1:length(derivedParamList)
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         a_driftOptode.data(:, end+1) = ones(size(a_driftOptode.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_driftOptode.dataQc))
            a_driftOptode.dataQc(:, end+1) = ones(size(a_driftOptode.data, 1), 1)*g_decArgo_qcDef;
         end
         a_driftOptode.paramList = [a_driftOptode.paramList derivedParam];
      end
   end
else
   
   % retrieve measured CTD data
   paramNameListCtd = {a_driftCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasDates = a_driftCtd.dates;
   ctdMeasData = a_driftCtd.data(:, [presId tempId psalId]);
   
   % compute DOXY data and add them in the profile structure
   paramToDeriveList = [ ...
      {'C1PHASE_DOXY'} {'C2PHASE_DOXY'} {'TEMP_DOXY'} ...
      ];
   derivedParamList = [ ...
      {'DOXY'} ...
      ];
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramPsal = get_netcdf_param_attributes('PSAL');
   for idD = 1:size(paramToDeriveList, 1)
      idF1 = find(strcmp(paramToDeriveList{idD, 1}, paramNameList) == 1, 1);
      idF2 = find(strcmp(paramToDeriveList{idD, 2}, paramNameList) == 1, 1);
      idF3 = find(strcmp(paramToDeriveList{idD, 3}, paramNameList) == 1, 1);
      if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
         paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idD, 1});
         paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idD, 2});
         paramToDerive3 = get_netcdf_param_attributes(paramToDeriveList{idD, 3});
         derivedParam = get_netcdf_param_attributes(derivedParamList{idD});
         
         % compute DOXY values
         doxy = compute_drift_DOXY( ...
            a_driftOptode.data(:, idF1), ...
            a_driftOptode.data(:, idF2), ...
            a_driftOptode.data(:, idF3), ...
            paramToDerive1.fillValue, ...
            paramToDerive2.fillValue, ...
            paramToDerive3.fillValue, ...
            derivedParam.fillValue, ...
            a_driftOptode.dates, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftOptode, a_decoderId);
         
         a_driftOptode.data(:, end+1) = doxy;
         if (isempty(a_driftOptode.dataQc))
            a_driftOptode.dataQc = ones(size(a_driftOptode.data, 1), size(a_driftOptode.data, 2)-1)*g_decArgo_qcDef;
         end
         doxyQc = ones(size(a_driftOptode.data, 1), 1)*g_decArgo_qcDef;
         doxyQc(find(doxy ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
         a_driftOptode.dataQc(:, end+1) = doxyQc;
         
         a_driftOptode.paramList = [a_driftOptode.paramList derivedParam];
      end
   end
end

% update output parameters
a_driftOptode.derived = 1;
o_driftOptode = a_driftOptode;

return

% ------------------------------------------------------------------------------
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_drift_DOXY( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_DOXY_fillValue, ...
%    a_DOXY_dates, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_driftOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY           : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY           : input C2PHASE_DOXY data
%   a_TEMP_DOXY              : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fillValue : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fillValue : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fillValue    : fill value for input TEMP_DOXY data
%   a_DOXY_fillValue         : fill value for output DOXY data
%   a_DOXY_dates             : dates of DOXY data
%   a_ctdDates               : dates of ascociated CTD (P, T, S) data
%   a_ctdData                : ascociated CTD (P, T, S) data
%   a_PRES_fillValue         : fill value for input PRES data
%   a_TEMP_fillValue         : fill value for input TEMP data
%   a_PSAL_fillValue         : fill value for input PSAL data
%   a_driftOptode            : input OPTODE drift profile structure
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_DOXY    : output drift DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_drift_DOXY( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_DOXY_fillValue, ...
   a_DOXY_dates, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_driftOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;


% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_DOXY_dates);
if (~isempty(ctdLinkData))
   
   switch (a_decoderId)
      
      case {106}
         
         % compute DOXY values using the Aanderaa standard calibration method
         o_DOXY = compute_DOXY_106_301( ...
            a_C1PHASE_DOXY, ...
            a_C2PHASE_DOXY, ...
            a_TEMP_DOXY, ...
            a_C1PHASE_DOXY_fillValue, ...
            a_C2PHASE_DOXY_fillValue, ...
            a_TEMP_DOXY_fillValue, ...
            ctdLinkData(:, 1), ...
            ctdLinkData(:, 2), ...
            ctdLinkData(:, 3), ...
            a_PRES_fillValue, ...
            a_TEMP_fillValue, ...
            a_PSAL_fillValue, ...
            a_DOXY_fillValue, ...
            a_driftOptode);
         
      case {107, 109, 110, 111, 113, 121, 122, 124}
         
         % compute DOXY values using the Stern-Volmer equation
         o_DOXY = compute_DOXY_107_109_to_111_113_121_122_124( ...
            a_C1PHASE_DOXY, ...
            a_C2PHASE_DOXY, ...
            a_TEMP_DOXY, ...
            a_C1PHASE_DOXY_fillValue, ...
            a_C2PHASE_DOXY_fillValue, ...
            a_TEMP_DOXY_fillValue, ...
            ctdLinkData(:, 1), ...
            ctdLinkData(:, 2), ...
            ctdLinkData(:, 3), ...
            a_PRES_fillValue, ...
            a_TEMP_fillValue, ...
            a_PSAL_fillValue, ...
            a_DOXY_fillValue, ...
            a_driftOptode);
         
      case {112, 123, 125}
         
         % compute DOXY values using the Aanderaa standard calibration method
         % + an additional two-point adjustment
         o_DOXY(idNoNan) = compute_DOXY_112_123_125( ...
            a_C1PHASE_DOXY, ...
            a_C2PHASE_DOXY, ...
            a_TEMP_DOXY, ...
            a_C1PHASE_DOXY_fillValue, ...
            a_C2PHASE_DOXY_fillValue, ...
            a_TEMP_DOXY_fillValue, ...
            ctdLinkData(:, 1), ...
            ctdLinkData(:, 2), ...
            ctdLinkData(:, 3), ...
            a_PRES_fillValue, ...
            a_TEMP_fillValue, ...
            a_PSAL_fillValue, ...
            a_DOXY_fillValue, ...
            a_driftOptode);
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d => DOXY drift measurements set to fill value\n', ...
            g_decArgo_floatNum, ...
            a_driftOptode.cycleNumber, ...
            a_driftOptode.profileNumber, ...
            a_decoderId);
         
   end
end

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the TRANSISTOR_PH sensor.
%
% SYNTAX :
%  [o_driftTransPh] = compute_drift_derived_parameters_for_TRANSISTOR_PH( ...
%    a_driftTRansPh, a_driftCtd)
%
% INPUT PARAMETERS :
%   a_driftTRansPh : input TRANSISTOR_PH drift profile structure
%   a_driftCtd     : input CTD drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftTransPh : output TRANSISTOR_PH drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/11/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftTransPh] = compute_drift_derived_parameters_for_TRANSISTOR_PH( ...
   a_driftTRansPh, a_driftCtd)

% output parameters initialization
o_driftTransPh = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftTRansPh.paramList.name};

if (isempty(a_driftCtd))
   
   % we have not been able to retrieve the associated CTD profile
   if (ismember('VRS_PH', paramNameList))
      derivedParamList = [ ...
         {'PH_IN_SITU_FREE'} ...
         {'PH_IN_SITU_TOTAL'} ...
         ];
      for idP = 1:length(derivedParamList)
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         a_driftTRansPh.data(:, end+1) = ones(size(a_driftTRansPh.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_driftTRansPh.dataQc))
            a_driftTRansPh.dataQc(:, end+1) = ones(size(a_driftTRansPh.data, 1), 1)*g_decArgo_qcDef;
         end
         a_driftTRansPh.paramList = [a_driftTRansPh.paramList derivedParam];
      end
   end
   
else
   
   % retrieve measured CTD data
   paramNameListCtd = {a_driftCtd.paramList.name};
   presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
   tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
   psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
   ctdMeasDates = a_driftCtd.dates;
   ctdMeasData = a_driftCtd.data(:, [presId tempId psalId]);

   % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data and add them in the
   % profile structure
   paramToDeriveList = [ ...
      {'VRS_PH'} ...
      ];
   derivedParamList = [ ...
      {'PH_IN_SITU_FREE'} ...
      {'PH_IN_SITU_TOTAL'} ...
      ];
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramPsal = get_netcdf_param_attributes('PSAL');
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
         derivedParam1 = get_netcdf_param_attributes(derivedParamList{idP, 1});
         derivedParam2 = get_netcdf_param_attributes(derivedParamList{idP, 2});
         
         % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL values
         [phInSituFree, phInSituTotal] = compute_drift_PH( ...
            a_driftTRansPh.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam1.fillValue, ...
            derivedParam2.fillValue, ...
            a_driftTRansPh.dates, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftTRansPh);
         
         % for CTS5 floats the derived parameter could be already in the list of
         % parameters => we should first look for it
         
         idFDerivedParam1 = find(strcmp({a_driftTRansPh.paramList.name}, derivedParamList{idP, 1}), 1);
         if (isempty(idFDerivedParam1))
            a_driftTRansPh.data(:, end+1) = ones(size(a_driftTRansPh.data, 1), 1)*derivedParam1.fillValue;
            if (isempty(a_driftTRansPh.dataQc))
               a_driftTRansPh.dataQc = ones(size(a_driftTRansPh.data))*g_decArgo_qcDef;
            else
               a_driftTRansPh.dataQc(:, end+1) = ones(size(a_driftTRansPh.data, 1), 1)*g_decArgo_qcDef;
            end
            a_driftTRansPh.paramList = [a_driftTRansPh.paramList derivedParam1];
            derivedParam1Id = size(a_driftTRansPh.data, 2);
         else
            if (isempty(a_driftTRansPh.paramNumberWithSubLevels))
               derivedParam1Id = idFDerivedParam1;
            else
               idF = find(a_driftTRansPh.paramNumberWithSubLevels < idFDerivedParam1);
               if (isempty(idF))
                  derivedParam1Id = idFDerivedParam1;
               else
                  derivedParam1Id = idFDerivedParam1 + sum(a_driftTRansPh.paramNumberOfSubLevels(idF)) - length(idF);
               end
            end
         end
         
         idFDerivedParam2 = find(strcmp({a_driftTRansPh.paramList.name}, derivedParamList{idP, 2}), 1);
         if (isempty(idFDerivedParam2))
            a_driftTRansPh.data(:, end+1) = ones(size(a_driftTRansPh.data, 1), 1)*derivedParam2.fillValue;
            if (isempty(a_driftTRansPh.dataQc))
               a_driftTRansPh.dataQc = ones(size(a_driftTRansPh.data))*g_decArgo_qcDef;
            else
               a_driftTRansPh.dataQc(:, end+1) = ones(size(a_driftTRansPh.data, 1), 1)*g_decArgo_qcDef;
            end
            a_driftTRansPh.paramList = [a_driftTRansPh.paramList derivedParam2];
            derivedParam2Id = size(a_driftTRansPh.data, 2);
         else
            if (isempty(a_driftTRansPh.paramNumberWithSubLevels))
               derivedParam2Id = idFDerivedParam2;
            else
               idF = find(a_driftTRansPh.paramNumberWithSubLevels < idFDerivedParam2);
               if (isempty(idF))
                  derivedParam2Id = idFDerivedParam2;
               else
                  derivedParam2Id = idFDerivedParam2 + sum(a_driftTRansPh.paramNumberOfSubLevels(idF)) - length(idF);
               end
            end
         end
         
         if (~isempty(phInSituFree))
            a_driftTRansPh.data(:, derivedParam1Id) = phInSituFree;
            phInSituFreeQc = ones(size(a_driftTRansPh.data, 1), 1)*g_decArgo_qcDef;
            phInSituFreeQc(find(phInSituFree ~= derivedParam1.fillValue)) = g_decArgo_qcNoQc;
            a_driftTRansPh.dataQc(:, derivedParam1Id) = phInSituFreeQc;
         end
         
         if (~isempty(phInSituTotal))
            a_driftTRansPh.data(:, derivedParam2Id) = phInSituTotal;
            phInSituFreeQc = ones(size(a_driftTRansPh.data, 1), 1)*g_decArgo_qcDef;
            phInSituFreeQc(find(phInSituTotal ~= derivedParam2.fillValue)) = g_decArgo_qcNoQc;
            a_driftTRansPh.dataQc(:, derivedParam2Id) = phInSituFreeQc;
         end
      end
   end
end

% update output parameters
a_driftTRansPh.derived = 1;
o_driftTransPh = a_driftTRansPh;

return

% ------------------------------------------------------------------------------
% Compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL from the data provided by the
% TRANSISTOR_PH sensor.
%
% SYNTAX :
%  [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_drift_PH( ...
%    a_VRS_PH, ...
%    a_VRS_PH_fillValue, ...
%    a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue, ...
%    a_VRS_PH_dates, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_driftTransPh)
%
% INPUT PARAMETERS :
%   a_VRS_PH                     : input VRS_PH data
%   a_VRS_PH_fillValue           : fill value for input VRS_PH data
%   a_PH_IN_SITU_FREE_fillValue  : fill value for output PH_IN_SITU_FREE data
%   a_PH_IN_SITU_TOTAL_fillValue : fill value for output PH_IN_SITU_TOTAL data
%   a_VRS_PH_dates               : dates of VRS_PH data
%   a_ctdDates                   : dates of ascociated CTD (P, T, S) data
%   a_ctdData                    : ascociated CTD (P, T, S) data
%   a_PRES_fillValue             : fill value for input PRES data
%   a_TEMP_fillValue             : fill value for input TEMP data
%   a_PSAL_fillValue             : fill value for input PSAL data
%   a_driftTransPh               : input TRANSISTOR_PH drift profile structure
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
%   06/11/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_drift_PH( ...
   a_VRS_PH, ...
   a_VRS_PH_fillValue, ...
   a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue, ...
   a_VRS_PH_dates, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_driftTransPh)

% output parameters initialization
o_PH_IN_SITU_FREE = ones(length(a_VRS_PH), 1)*a_PH_IN_SITU_FREE_fillValue;
o_PH_IN_SITU_TOTAL = ones(length(a_VRS_PH), 1)*a_PH_IN_SITU_TOTAL_fillValue;


% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_VRS_PH_dates);
if (~isempty(ctdLinkData))
   
   % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL values
   [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_PH_111_113_123( ...
      a_VRS_PH, ...
      a_VRS_PH_fillValue, ...
      ctdLinkData(:, 1), ...
      ctdLinkData(:, 2), ...
      ctdLinkData(:, 3), ...
      a_PRES_fillValue, ...
      a_TEMP_fillValue, ...
      a_PSAL_fillValue, ...
      a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue, ...
      a_driftTransPh);
end

return
