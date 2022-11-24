% ------------------------------------------------------------------------------
% Compute drift derived parameters and add them in the drift measurements 
% profile structures.
%
% SYNTAX :
%  [o_tabDrift] = compute_drift_derived_parameters_ir_sbd2(a_tabDrift, a_decoderId)
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabDrift] = compute_drift_derived_parameters_ir_sbd2(a_tabDrift, a_decoderId)

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
      a_tabDrift(driftInfo(idSensor1(idD), 1)) = ...
         compute_drift_derived_parameters_for_OPTODE(driftOptode, driftCtd, a_decoderId);
   end
   
   switch (a_decoderId)
      case {301}
         
         % compute FLBB derived parameters
         idSensor4 = find((driftInfo(:, 2) == 4) & (driftInfo(:, 3) == 0));
         for idP = 1:length(idSensor4)
            profFlbb = a_tabDrift(driftInfo(idSensor4(idP), 1));
            
            % look for the associated CTD profile
            profCtd = [];
            idF = find((driftInfo(:, 2) == 0) & ...
               (driftInfo(:, 4) == profFlbb.cycleNumber) & ...
               (driftInfo(:, 5) == profFlbb.profileNumber));
            if (length(idF) == 1)
               profCtd = a_tabDrift(driftInfo(idF, 1));
            else
               if (isempty(idF))
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD drift measurement profile to compute BBP drift measurements of FLBB sensor => BBP drift measurements set to fill value\n', ...
                     g_decArgo_floatNum, ...
                     profFlbb.cycleNumber, ...
                     profFlbb.profileNumber);
               else
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD drift measurement profiles have been found to compute BBP drift measurements of FLBB sensor => BBP data set to fill value\n', ...
                     g_decArgo_floatNum, ...
                     profFlbb.cycleNumber, ...
                     profFlbb.profileNumber, ...
                     length(idF));
               end
            end
            a_tabDrift(driftInfo(idSensor4(idP), 1)) = ...
               compute_drift_derived_parameters_for_FLBB(profFlbb, profCtd);
         end
         
      case {302}
         
         % compute FLNTU derived parameters
         idSensor4 = find((driftInfo(:, 2) == 4) & (driftInfo(:, 3) == 0));
         for idP = 1:length(idSensor4)
            profFlntu = a_tabDrift(driftInfo(idSensor4(idP), 1));
            a_tabDrift(driftInfo(idSensor4(idP), 1)) = ...
               compute_drift_derived_parameters_for_FLNTU(profFlntu);
         end
         
      case {303}
         
         % compute FLNTU derived parameters
         idSensor4 = find((driftInfo(:, 2) == 4) & (driftInfo(:, 3) == 0));
         for idP = 1:length(idSensor4)
            profFlntu = a_tabDrift(driftInfo(idSensor4(idP), 1));
            a_tabDrift(driftInfo(idSensor4(idP), 1)) = ...
               compute_drift_derived_parameters_for_FLNTU(profFlntu);
         end
         
         % compute CYCLOPS derived parameters
         fprintf('INFO: Float #%d Cycle #%d Profile #%d: drift CHLA measurements not computed for CYCLOPS sensor\n', ...
            g_decArgo_floatNum, ...
            profFlntu.cycleNumber, ...
            profFlntu.profileNumber);
         if (0)
            idSensor7 = find((driftInfo(:, 2) == 7) & (driftInfo(:, 3) == 0));
            for idP = 1:length(idSensor7)
               profCyc = a_tabDrift(driftInfo(idSensor7(idP), 1));
               a_tabDrift(driftInfo(idSensor7(idP), 1)) = ...
                  compute_drift_derived_parameters_for_CYCLOPS(profCyc);
            end
         end
         
         % compute SEAPOINT derived parameters
         fprintf('INFO: Float #%d Cycle #%d Profile #%d: drift TURBIDITY measurements not computed for SEAPOINT sensor\n', ...
            g_decArgo_floatNum, ...
            profFlntu.cycleNumber, ...
            profFlntu.profileNumber);
         if (0)
            idSensor8 = find((driftInfo(:, 2) == 8) & (driftInfo(:, 3) == 0));
            for idP = 1:length(idSensor8)
               profStm = a_tabDrift(driftInfo(idSensor8(idP), 1));
               a_tabDrift(driftInfo(idSensor8(idP), 1)) = ...
                  compute_drift_derived_parameters_for_SEAPOINT(profStm);
            end
         end
   end
