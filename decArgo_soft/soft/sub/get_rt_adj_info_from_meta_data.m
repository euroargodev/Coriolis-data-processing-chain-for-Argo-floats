% ------------------------------------------------------------------------------
% Retrieve (and format) RT adjustment information stored in the JSON meta-data
% file.
%
% SYNTAX :
%  [o_rtOffsetInfo] = get_rt_adj_info_from_meta_data(a_metaData)
%
% INPUT PARAMETERS :
%   a_metaData : JSON meta-data
%
% OUTPUT PARAMETERS :
%   o_rtOffsetInfo : formated RT adjustement information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rtOffsetInfo] = get_rt_adj_info_from_meta_data(a_metaData)

% output parameters initialization
o_rtOffsetInfo = [];

% default values
global g_decArgo_janFirst1950InMatlab;


if (isfield(a_metaData, 'RT_OFFSET'))
   o_rtOffsetInfo.param = [];
   o_rtOffsetInfo.slope = [];
   o_rtOffsetInfo.value = [];
   o_rtOffsetInfo.adjError = [];
   o_rtOffsetInfo.adjErrorStr = [];
   o_rtOffsetInfo.adjErrorMethod = [];
   o_rtOffsetInfo.date = [];
   
   rtData = a_metaData.RT_OFFSET;
   params = unique(struct2cell(rtData.PARAM), 'stable');
   for idParam = 1:length(params)
      param = params{idParam};
      fieldNames = fields(rtData.PARAM);
      tabSlope = [];
      tabValue = [];
      tabAdjError = [];
      tabAdjErrorStr = [];
      tabAdjErrorMethod = [];
      tabDate = [];
      for idF = 1:length(fieldNames)
         fieldName = fieldNames{idF};
         if (strcmp(rtData.PARAM.(fieldName), param) == 1)
            idPos = strfind(fieldName, '_');
            paramNum = fieldName(idPos+1:end);
            if (isfield(rtData, 'SLOPE'))
               slope = str2double(rtData.SLOPE.(['SLOPE_' paramNum]));
            else
               slope = 1;
            end
            tabSlope = [tabSlope slope];
            value = str2double(rtData.VALUE.(['VALUE_' paramNum]));
            tabValue = [tabValue value];
            if (isfield(rtData, 'ADJUSTED_ERROR'))
               if (isfield(rtData.ADJUSTED_ERROR, ['ADJUSTED_ERROR_' paramNum]))
                  adjError = str2double(rtData.ADJUSTED_ERROR.(['ADJUSTED_ERROR_' paramNum]));
                  tabAdjError = [tabAdjError adjError];
                  tabAdjErrorStr{end+1} = rtData.ADJUSTED_ERROR.(['ADJUSTED_ERROR_' paramNum]);
               else
                  tabAdjError = [tabAdjError nan];
                  tabAdjErrorStr{end+1} = 'nan';
               end
            else
               tabAdjError = [tabAdjError nan];
               tabAdjErrorStr{end+1} = 'nan';
            end
            if (isfield(rtData, 'ADJUSTED_ERROR_METHOD'))
               if (isfield(rtData.ADJUSTED_ERROR_METHOD, ['ADJUSTED_ERROR_METHOD_' paramNum]))
                  adjErrorMethod = rtData.ADJUSTED_ERROR_METHOD.(['ADJUSTED_ERROR_METHOD_' paramNum]);
                  tabAdjErrorMethod = [tabAdjErrorMethod adjErrorMethod];
               else
                  tabAdjErrorMethod = [tabAdjErrorMethod nan];
               end
            else
               tabAdjErrorMethod = [tabAdjErrorMethod nan];
            end
            date = rtData.DATE.(['DATE_' paramNum]);
            date = datenum(date, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
            tabDate = [tabDate date];
         end
      end
      [tabDate, idSorted] = sort(tabDate);
      tabSlope = tabSlope(idSorted);
      tabValue = tabValue(idSorted);
      tabAdjError = tabAdjError(idSorted);
      
      % store the RT offsets
      o_rtOffsetInfo.param{end+1} = param;
      o_rtOffsetInfo.slope{end+1} = tabSlope;
      o_rtOffsetInfo.value{end+1} = tabValue;
      o_rtOffsetInfo.adjError{end+1} = tabAdjError;
      o_rtOffsetInfo.adjErrorStr{end+1} = tabAdjErrorStr;
      o_rtOffsetInfo.adjErrorMethod{end+1} = tabAdjErrorMethod;
      o_rtOffsetInfo.date{end+1} = tabDate;
   end
end

return
