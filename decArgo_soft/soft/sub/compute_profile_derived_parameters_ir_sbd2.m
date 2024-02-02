% ------------------------------------------------------------------------------
% Compute derived parameters and add them in the profile structures.
%
% SYNTAX :
%  [o_tabProfiles] = compute_profile_derived_parameters_ir_sbd2(a_tabProfiles, a_decoderId)
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = compute_profile_derived_parameters_ir_sbd2(a_tabProfiles, a_decoderId)

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
      a_tabProfiles(profInfo(idSensor1(idP), 1)) = ...
         compute_profile_derived_parameters_for_OPTODE(profOptode, profCtd, a_decoderId);
   end
   
   switch (a_decoderId)
      case {301}
         
         % compute FLBB derived parameters
         idSensor4 = find((profInfo(:, 2) == 4) & (profInfo(:, 3) == 0));
         for idP = 1:length(idSensor4)
            profFlbb = a_tabProfiles(profInfo(idSensor4(idP), 1));
            
            % look for the associated CTD profile
            profCtd = [];
            idF = find((profInfo(:, 2) == 0) & ...
               (profInfo(:, 4) == profFlbb.cycleNumber) & ...
               (profInfo(:, 5) == profFlbb.profileNumber) & ...
               (profInfo(:, 6) == profFlbb.phaseNumber));
            if (length(idF) == 1)
               profCtd = a_tabProfiles(profInfo(idF, 1));
            else
               if (isempty(idF))
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: unable to find the associated CTD profile to compute BBP parameter for ''%c'' profile of FLBB sensor - BBP data set to fill value\n', ...
                     g_decArgo_floatNum, ...
                     profFlbb.cycleNumber, ...
                     profFlbb.profileNumber, ...
                     profFlbb.direction);
               else
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d: %d associated CTD profiles have been found to compute BBP parameter for ''%c'' profile of FLBB sensor - BBP data set to fill value\n', ...
                     g_decArgo_floatNum, ...
                     profFlbb.cycleNumber, ...
                     profFlbb.profileNumber, ...
                     length(idF), ...
                     profFlbb.direction);
               end
            end
            a_tabProfiles(profInfo(idSensor4(idP), 1)) = ...
               compute_profile_derived_parameters_for_FLBB(profFlbb, profCtd);
         end
         
      case {302}
         
         % compute FLNTU derived parameters
         idSensor4 = find((profInfo(:, 2) == 4) & (profInfo(:, 3) == 0));
         for idP = 1:length(idSensor4)
            profFlntu = a_tabProfiles(profInfo(idSensor4(idP), 1));
            a_tabProfiles(profInfo(idSensor4(idP), 1)) = ...
               compute_profile_derived_parameters_for_FLNTU(profFlntu);
         end
         
      case {303}
         
         % compute FLNTU derived parameters
         idSensor4 = find((profInfo(:, 2) == 4) & (profInfo(:, 3) == 0));
         for idP = 1:length(idSensor4)
            profFlntu = a_tabProfiles(profInfo(idSensor4(idP), 1));
            a_tabProfiles(profInfo(idSensor4(idP), 1)) = ...
               compute_profile_derived_parameters_for_FLNTU(profFlntu);
         end
         
         % compute CYCLOPS derived parameters
         fprintf('INFO: Float #%d Cycle #%d Profile #%d: profile CHLA measurements not computed for CYCLOPS sensor\n', ...
            g_decArgo_floatNum, ...
            profFlntu.cycleNumber, ...
            profFlntu.profileNumber);
         if (0)
            idSensor7 = find((profInfo(:, 2) == 7) & (profInfo(:, 3) == 0));
            for idP = 1:length(idSensor7)
               profCyc = a_tabProfiles(profInfo(idSensor7(idP), 1));
               a_tabProfiles(profInfo(idSensor7(idP), 1)) = ...
                  compute_profile_derived_parameters_for_CYCLOPS(profCyc);
            end
         end

         % compute SEAPOINT derived parameters
         fprintf('INFO: Float #%d Cycle #%d Profile #%d: profile TURBIDITY measurements not computed for SEAPOINT sensor\n', ...
            g_decArgo_floatNum, ...
            profFlntu.cycleNumber, ...
            profFlntu.profileNumber);
         if (0)
            idSensor8 = find((profInfo(:, 2) == 8) & (profInfo(:, 3) == 0));
            for idP = 1:length(idSensor8)
               profStm = a_tabProfiles(profInfo(idSensor8(idP), 1));
               a_tabProfiles(profInfo(idSensor8(idP), 1)) = ...
                  compute_profile_derived_parameters_for_SEAPOINT(profStm);
            end
         end
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the FLBB sensor.
%
% SYNTAX :
%  [o_profFlbb] = compute_profile_derived_parameters_for_FLBB( ...
%    a_profFlbb, a_profCtd)
%
% INPUT PARAMETERS :
%   a_profFlbb   : input FLBB profile structure
%   a_profCtd    : input CTD profile structure
%
% OUTPUT PARAMETERS :
%   o_profFlbb : output FLBB profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profFlbb] = compute_profile_derived_parameters_for_FLBB( ...
   a_profFlbb, a_profCtd)

