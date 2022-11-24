% ------------------------------------------------------------------------------
% Create calibration and RTOffset configuration structures from JSON meta-data
% information.
%
% SYNTAX :
%  init_float_config_apx_argos(a_decoderId)
%
% INPUT PARAMETERS :
%    a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :.
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2016 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_apx_argos(a_decoderId)

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% arrays to store calibration information
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_calibInfo = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return;
end

% read meta-data file
jsonMetaData = loadjson(jsonInputFileName);

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(metaData);

% add DO calibration coefficients
if (ismember(a_decoderId, [1006 1008 1014 1016]))
      
   % fill the calibration coefficients
   if (isfield(jsonMetaData, 'CALIBRATION_COEFFICIENT'))
      if (~isempty(jsonMetaData.CALIBRATION_COEFFICIENT))
         fieldNames = fields(jsonMetaData.CALIBRATION_COEFFICIENT);
         for idF = 1:length(fieldNames)
            g_decArgo_calibInfo.(fieldNames{idF}) = jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
         end
      end
   end
   
   % create the tabPhaseCoef, tabDoxyCoef and tabDoxyTempCoef arrays
   if (isfield(g_decArgo_calibInfo, 'OPTODE'))
      calibData = g_decArgo_calibInfo.OPTODE;
      
      tabPhaseCoef = [];
      for id = 0:3
         fieldName = ['PhaseCoef' num2str(id)];
         if (isfield(calibData, fieldName))
            tabPhaseCoef(id+1) = calibData.(fieldName);
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
            return;
         end
      end
      tabDoxyCoef = [];
      for idI = 0:4
         for idJ = 0:3
            fieldName = ['CCoef' num2str(idI) num2str(idJ)];
            if (isfield(calibData, fieldName))
               tabDoxyCoef(idI+1, idJ+1) = calibData.(fieldName);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               return;
            end
         end
      end
      g_decArgo_calibInfo.OPTODE.TabPhaseCoef = tabPhaseCoef;
      g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
      
      tabDoxyTempCoef = [];
      for id = 0:5
         fieldName = ['TempCoef' num2str(id)];
         if (isfield(calibData, fieldName))
            tabDoxyTempCoef(1, id+1) = calibData.(fieldName);
         else
            tabDoxyTempCoef = [];
            break;
         end
      end
      if (~isempty(tabDoxyTempCoef))
         g_decArgo_calibInfo.OPTODE.TabDoxyTempCoef = tabDoxyTempCoef;
      end
   else
      fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
   end
elseif (ismember(a_decoderId, [1009]))
      
   % fill the calibration coefficients
   if (isfield(jsonMetaData, 'CALIBRATION_COEFFICIENT'))
      if (~isempty(jsonMetaData.CALIBRATION_COEFFICIENT))
         fieldNames = fields(jsonMetaData.CALIBRATION_COEFFICIENT);
         for idF = 1:length(fieldNames)
            g_decArgo_calibInfo.(fieldNames{idF}) = jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
         end
      end
   end
   
   % create the tabDoxyCoef and tabDoxyTempCoef arrays
   if (isfield(g_decArgo_calibInfo, 'OPTODE'))
      calibData = g_decArgo_calibInfo.OPTODE;

      tabDoxyCoef = [];
      for id = 0:3
         fieldName = ['PhaseCoef' num2str(id)];
         if (isfield(calibData, fieldName))
            tabDoxyCoef(1, id+1) = calibData.(fieldName);
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
            return;
         end
      end
      for id = 0:6
         fieldName = ['SVUFoilCoef' num2str(id)];
         if (isfield(calibData, fieldName))
            tabDoxyCoef(2, id+1) = calibData.(fieldName);
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
            return;
         end
      end
      g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
      
      tabDoxyTempCoef = [];
      for id = 0:5
         fieldName = ['TempCoef' num2str(id)];
         if (isfield(calibData, fieldName))
            tabDoxyTempCoef(1, id+1) = calibData.(fieldName);
         else
            tabDoxyTempCoef = [];
            break;
         end
      end
      if (~isempty(tabDoxyTempCoef))
         g_decArgo_calibInfo.OPTODE.TabDoxyTempCoef = tabDoxyTempCoef;
      end
   else
      fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
   end
elseif (ismember(a_decoderId, [1013 1015]))
   
   % fill the calibration coefficients
   if (isfield(jsonMetaData, 'CALIBRATION_COEFFICIENT'))
      if (~isempty(jsonMetaData.CALIBRATION_COEFFICIENT))
         fieldNames = fields(jsonMetaData.CALIBRATION_COEFFICIENT);
         for idF = 1:length(fieldNames)
            g_decArgo_calibInfo.(fieldNames{idF}) = jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
         end
         
         % create the tabDoxyCoef array
         if (isfield(g_decArgo_calibInfo, 'OPTODE'))
            calibData = g_decArgo_calibInfo.OPTODE;

            tabDoxyCoef = [];
            coefNameList = [{'Soc'} {'FOffset'} {'CoefA'} {'CoefB'} {'CoefC'} {'CoefE'}];
            for id = 1:length(coefNameList)
               fieldName = coefNameList{id};
               if (isfield(calibData, fieldName))
                  tabDoxyCoef = [tabDoxyCoef calibData.(fieldName)];
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return;
               end
            end
            g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef = tabDoxyCoef;
         end
      end
   end
end

return;
