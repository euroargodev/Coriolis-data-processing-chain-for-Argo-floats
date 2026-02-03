% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_sbd_40x(a_launchDate)
%
% INPUT PARAMETERS :
%   a_launchDate : launch date of the float
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_sbd_40x(a_launchDate)

% float configuration structures:

% configuration used to store static configuration values (not received through
% messages)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES

% configuration used to store parameter message contents
% g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES
% g_decArgo_floatConfig.DYNAMIC_TMP.DATES
% g_decArgo_floatConfig.DYNAMIC_TMP.NAMES
% g_decArgo_floatConfig.DYNAMIC_TMP.VALUES

% configuration used to store configuration per cycle(used by the
% decoder)
% g_decArgo_floatConfig.DYNAMIC.NUMBER
% g_decArgo_floatConfig.DYNAMIC.NAMES
% g_decArgo_floatConfig.DYNAMIC.VALUES
% g_decArgo_floatConfig.USE.CYCLE
% g_decArgo_floatConfig.USE.CONFIG

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% json meta-data
global g_decArgo_jsonMetaData;


% init configuration at launch from META.json contents
if (~isempty(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME) && ~isempty(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE))

   jConfNames = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE);

   % remove unused parameters (that are not convertible into numerical values)
   excludedParam = [{'PRODUCT.P0'} {'PRODUCT.P1'} {'VERSION.P0'}];
   idDel = find(ismember(jConfNames, excludedParam));
   jConfNames(idDel) = [];
   jConfValues(idDel) = [];
   
   confNames = jConfNames;
   confValues = nan(length(confNames), 1);
   for id = 1:length(confNames)
      if (strcmp(confNames{id}, 'ICE.P0'))
         if (isempty(jConfValues{id}))
            confValues(id) = 0; % ICE capability disabled
         else
            confValues(id) = 1; % ICE capability enabled
         end
      elseif (isempty(jConfValues{id}))
         continue
      else
         % 'Expected hour at surface' is formatted	'hh:mm:ss', we store it as
         % hhmmss numerical value
         [~, count, errmsg, ~] = sscanf(confNames{id}, 'MISSION-LOOP%d-CYCLE%d.P2');
         if (isempty(errmsg) && (count == 2))
            hhMmSs = jConfValues{id};
            hhMmSs = regexprep(hhMmSs, ':', '');
            confValues(id) = str2double(hhMmSs);
         else
            if (strcmp(jConfValues{id}, 'true'))
               confValues(id) = 1;
            elseif (strcmp(jConfValues{id}, 'false'))
               confValues(id) = 0;
            else
               confValue = str2double(jConfValues{id});
               if (~isnan(confValue))
                  confValues(id) = confValue;
               else
                  fprintf('ERROR: Float #%d: The configuration value ''%s'' = ''%s'' cannot be converted to numerical value\n', ...
                     g_decArgo_floatNum, ...
                     jConfNames{id}, jConfValues{id});
                  continue
               end
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % add the current configuration for '-LOOPXX-CYCLEXX' parameters
   % by duplicating '-LOOP01-CYCLE01' parameters (assigned to '-L-C')
   idF = find(contains(confNames, '-LOOP01-CYCLE01'));
   curConfNames = confNames(idF);
   curConfValues = confValues(idF);
   curConfNames = regexprep(curConfNames, '-LOOP01-CYCLE01', '-L-C');
   confNames = [confNames; curConfNames];
   confValues = [confValues; curConfValues];

else
   fprintf('ERROR: Float #%d: No CONFIG_PARAMETER_NAME or CONFIG_PARAMETER_VALUE in META.json file\n', ...
      g_decArgo_floatNum);
   confNames = [];
   confValues = [];
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = [];
g_decArgo_floatConfig.STATIC.VALUES = [];
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = confNames;
g_decArgo_floatConfig.DYNAMIC.VALUES = confValues;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES = -1;
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = a_launchDate;
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = confNames;
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = confValues;

% create_csv_to_print_config_ir_sbd('init_', 0, g_decArgo_floatConfig);

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(g_decArgo_jsonMetaData);

% fill the calibration coefficients
if (isfield(g_decArgo_jsonMetaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
   end
end

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
end

return
