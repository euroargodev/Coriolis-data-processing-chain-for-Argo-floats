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
   o_rtOffsetInfo.drift = [];
   o_rtOffsetInfo.inclineT = [];
   o_rtOffsetInfo.doCorPres = [];
   o_rtOffsetInfo.adjError = [];
   o_rtOffsetInfo.adjErrorStr = [];
   o_rtOffsetInfo.adjErrorMethod = [];
   o_rtOffsetInfo.equation = [];
   o_rtOffsetInfo.coefficient = [];
   o_rtOffsetInfo.comment = [];
   o_rtOffsetInfo.date = [];
   o_rtOffsetInfo.dateApply = [];

   rtData = a_metaData.RT_OFFSET;
   params = unique(struct2cell(rtData.PARAM), 'stable');
   for idParam = 1:length(params)
      param = params{idParam};
      fieldNames = fields(rtData.PARAM);
      tabSlope = [];
      tabValue = [];
      tabDrift = [];
      tabInclineT = [];
      tabDoCorPres = [];
      tabAdjError = [];
      tabAdjErrorStr = [];
      tabAdjErrorMethod = [];
      tabDate = [];
      tabDateApply = [];
      tabEquation = [];
      tabCoef = [];
      tabComment = [];
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
            if (isfield(rtData, 'DRIFT'))
               if (isfield(rtData.DRIFT, ['DRIFT_' paramNum]))
                  drift = str2double(rtData.DRIFT.(['DRIFT_' paramNum]));
                  tabDrift = [tabDrift drift];
               else
                  tabDrift = [tabDrift 0];
               end
            else
               tabDrift = [tabDrift 0];
            end
            if (isfield(rtData, 'INCLINE'))
               if (isfield(rtData.INCLINE, ['INCLINE_' paramNum]))
                  inclineT = str2double(rtData.INCLINE.(['INCLINE_' paramNum]));
                  tabInclineT = [tabInclineT inclineT];
               else
                  tabInclineT = [tabInclineT 0];
               end
            else
               tabInclineT = [tabInclineT 0];
            end
            if (isfield(rtData, 'COR'))
               if (isfield(rtData.COR, ['COR_' paramNum]))
                  doCorPres = str2double(rtData.COR.(['COR_' paramNum]));
                  tabDoCorPres = [tabDoCorPres doCorPres];
               else
                  tabDoCorPres = [tabDoCorPres nan];
               end
            else
               tabDoCorPres = [tabDoCorPres nan];
            end
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
                  tabAdjErrorMethod{end+1} = adjErrorMethod;
               else
                  tabAdjErrorMethod{end+1} = 'nan';
               end
            else
               tabAdjErrorMethod{end+1} = 'nan';
            end
            date = rtData.DATE.(['DATE_' paramNum]);
            date = datenum(date, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
            tabDate = [tabDate date];
            if (isfield(rtData, 'DATE_APPLY'))
               if (isfield(rtData.DATE_APPLY, ['DATE_APPLY_' paramNum]))
                  dateApply = rtData.DATE_APPLY.(['DATE_APPLY_' paramNum]);
                  if (any(strfind(dateApply, '/')))
                     dateApply = datenum(dateApply, 'dd/mm/yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
                  else
                     dateApply = datenum(dateApply, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
                  end
                  tabDateApply = [tabDateApply dateApply];
               else
                  tabDateApply = [tabDateApply nan];
               end
            else
               tabDateApply = [tabDateApply nan];
            end
            
            % direct copy of DB information (to be reported in case of linear
            % adjustment)
            % be careful: the order in CALIB_RT_PARAMETER and RT_OFFSET.PARAM
            % are not necessarily the same
            % look for current PARAM number in CALIB_RT_PARAMETER => paramNum2
            paramNum2 = '';
            fieldNames2 = fields(a_metaData.CALIB_RT_PARAMETER);
            for id = 1:length(fieldNames2)
               if (strcmp(a_metaData.CALIB_RT_PARAMETER.(['CALIB_RT_PARAMETER_' num2str(id)]), param))
                  paramNum2 = id;
                  break
               end
            end
            tabEquation = [tabEquation {a_metaData.CALIB_RT_EQUATION.(['CALIB_RT_EQUATION_' num2str(paramNum2)])}];
            tabCoef = [tabCoef {a_metaData.CALIB_RT_COEFFICIENT.(['CALIB_RT_COEFFICIENT_' num2str(paramNum2)])}];
            tabComment = [tabComment {a_metaData.CALIB_RT_COMMENT.(['CALIB_RT_COMMENT_' num2str(paramNum2)])}];
         end
      end
      [tabDate, idSorted] = sort(tabDate);
      tabSlope = tabSlope(idSorted);
      tabValue = tabValue(idSorted);
      tabDrift = tabDrift(idSorted);
      tabInclineT = tabInclineT(idSorted);
      tabDoCorPres = tabDoCorPres(idSorted);
      tabAdjError = tabAdjError(idSorted);
      tabAdjErrorStr = tabAdjErrorStr(idSorted);
      tabAdjErrorMethod = tabAdjErrorMethod(idSorted);
      tabDateApply = tabDateApply(idSorted);
      tabEquation = tabEquation(idSorted);
      tabCoef = tabCoef(idSorted);
      tabComment = tabComment(idSorted);
      
      % store the RT offsets
      o_rtOffsetInfo.param{end+1} = param;
      o_rtOffsetInfo.slope{end+1} = tabSlope;
      o_rtOffsetInfo.value{end+1} = tabValue;
      o_rtOffsetInfo.drift{end+1} = tabDrift;
      o_rtOffsetInfo.inclineT{end+1} = tabInclineT;
      o_rtOffsetInfo.doCorPres{end+1} = tabDoCorPres;
      o_rtOffsetInfo.adjError{end+1} = tabAdjError;
      o_rtOffsetInfo.adjErrorStr{end+1} = tabAdjErrorStr;
      o_rtOffsetInfo.adjErrorMethod{end+1} = tabAdjErrorMethod;
      o_rtOffsetInfo.equation{end+1} = tabEquation;
      o_rtOffsetInfo.coefficient{end+1} = tabCoef;
      o_rtOffsetInfo.comment{end+1} = tabComment;
      o_rtOffsetInfo.date{end+1} = tabDate;
      o_rtOffsetInfo.dateApply{end+1} = tabDateApply;
   end
end

return
