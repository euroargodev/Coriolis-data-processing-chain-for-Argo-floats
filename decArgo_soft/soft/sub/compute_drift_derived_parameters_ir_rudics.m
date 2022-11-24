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
      profCtd = [];
      idF = find((driftInfo(:, 2) == 0) & ...
         (driftInfo(:, 4) == profEco3.cycleNumber) & ...
         (driftInfo(:, 5) == profEco3.profileNumber));
      if (length(idF) == 1)
         profCtd = a_tabDrift(driftInfo(idF, 1));
      else
         if (isempty(idF))
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute BBP drift measurements of ECO3 sensor => BBP drift measurements set to fill value\n', ...
               g_decArgo_floatNum, ...
               profEco3.cycleNumber, ...
               profEco3.profileNumber, ...
               profEco3.direction);
         else
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute BBP drift measurements of ECO3 sensor => BBP data set to fill value\n', ...
               g_decArgo_floatNum, ...
               profEco3.cycleNumber, ...
               profEco3.profileNumber, ...
               length(idF), ...
               profEco3.direction);
         end
      end
      a_tabDrift(driftInfo(idSensor3(idP), 1)) = compute_drift_derived_parameters_for_ECO3( ...
         profEco3, profCtd);
   end
   
   % compute SUNA derived parameters
   idSensor6 = find((driftInfo(:, 2) == 6) & (driftInfo(:, 3) == 0));
   for idD = 1:length(idSensor6)
      driftCtd = [];
      driftSuna = a_tabDrift(driftInfo(idSensor6(idD), 1));
      % the CTD PTS values are provided with the data when in "APF frame" mode
      % if we are not in "APF frame" mode, we need the associated CTD drift
      % measurement profile
      % (for better reliability, we prefer to check the "APF frame" mode from
      % the received data than from the SUNA configuration)
      paramNameList = {driftSuna.paramList.name};
      if (isempty(find(strcmp('TEMP', paramNameList) == 1, 1)))
         % look for the associated CTD drift measurement profile
         idF = find((driftInfo(:, 2) == 0) & ...
            (driftInfo(:, 4) == driftSuna.cycleNumber) & ...
            (driftInfo(:, 5) == driftSuna.profileNumber));
         if (length(idF) == 1)
            driftCtd = a_tabDrift(driftInfo(idF, 1));
         else
            if (isempty(idF))
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute NITRATE drift measurements of SUNA sensor => NITRATE drift measurements set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  driftSuna.cycleNumber, ...
                  driftSuna.profileNumber);
            else
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute NITRATE drift measurements of SUNA sensor => NITRATE drift measurements set to fill value\n', ...
                  g_decArgo_floatNum, ...
                  driftSuna.cycleNumber, ...
                  driftSuna.profileNumber, ...
                  length(idF));
            end
         end
      end
      a_tabDrift(driftInfo(idSensor6(idD), 1)) = compute_drift_derived_parameters_for_SUNA( ...
         driftSuna, driftCtd);
   end
end

% update output parameters
o_tabDrift = a_tabDrift;

