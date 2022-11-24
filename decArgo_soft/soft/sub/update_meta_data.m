% ------------------------------------------------------------------------------
% Update meta-data stored in the json file.
%
% SYNTAX :
%  [o_metaData] = update_meta_data(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_meta_data(a_metaData, a_decoderId)

% output parameters initialization
o_metaData = a_metaData;

% current float WMO number
global g_decArgo_floatNum;


% list of decoder Ids implemented in the current decoder
decoderIdListNke = [1 3 4 11 12 17 19 24 25 27 28 29 30 31 32 105 106 107 109 110 121 201 202 203 204 205 206 208 209 210 211 212 213 301 302 303];
decoderIdListApex = [1001 1002 1003 1004 1005 1006 1007 1008 1009 1010 1011 1012 1013 1016];
decoderIdListNova = [2001 2002];
decoderIdList = [decoderIdListNke decoderIdListApex decoderIdListNova];
% only to check that the function has been updated for each new decoder
if (~ismember(a_decoderId, decoderIdList))
   fprintf('ERROR: Float #%d: decoderId=%d is not present in the check list of the update_meta_data function\n', ...
      g_decArgo_floatNum);
end

% add a POSITIONING_SYSTEM = 'IRIDIUM' to GPS floats
if ~(fix(a_decoderId/100) == 1) % because this should not be done for Remocean floats
   if ((isfield(o_metaData, 'POSITIONING_SYSTEM')) && ...
         (isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_1')) && ...
         (strcmp(o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_1, 'GPS')) && ...
         ~(isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_2')))
      o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_2 = 'IRIDIUM';
      
      fprintf('INFO: Float #%d: adding ''POSITIONING_SYSTEM = IRIDIUM'' to float positioning systems\n', ...
         g_decArgo_floatNum);
   end
end

fieldList = [ ...
   {'PARAMETER_SENSOR'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_ACCURACY'} ...
   {'PARAMETER_RESOLUTION'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_COMMENT'} ...
   ];

if (isfield(o_metaData, 'PARAMETER'))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update CTD meta-data
   
   [o_metaData] = update_parameter_list_ctd(o_metaData);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_ctd(paramList{idP});
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end   
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update OXYGEN meta-data
   
   [o_metaData] = update_parameter_list_oxygen(o_metaData, a_decoderId);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_oxygen(paramList{idP}, a_decoderId, o_metaData);
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update RADIOMETRIC meta-data
   
   [o_metaData] = update_parameter_list_radiometric(o_metaData, a_decoderId);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_radiometric(paramList{idP}, a_decoderId);
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update BACKSCATTERING meta-data
   
   [o_metaData] = update_parameter_list_backscattering(o_metaData, a_decoderId);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_backscattering(paramList{idP}, a_decoderId);
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end   
   
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update NITRATE meta-data
   
   [o_metaData] = update_parameter_list_nitrate(o_metaData, a_decoderId);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_nitrate(paramList{idP}, a_decoderId);
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update CHLA meta-data
   
   [o_metaData] = update_parameter_list_chla(o_metaData, a_decoderId);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_chla(paramList{idP}, a_decoderId);
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update CDOM meta-data
   
   [o_metaData] = update_parameter_list_cdom(o_metaData, a_decoderId);
   
   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_cdom(paramList{idP}, a_decoderId);
      if (~isempty(param))
         
         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) => cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end
         
         for idF = 1:length(fieldList)
            if (isempty(o_metaData.(fieldList{idF})))
               for id = 1:length(paramList)
                  o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
               end
            end
         end
         
         o_metaData.PARAMETER_SENSOR.(['PARAMETER_SENSOR_' num2str(idP)]) = paramSensor;
         o_metaData.PARAMETER_UNITS.(['PARAMETER_UNITS_' num2str(idP)]) = paramUnits;
         o_metaData.PARAMETER_ACCURACY.(['PARAMETER_ACCURACY_' num2str(idP)]) = paramAccuracy;
         o_metaData.PARAMETER_RESOLUTION.(['PARAMETER_RESOLUTION_' num2str(idP)]) = paramResolution;
         o_metaData.PREDEPLOYMENT_CALIB_EQUATION.(['PREDEPLOYMENT_CALIB_EQUATION_' num2str(idP)]) = preCalibEq;
         o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.(['PREDEPLOYMENT_CALIB_COEFFICIENT_' num2str(idP)]) = preCalibCoef;
         o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(['PREDEPLOYMENT_CALIB_COMMENT_' num2str(idP)]) = preCalibComment;
      end
   end   
   
else
   fprintf('WARNING: Float #%d: ''PARAMETER'' field not found in Json meta-data information => parameter information cannot be updated\n', ...
      g_decArgo_floatNum);
end

return;

% ------------------------------------------------------------------------------
% Update parameter list for ctd associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_ctd(a_metaData)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/24/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_ctd(a_metaData)

paramList = [ ...
   {'PRES'} ...
   {'TEMP'} ...
   {'PSAL'} ...
   ];

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for ctd associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_ctd(a_paramName)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/27/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_ctd(a_paramName)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';


switch (a_paramName)
   
   case {'PRES'}
      o_param = 'PRES';
      o_paramSensor = 'CTD_PRES';
      o_paramUnits = 'decibar';
      o_paramAccuracy = '2.4';
      o_paramResolution = '1';
      o_preCalibEq = 'none';
      o_preCalibCoef = 'none';
      o_preCalibComment = '';
      
   case {'TEMP'}
      o_param = 'TEMP';
      o_paramSensor = 'CTD_TEMP';
      o_paramUnits = 'degree_Celsius';
      o_paramAccuracy = '0.002';
      o_paramResolution = '0.001';
      o_preCalibEq = 'none';
      o_preCalibCoef = 'none';
      o_preCalibComment = '';
      
   case {'PSAL'}
      o_param = 'PSAL';
      o_paramSensor = 'CTD_PSAL';
      o_paramUnits = 'psu';
      o_paramAccuracy = '0.005';
      o_paramResolution = '0.001';
      o_preCalibEq = 'none';
      o_preCalibCoef = 'none';
      o_preCalibComment = '';

end

return;

% ------------------------------------------------------------------------------
% Update parameter list for oxygen associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_oxygen(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/13/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_oxygen(a_metaData, a_decoderId)

% float configuration
global g_decArgo_floatConfig;

paramList = [];
switch (a_decoderId)
   case {4, 19, 25}
      paramList = [ ...
         {'MOLAR_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {27, 28, 29, 32}
      paramList = [ ...
         {'TPHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {106, 301, 202, 207, 208, 213, 107, 109, 110, 201, 203, 206, 121}
      if (ismember(a_decoderId, [106 107 109 110 213]))
         if (a_decoderId == 213)
         
            % retrieve configuration parameters
            configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
            configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;
            
            % retrieve PX04 configuration value (to get if the optode is mounted
            % on an additional stick)
            optodeInAirMeasFlag = [];
            idPos = find(strncmp('CONFIG_PX04_', configNames, length('CONFIG_PX04_')) == 1, 1);
            if (~isempty(idPos))
               optodeInAirMeasFlag = configValues(idPos, end);
            end
         else
            
            optodeInAirMeasFlag = get_static_config_value('CONFIG_PX_1_1_0_0_7', 0);
         end
         if (isempty(optodeInAirMeasFlag) || (optodeInAirMeasFlag == 0))
            paramList = [ ...
               {'TEMP_DOXY'} ...
               {'C1PHASE_DOXY'} ...
               {'C2PHASE_DOXY'} ...
               {'DOXY'} ...
               ];
         else
            paramList = [ ...
               {'TEMP_DOXY'} ...
               {'C1PHASE_DOXY'} ...
               {'C2PHASE_DOXY'} ...
               {'PPOX_DOXY'} ...
               {'DOXY'} ...
               ];
         end
      else
         paramList = [ ...
            {'TEMP_DOXY'} ...
            {'C1PHASE_DOXY'} ...
            {'C2PHASE_DOXY'} ...
            {'PPOX_DOXY'} ...
            {'DOXY'} ...
            ];
      end
      
   case {209}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'C1PHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         {'TEMP_DOXY2'} ...
         {'PHASE_DELAY_DOXY'} ...
         {'PPOX_DOXY2'} ...
         {'DOXY2'} ...
         ];
      
   case {302, 303}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'DPHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {2002}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'PHASE_DELAY_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {1006, 1008, 1014, 1016}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'BPHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {1009}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'TPHASE_DOXY'} ...
         {'RPHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];
      
   case {1013, 1015}
      paramList = [ ...
         {'FREQUENCY_DOXY'} ...
         {'DOXY'} ...
         ];
end

% for a_decoderId = 201 we have 5.61 floats (with DO sensor) and 5.63 floats
% (without DO sensor)
if (a_decoderId == 201)
   if ((isfield(a_metaData, 'DAC_FORMAT_ID')) && (str2num(a_metaData.DAC_FORMAT_ID) == 5.63))
      paramList = [];
   end
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for oxygen associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_oxygen(a_paramName, a_decoderId, a_metaData)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%   a_decoderId : float decoder Id
%   a_metaData  : input meta-data to be updated
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/08/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_oxygen(a_paramName, a_decoderId, a_metaData)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0_aanderaa;
global g_decArgo_doxy_201and202_201_301_b1_aanderaa;
global g_decArgo_doxy_201and202_201_301_b2_aanderaa;
global g_decArgo_doxy_201and202_201_301_b3_aanderaa;
global g_decArgo_doxy_201and202_201_301_c0_aanderaa;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;

global g_decArgo_doxy_202_204_204_d0;
global g_decArgo_doxy_202_204_204_d1;
global g_decArgo_doxy_202_204_204_d2;
global g_decArgo_doxy_202_204_204_d3;
global g_decArgo_doxy_202_204_204_sPreset;
global g_decArgo_doxy_202_204_204_b0;
global g_decArgo_doxy_202_204_204_b1;
global g_decArgo_doxy_202_204_204_b2;
global g_decArgo_doxy_202_204_204_b3;
global g_decArgo_doxy_202_204_204_c0;
global g_decArgo_doxy_202_204_204_pCoef1;
global g_decArgo_doxy_202_204_204_pCoef2;
global g_decArgo_doxy_202_204_204_pCoef3;

global g_decArgo_doxy_202_204_304_d0;
global g_decArgo_doxy_202_204_304_d1;
global g_decArgo_doxy_202_204_304_d2;
global g_decArgo_doxy_202_204_304_d3;
global g_decArgo_doxy_202_204_304_sPreset;
global g_decArgo_doxy_202_204_304_b0;
global g_decArgo_doxy_202_204_304_b1;
global g_decArgo_doxy_202_204_304_b2;
global g_decArgo_doxy_202_204_304_b3;
global g_decArgo_doxy_202_204_304_c0;
global g_decArgo_doxy_202_204_304_pCoef1;
global g_decArgo_doxy_202_204_304_pCoef2;
global g_decArgo_doxy_202_204_304_pCoef3;

global g_decArgo_doxy_202_204_202_a0;
global g_decArgo_doxy_202_204_202_a1;
global g_decArgo_doxy_202_204_202_a2;
global g_decArgo_doxy_202_204_202_a3;
global g_decArgo_doxy_202_204_202_a4;
global g_decArgo_doxy_202_204_202_a5;
global g_decArgo_doxy_202_204_202_d0;
global g_decArgo_doxy_202_204_202_d1;
global g_decArgo_doxy_202_204_202_d2;
global g_decArgo_doxy_202_204_202_d3;
global g_decArgo_doxy_202_204_202_sPreset;
global g_decArgo_doxy_202_204_202_b0;
global g_decArgo_doxy_202_204_202_b1;
global g_decArgo_doxy_202_204_202_b2;
global g_decArgo_doxy_202_204_202_b3;
global g_decArgo_doxy_202_204_202_c0;
global g_decArgo_doxy_202_204_202_pCoef1;
global g_decArgo_doxy_202_204_202_pCoef2;
global g_decArgo_doxy_202_204_202_pCoef3;

global g_decArgo_doxy_202_204_203_a0;
global g_decArgo_doxy_202_204_203_a1;
global g_decArgo_doxy_202_204_203_a2;
global g_decArgo_doxy_202_204_203_a3;
global g_decArgo_doxy_202_204_203_a4;
global g_decArgo_doxy_202_204_203_a5;
global g_decArgo_doxy_202_204_203_d0;
global g_decArgo_doxy_202_204_203_d1;
global g_decArgo_doxy_202_204_203_d2;
global g_decArgo_doxy_202_204_203_d3;
global g_decArgo_doxy_202_204_203_sPreset;
global g_decArgo_doxy_202_204_203_b0;
global g_decArgo_doxy_202_204_203_b1;
global g_decArgo_doxy_202_204_203_b2;
global g_decArgo_doxy_202_204_203_b3;
global g_decArgo_doxy_202_204_203_c0;
global g_decArgo_doxy_202_204_203_pCoef1;
global g_decArgo_doxy_202_204_203_pCoef2;
global g_decArgo_doxy_202_204_203_pCoef3;

global g_decArgo_doxy_202_205_302_a0;
global g_decArgo_doxy_202_205_302_a1;
global g_decArgo_doxy_202_205_302_a2;
global g_decArgo_doxy_202_205_302_a3;
global g_decArgo_doxy_202_205_302_a4;
global g_decArgo_doxy_202_205_302_a5;
global g_decArgo_doxy_202_205_302_d0;
global g_decArgo_doxy_202_205_302_d1;
global g_decArgo_doxy_202_205_302_d2;
global g_decArgo_doxy_202_205_302_d3;
global g_decArgo_doxy_202_205_302_sPreset;
global g_decArgo_doxy_202_205_302_b0;
global g_decArgo_doxy_202_205_302_b1;
global g_decArgo_doxy_202_205_302_b2;
global g_decArgo_doxy_202_205_302_b3;
global g_decArgo_doxy_202_205_302_c0;
global g_decArgo_doxy_202_205_302_pCoef1;
global g_decArgo_doxy_202_205_302_pCoef2;
global g_decArgo_doxy_202_205_302_pCoef3;

global g_decArgo_doxy_202_205_303_a0;
global g_decArgo_doxy_202_205_303_a1;
global g_decArgo_doxy_202_205_303_a2;
global g_decArgo_doxy_202_205_303_a3;
global g_decArgo_doxy_202_205_303_a4;
global g_decArgo_doxy_202_205_303_a5;
global g_decArgo_doxy_202_205_303_d0;
global g_decArgo_doxy_202_205_303_d1;
global g_decArgo_doxy_202_205_303_d2;
global g_decArgo_doxy_202_205_303_d3;
global g_decArgo_doxy_202_205_303_sPreset;
global g_decArgo_doxy_202_205_303_b0;
global g_decArgo_doxy_202_205_303_b1;
global g_decArgo_doxy_202_205_303_b2;
global g_decArgo_doxy_202_205_303_b3;
global g_decArgo_doxy_202_205_303_c0;
global g_decArgo_doxy_202_205_303_pCoef1;
global g_decArgo_doxy_202_205_303_pCoef2;
global g_decArgo_doxy_202_205_303_pCoef3;

global g_decArgo_doxy_202_205_304_d0;
global g_decArgo_doxy_202_205_304_d1;
global g_decArgo_doxy_202_205_304_d2;
global g_decArgo_doxy_202_205_304_d3;
global g_decArgo_doxy_202_205_304_sPreset;
global g_decArgo_doxy_202_205_304_b0;
global g_decArgo_doxy_202_205_304_b1;
global g_decArgo_doxy_202_205_304_b2;
global g_decArgo_doxy_202_205_304_b3;
global g_decArgo_doxy_202_205_304_c0;
global g_decArgo_doxy_202_205_304_pCoef1;
global g_decArgo_doxy_202_205_304_pCoef2;
global g_decArgo_doxy_202_205_304_pCoef3;

global g_decArgo_doxy_103_208_307_d0;
global g_decArgo_doxy_103_208_307_d1;
global g_decArgo_doxy_103_208_307_d2;
global g_decArgo_doxy_103_208_307_d3;
global g_decArgo_doxy_103_208_307_sPreset;
global g_decArgo_doxy_103_208_307_solB0;
global g_decArgo_doxy_103_208_307_solB1;
global g_decArgo_doxy_103_208_307_solB2;
global g_decArgo_doxy_103_208_307_solB3;
global g_decArgo_doxy_103_208_307_solC0;
global g_decArgo_doxy_103_208_307_pCoef1;
global g_decArgo_doxy_103_208_307_pCoef2;
global g_decArgo_doxy_103_208_307_pCoef3;

global g_decArgo_doxy_201_203_202_d0;
global g_decArgo_doxy_201_203_202_d1;
global g_decArgo_doxy_201_203_202_d2;
global g_decArgo_doxy_201_203_202_d3;
global g_decArgo_doxy_201_203_202_sPreset;
global g_decArgo_doxy_201_203_202_b0;
global g_decArgo_doxy_201_203_202_b1;
global g_decArgo_doxy_201_203_202_b2;
global g_decArgo_doxy_201_203_202_b3;
global g_decArgo_doxy_201_203_202_c0;
global g_decArgo_doxy_201_203_202_pCoef1;
global g_decArgo_doxy_201_203_202_pCoef2;
global g_decArgo_doxy_201_203_202_pCoef3;

global g_decArgo_doxy_201_202_202_d0;
global g_decArgo_doxy_201_202_202_d1;
global g_decArgo_doxy_201_202_202_d2;
global g_decArgo_doxy_201_202_202_d3;
global g_decArgo_doxy_201_202_202_sPreset;
global g_decArgo_doxy_201_202_202_b0;
global g_decArgo_doxy_201_202_202_b1;
global g_decArgo_doxy_201_202_202_b2;
global g_decArgo_doxy_201_202_202_b3;
global g_decArgo_doxy_201_202_202_c0;
global g_decArgo_doxy_201_202_202_pCoef1;
global g_decArgo_doxy_201_202_202_pCoef2;
global g_decArgo_doxy_201_202_202_pCoef3;

global g_decArgo_doxy_102_207_206_a0;
global g_decArgo_doxy_102_207_206_a1;
global g_decArgo_doxy_102_207_206_a2;
global g_decArgo_doxy_102_207_206_a3;
global g_decArgo_doxy_102_207_206_a4;
global g_decArgo_doxy_102_207_206_a5;
global g_decArgo_doxy_102_207_206_b0;
global g_decArgo_doxy_102_207_206_b1;
global g_decArgo_doxy_102_207_206_b2;
global g_decArgo_doxy_102_207_206_b3;
global g_decArgo_doxy_102_207_206_c0;

switch (a_decoderId)
   case {4, 19, 25}
      % find SENSOR_MODEL
      sensorList = struct2cell(a_metaData.SENSOR);
      idF = find(strcmp(sensorList, 'OPTODE_DOXY'), 1);
      if (isempty(idF))
         fprintf('WARNING: Float #%d: ''OPTODE_DOXY'' sensor is missing in JSON meta-data\n', ...
            g_decArgo_floatNum);
         return;
      end
      sensorModel = a_metaData.SENSOR_MODEL.(['SENSOR_MODEL_' num2str(idF)]);
      if (~strcmp(sensorModel, 'AANDERAA_OPTODE_3830') && ~strcmp(sensorModel, 'AANDERAA_OPTODE_4330'))
         fprintf('WARNING: Float #%d: ''OPTODE_DOXY'' sensor model is inconsistent in JSON meta-data\n', ...
            g_decArgo_floatNum);
         return;
      end
      
      if (strcmp(sensorModel, 'AANDERAA_OPTODE_3830'))
         
         % CASE_201_201_301
         switch (a_paramName)
            
            case {'MOLAR_DOXY'}
               o_param = 'MOLAR_DOXY';
               o_paramSensor = 'OPTODE_DOXY';
               o_paramUnits = 'umol/L';
               o_paramAccuracy = '8 umol/L or 10%';
               o_paramResolution = '1 umol/L';
               o_preCalibEq = 'none';
               o_preCalibCoef = 'none';
               o_preCalibComment = 'dissolved oxygen concentration at zero pressure and in fresh water or at a reference salinity; see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175';
               
            case {'DOXY'}
               % get calibration information
               if (isempty(g_decArgo_calibInfo) || ...
                     ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                     ~isfield(g_decArgo_calibInfo.OPTODE, 'DoxyCalibRefSalinity'))
                  fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               doxyCalibRefSalinity = g_decArgo_calibInfo.OPTODE.DoxyCalibRefSalinity;
               
               o_param = 'DOXY';
               o_paramSensor = 'OPTODE_DOXY';
               o_paramUnits = 'umol/kg';
               o_paramAccuracy = '8 umol/kg or 10%';
               o_paramResolution = '1 umol/kg';
               o_preCalibEq = 'O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[(PSAL-Sref)*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*(PSAL^2-Sref^2)]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho; where rho is the potential density [kg/L] calculated from CTD data';
               o_preCalibCoef = sprintf('Sref=%g; Spreset=%g; Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
                  doxyCalibRefSalinity, ...
                  g_decArgo_doxy_201and202_201_301_sPreset, ...
                  g_decArgo_doxy_201and202_201_301_pCoef2, ...
                  g_decArgo_doxy_201and202_201_301_pCoef3, ...
                  g_decArgo_doxy_201and202_201_301_b0, ...
                  g_decArgo_doxy_201and202_201_301_b1, ...
                  g_decArgo_doxy_201and202_201_301_b2, ...
                  g_decArgo_doxy_201and202_201_301_b3, ...
                  g_decArgo_doxy_201and202_201_301_c0, ...
                  g_decArgo_doxy_201and202_201_301_d0, ...
                  g_decArgo_doxy_201and202_201_301_d1, ...
                  g_decArgo_doxy_201and202_201_301_d2, ...
                  g_decArgo_doxy_201and202_201_301_d3 ...
                  );
               o_preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
               
            case {'PPOX_DOXY'}
               % get calibration information
               if (isempty(g_decArgo_calibInfo) || ...
                     ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                     ~isfield(g_decArgo_calibInfo.OPTODE, 'DoxyCalibRefSalinity'))
                  fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               doxyCalibRefSalinity = g_decArgo_calibInfo.OPTODE.DoxyCalibRefSalinity;
               
               o_param = 'PPOX_DOXY';
               o_paramSensor = 'OPTODE_DOXY';
               o_paramUnits = 'mbar';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL=0))]; MOLAR_DOXY=A*MOLAR_DOXY/exp[Sref*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*Sref^2]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2O(TEMP,PSAL=0)))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
               o_preCalibCoef = sprintf('Sref=%g; Spreset=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; D0=%g, D1=%g, D2=%g, D3=%g; Pcoef2=%g, Pcoef3=%g', ...
                  doxyCalibRefSalinity, ...
                  g_decArgo_doxy_201and202_201_301_sPreset, ...
                  g_decArgo_doxy_201and202_201_301_b0_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_b1_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_b2_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_b3_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_c0_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_d0, ...
                  g_decArgo_doxy_201and202_201_301_d1, ...
                  g_decArgo_doxy_201and202_201_301_d2, ...
                  g_decArgo_doxy_201and202_201_301_d3, ...
                  g_decArgo_doxy_201and202_201_301_pCoef2, ...
                  g_decArgo_doxy_201and202_201_301_pCoef3 ...
                  );
               o_preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
         end
      else
         
         % CASE_202_201_301
         switch (a_paramName)
            
            case {'MOLAR_DOXY'}
               o_param = 'MOLAR_DOXY';
               o_paramSensor = 'OPTODE_DOXY';
               o_paramUnits = 'umol/L';
               o_paramAccuracy = '8 umol/L or 10%';
               o_paramResolution = '1 umol/L';
               o_preCalibEq = 'none';
               o_preCalibCoef = 'none';
               o_preCalibComment = 'dissolved oxygen concentration at zero pressure and in fresh water or at a reference salinity; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
               
            case {'DOXY'}
               % get calibration information
               if (isempty(g_decArgo_calibInfo) || ...
                     ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                     ~isfield(g_decArgo_calibInfo.OPTODE, 'DoxyCalibRefSalinity'))
                  fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               doxyCalibRefSalinity = g_decArgo_calibInfo.OPTODE.DoxyCalibRefSalinity;
               
               o_param = 'DOXY';
               o_paramSensor = 'OPTODE_DOXY';
               o_paramUnits = 'umol/kg';
               o_paramAccuracy = '8 umol/kg or 10%';
               o_paramResolution = '1 umol/kg';
               o_preCalibEq = 'O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[(PSAL-Sref)*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*(PSAL^2-Sref^2)]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho; where rho is the potential density [kg/L] calculated from CTD data';
               o_preCalibCoef = sprintf('Sref=%g; Spreset=%g; Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
                  doxyCalibRefSalinity, ...
                  g_decArgo_doxy_201and202_201_301_sPreset, ...
                  g_decArgo_doxy_201and202_201_301_pCoef2, ...
                  g_decArgo_doxy_201and202_201_301_pCoef3, ...
                  g_decArgo_doxy_201and202_201_301_b0, ...
                  g_decArgo_doxy_201and202_201_301_b1, ...
                  g_decArgo_doxy_201and202_201_301_b2, ...
                  g_decArgo_doxy_201and202_201_301_b3, ...
                  g_decArgo_doxy_201and202_201_301_c0, ...
                  g_decArgo_doxy_201and202_201_301_d0, ...
                  g_decArgo_doxy_201and202_201_301_d1, ...
                  g_decArgo_doxy_201and202_201_301_d2, ...
                  g_decArgo_doxy_201and202_201_301_d3 ...
                  );
               o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
               
            case {'PPOX_DOXY'}
               % get calibration information
               if (isempty(g_decArgo_calibInfo) || ...
                     ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                     ~isfield(g_decArgo_calibInfo.OPTODE, 'DoxyCalibRefSalinity'))
                  fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               doxyCalibRefSalinity = g_decArgo_calibInfo.OPTODE.DoxyCalibRefSalinity;
               
               o_param = 'PPOX_DOXY';
               o_paramSensor = 'OPTODE_DOXY';
               o_paramUnits = 'mbar';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL=0))]; MOLAR_DOXY=A*MOLAR_DOXY/exp[Sref*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*Sref^2]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2O(TEMP,PSAL=0)))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
               o_preCalibCoef = sprintf('Sref=%g; Spreset=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; D0=%g, D1=%g, D2=%g, D3=%g; Pcoef2=%g, Pcoef3=%g', ...
                  doxyCalibRefSalinity, ...
                  g_decArgo_doxy_201and202_201_301_sPreset, ...
                  g_decArgo_doxy_201and202_201_301_b0_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_b1_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_b2_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_b3_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_c0_aanderaa, ...
                  g_decArgo_doxy_201and202_201_301_d0, ...
                  g_decArgo_doxy_201and202_201_301_d1, ...
                  g_decArgo_doxy_201and202_201_301_d2, ...
                  g_decArgo_doxy_201and202_201_301_d3, ...
                  g_decArgo_doxy_201and202_201_301_pCoef2, ...
                  g_decArgo_doxy_201and202_201_301_pCoef3 ...
                  );
               o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
         end
      end
      
   case {27, 32}
      % CASE_202_204_204
      switch (a_paramName)
         
         case {'TPHASE_DOXY'}
            o_param = 'TPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; MOLAR_DOXY=[((c3+c4*TEMP)/(c5+c6*CalPhase))-1]/Ksv; Ksv=c0+c1*TEMP+c2*TEMP^2; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_204_204_sPreset, ...
               g_decArgo_doxy_202_204_204_pCoef1, ...
               g_decArgo_doxy_202_204_204_pCoef2, ...
               g_decArgo_doxy_202_204_204_pCoef3, ...
               g_decArgo_doxy_202_204_204_b0, ...
               g_decArgo_doxy_202_204_204_b1, ...
               g_decArgo_doxy_202_204_204_b2, ...
               g_decArgo_doxy_202_204_204_b3, ...
               g_decArgo_doxy_202_204_204_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_204_204_d0, ...
               g_decArgo_doxy_202_204_204_d1, ...
               g_decArgo_doxy_202_204_204_d2, ...
               g_decArgo_doxy_202_204_204_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; Ksv=c0+c1*TEMP+c2*TEMP^2; MOLAR_DOXY=[((c3+c4*TEMP)/(c5+c6*CalPhase))-1]/Ksv; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_204_204_pCoef1, ...
               g_decArgo_doxy_202_204_204_pCoef2, ...
               g_decArgo_doxy_202_204_204_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_204_204_d0, ...
               g_decArgo_doxy_202_204_204_d1, ...
               g_decArgo_doxy_202_204_204_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {28}
      % CASE_202_204_202
      switch (a_paramName)
         
         case {'TPHASE_DOXY'}
            o_param = 'TPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_204_202_sPreset, ...
               g_decArgo_doxy_202_204_202_pCoef1, ...
               g_decArgo_doxy_202_204_202_pCoef2, ...
               g_decArgo_doxy_202_204_202_pCoef3, ...
               g_decArgo_doxy_202_204_202_b0, ...
               g_decArgo_doxy_202_204_202_b1, ...
               g_decArgo_doxy_202_204_202_b2, ...
               g_decArgo_doxy_202_204_202_b3, ...
               g_decArgo_doxy_202_204_202_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decArgo_doxy_202_204_202_a0, ...
               g_decArgo_doxy_202_204_202_a1, ...
               g_decArgo_doxy_202_204_202_a2, ...
               g_decArgo_doxy_202_204_202_a3, ...
               g_decArgo_doxy_202_204_202_a4, ...
               g_decArgo_doxy_202_204_202_a5, ...
               g_decArgo_doxy_202_204_202_d0, ...
               g_decArgo_doxy_202_204_202_d1, ...
               g_decArgo_doxy_202_204_202_d2, ...
               g_decArgo_doxy_202_204_202_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=Cstar*44.614*AirSat/100; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_204_202_pCoef1, ...
               g_decArgo_doxy_202_204_202_pCoef2, ...
               g_decArgo_doxy_202_204_202_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decArgo_doxy_202_204_202_a0, ...
               g_decArgo_doxy_202_204_202_a1, ...
               g_decArgo_doxy_202_204_202_a2, ...
               g_decArgo_doxy_202_204_202_a3, ...
               g_decArgo_doxy_202_204_202_a4, ...
               g_decArgo_doxy_202_204_202_a5, ...
               g_decArgo_doxy_202_204_202_d0, ...
               g_decArgo_doxy_202_204_202_d1, ...
               g_decArgo_doxy_202_204_202_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {29}
      % CASE_202_204_203
      switch (a_paramName)
         
         case {'TPHASE_DOXY'}
            o_param = 'TPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_204_203_sPreset, ...
               g_decArgo_doxy_202_204_203_pCoef1, ...
               g_decArgo_doxy_202_204_203_pCoef2, ...
               g_decArgo_doxy_202_204_203_pCoef3, ...
               g_decArgo_doxy_202_204_203_b0, ...
               g_decArgo_doxy_202_204_203_b1, ...
               g_decArgo_doxy_202_204_203_b2, ...
               g_decArgo_doxy_202_204_203_b3, ...
               g_decArgo_doxy_202_204_203_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decArgo_doxy_202_204_203_a0, ...
               g_decArgo_doxy_202_204_203_a1, ...
               g_decArgo_doxy_202_204_203_a2, ...
               g_decArgo_doxy_202_204_203_a3, ...
               g_decArgo_doxy_202_204_203_a4, ...
               g_decArgo_doxy_202_204_203_a5, ...
               g_decArgo_doxy_202_204_203_d0, ...
               g_decArgo_doxy_202_204_203_d1, ...
               g_decArgo_doxy_202_204_203_d2, ...
               g_decArgo_doxy_202_204_203_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_204_203_pCoef1, ...
               g_decArgo_doxy_202_204_203_pCoef2, ...
               g_decArgo_doxy_202_204_203_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decArgo_doxy_202_204_203_a0, ...
               g_decArgo_doxy_202_204_203_a1, ...
               g_decArgo_doxy_202_204_203_a2, ...
               g_decArgo_doxy_202_204_203_a3, ...
               g_decArgo_doxy_202_204_203_a4, ...
               g_decArgo_doxy_202_204_203_a5, ...
               g_decArgo_doxy_202_204_203_d0, ...
               g_decArgo_doxy_202_204_203_d1, ...
               g_decArgo_doxy_202_204_203_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {106, 301, 202, 207}
      % CASE_202_205_302
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_202_102_001
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.03 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            o_preCalibCoef = sprintf('T0=%g; T1=%g; T2=%g; T3=%g; T4=%g; T5=%g', ...
               tabDoxyCoef(2, 1:6));
            o_preCalibComment = 'optode temperature, see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C1PHASE_DOXY'}
            o_param = 'C1PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C2PHASE_DOXY'}
            o_param = 'C2PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with red excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP_DOXY^m0*CalPhase^n0+c1*TEMP_DOXY^m1*CalPhase^n1+..+c27*TEMP_DOXY^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP_DOXY+273.15)-4.681*ln(TEMP_DOXY+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts1+A2*Ts1^2+A3*Ts1^3+A4*Ts1^4+A5*Ts1^5; Ts1=ln[(298.15-TEMP_DOXY)/(273.15+TEMP_DOXY)]; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts2+B2*Ts2^2+B3*Ts2^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Ts2=ln[(298.15-TEMP)/(273.15+TEMP)]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_205_302_sPreset, ...
               g_decArgo_doxy_202_205_302_pCoef1, ...
               g_decArgo_doxy_202_205_302_pCoef2, ...
               g_decArgo_doxy_202_205_302_pCoef3, ...
               g_decArgo_doxy_202_205_302_b0, ...
               g_decArgo_doxy_202_205_302_b1, ...
               g_decArgo_doxy_202_205_302_b2, ...
               g_decArgo_doxy_202_205_302_b3, ...
               g_decArgo_doxy_202_205_302_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decArgo_doxy_202_205_302_a0, ...
               g_decArgo_doxy_202_205_302_a1, ...
               g_decArgo_doxy_202_205_302_a2, ...
               g_decArgo_doxy_202_205_302_a3, ...
               g_decArgo_doxy_202_205_302_a4, ...
               g_decArgo_doxy_202_205_302_a5, ...
               g_decArgo_doxy_202_205_302_d0, ...
               g_decArgo_doxy_202_205_302_d1, ...
               g_decArgo_doxy_202_205_302_d2, ...
               g_decArgo_doxy_202_205_302_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP_DOXY^m0*CalPhase^n0+c1*TEMP_DOXY^m1*CalPhase^n1+..+c27*TEMP_DOXY^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP_DOXY+273.15)-4.681*ln(TEMP_DOXY+273.15)])*0.20946]; ln(Cstar)=A0+A1*Ts1+A2*Ts1^2+A3*Ts1^3+A4*Ts1^4+A5*Ts1^5; Ts1=ln[(298.15-TEMP_DOXY)/(273.15+TEMP_DOXY)]; MOLAR_DOXY=Cstar*44.614*AirSat/100; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts2+4.05010*Ts2^2+4.94457*Ts2^3-2.56847e-1*Ts2^4+3.88767*Ts2^5]; Ts2=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_205_302_pCoef1, ...
               g_decArgo_doxy_202_205_302_pCoef2, ...
               g_decArgo_doxy_202_205_302_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decArgo_doxy_202_205_302_a0, ...
               g_decArgo_doxy_202_205_302_a1, ...
               g_decArgo_doxy_202_205_302_a2, ...
               g_decArgo_doxy_202_205_302_a3, ...
               g_decArgo_doxy_202_205_302_a4, ...
               g_decArgo_doxy_202_205_302_a5, ...
               g_decArgo_doxy_202_205_302_d0, ...
               g_decArgo_doxy_202_205_302_d1, ...
               g_decArgo_doxy_202_205_302_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {208}
      % CASE_202_205_303
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_202_102_001
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.03 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            o_preCalibCoef = sprintf('T0=%g; T1=%g; T2=%g; T3=%g; T4=%g; T5=%g', ...
               tabDoxyCoef(2, 1:6));
            o_preCalibComment = 'optode temperature, see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C1PHASE_DOXY'}
            o_param = 'C1PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C2PHASE_DOXY'}
            o_param = 'C2PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with red excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_205_303_sPreset, ...
               g_decArgo_doxy_202_205_303_pCoef1, ...
               g_decArgo_doxy_202_205_303_pCoef2, ...
               g_decArgo_doxy_202_205_303_pCoef3, ...
               g_decArgo_doxy_202_205_303_b0, ...
               g_decArgo_doxy_202_205_303_b1, ...
               g_decArgo_doxy_202_205_303_b2, ...
               g_decArgo_doxy_202_205_303_b3, ...
               g_decArgo_doxy_202_205_303_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decArgo_doxy_202_205_303_a0, ...
               g_decArgo_doxy_202_205_303_a1, ...
               g_decArgo_doxy_202_205_303_a2, ...
               g_decArgo_doxy_202_205_303_a3, ...
               g_decArgo_doxy_202_205_303_a4, ...
               g_decArgo_doxy_202_205_303_a5, ...
               g_decArgo_doxy_202_205_303_d0, ...
               g_decArgo_doxy_202_205_303_d1, ...
               g_decArgo_doxy_202_205_303_d2, ...
               g_decArgo_doxy_202_205_303_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_205_303_pCoef1, ...
               g_decArgo_doxy_202_205_303_pCoef2, ...
               g_decArgo_doxy_202_205_303_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decArgo_doxy_202_205_303_a0, ...
               g_decArgo_doxy_202_205_303_a1, ...
               g_decArgo_doxy_202_205_303_a2, ...
               g_decArgo_doxy_202_205_303_a3, ...
               g_decArgo_doxy_202_205_303_a4, ...
               g_decArgo_doxy_202_205_303_a5, ...
               g_decArgo_doxy_202_205_303_d0, ...
               g_decArgo_doxy_202_205_303_d1, ...
               g_decArgo_doxy_202_205_303_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {107, 109, 110, 201, 203, 206, 213, 121}
      % CASE_202_205_304
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_202_102_001
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.03 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            o_preCalibCoef = 'T0=not available; T1=not available; T2=not available; T3=not available; T4=not available; T5=not available';
            o_preCalibComment = 'optode temperature, see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C1PHASE_DOXY'}
            o_param = 'C1PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C2PHASE_DOXY'}
            o_param = 'C2PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with red excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_205_304_sPreset, ...
               g_decArgo_doxy_202_205_304_pCoef1, ...
               g_decArgo_doxy_202_205_304_pCoef2, ...
               g_decArgo_doxy_202_205_304_pCoef3, ...
               g_decArgo_doxy_202_205_304_b0, ...
               g_decArgo_doxy_202_205_304_b1, ...
               g_decArgo_doxy_202_205_304_b2, ...
               g_decArgo_doxy_202_205_304_b3, ...
               g_decArgo_doxy_202_205_304_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_205_304_d0, ...
               g_decArgo_doxy_202_205_304_d1, ...
               g_decArgo_doxy_202_205_304_d2, ...
               g_decArgo_doxy_202_205_304_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_205_304_pCoef1, ...
               g_decArgo_doxy_202_205_304_pCoef2, ...
               g_decArgo_doxy_202_205_304_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_205_304_d0, ...
               g_decArgo_doxy_202_205_304_d1, ...
               g_decArgo_doxy_202_205_304_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {209}
      % CASE_202_205_304 for AANDERAA
      % CASE_103_208_307 for SBE
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_202_102_001
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.03 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            o_preCalibCoef = 'T0=not available; T1=not available; T2=not available; T3=not available; T4=not available; T5=not available';
            o_preCalibComment = 'optode temperature, see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
            % CASE_202_205_304 for AANDERAA
            
         case {'C1PHASE_DOXY'}
            o_param = 'C1PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'C2PHASE_DOXY'}
            o_param = 'C2PHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with red excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_205_304_sPreset, ...
               g_decArgo_doxy_202_205_304_pCoef1, ...
               g_decArgo_doxy_202_205_304_pCoef2, ...
               g_decArgo_doxy_202_205_304_pCoef3, ...
               g_decArgo_doxy_202_205_304_b0, ...
               g_decArgo_doxy_202_205_304_b1, ...
               g_decArgo_doxy_202_205_304_b2, ...
               g_decArgo_doxy_202_205_304_b3, ...
               g_decArgo_doxy_202_205_304_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_205_304_d0, ...
               g_decArgo_doxy_202_205_304_d1, ...
               g_decArgo_doxy_202_205_304_d2, ...
               g_decArgo_doxy_202_205_304_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_205_304_pCoef1, ...
               g_decArgo_doxy_202_205_304_pCoef2, ...
               g_decArgo_doxy_202_205_304_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_205_304_d0, ...
               g_decArgo_doxy_202_205_304_d1, ...
               g_decArgo_doxy_202_205_304_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'TEMP_DOXY2'} % CASE_103_102_001
            o_param = 'TEMP_DOXY2';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TEMP_DOXY2=1/(TA0+TA1*L+TA2*L^2+TA3*L^3)-273.15; L=ln(100000*TEMP_VOLTAGE_DOXY/(3.3-TEMP_VOLTAGE_DOXY)); TEMP_VOLTAGE_DOXY is the thermistor voltage in volts';
            o_preCalibCoef = 'TA0=not available; TA1=not available; TA2=not available; TA3=not available';
            o_preCalibComment = 'optode temperature, see SBE63 User�s Manual (manual version #007, 10/28/13)';
            
            % CASE_103_208_307 for SBE
            
         case {'PHASE_DELAY_DOXY'}
            o_param = 'PHASE_DELAY_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'usec';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'output phase delay';
            
         case {'DOXY2'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
            if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY2';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '3 umol/kg or 2%';
            o_paramResolution = '0.2 umol/kg';
            o_preCalibEq = 'V=(PHASE_DELAY_DOXY+Pcoef1*PRES/1000)/39.457071; Ksv=C0+C1*TEMP_DOXY2+C2*TEMP_DOXY2^2; MLPL_DOXY=[(A0+A1*TEMP_DOXY2+A2*V^2)/(B0+B1*V)-1]/Ksv; O2=MLPL_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(SolB0+SolB1*TS+SolB2*TS^2+SolB3*TS^3)+SolC0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; TS=ln[(298.15�TEMP)/(273.15+TEMP)]; DOXY2[umol/kg]=44.6596*O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; A0=%g, A1=%g, A2=%g; B0=%g, B1=%g; C0=%g, C1=%g, C2=%g; Spreset=%g; D0=%g, D1=%g, D2=%g, D3=%g; SolB0=%g, SolB1=%g, SolB2=%g, SolB3=%g; SolC0=%g', ...
               g_decArgo_doxy_103_208_307_pCoef1, ...
               g_decArgo_doxy_103_208_307_pCoef2, ...
               g_decArgo_doxy_103_208_307_pCoef3, ...
               tabDoxyCoef(1, 1:8), ...
               g_decArgo_doxy_103_208_307_sPreset, ...
               g_decArgo_doxy_103_208_307_d0, ...
               g_decArgo_doxy_103_208_307_d1, ...
               g_decArgo_doxy_103_208_307_d2, ...
               g_decArgo_doxy_103_208_307_d3, ...
               g_decArgo_doxy_103_208_307_solB0, ...
               g_decArgo_doxy_103_208_307_solB1, ...
               g_decArgo_doxy_103_208_307_solB2, ...
               g_decArgo_doxy_103_208_307_solB3, ...
               g_decArgo_doxy_103_208_307_solC0 ...
               );
            o_preCalibComment = 'see SBE63 User�s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY2'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
            if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY2';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'V=(PHASE_DELAY_DOXY+Pcoef1*PRES/1000)/39.457071; Ksv=C0+C1*TEMP_DOXY2+C2*TEMP_DOXY2^2; MLPL_DOXY=[(A0+A1*TEMP_DOXY2+A2*V^2)/(B0+B1*V)-1]/Ksv; MOLAR_DOXY=44.6596*MLPL_DOXY; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY2=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g; A0=%g, A1=%g, A2=%g; B0=%g, B1=%g; C0=%g, C1=%g, C2=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_103_208_307_pCoef1, ...
               tabDoxyCoef(1, 1:8), ...
               g_decArgo_doxy_103_208_307_d0, ...
               g_decArgo_doxy_103_208_307_d1, ...
               g_decArgo_doxy_103_208_307_d2 ...
               );
            o_preCalibComment = 'see SBE63 User�s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {302, 303}
      % CASE_201_203_202
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_201_102_001
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.05 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            o_preCalibCoef = 'T0=not available; T1=not available; T2=not available; T3=not available; T4=not available; T5=not available';
            o_preCalibComment = 'optode temperature, see TD218 Operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175';
            
         case {'DPHASE_DOXY'}
            o_param = 'DPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Calibrated phase measurement; see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'Phase_Pcorr=DPHASE_DOXY+Pcoef1*PRES/1000; MOLAR_DOXY=c0+c1*Phase_Pcorr+c2*Phase_Pcorr^2+c3*Phase_Pcorr^3+c4*Phase_Pcorr^4; ci=ci0+ci1*TEMP+ci2*TEMP^2+ci3*TEMP^3, i=0..4; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; c00=%g, c01=%g, c02=%g, c03=%g, c10=%g, c11=%g, c12=%g, c13=%g, c20=%g, c21=%g, c22=%g, c23=%g, c30=%g, c31=%g, c32=%g, c33=%g, c40=%g, c41=%g, c42=%g, c43=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_201_203_202_sPreset, ...
               g_decArgo_doxy_201_203_202_pCoef1, ...
               g_decArgo_doxy_201_203_202_pCoef2, ...
               g_decArgo_doxy_201_203_202_pCoef3, ...
               g_decArgo_doxy_201_203_202_b0, ...
               g_decArgo_doxy_201_203_202_b1, ...
               g_decArgo_doxy_201_203_202_b2, ...
               g_decArgo_doxy_201_203_202_b3, ...
               g_decArgo_doxy_201_203_202_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:4), ...
               tabDoxyCoef(3, 1:4), ...
               tabDoxyCoef(4, 1:4), ...
               tabDoxyCoef(5, 1:4), ...
               g_decArgo_doxy_201_203_202_d0, ...
               g_decArgo_doxy_201_203_202_d1, ...
               g_decArgo_doxy_201_203_202_d2, ...
               g_decArgo_doxy_201_203_202_d3 ...
               );
            o_preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=DPHASE_DOXY+Pcoef1*PRES/1000; ci=ci0+ci1*TEMP+ci2*TEMP^2+ci3*TEMP^3, i=0..4; MOLAR_DOXY=c0+c1*Phase_Pcorr+c2*Phase_Pcorr^2+c3*Phase_Pcorr^3+c4*Phase_Pcorr^4; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; c00=%g, c01=%g, c02=%g, c03=%g, c10=%g, c11=%g, c12=%g, c13=%g, c20=%g, c21=%g, c22=%g, c23=%g, c30=%g, c31=%g, c32=%g, c33=%g, c40=%g, c41=%g, c42=%g, c43=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_201_203_202_pCoef1, ...
               g_decArgo_doxy_201_203_202_pCoef2, ...
               g_decArgo_doxy_201_203_202_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:4), ...
               tabDoxyCoef(3, 1:4), ...
               tabDoxyCoef(4, 1:4), ...
               tabDoxyCoef(5, 1:4), ...
               g_decArgo_doxy_201_203_202_d0, ...
               g_decArgo_doxy_201_203_202_d1, ...
               g_decArgo_doxy_201_203_202_d2 ...
               );
            o_preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {2002}
      % CASE_103_208_307
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_103_102_001
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TEMP_DOXY=1/(TA0+TA1*L+TA2*L^2+TA3*L^3)-273.15; L=ln(100000*TEMP_VOLTAGE_DOXY/(3.3-TEMP_VOLTAGE_DOXY)); TEMP_VOLTAGE_DOXY is the thermistor voltage in volts';
            o_preCalibCoef = 'TA0=not available; TA1=not available; TA2=not available; TA3=not available';
            o_preCalibComment = 'optode temperature, see SBE63 User�s Manual (manual version #007, 10/28/13)';
            
         case {'PHASE_DELAY_DOXY'}
            o_param = 'PHASE_DELAY_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'usec';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'output phase delay';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
            if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '3 umol/kg or 2%';
            o_paramResolution = '0.2 umol/kg';
            o_preCalibEq = 'V=(PHASE_DELAY_DOXY+Pcoef1*PRES/1000)/39.457071; Ksv=C0+C1*TEMP_DOXY+C2*TEMP_DOXY^2; MLPL_DOXY=[(A0+A1*TEMP_DOXY+A2*V^2)/(B0+B1*V)-1]/Ksv; MOLAR_DOXY=44.6596*MLPL_DOXY; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; A0=%g, A1=%g, A2=%g; B0=%g, B1=%g; C0=%g, C1=%g, C2=%g; Spreset=%g; D0=%g, D1=%g, D2=%g, D3=%g; SolB0=%g, SolB1=%g, SolB2=%g, SolB3=%g; SolC0=%g', ...
               g_decArgo_doxy_103_208_307_pCoef1, ...
               g_decArgo_doxy_103_208_307_pCoef2, ...
               g_decArgo_doxy_103_208_307_pCoef3, ...
               tabDoxyCoef(1, 1:8), ...
               g_decArgo_doxy_103_208_307_sPreset, ...
               g_decArgo_doxy_103_208_307_d0, ...
               g_decArgo_doxy_103_208_307_d1, ...
               g_decArgo_doxy_103_208_307_d2, ...
               g_decArgo_doxy_103_208_307_d3, ...
               g_decArgo_doxy_103_208_307_solB1, ...
               g_decArgo_doxy_103_208_307_solB2, ...
               g_decArgo_doxy_103_208_307_solB3, ...
               g_decArgo_doxy_103_208_307_solC0 ...
               );
            o_preCalibComment = 'see SBE63 User�s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {1006, 1008, 1014, 1016}
      % CASE_201_202_202
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_201_102_001
            
            % get calibration information
            tabDoxyTempCoef = [];
            if (~isempty(g_decArgo_calibInfo) && ...
                  isfield(g_decArgo_calibInfo, 'OPTODE') && ...
                  isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyTempCoef'))
               tabDoxyTempCoef = g_decArgo_calibInfo.OPTODE.TabDoxyTempCoef;
            end
            
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.05 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            if (isempty(tabDoxyTempCoef))
               o_preCalibCoef = 'T0=not available; T1=not available; T2=not available; T3=not available; T4=not available; T5=not available';
            else
               o_preCalibCoef = sprintf('T0=%g; T1=%g; T2=%g; T3=%g; T4=%g; T5=%g', ...
                  tabDoxyTempCoef(1, 1:6));
            end
            o_preCalibComment = 'optode temperature, see TD218 Operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175';
            
         case {'BPHASE_DOXY'}
            o_param = 'BPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabPhaseCoef') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
            % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
            % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
            if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'UNCAL_Phase=BPHASE_DOXY-RPHASE_DOXY; Phase_Pcorr=UNCAL_Phase+Pcoef1*PRES/1000; DPHASE_DOXY=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Pcorr_Phase^2+PhaseCoef3*Pcorr_Phase^3; MOLAR_DOXY=c0+c1*DPHASE_DOXY+c2*DPHASE_DOXY^2+c3*DPHASE_DOXY^3+c4*DPHASE_DOXY^4; ci=ci0+ci1*TEMP+ci2*TEMP^2+ci3*TEMP^3, i=0..4; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c00=%g, c01=%g, c02=%g, c03=%g, c10=%g, c11=%g, c12=%g, c13=%g, c20=%g, c21=%g, c22=%g, c23=%g, c30=%g, c31=%g, c32=%g, c33=%g, c40=%g, c41=%g, c42=%g, c43=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_201_202_202_sPreset, ...
               g_decArgo_doxy_201_202_202_pCoef1, ...
               g_decArgo_doxy_201_202_202_pCoef2, ...
               g_decArgo_doxy_201_202_202_pCoef3, ...
               g_decArgo_doxy_201_202_202_b0, ...
               g_decArgo_doxy_201_202_202_b1, ...
               g_decArgo_doxy_201_202_202_b2, ...
               g_decArgo_doxy_201_202_202_b3, ...
               g_decArgo_doxy_201_202_202_c0, ...
               tabPhaseCoef(1, 1:4), ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:4), ...
               tabDoxyCoef(3, 1:4), ...
               tabDoxyCoef(4, 1:4), ...
               tabDoxyCoef(5, 1:4), ...
               g_decArgo_doxy_201_202_202_d0, ...
               g_decArgo_doxy_201_202_202_d1, ...
               g_decArgo_doxy_201_202_202_d2, ...
               g_decArgo_doxy_201_202_202_d3 ...
               );
            o_preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabPhaseCoef') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
            % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
            % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
            if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'UNCAL_Phase=BPHASE_DOXY-RPHASE_DOXY; Phase_Pcorr=UNCAL_Phase+Pcoef1*PRES/1000; DPHASE_DOXY=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Pcorr_Phase^2+PhaseCoef3*Pcorr_Phase^3; ci=ci0+ci1*TEMP_DOXY+ci2*TEMP_DOXY^2+ci3*TEMP_DOXY^3, i=0..4; MOLAR_DOXY=c0+c1*DPHASE_DOXY+c2*DPHASE_DOXY^2+c3*DPHASE_DOXY^3+c4*DPHASE_DOXY^4; Pcorr=1+((Pcoef2*TEMP_DOXY+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP_DOXY+273.15))+D2*ln((TEMP_DOXY+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP_DOXY)/(273.15+TEMP_DOXY)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP_DOXY+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c00=%g, c01=%g, c02=%g, c03=%g, c10=%g, c11=%g, c12=%g, c13=%g, c20=%g, c21=%g, c22=%g, c23=%g, c30=%g, c31=%g, c32=%g, c33=%g, c40=%g, c41=%g, c42=%g, c43=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_201_202_202_pCoef1, ...
               g_decArgo_doxy_201_202_202_pCoef2, ...
               g_decArgo_doxy_201_202_202_pCoef3, ...
               tabPhaseCoef(1, 1:4), ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:4), ...
               tabDoxyCoef(3, 1:4), ...
               tabDoxyCoef(4, 1:4), ...
               tabDoxyCoef(5, 1:4), ...
               g_decArgo_doxy_201_202_202_d0, ...
               g_decArgo_doxy_201_202_202_d1, ...
               g_decArgo_doxy_201_202_202_d2 ...
               );
            o_preCalibComment = 'see TD218 operating manual oxygen optode 3830, 3835, 3930, 3975, 4130, 4175; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {1009}
      % CASE_202_204_304
      switch (a_paramName)
         
         case {'TEMP_DOXY'} % CASE_202_102_001
            
            % get calibration information
            tabDoxyTempCoef = [];
            if (~isempty(g_decArgo_calibInfo) && ...
                  isfield(g_decArgo_calibInfo, 'OPTODE') && ...
                  isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyTempCoef'))
               tabDoxyTempCoef = g_decArgo_calibInfo.OPTODE.TabDoxyTempCoef;
            end
            
            o_param = 'TEMP_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '0.03 degC';
            o_paramResolution = '0.01 degC';
            o_preCalibEq = 'TEMP_DOXY=T0+T1*TEMP_VOLTAGE_DOXY+T2*TEMP_VOLTAGE_DOXY^2+T3*TEMP_VOLTAGE_DOXY^3+T4*TEMP_VOLTAGE_DOXY^4+T5*TEMP_VOLTAGE_DOXY^5; with TEMP_VOLTAGE_DOXY=voltage from thermistor bridge (mV)';
            if (isempty(tabDoxyTempCoef))
               o_preCalibCoef = 'T0=not available; T1=not available; T2=not available; T3=not available; T4=not available; T5=not available';
            else
               o_preCalibCoef = sprintf('T0=%g; T1=%g; T2=%g; T3=%g; T4=%g; T5=%g', ...
                  tabDoxyTempCoef(1, 1:6));
            end
            o_preCalibComment = 'optode temperature, see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'TPHASE_DOXY'}
            o_param = 'TPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with blue excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'RPHASE_DOXY'}
            o_param = 'RPHASE_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degree';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Phase measurement with red excitation light; see TD269 Operating manual oxygen optode 4330, 4835, 4831';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_204_304_sPreset, ...
               g_decArgo_doxy_202_204_304_pCoef1, ...
               g_decArgo_doxy_202_204_304_pCoef2, ...
               g_decArgo_doxy_202_204_304_pCoef3, ...
               g_decArgo_doxy_202_204_304_b0, ...
               g_decArgo_doxy_202_204_304_b1, ...
               g_decArgo_doxy_202_204_304_b2, ...
               g_decArgo_doxy_202_204_304_b3, ...
               g_decArgo_doxy_202_204_304_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_204_304_d0, ...
               g_decArgo_doxy_202_204_304_d1, ...
               g_decArgo_doxy_202_204_304_d2, ...
               g_decArgo_doxy_202_204_304_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
            
         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; Ksv=c0+c1*TEMP_DOXY+c2*TEMP_DOXY^2; MOLAR_DOXY=[((c3+c4*TEMP_DOXY)/(c5+c6*CalPhase))-1]/Ksv; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_204_304_pCoef1, ...
               g_decArgo_doxy_202_204_304_pCoef2, ...
               g_decArgo_doxy_202_204_304_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(2, 1:7), ...
               g_decArgo_doxy_202_204_304_d0, ...
               g_decArgo_doxy_202_204_304_d1, ...
               g_decArgo_doxy_202_204_304_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
      
   case {1013, 1015}
      % CASE_102_207_206
      switch (a_paramName)
         
         case {'FREQUENCY_DOXY'}
            o_param = 'FREQUENCY_DOXY';
            o_paramSensor = 'IDO_DOXY';
            o_paramUnits = 'hertz';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Output frequency of the DO sensor';
            
         case {'DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef'))
               fprintf('WARNING: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
            if (~isempty(find((size(tabDoxyCoef) == [1 6]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOXY';
            o_paramSensor = 'IDO_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '4 umol/kg or 2%';
            o_paramResolution = '0.4 umol/kg';
            o_preCalibEq = 'Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; Oxsol=exp[A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5+PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; MLPL_DOXY=Soc*(FREQUENCY_DOXY+Foffset)*Oxsol*(1.0+A*TEMP+B*TEMP^2+C*TEMP^3)*exp[E*PRES/(273.15+TEMP)]; DOXY=44.6596*MLPL_DOXY/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Soc=%g, Foffset=%g, A=%g, B=%g, C=%g, E=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g', ...
               tabDoxyCoef(1:6), ...
               g_decArgo_doxy_102_207_206_a0, ...
               g_decArgo_doxy_102_207_206_a1, ...
               g_decArgo_doxy_102_207_206_a2, ...
               g_decArgo_doxy_102_207_206_a3, ...
               g_decArgo_doxy_102_207_206_a4, ...
               g_decArgo_doxy_102_207_206_a5, ...
               g_decArgo_doxy_102_207_206_b0, ...
               g_decArgo_doxy_102_207_206_b1, ...
               g_decArgo_doxy_102_207_206_b2, ...
               g_decArgo_doxy_102_207_206_b3, ...
               g_decArgo_doxy_102_207_206_c0);
            o_preCalibComment = 'see Application note #64: SBE43 Dissolved Oxygen Sensor � Background Information, Deployment Recommendations and Clearing and Storage (revised June 2013); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
end

return;

% ------------------------------------------------------------------------------
% Update parameter list for radiometric associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_radiometric(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/27/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_radiometric(a_metaData, a_decoderId)

paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 108, 109, 110, 121}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('OCR', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'RAW_DOWNWELLING_IRRADIANCE380'} ...
            {'RAW_DOWNWELLING_IRRADIANCE412'} ...
            {'RAW_DOWNWELLING_IRRADIANCE490'} ...
            {'RAW_DOWNWELLING_PAR'} ...
            {'DOWN_IRRADIANCE380'} ...
            {'DOWN_IRRADIANCE412'} ...
            {'DOWN_IRRADIANCE490'} ...
            {'DOWNWELLING_PAR'} ...
            ];
      end
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for radiometric associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_radiometric(a_paramName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/30/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_radiometric(a_paramName, a_decoderId)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


switch (a_decoderId)
   case {105, 106, 107, 108, 109, 110, 121}
      switch (a_paramName)
         
         case {'RAW_DOWNWELLING_IRRADIANCE380'}
            o_param = 'RAW_DOWNWELLING_IRRADIANCE380';
            o_paramSensor = 'RADIOMETER_DOWN_IRR380';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling irradiance measurement at 380 nm';
            
         case {'RAW_DOWNWELLING_IRRADIANCE412'}
            o_param = 'RAW_DOWNWELLING_IRRADIANCE412';
            o_paramSensor = 'RADIOMETER_DOWN_IRR412';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling irradiance measurement at 412 nm';
            
         case {'RAW_DOWNWELLING_IRRADIANCE490'}
            o_param = 'RAW_DOWNWELLING_IRRADIANCE490';
            o_paramSensor = 'RADIOMETER_DOWN_IRR490';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling irradiance measurement at 490 nm';
            
         case {'RAW_DOWNWELLING_PAR'}
            o_param = 'RAW_DOWNWELLING_PAR';
            o_paramSensor = 'RADIOMETER_PAR';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling PAR measurement';
            
         case {'DOWN_IRRADIANCE380'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent DOWN_IRRADIANCE380 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda380'))
               a0Lambda380 = double(g_decArgo_calibInfo.OCR.A0Lambda380);
               a1Lambda380 = double(g_decArgo_calibInfo.OCR.A1Lambda380);
               lmLambda380 = double(g_decArgo_calibInfo.OCR.LmLambda380);
            else
               fprintf('WARNING: Float #%d: inconsistent DOWN_IRRADIANCE380 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOWN_IRRADIANCE380';
            o_paramSensor = 'RADIOMETER_DOWN_IRR380';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE380=0.01*A1_380*(RAW_DOWNWELLING_IRRADIANCE380-A0_380)*lm_380';
            o_preCalibCoef = sprintf('A1_380=%g, A0_380=%g, lm_380=%g', ...
               a1Lambda380, a0Lambda380, lmLambda380);
            o_preCalibComment = '';
            
         case {'DOWN_IRRADIANCE412'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent DOWN_IRRADIANCE412 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda412'))
               a0Lambda412 = double(g_decArgo_calibInfo.OCR.A0Lambda412);
               a1Lambda412 = double(g_decArgo_calibInfo.OCR.A1Lambda412);
               lmLambda412 = double(g_decArgo_calibInfo.OCR.LmLambda412);
            else
               fprintf('WARNING: Float #%d: inconsistent DOWN_IRRADIANCE412 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOWN_IRRADIANCE412';
            o_paramSensor = 'RADIOMETER_DOWN_IRR412';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE412=0.01*A1_412*(RAW_DOWNWELLING_IRRADIANCE412-A0_412)*lm_412';
            o_preCalibCoef = sprintf('A1_412=%g, A0_412=%g, lm_412=%g', ...
               a1Lambda412, a0Lambda412, lmLambda412);
            o_preCalibComment = '';
            
         case {'DOWN_IRRADIANCE490'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent DOWN_IRRADIANCE490 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda490'))
               a0Lambda490 = double(g_decArgo_calibInfo.OCR.A0Lambda490);
               a1Lambda490 = double(g_decArgo_calibInfo.OCR.A1Lambda490);
               lmLambda490 = double(g_decArgo_calibInfo.OCR.LmLambda490);
            else
               fprintf('WARNING: Float #%d: inconsistent DOWN_IRRADIANCE490 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOWN_IRRADIANCE490';
            o_paramSensor = 'RADIOMETER_DOWN_IRR490';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE490=0.01*A1_490*(RAW_DOWNWELLING_IRRADIANCE490-A0_490)*lm_490';
            o_preCalibCoef = sprintf('A1_490=%g, A0_490=%g, lm_490=%g', ...
               a1Lambda490, a0Lambda490, lmLambda490);
            o_preCalibComment = '';
            
         case {'DOWNWELLING_PAR'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent DOWNWELLING_PAR calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0PAR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1PAR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmPAR'))
               a0PAR = double(g_decArgo_calibInfo.OCR.A0PAR);
               a1PAR = double(g_decArgo_calibInfo.OCR.A1PAR);
               lmPAR = double(g_decArgo_calibInfo.OCR.LmPAR);
            else
               fprintf('WARNING: Float #%d: inconsistent DOWNWELLING_PAR calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            o_param = 'DOWNWELLING_PAR';
            o_paramSensor = 'RADIOMETER_PAR';
            o_paramUnits = 'microMoleQuanta/m^2/sec';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWNWELLING_PAR=A1_PAR*(RAW_DOWNWELLING_PAR-A0_PAR)*lm_PAR';
            o_preCalibCoef = sprintf('A1_PAR=%g, A0_PAR=%g, lm_PAR=%g', ...
               a1PAR, a0PAR, lmPAR);
            o_preCalibComment = '';
            
      end
end

% ------------------------------------------------------------------------------
% Update parameter list for backscattering associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_backscattering(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/30/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_backscattering(a_metaData, a_decoderId)

paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 110, 121}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'BETA_BACKSCATTERING700'} ...
            {'BBP700'} ...
            ];
      end
   case {108, 109}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'BETA_BACKSCATTERING700'} ...
            {'BBP700'} ...
            {'BETA_BACKSCATTERING532'} ...
            {'BBP532'} ...
            ];
      end
   case {301}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('FLBB', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'BETA_BACKSCATTERING700'} ...
            {'BBP700'} ...
            ];
      end
   case {1015}
      paramList = [ ...
         {'BETA_BACKSCATTERING700'} ...
         {'BBP700'} ...
         ];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for backscattering associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_backscattering(a_paramName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/30/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_backscattering(a_paramName, a_decoderId)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


switch (a_decoderId)
   case {105, 106, 107, 110, 121}
      switch (a_paramName)
         
         case {'BETA_BACKSCATTERING700'}
            o_param = 'BETA_BACKSCATTERING700';
            o_paramSensor = 'SCATTEROMETER_BBP';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';
            
         case {'BBP700'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'KhiCoefBackscatter'))
               scaleFactBackscatter700 = double(g_decArgo_calibInfo.ECO3.ScaleFactBackscatter700);
               darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter700);
               darkCountBackscatter700_O = [];
               if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter700_O'))
                  darkCountBackscatter700_O = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter700_O);
               end
               khiCoefBackscatter = double(g_decArgo_calibInfo.ECO3.KhiCoefBackscatter);
            else
               fprintf('WARNING: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountBackscatter700_O))
               o_param = 'BBP700';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter700, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'No DARK_BACKSCATTERING700_O provided, Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
            else
               o_param = 'BBP700';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700_O)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, DARK_BACKSCATTERING700_O=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter700, darkCountBackscatter700_O, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
            end
            
      end
      
   case {108, 109}
      switch (a_paramName)
         
         case {'BETA_BACKSCATTERING700'}
            o_param = 'BETA_BACKSCATTERING700';
            o_paramSensor = 'SCATTEROMETER_BBP';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';
            
         case {'BBP700'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'KhiCoefBackscatter'))
               scaleFactBackscatter700 = double(g_decArgo_calibInfo.ECO3.ScaleFactBackscatter700);
               darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter700);
               darkCountBackscatter700_O = [];
               if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter700_O'))
                  darkCountBackscatter700_O = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter700_O);
               end
               khiCoefBackscatter = double(g_decArgo_calibInfo.ECO3.KhiCoefBackscatter);
            else
               fprintf('WARNING: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountBackscatter700_O))
               o_param = 'BBP700';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter700, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'No DARK_BACKSCATTERING700_O provided, Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
            else
               o_param = 'BBP700';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700_O)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, DARK_BACKSCATTERING700_O=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter700, darkCountBackscatter700_O, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
            end
            
         case {'BETA_BACKSCATTERING532'}
            o_param = 'BETA_BACKSCATTERING532';
            o_paramSensor = 'SCATTEROMETER_BBP';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';
            
         case {'BBP532'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent BBP532 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactBackscatter532') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter532') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'KhiCoefBackscatter'))
               scaleFactBackscatter532 = double(g_decArgo_calibInfo.ECO3.ScaleFactBackscatter532);
               darkCountBackscatter532 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter532);
               darkCountBackscatter532_O = [];
               if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter532_O'))
                  darkCountBackscatter532_O = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter532_O);
               end
               khiCoefBackscatter = double(g_decArgo_calibInfo.ECO3.KhiCoefBackscatter);
            else
               fprintf('WARNING: Float #%d: inconsistent BBP532 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountBackscatter532_O))
               o_param = 'BBP532';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP532=2*pi*khi*((BETA_BACKSCATTERING532-DARK_BACKSCATTERING532)*SCALE_BACKSCATTERING532-BETASW532)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING532=%g, SCALE_BACKSCATTERING532=%g, khi=%g, BETASW532 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter532, scaleFactBackscatter532, khiCoefBackscatter);
               o_preCalibComment = 'No DARK_BACKSCATTERING532_O provided, Sullivan et al., 2012, Zhang et al., 2009, BETASW532 is the contribution by the pure seawater at 532nm, the calculation can be found at http://doi.org/10.17882/42916';
            else
               o_param = 'BBP532';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP532=2*pi*khi*((BETA_BACKSCATTERING532-DARK_BACKSCATTERING532_O)*SCALE_BACKSCATTERING532-BETASW532)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING532=%g, DARK_BACKSCATTERING532_O=%g, SCALE_BACKSCATTERING532=%g, khi=%g, BETASW532 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter532, darkCountBackscatter532_O, scaleFactBackscatter532, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW532 is the contribution by the pure seawater at 532nm, the calculation can be found at http://doi.org/10.17882/42916';
            end
            
      end
      
   case {301, 1015}
      switch (a_paramName)
         
         case {'BETA_BACKSCATTERING700'}
            o_param = 'BETA_BACKSCATTERING700';
            o_paramSensor = 'SCATTEROMETER_BBP';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';
            
         case {'BBP700'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'FLBB') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'ScaleFactBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'DarkCountBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'KhiCoefBackscatter'))
               scaleFactBackscatter700 = double(g_decArgo_calibInfo.FLBB.ScaleFactBackscatter700);
               darkCountBackscatter700 = double(g_decArgo_calibInfo.FLBB.DarkCountBackscatter700);
               darkCountBackscatter700_O = [];
               if (isfield(g_decArgo_calibInfo.FLBB, 'DarkCountBackscatter700_O'))
                  darkCountBackscatter700_O = double(g_decArgo_calibInfo.FLBB.DarkCountBackscatter700_O);
               end
               khiCoefBackscatter = double(g_decArgo_calibInfo.FLBB.KhiCoefBackscatter);
            else
               fprintf('WARNING: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountBackscatter700_O))
               o_param = 'BBP700';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 142 angularDeg', ...
                  darkCountBackscatter700, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'No DARK_BACKSCATTERING700_O provided, Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
            else
               o_param = 'BBP700';
               o_paramSensor = 'SCATTEROMETER_BBP';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700_O)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, DARK_BACKSCATTERING700_O=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 142 angularDeg', ...
                  darkCountBackscatter700, darkCountBackscatter700_O, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
            end
            
      end