% output parameters initialization
o_profFlbb = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profFlbb.paramList.name};

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
         a_profFlbb.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profFlbb.data(:, end+1) = chla;
      if (isempty(a_profFlbb.dataQc))
         a_profFlbb.dataQc = ones(size(a_profFlbb.data, 1), length(a_profFlbb.paramList))*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profFlbb.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profFlbb.dataQc(:, end+1) = chlaQc;
      
      a_profFlbb.paramList = [a_profFlbb.paramList derivedParam];

      % duplicate CHLA profile as CHLA_FLUORESCENCE one
      a_profFlbb.data(:, end+1) = chla;
      if (isempty(a_profFlbb.dataQc))
         a_profFlbb.dataQc = ones(size(a_profFlbb.data, 1), length(a_profFlbb.paramList))*g_decArgo_qcDef;
      end
      chlaFluoQc = ones(size(a_profFlbb.data, 1), 1)*g_decArgo_qcDef;
      chlaFluoQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profFlbb.dataQc(:, end+1) = chlaFluoQc;
      
      chlaFluoParam = get_netcdf_param_attributes('CHLA_FLUORESCENCE');

      a_profFlbb.paramList = [a_profFlbb.paramList chlaFluoParam];
   end
end

if (isempty(a_profCtd))
   
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
         a_profFlbb.data(:, end+1) = ones(size(a_profFlbb.data, 1), 1)*derivedParam.fillValue;
         if (~isempty(a_profFlbb.dataQc))
            a_profFlbb.dataQc(:, end+1) = ones(size(a_profFlbb.data, 1), 1)*g_decArgo_qcDef;
         end
         a_profFlbb.paramList = [a_profFlbb.paramList derivedParam];
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
            a_profFlbb.data(:, idF), ...
            paramToDerive.fillValue, ...
            derivedParam.fillValue, ...
            a_profFlbb.data(:, 1), ...
            700, ...
            ctdMeasData, ...
            a_profFlbb);
         
         if (~isempty(bbp700))
            a_profFlbb.data(:, end+1) = bbp700;
            if (isempty(a_profFlbb.dataQc))
               a_profFlbb.dataQc = ones(size(a_profFlbb.data, 1), length(a_profFlbb.paramList))*g_decArgo_qcDef;
            end
            bbp700Qc = ones(size(a_profFlbb.data, 1), 1)*g_decArgo_qcDef;
            bbp700Qc(find(bbp700 ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
            a_profFlbb.dataQc(:, end+1) = bbp700Qc;
         else
            a_profFlbb.data(:, end+1) = ones(size(a_profFlbb.data, 1), 1)*derivedParam.fillValue;
            if (~isempty(a_profFlbb.dataQc))
               a_profFlbb.dataQc(:, end+1) = ones(size(a_profFlbb.data, 1), 1)*g_decArgo_qcDef;
            end
         end
         a_profFlbb.paramList = [a_profFlbb.paramList derivedParam];
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
      
      cdom = compute_CDOM_105_to_107_110_112_121_to_133_1121_to_28_1322_1323( ...
         a_profFlbb.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profFlbb.data(:, end+1) = cdom;
      if (isempty(a_profFlbb.dataQc))
         a_profFlbb.dataQc = ones(size(a_profFlbb.data, 1), length(a_profFlbb.paramList))*g_decArgo_qcDef;
      end
      cdomQc = ones(size(a_profFlbb.data, 1), 1)*g_decArgo_qcDef;
      cdomQc(find(cdom ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profFlbb.dataQc(:, end+1) = cdomQc;
      
      a_profFlbb.paramList = [a_profFlbb.paramList derivedParam];
   end
end

% update output parameters
a_profFlbb.derived = 1;
o_profFlbb = a_profFlbb;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the FLNTU sensor.
%
% SYNTAX :
%  [o_profFlntu] = compute_profile_derived_parameters_for_FLNTU(a_profFlntu)
%
% INPUT PARAMETERS :
%   o_profFlntu : input FLNTU profile structure
%
% OUTPUT PARAMETERS :
%   o_profFlntu : output FLNTU profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profFlntu] = compute_profile_derived_parameters_for_FLNTU(a_profFlntu)

% output parameters initialization
o_profFlntu = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profFlntu.paramList.name};

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
         a_profFlntu.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profFlntu.data(:, end+1) = chla;
      if (isempty(a_profFlntu.dataQc))
         a_profFlntu.dataQc = ones(size(a_profFlntu.data, 1), length(a_profFlntu.paramList))*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profFlntu.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profFlntu.dataQc(:, end+1) = chlaQc;
      
      a_profFlntu.paramList = [a_profFlntu.paramList derivedParam];

      % duplicate CHLA profile as CHLA_FLUORESCENCE one
      a_profFlntu.data(:, end+1) = chla;
      if (isempty(a_profFlntu.dataQc))
         a_profFlntu.dataQc = ones(size(a_profFlntu.data, 1), length(a_profFlntu.paramList))*g_decArgo_qcDef;
      end
      chlaFluoQc = ones(size(a_profFlntu.data, 1), 1)*g_decArgo_qcDef;
      chlaFluoQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profFlntu.dataQc(:, end+1) = chlaFluoQc;

      chlaFluoParam = get_netcdf_param_attributes('CHLA_FLUORESCENCE');

      a_profFlntu.paramList = [a_profFlntu.paramList chlaFluoParam];
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
         a_profFlntu.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profFlntu.data(:, end+1) = turbi;
      if (isempty(a_profFlntu.dataQc))
         a_profFlntu.dataQc = ones(size(a_profFlntu.data, 1), length(a_profFlntu.paramList))*g_decArgo_qcDef;
      end
      turbiQc = ones(size(a_profFlntu.data, 1), 1)*g_decArgo_qcDef;
      turbiQc(find(turbi ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profFlntu.dataQc(:, end+1) = turbiQc;
      
      a_profFlntu.paramList = [a_profFlntu.paramList derivedParam];
   end
end

% update output parameters
a_profFlntu.derived = 1;
o_profFlntu = a_profFlntu;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the CYCLOPS sensor.
%
% SYNTAX :
%  [o_profCyc] = compute_profile_derived_parameters_for_CYCLOPS(a_profCyc)
%
% INPUT PARAMETERS :
%   a_profCyc : input CYCLOPS profile structure
%
% OUTPUT PARAMETERS :
%   o_profCyc : output CYCLOPS profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profCyc] = compute_profile_derived_parameters_for_CYCLOPS(a_profCyc)

% output parameters initialization
o_profCyc = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profCyc.paramList.name};

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
         a_profCyc.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profCyc.data(:, end+1) = chla;
      if (isempty(a_profCyc.dataQc))
         a_profCyc.dataQc = ones(size(a_profCyc.data, 1), length(a_profCyc.paramList))*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profCyc.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profCyc.dataQc(:, end+1) = chlaQc;
      
      a_profCyc.paramList = [a_profCyc.paramList derivedParam];

      % duplicate CHLA2 profile as CHLA_FLUORESCENCE2 one
      a_profCyc.data(:, end+1) = chla;
      if (isempty(a_profCyc.dataQc))
         a_profCyc.dataQc = ones(size(a_profCyc.data, 1), length(a_profCyc.paramList))*g_decArgo_qcDef;
      end
      chlaFluoQc = ones(size(a_profCyc.data, 1), 1)*g_decArgo_qcDef;
      chlaFluoQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profCyc.dataQc(:, end+1) = chlaFluoQc;

      chlaFluoParam = get_netcdf_param_attributes('CHLA_FLUORESCENCE2');

      a_profCyc.paramList = [a_profCyc.paramList chlaFluoParam];
   end
end

% update output parameters
a_profCyc.derived = 1;
o_profCyc = a_profCyc;

return

% ------------------------------------------------------------------------------
% Compute derived parameters for the SEAPOINT sensor.
%
% SYNTAX :
%  [o_profStm] = compute_profile_derived_parameters_for_SEAPOINT(a_profStm)
%
% INPUT PARAMETERS :
%   a_profStm : input SEAPOINT profile structure
%
% OUTPUT PARAMETERS :
%   o_profStm : output SEAPOINT profile structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStm] = compute_profile_derived_parameters_for_SEAPOINT(a_profStm)

% output parameters initialization
o_profStm = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;


% list of parameters of the profile
paramNameList = {a_profStm.paramList.name};

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
      
      chla = compute_TURBIDITY_SEAPOINT_303( ...
         a_profStm.data(:, idF), ...
         paramToDerive.fillValue, derivedParam.fillValue);
      
      a_profStm.data(:, end+1) = chla;
      if (isempty(a_profStm.dataQc))
         a_profStm.dataQc = ones(size(a_profStm.data, 1), length(a_profStm.paramList))*g_decArgo_qcDef;
      end
      chlaQc = ones(size(a_profStm.data, 1), 1)*g_decArgo_qcDef;
      chlaQc(find(chla ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
      a_profStm.dataQc(:, end+1) = chlaQc;
      
      a_profStm.paramList = [a_profStm.paramList derivedParam];
   end
end

% update output parameters
a_profStm.derived = 1;
o_profStm = a_profStm;

return

% ------------------------------------------------------------------------------
% Compute BBP from the data provided by the FLBB sensor.
%
% SYNTAX :
%  [o_BBP] = compute_profile_BBP( ...
%    a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
%    a_BBP_fillValue, ...
%    a_BBP_pres, ...
%    a_lambda, ...
%    a_ctdData, ...
%    a_profFlbb)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING            : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fillValue : fill value for input BETA_BACKSCATTERING
%                                      data
%   a_BBP_fillValue                 : fill value for output BBP data
%   a_BBP_pres                       : pressure levels of BBP data
%   a_lambda                         : wavelength of the FLBB
%   a_ctdData                        : ascociated CTD (P, T, S) data
%   a_profFlbb                       : input FLBB profile structure
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
function [o_BBP] = compute_profile_BBP( ...
   a_BETA_BACKSCATTERING, a_BETA_BACKSCATTERING_fillValue, ...
   a_BBP_fillValue, ...
   a_BBP_pres, ...
   a_lambda, ...
   a_ctdData, ...
   a_profFlbb)

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
   
   % interpolate and extrapolate the CTD data at the pressures of the FLBB
   % measurements
   ctdIntData = compute_interpolated_CTD_measurements( ...
      ctdDataNoDef, a_BBP_pres, a_profFlbb.direction);
   if (~isempty(ctdIntData))
      
      idNoDef = find(~(isnan(ctdIntData(:, 2)) | isnan(ctdIntData(:, 3))));
      
      if (a_lambda == 700)
         o_BBP(idNoDef) = compute_BBP700_301_1015_1101_1105_1110_1111_1112( ...
            a_BETA_BACKSCATTERING(idNoDef), ...
            a_BETA_BACKSCATTERING_fillValue, ...
            a_BBP_fillValue, ...
            ctdIntData(idNoDef, :), ...
            paramPres.fillValue, ...
            paramTemp.fillValue, ...
            paramPsal.fillValue);
      else
         fprintf('WARNING: Float #%d Cycle #%d Profile #%d: BBP processing not implemented yet for lambda = %g - BBP data set to fill value in ''%c'' profile of FLBB sensor\n', ...
            g_decArgo_floatNum, ...
            a_profFlbb.cycleNumber, ...
            a_profFlbb.profileNumber, ...
            a_lambda, ...
            a_profFlbb.direction);
         
         % update output parameters
         o_BBP = [];
      end
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available interpolated CTD data to compute BBP parameter for ''%c'' profile of FLBB sensor - BBP data set to fill value\n', ...
         g_decArgo_floatNum, ...
         a_profFlbb.cycleNumber, ...
         a_profFlbb.profileNumber, ...
         a_profFlbb.direction);
      
      % update output parameters
      o_BBP = [];
      
   end
   
else
   
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: no available CTD data to compute BBP parameter for ''%c'' profile of FLBB sensor - BBP data set to fill value\n', ...
      g_decArgo_floatNum, ...
      a_profFlbb.cycleNumber, ...
      a_profFlbb.profileNumber, ...
      a_profFlbb.direction);
   
   % update output parameters
   o_BBP = [];
   
end

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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profOptode] = compute_profile_derived_parameters_for_OPTODE( ...
   a_profOptode, a_profCtd, a_decoderId)

% output parameters initialization
o_profOptode = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
         a_profOptode.dataQc = ones(size(a_profOptode.data, 1), length(a_profOptode.paramList))*g_decArgo_qcDef;
      end
      a_profOptode.paramList = [a_profOptode.paramList derivedParam];
   end
   
else
   
   switch (a_decoderId)
      case {301}
         
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
               [doxy, ptsForDoxy] = compute_profile_DOXY_301( ...
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
                     a_profOptode.dataQc = ones(size(a_profOptode.data, 1), length(a_profOptode.paramList))*g_decArgo_qcDef;
                  end
                  doxyQc = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
                  doxyQc(find(doxy ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
                  a_profOptode.dataQc(:, end+1) = doxyQc;
                  
                  a_profOptode.ptsForDoxy = ptsForDoxy;
               else
                  a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
                  if (~isempty(a_profOptode.dataQc))
                     a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
                  end
               end
               a_profOptode.paramList = [a_profOptode.paramList derivedParam];
            end
         end
         
      case {302, 303}
         
         % get the CTD profile data
         paramNameListCtd = {a_profCtd.paramList.name};
         presId = find(strcmp('PRES', paramNameListCtd) == 1, 1);
         tempId = find(strcmp('TEMP', paramNameListCtd) == 1, 1);
         psalId = find(strcmp('PSAL', paramNameListCtd) == 1, 1);
         ctdMeasData = a_profCtd.data(:, [presId tempId psalId]);
         
         % compute DOXY data and add them in the profile structure
         paramToDeriveList = [ ...
            {'DPHASE_DOXY'} {'TEMP_DOXY'} ...
            ];
         derivedParamList = [ ...
            {'DOXY'} ...
            ];
         for idP = 1:size(paramToDeriveList, 1)
            idF1 = find(strcmp(paramToDeriveList{idP, 1}, paramNameList) == 1, 1);
            idF2 = find(strcmp(paramToDeriveList{idP, 2}, paramNameList) == 1, 1);
            if (~isempty(idF1) && ~isempty(idF2))
               paramToDerive1 = get_netcdf_param_attributes(paramToDeriveList{idP, 1});
               paramToDerive2 = get_netcdf_param_attributes(paramToDeriveList{idP, 2});
               derivedParam = get_netcdf_param_attributes(derivedParamList{idP});
               
               % compute DOXY values
               
               [doxy, ptsForDoxy] = compute_profile_DOXY_302_303( ...
                  a_profOptode.data(:, idF1), ...
                  a_profOptode.data(:, idF2), ...
                  paramToDerive1.fillValue, ...
                  paramToDerive2.fillValue, ...
                  derivedParam.fillValue, ...
                  a_profOptode.data(:, 1), ...
                  ctdMeasData, ...
                  a_profOptode, a_decoderId);
               
               if (~isempty(doxy))
                  a_profOptode.data(:, end+1) = doxy;
                  if (isempty(a_profOptode.dataQc))
                     a_profOptode.dataQc = ones(size(a_profOptode.data, 1), length(a_profOptode.paramList))*g_decArgo_qcDef;
                  end
                  doxyQc = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
                  doxyQc(find(doxy ~= derivedParam.fillValue)) = g_decArgo_qcNoQc;
                  a_profOptode.dataQc(:, end+1) = doxyQc;
                  
                  a_profOptode.ptsForDoxy = ptsForDoxy;
               else
                  a_profOptode.data(:, end+1) = ones(size(a_profOptode.data, 1), 1)*derivedParam.fillValue;
                  if (~isempty(a_profOptode.dataQc))
                     a_profOptode.dataQc(:, end+1) = ones(size(a_profOptode.data, 1), 1)*g_decArgo_qcDef;
                  end
               end
               a_profOptode.paramList = [a_profOptode.paramList derivedParam];
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
a_profOptode.derived = 1;
o_profOptode = a_profOptode;

return

% ------------------------------------------------------------------------------
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY, o_ptsForDoxy] = compute_profile_DOXY_301( ...
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
%   o_DOXY       : output DOXY data
%   o_ptsForDoxy : PTS data used to compute DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY, o_ptsForDoxy] = compute_profile_DOXY_301( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_DOXY_fillValue, ...
   a_DOXY_pres, a_ctdData, ...
   a_profOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fillValue;
o_ptsForDoxy = [];

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
      
      idNoDef = find(~(isnan(ctdIntData(:, 2)) | isnan(ctdIntData(:, 3))));
      
      switch (a_decoderId)
         
         case {301}
            
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
            o_ptsForDoxy = ctdIntData;

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
% Compute DOXY from the data provided by the OPTODE sensor.
%
% SYNTAX :
%  [o_DOXY, o_ptsForDoxy] = compute_profile_DOXY_302_303( ...
%    a_DPHASE_DOXY, a_TEMP_DOXY, ...
%    a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_DOXY_fillValue, ...
%    a_DOXY_pres, a_ctdData, ...
%    a_profOptode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_DPHASE_DOXY            : input DPHASE_DOXY data
%   a_TEMP_DOXY              : input TEMP_DOXY data
%   a_DPHASE_DOXY_fillValue : fill value for input DPHASE_DOXY data
%   a_TEMP_DOXY_fillValue   : fill value for input TEMP_DOXY data
%   a_DOXY_fillValue        : fill value for output DOXY data
%   a_DOXY_pres              : pressure levels of DOXY data
%   a_ctdData                : ascociated CTD (P, T, S) data
%   a_profOptode             : input OPTODE profile structure
%   a_decoderId              : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_DOXY       : output DOXY data
%   o_ptsForDoxy : PTS data used to compute DOXY
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY, o_ptsForDoxy] = compute_profile_DOXY_302_303( ...
   a_DPHASE_DOXY, a_TEMP_DOXY, ...
   a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_DOXY_fillValue, ...
   a_DOXY_pres, a_ctdData, ...
   a_profOptode, a_decoderId)

% output parameters initialization
o_DOXY = ones(length(a_DPHASE_DOXY), 1)*a_DOXY_fillValue;
o_ptsForDoxy = [];

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
      
      idNoDef = find(~(isnan(ctdIntData(:, 2)) | isnan(ctdIntData(:, 3))));
      
      switch (a_decoderId)
         
         case {302, 303}
            
            % compute DOXY values using the Aanderaa standard calibration method
            o_DOXY(idNoDef) = compute_DOXY_302_303( ...
               a_DPHASE_DOXY(idNoDef), ...
               a_TEMP_DOXY(idNoDef), ...
               a_DPHASE_DOXY_fillValue, ...
               a_TEMP_DOXY_fillValue, ...
               ctdIntData(idNoDef, 1), ...
               ctdIntData(idNoDef, 2), ...
               ctdIntData(idNoDef, 3), ...
               paramPres.fillValue, ...
               paramTemp.fillValue, ...
               paramPsal.fillValue, ...
               a_DOXY_fillValue, ...
               a_profOptode);
            o_ptsForDoxy = ctdIntData;

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