end

% update output parameters
o_tabDrift = a_tabDrift;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the FLBB sensor.
%
% SYNTAX :
%  [o_driftFlbb] = compute_drift_derived_parameters_for_FLBB( ...
%    a_driftFlbb, a_driftCtd)
%
% INPUT PARAMETERS :
%   a_driftFlbb : input FLBB drift profile structure
%   a_driftCtd  : input CTD drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftFlbb : output FLBB drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftFlbb] = compute_drift_derived_parameters_for_FLBB( ...
   a_driftFlbb, a_driftCtd)

% output parameters initialization
o_driftFlbb = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftFlbb.paramList.name};

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
      
      chla = compute_CHLA_301_1015_1101_1105_1110_1111_1112( ...
         a_driftFlbb.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftFlbb.data(:, end+1) = chla;
      if (isempty(a_driftFlbb.dataQc))
         a_driftFlbb.dataQc = ones(size(a_driftFlbb.data, 1), size(a_driftFlbb.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_driftFlbb.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftFlbb.dataQc(:, end+1) = chlaQc;
      
      a_driftFlbb.paramList = [a_driftFlbb.paramList derivedParam];
   end
end

if (isempty(a_driftCtd))
   
   % we have not been able to retrieve the associated CTD profile
   paramToDeriveList = [ ...
      {'BETA_BACKSCATTERING700'} ...
      ];
   derivedParamList = [ ...
      {'BBP700'} ...
      ];
   for idP = 1:length(paramToDeriveList)
      idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
      if (~isempty(idF))
         derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
         a_driftFlbb.data(:, end+1) = ones(size(a_driftFlbb.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_driftFlbb.dataQc))
            a_driftFlbb.dataQc(:, end+1) = ones(size(a_driftFlbb.data, 1), 1)*g_decArgo_qcDef;
         end
         a_driftFlbb.paramList = [a_driftFlbb.paramList derivedParam];
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
            a_driftFlbb.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_driftFlbb.dates, ...
            700, ...
            ctdMeasDates, ctdMeasData, ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue, ...
            a_driftFlbb);
         
         if (~isempty(bbp700))
            a_driftFlbb.data(:, end+1) = bbp700;
            if (isempty(a_driftFlbb.dataQc))
               a_driftFlbb.dataQc = ones(size(a_driftFlbb.data, 1), size(a_driftFlbb.data, 2)-1)*g_decArgo_qcDef;
            end
            bbp700Qc = ones(size(a_driftFlbb.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_driftFlbb.dataQc(:, end+1) = bbp700Qc;
         else
            a_driftFlbb.data(:, end+1) = ones(size(a_driftFlbb.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_driftFlbb.dataQc))
               a_driftFlbb.dataQc(:, end+1) = ones(size(a_driftFlbb.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_driftFlbb.paramList = [a_driftFlbb.paramList derivedParam];
      end
   end
end

% update output parameters
a_driftFlbb.derived = 1;
o_driftFlbb = a_driftFlbb;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the FLNTU sensor.
%
% SYNTAX :
%  [o_driftFlntu] = compute_drift_derived_parameters_for_FLNTU(a_driftFlntu)
%
% INPUT PARAMETERS :
%   o_driftFlntu : input FLNTU drift profile structure
%
% OUTPUT PARAMETERS :
%   a_driftFlntu : output FLNTU drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftFlntu] = compute_drift_derived_parameters_for_FLNTU(a_driftFlntu)

% output parameters initialization
o_driftFlntu = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftFlntu.paramList.name};

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
      
      chla = compute_CHLA_302_303_1014( ...
         a_driftFlntu.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftFlntu.data(:, end+1) = chla;
      if (isempty(a_driftFlntu.dataQc))
         a_driftFlntu.dataQc = ones(size(a_driftFlntu.data, 1), size(a_driftFlntu.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_driftFlntu.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftFlntu.dataQc(:, end+1) = chlaQc;
      
      a_driftFlntu.paramList = [a_driftFlntu.paramList derivedParam];
   end
end

% compute TURBIDITY data and add them in the profile structure
paramToDeriveList = [ ...
   {'SIDE_SCATTERING_TURBIDITY'} ...
   ];
derivedParamList = [ ...
   {'TURBIDITY'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      turbi = compute_TURBIDITY_302_303_1014( ...
         a_driftFlntu.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftFlntu.data(:, end+1) = turbi;
      if (isempty(a_driftFlntu.dataQc))
         a_driftFlntu.dataQc = ones(size(a_driftFlntu.data, 1), size(a_driftFlntu.data, 2)-1)*g_decArgo_qcDef;
      end
      turbiQc = ones(size(a_driftFlntu.data, 1), 1)*g_decArgo_qcDef;
      turbiQc(find(turbi ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftFlntu.dataQc(:, end+1) = turbiQc;
      
      a_driftFlntu.paramList = [a_driftFlntu.paramList derivedParam];
   end
end

% update output parameters
a_driftFlntu.derived = 1;
o_driftFlntu = a_driftFlntu;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the CYCLOPS sensor.
%
% SYNTAX :
%  [o_driftCyc] = compute_drift_derived_parameters_for_CYCLOPS(a_driftCyc)
%
% INPUT PARAMETERS :
%   a_driftCyc : input CYCLOPS drift profile structure
%
% OUTPUT PARAMETERS :
%   o_driftCyc : output CYCLOPS drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftCyc] = compute_drift_derived_parameters_for_CYCLOPS(a_driftCyc)

% output parameters initialization
o_driftCyc = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftCyc.paramList.name};

% compute CHLA data and add them in the profile structure
paramToDeriveList = [ ...
   {'FLUORESCENCE_VOLTAGE_CHLA'} ...
   ];
derivedParamList = [ ...
   {'CHLA2'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      chla = compute_CHLA_CYCLOPS_303( ...
         a_driftCyc.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftCyc.data(:, end+1) = chla;
      if (isempty(a_driftCyc.dataQc))
         a_driftCyc.dataQc = ones(size(a_driftCyc.data, 1), size(a_driftCyc.data, 2)-1)*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_driftCyc.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftCyc.dataQc(:, end+1) = chlaQc;
      
      a_driftCyc.paramList = [a_driftCyc.paramList derivedParam];
   end
end

% update output parameters
a_driftCyc.derived = 1;
o_driftCyc = a_driftCyc;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the SEAPOINT sensor.
%
% SYNTAX :
%  [o_driftStm] = compute_drift_derived_parameters_for_SEAPOINT(a_driftStm)
%
% INPUT PARAMETERS :
%   o_driftStm : input SEAPOINT drift profile structure
%
% OUTPUT PARAMETERS :
%   a_driftStm : output SEAPOINT drift profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftStm] = compute_drift_derived_parameters_for_SEAPOINT(a_driftStm)

% output parameters initialization
o_driftStm = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_driftStm.paramList.name};

% compute TURBIDITY data and add them in the profile structure
paramToDeriveList = [ ...
   {'VOLTAGE_TURBIDITY'} ...
   ];
derivedParamList = [ ...
   {'TURBIDITY2'} ...
   ];
for idP = 1:length(paramToDeriveList)
   idF = find(strcmp(paramToDeriveList{idP}, paramNameList) == 1, 1);
   if (~isempty(idF))
      paramToDerive = get_netcdf_param_attributes(paramToDeriveList{idP});
      derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
      
      turbi = compute_TURBIDITY_SEAPOINT_303( ...
         a_driftStm.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_driftStm.data(:, end+1) = turbi;
      if (isempty(a_driftStm.dataQc))
         a_driftStm.dataQc = ones(size(a_driftStm.data, 1), size(a_driftStm.data, 2)-1)*g_decArgo_qcDef;
      end
      turbiQc = ones(size(a_driftStm.data, 1), 1)*g_decArgo_qcDef;
      turbiQc(find(turbi ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_driftStm.dataQc(:, end+1) = turbiQc;
      
      a_driftStm.paramList = [a_driftStm.paramList derivedParam];
   end
end

% update output parameters
a_driftStm.derived = 1;
o_driftStm = a_driftStm;

return

% ------------------------------------------------------------------------------
% Compute BBP from the data provided by the FLBB sensor.
%
% SYNTAX :
%  [o_BBP] = compute_drift_BBP( ...
%    a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
%    a_BBP_fillValue, ...
%    a_BBP_dates, ...
%    a_lambda, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_driftFlbb)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING           : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fillValue : fill value for input BETA_BACKSCATTERING
%                                     data
%   a_BBP_fillValue                 : fill value for output BBP data
%   a_BBP_dates                     : dates of BBP data
%   a_lambda                        : wavelength of the FLBB
%   a_ctdDates                      : dates of ascociated CTD (P, T, S) data
%   a_ctdData                       : ascociated CTD (P, T, S) data
%   a_PRES_fillValue                : fill value for input PRES data
%   a_TEMP_fillValue                : fill value for input TEMP data
%   a_PSAL_fillValue                : fill value for input PSAL data
%   a_driftFlbb                     : input FLBB drift profile structure
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_BBP] = compute_drift_BBP( ...
   a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
   a_BBP_fillValue, ...
   a_BBP_dates, ...
   a_lambda, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_driftFlbb)

% current float WMO number
global g_decArgo_floatNum;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fillValue;


% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_BBP_dates);
if (~isempty(ctdLinkData))   
      
   if (a_lambda == 700)
      o_BBP = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
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
         a_driftFlbb.cycleNumber, ...
         a_driftFlbb.profileNumber, ...
         a_lambda);
   end
   
end

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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftOptode] = compute_drift_derived_parameters_for_OPTODE( ...
   a_driftOptode, a_driftCtd, a_decoderId)

% output parameters initialization
o_driftOptode = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
   
   switch (a_decoderId)
      case {301}
         
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
               doxy = compute_drift_DOXY_301( ...
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
         
      case {302, 303}
         
         % retrieve measured CTD data
         paramNameListCtd = {a_driftCtd.paramList.name};
         presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
         tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
         psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
         ctdMeasDates = a_driftCtd.dates;
         ctdMeasData = a_driftCtd.data(:, [presId tempId psalId]);
         
         % compute DOXY data and add them in the profile structure
         paramToDeriveList = [ ...
            {'DPHASE_DOXY'} {'TEMP_DOXY'} ...
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
            if (~isempty(idF1) && ~isempty(idF2))
               paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idD, 1});
               paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idD, 2});
               derivedParam = get_netcdf_param_attributes(derivedParamList{idD});
               
               % compute DOXY values
               doxy = compute_drift_DOXY_302_303( ...
                  a_driftOptode.data(:, idF1), ...
                  a_driftOptode.data(:, idF2), ...
                  paramToDerive1.fillValue, ...
                  paramToDerive2.fillValue, ...
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
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet to compute profile DOXY data for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            a_decoderId);
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
%  [o_DOXY] = compute_drift_DOXY_301( ...
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_drift_DOXY_301( ...
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
      
      case {301}
         
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
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_drift_DOXY_302_303( ...
%    a_DPHASE_DOXY, a_TEMP_DOXY, ...
%    a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_DOXY_fillValue, ...
%    a_DOXY_dates, ...
%    a_ctdDates, a_ctdData, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_driftOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_DPHASE_DOXY           : input DPHASE_DOXY data
%   a_TEMP_DOXY             : input TEMP_DOXY data
%   a_DPHASE_DOXY_fillValue : fill value for input DPHASE_DOXY data
%   a_TEMP_DOXY_fillValue   : fill value for input TEMP_DOXY data
%   a_DOXY_fillValue        : fill value for output DOXY data
%   a_DOXY_dates            : dates of DOXY data
%   a_ctdDates              : dates of ascociated CTD (P, T, S) data
%   a_ctdData               : ascociated CTD (P, T, S) data
%   a_PRES_fillValue        : fill value for input PRES data
%   a_TEMP_fillValue        : fill value for input TEMP data
%   a_PSAL_fillValue        : fill value for input PSAL data
%   a_driftOptode           : input OPTODE drift profile structure
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_DOXY : output drift DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_drift_DOXY_302_303( ...
   a_DPHASE_DOXY, a_TEMP_DOXY, ...
   a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_DOXY_fillValue, ...
   a_DOXY_dates, ...
   a_ctdDates, a_ctdData, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_driftOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_DPHASE_DOXY), 1)*a_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;


% assign the CTD data to the OPTODE measurements (timely closest association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_DOXY_dates);
if (~isempty(ctdLinkData))   
   
   switch (a_decoderId)
      
      case {302, 303}
         
         % compute DOXY values using the Aanderaa standard calibration method
         o_DOXY = compute_DOXY_302_303( ...
            a_DPHASE_DOXY, ...
            a_TEMP_DOXY, ...
            a_DPHASE_DOXY_fillValue, ...
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