return;

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
      
      downIrr380 = compute_DOWN_IRRADIANCE380_105_to_109( ...
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
      
      downIrr412 = compute_DOWN_IRRADIANCE412_105_to_109( ...
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
      
      downIrr490 = compute_DOWN_IRRADIANCE490_105_to_109( ...
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
      
      downPar = compute_DOWNWELLING_PAR_105_to_109( ...
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

return;

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
      
      chla = compute_CHLA_105_to_109( ...
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
      
      cdom = compute_CDOM_105_to_107( ...
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

return;

% ------------------------------------------------------------------------------
% Compute BBP from the data provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_BBP] = compute_drift_BBP( ...
%    a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fill_value, ...
%    a_BBP_fill_value, ...
%    a_BBP_dates, ...
%    a_lambda, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
%    a_driftEco3)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING            : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fill_value : fill value for input BETA_BACKSCATTERING
%                                      data
%   a_BBP_fill_value                 : fill value for output BBP data
%   a_BBP_dates                      : dates of BBP data
%   a_lambda                         : wavelength of the ECO3
%   a_ctdDates                       : dates of ascociated CTD (P, T, S) data
%   a_ctdData                        : ascociated CTD (P, T, S) data
%   a_PRES_fill_value                : fill value for input PRES data
%   a_TEMP_fill_value                : fill value for input TEMP data
%   a_PSAL_fill_value                : fill value for input PSAL data
%   a_driftEco3                      : input ECO3 drift profile structure
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
   a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fill_value, ...
   a_BBP_fill_value, ...
   a_BBP_dates, ...
   a_lambda, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, ...
   a_driftEco3)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fill_value;


% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_BBP_dates);
if (~isempty(ctdLinkData))   
      
   if (a_lambda == 700)
      o_BBP = compute_BBP700_105_to_109( ...
         a_BETA_BACKSCATTERING, ...
         a_BETA_BACKSCATTERING_fill_value, ...
         a_BBP_fill_value, ...
         ctdLinkData, ...
         a_PRES_fill_value, ...
         a_TEMP_fill_value, ...
         a_PSAL_fill_value);
   elseif (a_lambda == 532)
      o_BBP = compute_BBP532_108_109( ...
         a_BETA_BACKSCATTERING, ...
         a_BETA_BACKSCATTERING_fill_value, ...
         a_BBP_fill_value, ...
         ctdLinkData, ...
         a_PRES_fill_value, ...
         a_TEMP_fill_value, ...
         a_PSAL_fill_value);
   else
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: BBP processing not implemented yet for lambda = %g => BBP drift measurements set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_driftEco3.cycleNumber, ...
         a_driftEco3.profileNumber, ...
         a_lambda);
   end
   
end

return;

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

      chla = compute_CHLA_105_to_109( ...
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
      
      bbp700 = compute_BBP700_105_to_109_V1( ...
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
      
      cdom = compute_CDOM_105_to_107( ...
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

return;

% ------------------------------------------------------------------------------
% Compute derived parameters for the SUNA sensor.
%
% SYNTAX :
%  [o_driftSuna] = compute_drift_derived_parameters_for_SUNA(a_driftSuna, a_driftCtd)
%
% INPUT PARAMETERS :
%   a_driftSuna : input SUNA drift profile structure
%   a_driftCtd  : input CTD drift profile structure
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
function [o_driftSuna] = compute_drift_derived_parameters_for_SUNA(a_driftSuna, a_driftCtd)

% output parameters initialization
o_driftSuna = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

WAITING_FOR_FITLM_MATLAB_FUNCTION = 1;


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

% compute NITRATE data and add them in the profile structure
if (WAITING_FOR_FITLM_MATLAB_FUNCTION)
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
         
         nitrate = compute_drift_NITRATE_105_to_109( ...
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

% compute NITRATE data and add them in the profile structure
if (~WAITING_FOR_FITLM_MATLAB_FUNCTION)
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
         
         nitrate = compute_drift_NITRATE_BIS_105_to_109( ...
            a_driftSuna.data(:, idF1:idF1+a_driftSuna.paramNumberOfSubLevels-1), ...
            a_driftSuna.data(:, idF2), ...
            paramToDerive1.fillValue, ...
            paramToDerive2.fillValue, ...
            derivedParam.fillValue, ...
            a_driftSuna.dates, ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftSuna);
         
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

return;

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

return;

% ------------------------------------------------------------------------------
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_drift_DOXY( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, a_TEMP_DOXY_fill_value, ...
%    a_DOXY_fill_value, ...
%    a_DOXY_dates, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fill_value, a_PSAL_fill_value, ...
%    a_driftOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY            : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY            : input C2PHASE_DOXY data
%   a_TEMP_DOXY               : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fill_value : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fill_value : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fill_value    : fill value for input TEMP_DOXY data
%   a_DOXY_fill_value         : fill value for output DOXY data
%   a_DOXY_dates              : dates of DOXY data
%   a_ctdDates                : dates of ascociated CTD (P, T, S) data
%   a_ctdData                 : ascociated CTD (P, T, S) data
%   a_PRES_fill_value         : fill value for input PRES data
%   a_PSAL_fill_value         : fill value for input PSAL data
%   a_driftOptode             : input OPTODE drift profile structure
%   a_decoderId               : float decoder Id
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
   a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, a_TEMP_DOXY_fill_value, ...
   a_DOXY_fill_value, ...
   a_DOXY_dates, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fill_value, a_PSAL_fill_value, ...
   a_driftOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fill_value;

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
            a_C1PHASE_DOXY_fill_value, ...
            a_C2PHASE_DOXY_fill_value, ...
            a_TEMP_DOXY_fill_value, ...
            a_DOXY_fill_value, ...
            ctdLinkData(:, [1 3]), ...
            a_PRES_fill_value, ...
            a_PSAL_fill_value, ...
            a_driftOptode);
         
      case {107, 109}
         
         % compute DOXY values using the Stern-Volmer equation
         o_DOXY = compute_DOXY_107_109( ...
            a_C1PHASE_DOXY, ...
            a_C2PHASE_DOXY, ...
            a_TEMP_DOXY, ...
            a_C1PHASE_DOXY_fill_value, ...
            a_C2PHASE_DOXY_fill_value, ...
            a_TEMP_DOXY_fill_value, ...
            a_DOXY_fill_value, ...
            ctdLinkData(:, [1 3]), ...
            a_PRES_fill_value, ...
            a_PSAL_fill_value, ...
            a_driftOptode);
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY processing not implemented yet for decoderId #%d => DOXY drift measurements set to fill value\n', ...
            g_decArgo_floatNum, ...
            a_driftOptode.cycleNumber, ...
            a_driftOptode.profileNumber, ...
            a_decoderId);

   end
end
               
return;