end

% ------------------------------------------------------------------------------
% Update parameter list for chla associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_chla(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/30/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_chla(a_metaData, a_decoderId)

paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 108, 109, 110, 301, 302, 303, 121}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('OCR', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'FLUORESCENCE_CHLA'} ...
            {'CHLA'} ...
            ];
      end
   case {1015}
      paramList = [ ...
         {'FLUORESCENCE_CHLA'} ...
         {'TEMP_CPU_CHLA'} ...
         {'CHLA'} ...
         ];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for chla associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_chla(a_paramName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/30/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_chla(a_paramName, a_decoderId)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


switch (a_decoderId)
   case {105, 106, 107, 108, 109, 110, 121}
      switch (a_paramName)
         
         case {'FLUORESCENCE_CHLA'}
            o_param = 'FLUORESCENCE_CHLA';
            o_paramSensor = 'FLUOROMETER_CHLA';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated chlorophyll-a fluorescence measurement';
                        
         case {'CHLA'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.ECO3.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA);
               darkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.ECO3, 'darkCountChloroA_O'))
                  darkCountChloroA_O = double(g_decArgo_calibInfo.ECO3.darkCountChloroA_O);
               end
            else
               fprintf('WARNING: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = 'No DARK_CHLA_O provided';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, darkCountChloroA_O);
               o_preCalibComment = '';
            end
            
      end
      
   case {302, 303}
      switch (a_paramName)
         
         case {'FLUORESCENCE_CHLA'}
            o_param = 'FLUORESCENCE_CHLA';
            o_paramSensor = 'FLUOROMETER_CHLA';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated chlorophyll-a fluorescence measurement';
                        
         case {'CHLA'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'FLNTU') && ...
                  isfield(g_decArgo_calibInfo.FLNTU, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.FLNTU.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA);
               darkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.FLNTU, 'darkCountChloroA_O'))
                  darkCountChloroA_O = double(g_decArgo_calibInfo.FLNTU.darkCountChloroA_O);
               end
            else
               fprintf('WARNING: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = 'No DARK_CHLA_O provided';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, darkCountChloroA_O);
               o_preCalibComment = '';
            end

      end
      
   case {301, 1015}
      switch (a_paramName)
         
         case {'FLUORESCENCE_CHLA'}
            o_param = 'FLUORESCENCE_CHLA';
            o_paramSensor = 'FLUOROMETER_CHLA';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated chlorophyll-a fluorescence measurement';
            
         case {'TEMP_CPU_CHLA'}
            o_param = 'TEMP_CPU_CHLA';
            o_paramSensor = 'FLUOROMETER_CHLA';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Thermistor signal from backscattering sensor';
            
         case {'CHLA'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'FLBB') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.FLBB.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.FLBB.DarkCountChloroA);
               darkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.FLBB, 'darkCountChloroA_O'))
                  darkCountChloroA_O = double(g_decArgo_calibInfo.FLBB.darkCountChloroA_O);
               end
            else
               fprintf('WARNING: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = 'No DARK_CHLA_O provided';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, darkCountChloroA_O);
               o_preCalibComment = '';
            end

      end
end

return;

% ------------------------------------------------------------------------------
% Update parameter list for cdom associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_cdom(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/24/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_cdom(a_metaData, a_decoderId)

paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 110, 121}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'FLUORESCENCE_CDOM'} ...
            {'CDOM'} ...
            ];
      end
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for cdom associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_cdom(a_paramName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/24/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_cdom(a_paramName, a_decoderId)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


switch (a_decoderId)
   case {105, 106, 107, 110, 121}
      switch (a_paramName)
         
         case {'FLUORESCENCE_CDOM'}
            o_param = 'FLUORESCENCE_CDOM';
            o_paramSensor = 'FLUOROMETER_CDOM';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = '';
                        
         case {'CDOM'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent CDOM calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactCDOM') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountCDOM'))
               scaleFactCDOM = double(g_decArgo_calibInfo.ECO3.ScaleFactCDOM);
               darkCountCDOM = double(g_decArgo_calibInfo.ECO3.DarkCountCDOM);
               darkCountCDOM_O = [];
               if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountCDOM_O'))
                  darkCountCDOM_O = double(g_decArgo_calibInfo.ECO3.DarkCountCDOM_O);
               end
            else
               fprintf('WARNING: Float #%d: inconsistent CDOM calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            if (isempty(darkCountCDOM_O))
               o_param = 'CDOM';
               o_paramSensor = 'FLUOROMETER_CDOM';
               o_paramUnits = 'ppb';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'CDOM=(FLUORESCENCE_CDOM-DARK_CDOM)*SCALE_CDOM';
               o_preCalibCoef = sprintf('SCALE_CDOM=%g, DARK_CDOM=%g', ...
                  scaleFactCDOM, darkCountCDOM);
               o_preCalibComment = 'No DARK_CDOM_O provided';
            else
               o_param = 'CDOM';
               o_paramSensor = 'FLUOROMETER_CDOM';
               o_paramUnits = 'ppb';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'CDOM=(FLUORESCENCE_CDOM-DARK_CDOM_O)*SCALE_CDOM';
               o_preCalibCoef = sprintf('SCALE_CDOM=%g, DARK_CDOM=%g, DARK_CDOM_O=%g', ...
                  scaleFactCDOM, darkCountCDOM, darkCountCDOM_O);
               o_preCalibComment = '';
            end
            
      end
      
end

return;

% ------------------------------------------------------------------------------
% Update parameter list for nitrate associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_nitrate(a_metaData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/27/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_nitrate(a_metaData, a_decoderId)

paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 109, 121}
      % check that a SUNA sensor is mounted on the float
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp(struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT), 'SUNA')))
         paramList = [ ...
            {'UV_INTENSITY_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE'} ...
            {'NITRATE'} ...
            {'FIT_ERROR_NITRATE'} ...
            {'TEMP_NITRATE'} ...
            {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
            {'HUMIDITY_NITRATE'} ...
            ];
      end
   case {110}
      % check that a SUNA sensor is mounted on the float
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp(struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT), 'SUNA')))
         paramList = [ ...
            {'UV_INTENSITY_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE'} ...
            {'NITRATE'} ...
            {'BISULFIDE'} ...
            {'FIT_ERROR_NITRATE'} ...
            {'TEMP_NITRATE'} ...
            {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
            {'HUMIDITY_NITRATE'} ...
            ];
      end
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return;

% ------------------------------------------------------------------------------
% Update meta-data for nitrate associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_nitrate(a_paramName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_paramName : input parameter to be updated
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_param           : output updated PARAMETER information
%   o_paramSensor     : output updated PARAMETER_SENSOR information
%   o_paramUnits      : output updated PARAMETER_UNITS information
%   o_paramAccuracy   : output updated PARAMETER_ACCURACY information
%   o_paramResolution : output updated PARAMETER_RESOLUTION information
%   o_preCalibEq      : output updated PREDEPLOYMENT_CALIB_EQUATION information
%   o_preCalibCoef    : output updated PREDEPLOYMENT_CALIB_COEFFICIENT information
%   o_preCalibComment : output updated PARAMETER_ACCURACY information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/27/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_nitrate(a_paramName, a_decoderId)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% NITRATE coefficients
global g_decArgo_nitrate_a;
global g_decArgo_nitrate_b;
global g_decArgo_nitrate_c;
global g_decArgo_nitrate_d;
global g_decArgo_nitrate_opticalWavelengthOffset;


switch (a_decoderId)
   case {105, 106, 107, 109, 110, 121}
      switch (a_paramName)
         
         case {'UV_INTENSITY_NITRATE'}
            o_param = 'UV_INTENSITY_NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Intensity of ultra violet flux from nitrate sensor';
            
         case {'UV_INTENSITY_DARK_NITRATE'}
            o_param = 'UV_INTENSITY_NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Intensity of ultra violet flux dark measurement from nitrate sensor';
            
         case {'NITRATE'}
            
            if (a_decoderId ~= 110)
               
               % get calibration information
               if (isempty(g_decArgo_calibInfo))
                  fprintf('WARNING: Float #%d: inconsistent NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE'))
                  tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
                  tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
                  tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
                  tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
                  tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
               else
                  fprintf('WARNING: Float #%d: inconsistent NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               
               floatPixelBegin = get_static_config_value('CONFIG_PX_1_6_0_0_3', 1);
               floatPixelEnd = get_static_config_value('CONFIG_PX_1_6_0_0_4', 1);
               if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
                  fprintf('WARNING: Float #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               
               idF1 = find(tabOpticalWavelengthUv >= 217);
               idF2 = find(tabOpticalWavelengthUv <= 240);
               pixelBegin = idF1(1);
               pixelEnd = idF2(end);
               
               o_param = 'NITRATE';
               o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
               o_paramUnits = 'umol/kg';
               o_paramAccuracy = '2 umol/kg';
               o_paramResolution = '0.01 umol/kg';
               
               o_preCalibEq = 'The sensor returns UV_INTENSITY_DARK_NITRATE and UV_INTENSITY_NITRATE(Ntrans), a subset of continuous pixels of UV_INTENSITY_NITRATE(N), N = 1 to 256. The Ntrans indices span the interval [PIXEL_START, PIXEL_END] subset of the original array (1 to 256). Thus Ntrans(i) refers to pixel N = (PIXEL_START+i-1). PIXEL_START and PIXEL_END are defined from calibration data so that the [PIXEL_START, PIXEL_END] interval is the smallest interval of pixels that correspond to the [217 nm, 250 nm] interval of wavelengths. Only a subset of the [PIXEL_START, PIXEL_END] interval is processed to compute nitrate concentration. This subset is defined as the [PIXEL_FIT_START, PIXEL_FIT_END] interval which is the smallest interval of pixels that correspond to the [217 nm, 240 nm] interval of wavelengths (thus PIXEL_FIT_START = PIXEL_START). In the following equations the data are computed for each pixel R = PIXEL_FIT_START to PIXEL_FIT_END; ABSORBANCE_SW(R)=-log10[(UV_INTENSITY_NITRATE(R)-UV_INTENSITY_DARK_NITRATE)/UV_INTENSITY_REF_NITRATE(R)]; F(R,T)=(A+B*T)*exp[(C+D*T)*(OPTICAL_WAVELENGTH_UV(R)-OPTICAL_WAVELENGTH_OFFSET)]; E_SWA_INSITU(R)=E_SWA_NITRATE(R)*F(R,TEMP)/F(R,TEMP_CAL_NITRATE); ABSORBANCE_COR_NITRATE(R)=ABSORBANCE_SW(R)-E_SWA_INSITU(R)*PSAL; Perform a multilinear regression to get MOLAR_NITRATE with estimated ABSORBANCE_COR_NITRATE(R) with ABSORBANCE_COR_NITRATE(R)=BASELINE_INTERCEPT+BASELINE_SLOPE*OPTICAL_WAVELENGTH_UV(R)+MOLAR_NITRATE*E_NITRATE(R); NITRATE=MOLAR_NITRATE/rho, where rho is the potential density [kg/L] calculated from CTD data';
               
               uvIntensityRefNitrateStr = sprintf('%.8f,', tabUvIntensityRefNitrate(floatPixelBegin:floatPixelEnd));
               opticalWavelengthUvStr = sprintf('%.2f,', tabOpticalWavelengthUv(floatPixelBegin:floatPixelEnd));
               eSwaNitrateStr = sprintf('%.8f,', tabESwaNitrate(floatPixelBegin:floatPixelEnd));
               eNitrateStr = sprintf('%.8f,', tabENitrate(floatPixelBegin:floatPixelEnd));
               o_preCalibCoef = [ ...
                  sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
                  floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
                  'UV_INTENSITY_REF_NITRATE(Ntrans)=[' uvIntensityRefNitrateStr(1:end-1) ']; ' ...
                  sprintf('A=%.7f, B=%.5f, C=%.7f, D=%.6f, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
                  g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_opticalWavelengthOffset) ...
                  'OPTICAL_WAVELENGTH_UV(Ntrans)=[' opticalWavelengthUvStr(1:end-1) ']; ' ...
                  sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
                  'E_SWA_NITRATE(Ntrans)=[' eSwaNitrateStr(1:end-1) ']; ' ...
                  'E_NITRATE(Ntrans)=[' eNitrateStr(1:end-1) ']' ...
                  ];
               
               o_preCalibComment = 'Nitrate concentration in umol/kg; see Processing Bio-Argo nitrate concentration at the DAC Level, Version 1.0, May 3rd 2016';
            else
               
               % get calibration information
               if (isempty(g_decArgo_calibInfo))
                  fprintf('WARNING: Float #%d: inconsistent NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabEBisulfide') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE'))
                  tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
                  tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
                  tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
                  tabEBisulfide = g_decArgo_calibInfo.SUNA.TabEBisulfide;
                  tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
                  tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
               else
                  fprintf('WARNING: Float #%d: inconsistent NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               
               floatPixelBegin = get_static_config_value('CONFIG_PX_1_6_0_0_3', 1);
               floatPixelEnd = get_static_config_value('CONFIG_PX_1_6_0_0_4', 1);
               if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
                  fprintf('WARNING: Float #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing\n', ...
                     g_decArgo_floatNum);
                  return;
               end
               
               idF1 = find(tabOpticalWavelengthUv >= 217);
               idF2 = find(tabOpticalWavelengthUv <= 280);
               pixelBegin = idF1(1);
               pixelEnd = idF2(end);
               
               o_param = 'NITRATE';
               o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
               o_paramUnits = 'umol/kg';
               o_paramAccuracy = '2 umol/kg';
               o_paramResolution = '0.01 umol/kg';
               
               o_preCalibEq = 'The sensor returns UV_INTENSITY_DARK_NITRATE and UV_INTENSITY_NITRATE(Ntrans), a subset of continuous pixels of UV_INTENSITY_NITRATE(N), N = 1 to 256. The Ntrans indices span the interval [PIXEL_START, PIXEL_END] subset of the original array (1 to 256). Thus Ntrans(i) refers to pixel N = (PIXEL_START+i-1). PIXEL_START and PIXEL_END are defined from calibration data so that the [PIXEL_START, PIXEL_END] interval is the smallest interval of pixels that correspond to the [217 nm, 289 nm] interval of wavelengths. Only a subset of the [PIXEL_START, PIXEL_END] interval is processed to compute nitrate concentration. This subset is defined as the [PIXEL_FIT_START, PIXEL_FIT_END] interval which is the smallest interval of pixels that correspond to the [217 nm, 280 nm] interval of wavelengths (thus PIXEL_FIT_START = PIXEL_START). In the following equations the data are computed for each pixel R = PIXEL_FIT_START to PIXEL_FIT_END; ABSORBANCE_SW(R)=-log10[(UV_INTENSITY_NITRATE(R)-UV_INTENSITY_DARK_NITRATE)/UV_INTENSITY_REF_NITRATE(R)]; F(R,T)=(A+B*T)*exp[(C+D*T)*(OPTICAL_WAVELENGTH_UV(R)-OPTICAL_WAVELENGTH_OFFSET)]; E_SWA_INSITU(R)=E_SWA_NITRATE(R)*F(R,TEMP)/F(R,TEMP_CAL_NITRATE); ABSORBANCE_COR_NITRATE(R)=ABSORBANCE_SW(R)-E_SWA_INSITU(R)*PSAL; Perform a multilinear regression to get MOLAR_NITRATE and MOLAR_BISULFIDE with estimated ABSORBANCE_COR_NITRATE(R) with ABSORBANCE_COR_NITRATE(R)=BASELINE_INTERCEPT+BASELINE_SLOPE*OPTICAL_WAVELENGTH_UV(R)+MOLAR_NITRATE*E_NITRATE(R)+MOLAR_BISULFIDE*E_BISULFIDE(R); NITRATE=MOLAR_NITRATE/rho and BISULFIDE=MOLAR_BISULFIDE/rho, where rho is the potential density [kg/L] calculated from CTD data';
               
               % for NITRATE&BISULFIDE we have more pixel and we must squeeze
               % their output as possible
               uvIntensityRefNitrateStr = [];
               opticalWavelengthUvStr = [];
               eSwaNitrateStr = [];
               eNitrateStr = [];
               eBisulfideStr = [];
               for id = floatPixelBegin:floatPixelEnd
                  if (tabUvIntensityRefNitrate(id) == 0)
                     uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%d,', tabUvIntensityRefNitrate(id))];
                  else
                     uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%.8f,', tabUvIntensityRefNitrate(id))];
                  end
                  if (tabOpticalWavelengthUv(id) == 0)
                     opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%d,', tabOpticalWavelengthUv(id))];
                  else
                     opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%.2f,', tabOpticalWavelengthUv(id))];
                  end
                  if (tabESwaNitrate(id) == 0)
                     eSwaNitrateStr = [eSwaNitrateStr sprintf('%d,', tabESwaNitrate(id))];
                  else
                     eSwaNitrateStr = [eSwaNitrateStr sprintf('%.8f,', tabESwaNitrate(id))];
                  end
                  if (tabENitrate(id) == 0)
                     eNitrateStr = [eNitrateStr sprintf('%d,', tabENitrate(id))];
                  else
                     eNitrateStr = [eNitrateStr sprintf('%.8f,', tabENitrate(id))];
                  end
                  if (tabEBisulfide(id) == 0)
                     eBisulfideStr = [eBisulfideStr sprintf('%d,', tabEBisulfide(id))];
                  else
                     eBisulfideStr = [eBisulfideStr sprintf('%.9f,', tabEBisulfide(id))];
                  end
               end
               o_preCalibCoef = [ ...
                  sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
                  floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
                  'UV_INTENSITY_REF_NITRATE(Ntrans)=[' uvIntensityRefNitrateStr(1:end-1) ']; ' ...
                  sprintf('A=%.7f, B=%.5f, C=%.7f, D=%.6f, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
                  g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_opticalWavelengthOffset) ...
                  'OPTICAL_WAVELENGTH_UV(Ntrans)=[' opticalWavelengthUvStr(1:end-1) ']; ' ...
                  sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
                  'E_SWA_NITRATE(Ntrans)=[' eSwaNitrateStr(1:end-1) ']; ' ...
                  'E_NITRATE(Ntrans)=[' eNitrateStr(1:end-1) ']' ...
                  'E_BISULFIDE(Ntrans)=[' eBisulfideStr(1:end-1) ']' ...
                  ];
               
               o_preCalibComment = 'Nitrate concentration in umol/kg; see Processing Bio-Argo nitrate concentration at the DAC Level, Version 1.0, May 3rd 2016';
            end
            
         case {'BISULFIDE'}
            
            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: inconsistent NITRATE calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabEBisulfide') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE'))
               tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
               tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
               tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
               tabEBisulfide = g_decArgo_calibInfo.SUNA.TabEBisulfide;
               tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
               tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
            else
               fprintf('WARNING: Float #%d: inconsistent NITRATE calibration information\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            floatPixelBegin = get_static_config_value('CONFIG_PX_1_6_0_0_3', 1);
            floatPixelEnd = get_static_config_value('CONFIG_PX_1_6_0_0_4', 1);
            if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
               fprintf('WARNING: Float #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing\n', ...
                  g_decArgo_floatNum);
               return;
            end
            
            idF1 = find(tabOpticalWavelengthUv >= 217);
            idF2 = find(tabOpticalWavelengthUv <= 280);
            pixelBegin = idF1(1);
            pixelEnd = idF2(end);
            
            o_param = 'NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '2 umol/kg';
            o_paramResolution = '0.02 umol/kg';
            
            o_preCalibEq = 'The sensor returns UV_INTENSITY_DARK_NITRATE and UV_INTENSITY_NITRATE(Ntrans), a subset of continuous pixels of UV_INTENSITY_NITRATE(N), N = 1 to 256. The Ntrans indices span the interval [PIXEL_START, PIXEL_END] subset of the original array (1 to 256). Thus Ntrans(i) refers to pixel N = (PIXEL_START+i-1). PIXEL_START and PIXEL_END are defined from calibration data so that the [PIXEL_START, PIXEL_END] interval is the smallest interval of pixels that correspond to the [217 nm, 289 nm] interval of wavelengths. Only a subset of the [PIXEL_START, PIXEL_END] interval is processed to compute nitrate concentration. This subset is defined as the [PIXEL_FIT_START, PIXEL_FIT_END] interval which is the smallest interval of pixels that correspond to the [217 nm, 280 nm] interval of wavelengths (thus PIXEL_FIT_START = PIXEL_START). In the following equations the data are computed for each pixel R = PIXEL_FIT_START to PIXEL_FIT_END; ABSORBANCE_SW(R)=-log10[(UV_INTENSITY_NITRATE(R)-UV_INTENSITY_DARK_NITRATE)/UV_INTENSITY_REF_NITRATE(R)]; F(R,T)=(A+B*T)*exp[(C+D*T)*(OPTICAL_WAVELENGTH_UV(R)-OPTICAL_WAVELENGTH_OFFSET)]; E_SWA_INSITU(R)=E_SWA_NITRATE(R)*F(R,TEMP)/F(R,TEMP_CAL_NITRATE); ABSORBANCE_COR_NITRATE(R)=ABSORBANCE_SW(R)-E_SWA_INSITU(R)*PSAL; Perform a multilinear regression to get MOLAR_NITRATE and MOLAR_BISULFIDE with estimated ABSORBANCE_COR_NITRATE(R) with ABSORBANCE_COR_NITRATE(R)=BASELINE_INTERCEPT+BASELINE_SLOPE*OPTICAL_WAVELENGTH_UV(R)+MOLAR_NITRATE*E_NITRATE(R)+MOLAR_BISULFIDE*E_BISULFIDE(R); NITRATE=MOLAR_NITRATE/rho and BISULFIDE=MOLAR_BISULFIDE/rho, where rho is the potential density [kg/L] calculated from CTD data';
            
            % for NITRATE&BISULFIDE we have more pixel and we must squeeze
            % their output as possible
            uvIntensityRefNitrateStr = [];
            opticalWavelengthUvStr = [];
            eSwaNitrateStr = [];
            eNitrateStr = [];
            eBisulfideStr = [];
            for id = floatPixelBegin:floatPixelEnd
               if (tabUvIntensityRefNitrate(id) == 0)
                  uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%d,', tabUvIntensityRefNitrate(id))];
               else
                  uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%.8f,', tabUvIntensityRefNitrate(id))];
               end
               if (tabOpticalWavelengthUv(id) == 0)
                  opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%d,', tabOpticalWavelengthUv(id))];
               else
                  opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%.2f,', tabOpticalWavelengthUv(id))];
               end
               if (tabESwaNitrate(id) == 0)
                  eSwaNitrateStr = [eSwaNitrateStr sprintf('%d,', tabESwaNitrate(id))];
               else
                  eSwaNitrateStr = [eSwaNitrateStr sprintf('%.8f,', tabESwaNitrate(id))];
               end
               if (tabENitrate(id) == 0)
                  eNitrateStr = [eNitrateStr sprintf('%d,', tabENitrate(id))];
               else
                  eNitrateStr = [eNitrateStr sprintf('%.8f,', tabENitrate(id))];
               end
               if (tabEBisulfide(id) == 0)
                  eBisulfideStr = [eBisulfideStr sprintf('%d,', tabEBisulfide(id))];
               else
                  eBisulfideStr = [eBisulfideStr sprintf('%.9f,', tabEBisulfide(id))];
               end
            end
            o_preCalibCoef = [ ...
               sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
               floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
               'UV_INTENSITY_REF_NITRATE(Ntrans)=[' uvIntensityRefNitrateStr(1:end-1) ']; ' ...
               sprintf('A=%.7f, B=%.5f, C=%.7f, D=%.6f, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
               g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_opticalWavelengthOffset) ...
               'OPTICAL_WAVELENGTH_UV(Ntrans)=[' opticalWavelengthUvStr(1:end-1) ']; ' ...
               sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
               'E_SWA_NITRATE(Ntrans)=[' eSwaNitrateStr(1:end-1) ']; ' ...
               'E_NITRATE(Ntrans)=[' eNitrateStr(1:end-1) ']' ...
               'E_BISULFIDE(Ntrans)=[' eBisulfideStr(1:end-1) ']' ...
               ];
            
            o_preCalibComment = 'Bisulfide concentration in umol/kg; see Processing Bio-Argo nitrate concentration at the DAC Level, Version 1.0, May 3rd 2016';
            
         case {'FIT_ERROR_NITRATE'}
            o_param = 'FIT_ERROR_NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'dimensionless';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Nitrate fit error (dimensionless)';
            
         case {'TEMP_NITRATE'}
            o_param = 'TEMP_NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'degC';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Internal temperature of the SUNA sensor';
            
         case {'TEMP_SPECTROPHOTOMETER_NITRATE'}
            o_param = 'TEMP_SPECTROPHOTOMETER_NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'degC';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Temperature of the spectrometer';
            
         case {'HUMIDITY_NITRATE'}
            o_param = 'HUMIDITY_NITRATE';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'percent';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Relative humidity inside the SUNA sensor (If > 50% There is a leak)';
      end
end

return;

% ------------------------------------------------------------------------------
% Generate fields associated to each parameter of a provided list.
%
% SYNTAX :
%  [o_metaData] = generate_parameter_fields(a_metaData, a_paramList)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_paramList : list of parameters
%
% OUTPUT PARAMETERS :
%   o_metaData : output updated meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/27/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = generate_parameter_fields(a_metaData, a_paramList)

% output parameters initialization
o_metaData = a_metaData;

% current float WMO number
global g_decArgo_floatNum;


if (~isempty(a_paramList))
   
   fieldList = [ ...
      {'PARAMETER_SENSOR'} ...
      {'PARAMETER_UNITS'} ...
      {'PARAMETER_ACCURACY'} ...
      {'PARAMETER_RESOLUTION'} ...
      {'PREDEPLOYMENT_CALIB_EQUATION'} ...
      {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
      {'PREDEPLOYMENT_CALIB_COMMENT'} ...
      ];
   
   floatparamList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(a_paramList)
      idF = find(strcmp(a_paramList{idP}, floatparamList) == 1, 1);
      if (isempty(idF))
         fprintf('WARNING: Float #%d: adding ''%s'' to float parameter list\n', ...
            g_decArgo_floatNum, a_paramList{idP});
         
         nbParam = length(floatparamList) + 1;
         o_metaData.PARAMETER.(['PARAMETER_' num2str(nbParam)]) = a_paramList{idP};
         for id = 1:length(fieldList)
            o_metaData.(fieldList{id}).([fieldList{id} '_' num2str(nbParam)]) = '';
         end
      end
   end
end

return;