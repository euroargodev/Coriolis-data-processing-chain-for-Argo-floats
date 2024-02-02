% ------------------------------------------------------------------------------
% Get RT adjustment information from database.
%
% SYNTAX :
%  [o_rtOffsetStruct] = get_rt_offset(a_metaData, a_idForWmo)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   a_metaData : all meta-data information
%   a_idForWmo : index in meta-data for the concerned float
%   floatNum : float WMO number
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/24/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rtOffsetStruct] = get_rt_offset(a_metaData, a_idForWmo, floatNum)

% output parameters initialization
o_rtOffsetStruct = '';


idF = find(strcmp(a_metaData(a_idForWmo, 5), 'CALIB_RT_PARAMETER') == 1);
if (~isempty(idF))

   floatNum = str2double(a_metaData{a_idForWmo(idF(1)), 1});
   
   rtOffsetData = [];
   
   dimLevelParam = [];
   dimLevelValueSlope = [];
   dimLevelDate = [];
   dimLevelDateApply = [];
   
   dimLevelAdjError = [];
   dimLevelAdjErrorMethod = [];
   
   rtOffsetParam = [];
   for id = 1:length(idF)
      dimLevel = str2num(a_metaData{a_idForWmo(idF(id)), 3});
      fieldName = ['PARAM_' num2str(dimLevel)];
      rtOffsetParam.(fieldName) = a_metaData{a_idForWmo(idF(id)), 4};
      dimLevelParam = [dimLevelParam dimLevel];
   end
   
   rtOffsetSlope = [];
   rtOffsetValue = [];
   rtOffsetDrift = [];
   rtOffsetInclineT = [];
   rtOffsetCor = [];
   idF = find(strcmp(a_metaData(a_idForWmo, 5), 'CALIB_RT_COEFFICIENT') == 1);
   for id = 1:length(idF)
      dimLevel = str2num(a_metaData{a_idForWmo(idF(id)), 3});
      fieldNameValue = ['VALUE_' num2str(dimLevel)];
      fieldNameSlope = ['SLOPE_' num2str(dimLevel)];
      fieldNameDrift = ['DRIFT_' num2str(dimLevel)];
      fieldNameInclineT = ['INCLINE_' num2str(dimLevel)];
      fieldNameCor = ['COR_' num2str(dimLevel)];
      coefStrOri = a_metaData{a_idForWmo(idF(id)), 4};
      coefStr = regexprep(coefStrOri, ' ', '');
      if (any(strfind(coefStr, 'a0')))
         % expecting a0 and a1 coefficients
         idPos1 = strfind(coefStr, 'a1=');
         idPos2 = strfind(coefStr, ',a0=');
         if (~isempty(idPos1) && ~isempty(idPos2))
            rtOffsetSlope.(fieldNameSlope) = coefStr(idPos1+3:idPos2-1);
            rtOffsetValue.(fieldNameValue) = coefStr(idPos2+4:end);
            [~, statusSlope] = str2num(rtOffsetSlope.(fieldNameSlope));
            [~, statusValue] = str2num(rtOffsetValue.(fieldNameValue));
            if ((statusSlope == 0) || (statusValue == 0))
               fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') - exit\n', ...
                  floatNum, coefStrOri);
               return
            end
            dimLevelValueSlope = [dimLevelValueSlope dimLevel];
         else
            fprintf('ERROR: while parsing CALIB_RT_COEFFICIENT for float %d (found: ''%s'') - exit\n', ...
               floatNum, coefStrOri);
            return
         end
      else
         idPos1 = strfind(coefStr, 'slope=');
         idPos2 = strfind(coefStr, ',offset=');
         idPos3 = strfind(coefStr, ',drift=');
         idPos4 = strfind(coefStr, ',incline_t=');
         idPos5 = strfind(coefStr, ',do_cor_pres=');
         if (~isempty(idPos1) && ~isempty(idPos2))
            rtOffsetSlope.(fieldNameSlope) = coefStr(idPos1+6:idPos2-1);
            if (~isempty(idPos3))
               rtOffsetValue.(fieldNameValue) = coefStr(idPos2+8:idPos3-1);
            elseif (~isempty(idPos4))
               rtOffsetValue.(fieldNameValue) = coefStr(idPos2+8:idPos4-1);
            elseif (~isempty(idPos5))
               rtOffsetValue.(fieldNameValue) = coefStr(idPos2+8:idPos5-1);
            else
               rtOffsetValue.(fieldNameValue) = coefStr(idPos2+8:end);
            end
            [~, statusSlope] = str2num(rtOffsetSlope.(fieldNameSlope));
            [~, statusValue] = str2num(rtOffsetValue.(fieldNameValue));
            if ((statusSlope == 0) || (statusValue == 0))
               fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') - exit\n', ...
                  floatNum, coefStrOri);
               return
            end
            if (~isempty(idPos3))
               if (~isempty(idPos4))
                  rtOffsetDrift.(fieldNameDrift) = coefStr(idPos3+7:idPos4-1);
               else
                  rtOffsetDrift.(fieldNameDrift) = coefStr(idPos3+7:end);
               end
               [~, statusDrift] = str2num(rtOffsetDrift.(fieldNameDrift));
               if (statusDrift == 0)
                  fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') - exit\n', ...
                     floatNum, coefStrOri);
                  return
               end
            else
               rtOffsetDrift.(fieldNameDrift) = '0';
            end
            if (~isempty(idPos4))
               if (~isempty(idPos5))
                  rtOffsetInclineT.(fieldNameInclineT) = coefStr(idPos4+11:idPos5-1);
               else
                  rtOffsetInclineT.(fieldNameInclineT) = coefStr(idPos4+11:end);
               end
               [~, statusInclineT] = str2num(rtOffsetInclineT.(fieldNameInclineT));
               if (statusInclineT == 0)
                  fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') - exit\n', ...
                     floatNum, coefStrOri);
                  return
               end
            else
               rtOffsetInclineT.(fieldNameInclineT) = '0';
            end
            if (~isempty(idPos5))
               rtOffsetCor.(fieldNameCor) = coefStr(idPos5+13:end);
               [~, statusCor] = str2num(rtOffsetCor.(fieldNameCor));
               if (statusCor == 0)
                  fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') - exit\n', ...
                     floatNum, coefStrOri);
                  return
               end
            end
            dimLevelValueSlope = [dimLevelValueSlope dimLevel];
         else
            fprintf('ERROR: while parsing CALIB_RT_COEFFICIENT for float %d (found: ''%s'') - exit\n', ...
               floatNum, coefStrOri);
            return
         end
      end
   end
   
   rtOffsetDate = [];
   idF = find(strcmp(a_metaData(a_idForWmo, 5), 'CALIB_RT_DATE') == 1);
   for id = 1:length(idF)
      dimLevel = str2num(a_metaData{a_idForWmo(idF(id)), 3});
      fieldName = ['DATE_' num2str(dimLevel)];
      rtOffsetDate.(fieldName) = a_metaData{a_idForWmo(idF(id)), 4};
      dimLevelDate = [dimLevelDate dimLevel];
   end

   rtOffsetDateApply = [];
   idF = find(strcmp(a_metaData(a_idForWmo, 5), 'CALIB_RT_DATE_APPLY') == 1);
   for id = 1:length(idF)
      dimLevel = str2num(a_metaData{a_idForWmo(idF(id)), 3});
      fieldName = ['DATE_APPLY_' num2str(dimLevel)];
      rtOffsetDateApply.(fieldName) = a_metaData{a_idForWmo(idF(id)), 4};
      dimLevelDateApply = [dimLevelDateApply dimLevel];
   end
   
   rtOffsetAdjError = [];
   idF = find(strcmp(a_metaData(a_idForWmo, 5), 'CALIB_RT_ADJUSTED_ERROR') == 1);
   for id = 1:length(idF)
      dimLevel = str2num(a_metaData{a_idForWmo(idF(id)), 3});
      fieldName = ['ADJUSTED_ERROR_' num2str(dimLevel)];
      rtOffsetAdjError.(fieldName) = a_metaData{a_idForWmo(idF(id)), 4};
      dimLevelAdjError = [dimLevelAdjError dimLevel];
   end
   
   rtOffsetAdjErrorMethod = [];
   idF = find(strcmp(a_metaData(a_idForWmo, 5), 'CALIB_RT_ADJ_ERROR_METHOD') == 1);
   for id = 1:length(idF)
      dimLevel = str2num(a_metaData{a_idForWmo(idF(id)), 3});
      fieldName = ['ADJUSTED_ERROR_METHOD_' num2str(dimLevel)];
      rtOffsetAdjErrorMethod.(fieldName) = a_metaData{a_idForWmo(idF(id)), 4};
      dimLevelAdjErrorMethod = [dimLevelAdjErrorMethod dimLevel];
   end
   
   % check inputs
   
   % PARAM and VALUE/SLOPE should have the same dimm levels
   if (~isempty(setdiff(dimLevelParam, dimLevelValueSlope)))
      missingDimLev = setdiff(dimLevelParam, dimLevelValueSlope);
      for idD = 1:length(missingDimLev)
         fprintf('ERROR: float %d no CALIB_RT_COEFFICIENT provided for DIM_LEVEL %d - exit\n', ...
            floatNum, missingDimLev(idD));
      end
      return
   elseif (~isempty(setdiff(dimLevelValueSlope, dimLevelParam)))
      missingDimLev = setdiff(dimLevelValueSlope, dimLevelParam);
      for idD = 1:length(missingDimLev)
         fprintf('ERROR: float %d no CALIB_RT_PARAMETER provided for DIM_LEVEL %d - exit\n', ...
            floatNum, missingDimLev(idD));
      end
      return
   end
   
   % ADJUSTED_ERROR and ADJUSTED_ERROR_METHOD should have the same dimm levels
   if (~isempty(setdiff(dimLevelAdjError, dimLevelAdjErrorMethod)))
      missingDimLev = setdiff(dimLevelAdjError, dimLevelAdjErrorMethod);
      for idD = 1:length(missingDimLev)
         fprintf('ERROR: float %d no CALIB_RT_ADJ_ERROR_METHOD provided for DIM_LEVEL %d - exit\n', ...
            floatNum, missingDimLev(idD));
      end
      return
   elseif (~isempty(setdiff(dimLevelAdjErrorMethod, dimLevelAdjError)))
      missingDimLev = setdiff(dimLevelAdjErrorMethod, dimLevelAdjError);
      for idD = 1:length(missingDimLev)
         fprintf('ERROR: float %d no CALIB_RT_ADJUSTED_ERROR provided for DIM_LEVEL %d - exit\n', ...
            floatNum, missingDimLev(idD));
      end
      return
   end
   
   % if DATE is not provided, we put launch date so that all profiles will be
   % adjusted
   if (~isempty(setdiff(dimLevelParam, dimLevelDate)))
      missingDimLev = setdiff(dimLevelParam, dimLevelDate);
      for idD = 1:length(missingDimLev)
         fieldName = ['DATE_' num2str(missingDimLev(idD))];
         rtOffsetDate.(fieldName) = ...
            datestr(datenum(metaStruct.LAUNCH_DATE, 'dd/mm/yyyy HH:MM:SS'), 'yyyymmddHHMMSS'); % to adjust all profiles
      end
   end
   
   rtOffsetData.PARAM = rtOffsetParam;
   rtOffsetData.SLOPE = rtOffsetSlope;
   rtOffsetData.VALUE = rtOffsetValue;
   if (~isempty(rtOffsetDrift))
      rtOffsetData.DRIFT = rtOffsetDrift;
   end
   if (~isempty(rtOffsetInclineT))
      rtOffsetData.INCLINE = rtOffsetInclineT;
   end
   if (~isempty(rtOffsetCor))
      rtOffsetData.COR = rtOffsetCor;
   end
   if (~isempty(rtOffsetAdjError))
      rtOffsetData.ADJUSTED_ERROR = rtOffsetAdjError;
   end
   if (~isempty(rtOffsetAdjErrorMethod))
      rtOffsetData.ADJUSTED_ERROR_METHOD = rtOffsetAdjErrorMethod;
   end
   rtOffsetData.DATE = rtOffsetDate;
   if (~isempty(rtOffsetDateApply))
      rtOffsetData.DATE_APPLY = rtOffsetDateApply;
   end

   o_rtOffsetStruct = rtOffsetData;
end

return
