% ------------------------------------------------------------------------------
% Initialize the float configurations.
%
% SYNTAX :
%  init_float_config_prv_argos(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/02/2013 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_argos(a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% json meta-data
global g_decArgo_jsonMetaData;

% float configuration
global g_decArgo_floatConfig;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];


% if the Argos float version transmits its configuration during the prelude, we
% will wait until the prelude transmission phase to create the float
% configuration
if (~ismember(a_decoderId, [30 32]))
   
   % retrieve the configuration
   configNames = [];
   configValues = [];
   configNumbers = [];
   if ((isfield(g_decArgo_jsonMetaData, 'CONFIG_PARAMETER_NAME')) && ...
         (isfield(g_decArgo_jsonMetaData, 'CONFIG_PARAMETER_VALUE')))
      
      configNames = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME);
      cellConfigValues = g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE;
      configValues = nan(size(configNames, 1), size(cellConfigValues, 2));
      configNumbers = 1:length(cellConfigValues);
      for idConf = 1:length(cellConfigValues)
         cellConfigVals = struct2cell(cellConfigValues{idConf});
         for idVal = 1:length(cellConfigVals)
            if (~isempty(cellConfigVals{idVal}))
               [value, status] = str2num(cellConfigVals{idVal});
               if ((length(value) == 1) && (status == 1))
                  configValues(idVal, idConf) = value;
               else
                  fprintf('ERROR: Float #%d: The configuration value ''%s'' cannot be converted to numerical value\n', ...
                     g_decArgo_floatNum, ...
                     configNames{idConf});
                  return
               end
            end
         end
      end
   end
   
   % store the configuration
   g_decArgo_floatConfig = [];
   g_decArgo_floatConfig.NAMES = configNames;
   g_decArgo_floatConfig.VALUES = configValues;
   g_decArgo_floatConfig.NUMBER = configNumbers;
   
   % compute the pressure to cut-off the ascending profile
   [g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF, ...
      g_decArgo_jsonMetaData.PRES_STOP_CTD_PUMP] = compute_cutoff_pres(a_decoderId);
end

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(g_decArgo_jsonMetaData);

% add DO calibration coefficients
if (ismember(a_decoderId, [4 19 25 27 28 29 32]))
   
   % read the calibration coefficients in the json meta-data file

   % fill the calibration coefficients
   if (isfield(g_decArgo_jsonMetaData, 'CALIBRATION_COEFFICIENT'))
      if (~isempty(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT))
         fieldNames = fields(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT);
         for idF = 1:length(fieldNames)
            g_decArgo_calibInfo.(fieldNames{idF}) = g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
         end
      end
   end
   
   % create the tabDoxyCoef array
   switch (a_decoderId)
      
      case {27, 32}
         if (isfield(g_decArgo_calibInfo, 'OPTODE'))
            calibData = g_decArgo_calibInfo.OPTODE;
            tabDoxyCoef = [];
            for id = 0:3
               fieldName = ['PhaseCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(1, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            for id = 0:6
               fieldName = ['SVUFoilCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(2, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
         end
         
      case {28, 29}
         if (isfield(g_decArgo_calibInfo, 'OPTODE'))
            calibData = g_decArgo_calibInfo.OPTODE;
            tabDoxyCoef = [];
            for id = 0:3
               fieldName = ['PhaseCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(1, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            for id = 0:5
               fieldName = ['TempCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(2, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            for id = 0:13
               fieldName = ['FoilCoefA' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(3, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            for id = 0:13
               fieldName = ['FoilCoefB' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(3, id+15) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            for id = 0:27
               fieldName = ['FoilPolyDegT' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(4, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            for id = 0:27
               fieldName = ['FoilPolyDegO' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(5, id+1) = calibData.(fieldName);
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            
            if (a_decoderId == 29)
               for id = 0:1
                  fieldName = ['ConcCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(6, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
            end
            
            g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
         end
         
   end
end

return
