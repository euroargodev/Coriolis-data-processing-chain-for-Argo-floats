% ------------------------------------------------------------------------------'
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

% lists of managed decoders
global g_decArgo_decoderIdListMtime;


% list of decoder Ids implemented in the current decoder
decoderIdListNke = [1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31, 32, ...
   105, 106, 107, 109, 110, 111, 112, 113, 114, 115, ...
   121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, ...
   201, 202, 203, 204, 205, 206, 208, 209, 210, 211, 212, 222, 213, 214, 215, 216, 217, 218, 219, 220, 221, 223, 224, 225, ...
   301, 302, 303];
decoderIdListApex = [1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1021, 1022, ...
   1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1114, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, ...
   1314, 1321, 1322, 1323];
decoderIdListNavis = [1201];
decoderIdListNova = [2001, 2002, 2003];
decoderIdListNemo = [3001];
decoderIdList = [ ...
   decoderIdListNke ...
   decoderIdListApex ...
   decoderIdListNavis ...
   decoderIdListNova ...
   decoderIdListNemo];
% only to check that the function has been updated for each new decoder
if (~ismember(a_decoderId, decoderIdList))
   fprintf('ERROR: Float #%d: decoderId=%d is not present in the check list of the update_meta_data function\n', ...
      g_decArgo_floatNum, a_decoderId);
   return
end

% add a POSITIONING_SYSTEM = 'IRIDIUM' to GPS floats
% add a POSITIONING_SYSTEM = 'RAFOS' to NEMO floats
% set CONTROLLER_BOARD_TYPE_PRIMARY and BATTERY_TYPE
[o_metaData] = add_misc_meta_data(o_metaData, a_decoderId);

% add 'MTIME' parameter and associated SENSOR to specific floats
if (ismember(a_decoderId, g_decArgo_decoderIdListMtime))
   o_metaData = add_mtime_parameter(o_metaData);
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
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_ctd(paramList{idP}, a_decoderId, o_metaData);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibComment), FORMAT_SIZE);
            preCalibComment = preCalibComment(1:FORMAT_SIZE);
         end

         for idF = 1:length(fieldList)
            if (isfield(o_metaData, fieldList{idF}))
               if (isempty(o_metaData.(fieldList{idF})))
                  for id = 1:length(paramList)
                     o_metaData.(fieldList{idF}).([fieldList{idF} '_' num2str(id)]) = '';
                  end
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
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
   % update RADIOMETRY meta-data

   [o_metaData] = update_parameter_list_radiometry(o_metaData, a_decoderId);

   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_radiometry(paramList{idP}, a_decoderId);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_backscattering(paramList{idP}, a_decoderId, o_metaData);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
   % update PH meta-data

   [o_metaData] = update_parameter_list_ph(o_metaData, a_decoderId);

   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_ph(paramList{idP}, a_decoderId);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
   % update CP meta-data

   [o_metaData] = update_parameter_list_cp(o_metaData, a_decoderId);

   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_cp(paramList{idP}, a_decoderId);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
   % update TURBIDITY meta-data

   [o_metaData] = update_parameter_list_turbidity(o_metaData, a_decoderId);

   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_turbidity(paramList{idP}, a_decoderId);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
   % update RAFOS meta-data

   [o_metaData] = update_parameter_list_rafos(o_metaData, a_decoderId);

   paramList = struct2cell(o_metaData.PARAMETER);
   for idP = 1:length(paramList)
      [param, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         preCalibEq, preCalibCoef, preCalibComment] = get_meta_data_rafos(paramList{idP}, a_decoderId);
      if (~isempty(param))

         % check meta data length
         FORMAT_SIZE = 4096;
         if (length(preCalibEq) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_EQUATION'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibEq), FORMAT_SIZE);
            preCalibEq = preCalibEq(1:FORMAT_SIZE);
         end
         if (length(preCalibCoef) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COEFFICIENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
               g_decArgo_floatNum, length(preCalibCoef), FORMAT_SIZE);
            preCalibCoef = preCalibCoef(1:FORMAT_SIZE);
         end
         if (length(preCalibComment) > FORMAT_SIZE)
            fprintf('ERROR: Float #%d: ''PREDEPLOYMENT_CALIB_COMMENT'' information exceeds format size (%d > STRING%d) - cut to fit the format\n', ...
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
   fprintf('WARNING: Float #%d: ''PARAMETER'' field not found in Json meta-data information - parameter information cannot be updated\n', ...
      g_decArgo_floatNum);
end

return

% ------------------------------------------------------------------------------
% Update misc meta data.
%
% SYNTAX :
%  [o_metaData] = add_misc_meta_data(a_metaData, a_decoderId)
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
%   02/27/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = add_misc_meta_data(a_metaData, a_decoderId)

% output parameters initialization
o_metaData = a_metaData;

% current float WMO number
global g_decArgo_floatNum;

% lists of managed decoders
global g_decArgo_decoderIdListNkeIridiumDeep;
global g_decArgo_decoderIdListNkeCts5Osean;
global g_decArgo_decoderIdListNkeCts5Usea;
global g_decArgo_decoderIdListNkeCts5;
global g_decArgo_decoderIdListNke;
global g_decArgo_decoderIdListApexApf9Argos;
global g_decArgo_decoderIdListApexApf9Iridium;
global g_decArgo_decoderIdListApexApf11Iridium;
global g_decArgo_decoderIdListApexApf11Argos;
global g_decArgo_decoderIdListApex;
global g_decArgo_decoderIdListNemo;


% add a POSITIONING_SYSTEM = 'IRIDIUM' to GPS floats
if (~(fix(a_decoderId/100) == 1) && ... % because this should not be done for Remocean floats
      ~(fix(a_decoderId/100) == 11) && ... % because this should not be done for Apex Iridium Rudics floats
      ~(fix(a_decoderId/100) == 12)) % because this should not be done for Navis floats
   if ((isfield(o_metaData, 'POSITIONING_SYSTEM')) && ...
         (isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_1')) && ...
         (strcmp(o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_1, 'GPS')) && ...
         ~(isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_2')))
      o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_2 = 'IRIDIUM';

      fprintf('INFO: Float #%d: adding ''POSITIONING_SYSTEM = IRIDIUM'' to float positioning systems\n', ...
         g_decArgo_floatNum);
   end
end

% add a POSITIONING_SYSTEM = 'RAFOS' to NEMO floats
if (ismember(a_decoderId, g_decArgo_decoderIdListNemo))
   if ((isfield(o_metaData, 'POSITIONING_SYSTEM')) && ...
         (isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_1')) && ...
         (strcmp(o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_1, 'GPS')) && ...
         (isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_2')) && ...
         (strcmp(o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_2, 'IRIDIUM')) && ...
         ~(isfield(o_metaData.POSITIONING_SYSTEM, 'POSITIONING_SYSTEM_3')))
      o_metaData.POSITIONING_SYSTEM.POSITIONING_SYSTEM_3 = 'RAFOS';

      fprintf('INFO: Float #%d: adding ''POSITIONING_SYSTEM = RAFOS'' to float positioning systems\n', ...
         g_decArgo_floatNum);
   end
end

% set CONTROLLER_BOARD_TYPE_PRIMARY
if (isfield(o_metaData, 'CONTROLLER_BOARD_TYPE_PRIMARY') && ...
      isempty(o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY))
   if (ismember(a_decoderId, g_decArgo_decoderIdListNke))
      if (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5))
         o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY = 'APMT';
      else
         o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY = 'I535';
      end
   elseif (ismember(a_decoderId, g_decArgo_decoderIdListApex))
      if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf9Argos) || ...
            ismember(a_decoderId, g_decArgo_decoderIdListApexApf9Iridium))
         o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY = 'APF9';
      elseif (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Argos) || ...
            ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium))
         o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY = 'APF11';
      end
   end
end

% set CONTROLLER_BOARD_TYPE_SECONDARY
if (isfield(o_metaData, 'CONTROLLER_BOARD_TYPE_SECONDARY') && ...
      isempty(o_metaData.CONTROLLER_BOARD_TYPE_SECONDARY))
   if (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5))
      if (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5Osean))
         o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY = 'OSEAN';
      elseif (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5Usea))
         o_metaData.CONTROLLER_BOARD_TYPE_PRIMARY = 'USEA';
      end
   end
end

% set BATTERY_TYPE
if (isfield(o_metaData, 'BATTERY_TYPE') && ...
      isempty(o_metaData.BATTERY_TYPE))
   if (ismember(a_decoderId, g_decArgo_decoderIdListNke))
      if (ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumDeep))
         o_metaData.BATTERY_TYPE = 'SAFT Lithium 14.5 V';
      else
         o_metaData.BATTERY_TYPE = 'SAFT Lithium 11 V';
      end
   end
end

return

% ------------------------------------------------------------------------------
% Add 'MTIME' parameter and associated SENSOR in meta-data.
%
% SYNTAX :
%  [o_metaData] = add_mtime_parameter(a_metaData)
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
%   07/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = add_mtime_parameter(a_metaData)

% output parameters initialization
o_metaData = a_metaData;


if (isfield(a_metaData, 'SENSOR') && ...
      isfield(a_metaData, 'SENSOR_MAKER') && ...
      isfield(a_metaData, 'PLATFORM_MAKER') && ...
      isfield(a_metaData, 'SENSOR_MODEL') && ...
      isfield(a_metaData, 'SENSOR_SERIAL_NO') && ...
      isfield(a_metaData, 'PARAMETER') && ...
      isfield(a_metaData, 'PARAMETER_SENSOR') && ...
      isfield(a_metaData, 'PARAMETER_UNITS') && ...
      isfield(a_metaData, 'PARAMETER_ACCURACY') && ...
      isfield(a_metaData, 'PARAMETER_RESOLUTION') && ...
      isfield(a_metaData, 'PREDEPLOYMENT_CALIB_EQUATION') && ...
      isfield(a_metaData, 'PREDEPLOYMENT_CALIB_COEFFICIENT') && ...
      isfield(a_metaData, 'PREDEPLOYMENT_CALIB_COMMENT'))

   paramMtime = get_netcdf_param_attributes('MTIME');

   o_metaData = add_field_in_top(o_metaData, 'SENSOR');
   o_metaData.SENSOR.SENSOR_1 = 'FLOATCLOCK_MTIME';
   o_metaData = add_field_in_top(o_metaData, 'SENSOR_MAKER');
   o_metaData.SENSOR_MAKER.SENSOR_MAKER_1 = o_metaData.PLATFORM_MAKER;
   o_metaData = add_field_in_top(o_metaData, 'SENSOR_MODEL');
   o_metaData.SENSOR_MODEL.SENSOR_MODEL_1 = 'FLOATCLOCK';
   o_metaData = add_field_in_top(o_metaData, 'SENSOR_SERIAL_NO');
   o_metaData = add_field_in_top(o_metaData, 'PARAMETER');
   o_metaData.PARAMETER.PARAMETER_1 = 'MTIME';
   o_metaData = add_field_in_top(o_metaData, 'PARAMETER_SENSOR');
   o_metaData.PARAMETER_SENSOR.PARAMETER_SENSOR_1 = 'FLOATCLOCK_MTIME';
   o_metaData = add_field_in_top(o_metaData, 'PARAMETER_UNITS');
   o_metaData.PARAMETER_UNITS.PARAMETER_UNITS_1 = paramMtime.units;
   o_metaData = add_field_in_top(o_metaData, 'PARAMETER_ACCURACY');
   o_metaData = add_field_in_top(o_metaData, 'PARAMETER_RESOLUTION');
   o_metaData = add_field_in_top(o_metaData, 'PREDEPLOYMENT_CALIB_EQUATION');
   o_metaData.PREDEPLOYMENT_CALIB_EQUATION.PREDEPLOYMENT_CALIB_EQUATION_1 = 'none';
   o_metaData = add_field_in_top(o_metaData, 'PREDEPLOYMENT_CALIB_COEFFICIENT');
   o_metaData.PREDEPLOYMENT_CALIB_COEFFICIENT.PREDEPLOYMENT_CALIB_COEFFICIENT_1 = 'none';
   o_metaData = add_field_in_top(o_metaData, 'PREDEPLOYMENT_CALIB_COMMENT');

end

return

% ------------------------------------------------------------------------------
% Insert a new field at the first place of the given structure and fill it with
% ' '.
%
% SYNTAX :
%  [o_metaData] = add_field_in_top(a_metaData, a_fieldName)
%
% INPUT PARAMETERS :
%   a_metaData  : input meta-data to be updated
%   a_fieldName : concerned field name
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
%   07/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = add_field_in_top(a_metaData, a_fieldName)

% output parameters initialization
o_metaData = a_metaData;


if (~isempty(o_metaData.(a_fieldName)))
   fieldNames = fieldnames(o_metaData.(a_fieldName));
   for id = length(fieldNames):-1:1
      o_metaData.(a_fieldName).([a_fieldName '_' num2str(id+1)]) = o_metaData.(a_fieldName).([a_fieldName '_' num2str(id)]);
   end
   o_metaData.(a_fieldName).([a_fieldName '_1']) = ' ';
end

return

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

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListCtd;


paramList = [ ...
   {'PRES'} ...
   {'TEMP'} ...
   {'PSAL'} ...
   ];

if (~isempty(g_decArgo_addParamListCtd))
   paramList = [paramList g_decArgo_addParamListCtd];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

% ------------------------------------------------------------------------------
% Update meta-data for ctd associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_ctd(a_paramName, a_decoderId, o_metaData)
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
%   03/27/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_ctd(a_paramName, a_decoderId, o_metaData)

% output parameters initialization
o_param = '';
o_paramSensor = '';
o_paramUnits = '';
o_paramAccuracy = '';
o_paramResolution = '';
o_preCalibEq = '';
o_preCalibCoef = '';
o_preCalibComment = '';

% lists of managed decoders
global g_decArgo_decoderIdListNkeIridiumRbr;
global g_decArgo_decoderIdListApexApf11Iridium;
global g_decArgo_decoderIdListNkeCts5Usea;

% current float WMO number
global g_decArgo_floatNum;


switch (a_paramName)

   case {'PRES'}
      o_param = 'PRES';
      o_paramSensor = 'CTD_PRES';
      o_paramUnits = 'decibar';
      if (~ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumRbr))
         o_paramAccuracy = '2.4';
         o_paramResolution = '0.1';
      else
         o_paramAccuracy = '1';
         o_paramResolution = '0.02';
      end
      o_preCalibEq = 'none';
      o_preCalibCoef = 'none';
      o_preCalibComment = '';

      if (ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumRbr))
         if (isfield(o_metaData, 'PRES_PARAMETER_ACCURACY') && ~isempty(o_metaData.PRES_PARAMETER_ACCURACY))
            o_paramAccuracy = o_metaData.PRES_PARAMETER_ACCURACY;
         end
         if (isfield(o_metaData, 'PRES_PARAMETER_RESOLUTION') && ~isempty(o_metaData.PRES_PARAMETER_RESOLUTION))
            o_paramResolution = o_metaData.PRES_PARAMETER_RESOLUTION;
         end
         if (isfield(o_metaData, 'PRES_PREDEPLOYMENT_CALIB_EQUATION') && ~isempty(o_metaData.PRES_PREDEPLOYMENT_CALIB_EQUATION))
            o_preCalibEq = o_metaData.PRES_PREDEPLOYMENT_CALIB_EQUATION;
         end
         if (isfield(o_metaData, 'PRES_PREDEPLOYMENT_CALIB_COEFFICIENT') && ~isempty(o_metaData.PRES_PREDEPLOYMENT_CALIB_COEFFICIENT))
            o_preCalibCoef = o_metaData.PRES_PREDEPLOYMENT_CALIB_COEFFICIENT;
         end
         if (isfield(o_metaData, 'PRES_PREDEPLOYMENT_CALIB_COMMENT') && ~isempty(o_metaData.PRES_PREDEPLOYMENT_CALIB_COMMENT))
            o_preCalibComment = o_metaData.PRES_PREDEPLOYMENT_CALIB_COMMENT;
         end
      end

      if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium))

         % Apex APF11 Iridium
         if (isfield(o_metaData, 'SBE_PRES_COEF_PA0'))
            o_preCalibEq = 'y=thermistor_output (counts); t=PTHA0+PTHA1*y+PTHA2*y^2; x=instrument_output-PTCA0-PTCA1*t-PTCA2*t^2; n=x*PTCB0/(PTCB0+PTCB1*t+PTCB2*t^2); pressure (PSIA)=PA0+PA1*n+PA2*n^2';
            if (isfield(o_metaData, 'SBE_PRES_COEF_PA0') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PA1') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PA2') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTHA0') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTHA1') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTHA2') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTCA0') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTCA1') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTCA2') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTCB0') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTCB1') && ...
                  isfield(o_metaData, 'SBE_PRES_COEF_PTCB2'))
               o_preCalibCoef = sprintf('%s, %s, %s; %s, %s, %s; %s, %s, %s; %s, %s, %s', ...
                  o_metaData.SBE_PRES_COEF_PTHA0, ...
                  o_metaData.SBE_PRES_COEF_PTHA1, ...
                  o_metaData.SBE_PRES_COEF_PTHA2, ...
                  o_metaData.SBE_PRES_COEF_PTCA0, ...
                  o_metaData.SBE_PRES_COEF_PTCA1, ...
                  o_metaData.SBE_PRES_COEF_PTCA2, ...
                  o_metaData.SBE_PRES_COEF_PTCB0, ...
                  o_metaData.SBE_PRES_COEF_PTCB1, ...
                  o_metaData.SBE_PRES_COEF_PTCB2, ...
                  o_metaData.SBE_PRES_COEF_PA0, ...
                  o_metaData.SBE_PRES_COEF_PA1, ...
                  o_metaData.SBE_PRES_COEF_PA2);
            end
            if (isfield(o_metaData, 'PARAMETER'))
               paramNum = find(strcmp(struct2cell(o_metaData.PARAMETER), o_param));
               fieldName = ['PREDEPLOYMENT_CALIB_COMMENT_' num2str(paramNum)];
               if (isfield(o_metaData, 'PREDEPLOYMENT_CALIB_COMMENT') && ...
                     isfield(o_metaData.PREDEPLOYMENT_CALIB_COMMENT, fieldName))
                  o_preCalibComment = o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(fieldName);
               end
            end
            if (isempty(o_preCalibCoef))
               fprintf('ERROR: Float #%d: inconsistent CTD_PRES calibration information\n', ...
                  g_decArgo_floatNum);
            end
         end
      end

   case {'TEMP'}
      o_param = 'TEMP';
      o_paramSensor = 'CTD_TEMP';
      o_paramUnits = 'degree_Celsius';
      if (~ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumRbr))
         o_paramAccuracy = '0.002';
         o_paramResolution = '0.001';
      else
         o_paramAccuracy = '0.002';
         o_paramResolution = '0.00005';
      end
      o_preCalibEq = 'none';
      o_preCalibCoef = 'none';
      o_preCalibComment = '';

      if (ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumRbr))
         if (isfield(o_metaData, 'TEMP_PARAMETER_ACCURACY') && ~isempty(o_metaData.TEMP_PARAMETER_ACCURACY))
            o_paramAccuracy = o_metaData.TEMP_PARAMETER_ACCURACY;
         end
         if (isfield(o_metaData, 'TEMP_PARAMETER_RESOLUTION') && ~isempty(o_metaData.TEMP_PARAMETER_RESOLUTION))
            o_paramResolution = o_metaData.TEMP_PARAMETER_RESOLUTION;
         end
         if (isfield(o_metaData, 'TEMP_PREDEPLOYMENT_CALIB_EQUATION') && ~isempty(o_metaData.TEMP_PREDEPLOYMENT_CALIB_EQUATION))
            o_preCalibEq = o_metaData.TEMP_PREDEPLOYMENT_CALIB_EQUATION;
         end
         if (isfield(o_metaData, 'TEMP_PREDEPLOYMENT_CALIB_COEFFICIENT') && ~isempty(o_metaData.TEMP_PREDEPLOYMENT_CALIB_COEFFICIENT))
            o_preCalibCoef = o_metaData.TEMP_PREDEPLOYMENT_CALIB_COEFFICIENT;
         end
         if (isfield(o_metaData, 'TEMP_PREDEPLOYMENT_CALIB_COMMENT') && ~isempty(o_metaData.TEMP_PREDEPLOYMENT_CALIB_COMMENT))
            o_preCalibComment = o_metaData.TEMP_PREDEPLOYMENT_CALIB_COMMENT;
         end
      end

      if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium) || ...
            ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5Usea))

         % Apex APF11 Iridium
         % Provor CTS5-USEA
         if (isfield(o_metaData, 'SBE_TEMP_COEF_TA0'))
            o_preCalibEq = 'n=instrument_output (counts); temperature ITS-90 (degC)=1/{a0+a1[ln(n)]+a2[ln^2(n)]+a3[ln^3(n)]}-273.15';
            if (isfield(o_metaData, 'SBE_TEMP_COEF_TA0') && ...
                  isfield(o_metaData, 'SBE_TEMP_COEF_TA1') && ...
                  isfield(o_metaData, 'SBE_TEMP_COEF_TA2') && ...
                  isfield(o_metaData, 'SBE_TEMP_COEF_TA3'))
               o_preCalibCoef = sprintf('%s, %s, %s, %s', ...
                  o_metaData.SBE_TEMP_COEF_TA0, ...
                  o_metaData.SBE_TEMP_COEF_TA1, ...
                  o_metaData.SBE_TEMP_COEF_TA2, ...
                  o_metaData.SBE_TEMP_COEF_TA3);
            end
            if (isfield(o_metaData, 'PARAMETER'))
               paramNum = find(strcmp(struct2cell(o_metaData.PARAMETER), o_param));
               fieldName = ['PREDEPLOYMENT_CALIB_COMMENT_' num2str(paramNum)];
               if (isfield(o_metaData, 'PREDEPLOYMENT_CALIB_COMMENT') && ...
                     isfield(o_metaData.PREDEPLOYMENT_CALIB_COMMENT, fieldName))
                  o_preCalibComment = o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(fieldName);
               end
            end
            if (isempty(o_preCalibCoef))
               fprintf('ERROR: Float #%d: inconsistent CTD_TEMP calibration information\n', ...
                  g_decArgo_floatNum);
            end
         end
      end

   case {'PSAL'}
      o_param = 'PSAL';
      o_paramSensor = 'CTD_CNDC';
      o_paramUnits = 'psu';
      if (~ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumRbr))
         o_paramAccuracy = '0.005';
         o_paramResolution = '0.001';
      else
         o_paramAccuracy = '0.003';
         o_paramResolution = '0.001';
      end
      o_preCalibEq = 'none';
      o_preCalibCoef = 'none';
      o_preCalibComment = '';

      if (ismember(a_decoderId, g_decArgo_decoderIdListNkeIridiumRbr))
         if (isfield(o_metaData, 'PSAL_PARAMETER_ACCURACY') && ~isempty(o_metaData.PSAL_PARAMETER_ACCURACY))
            o_paramAccuracy = o_metaData.PSAL_PARAMETER_ACCURACY;
         end
         if (isfield(o_metaData, 'PSAL_PARAMETER_RESOLUTION') && ~isempty(o_metaData.PSAL_PARAMETER_RESOLUTION))
            o_paramResolution = o_metaData.PSAL_PARAMETER_RESOLUTION;
         end
         if (isfield(o_metaData, 'PSAL_PREDEPLOYMENT_CALIB_EQUATION') && ~isempty(o_metaData.PSAL_PREDEPLOYMENT_CALIB_EQUATION))
            o_preCalibEq = o_metaData.PSAL_PREDEPLOYMENT_CALIB_EQUATION;
         end
         if (isfield(o_metaData, 'PSAL_PREDEPLOYMENT_CALIB_COEFFICIENT') && ~isempty(o_metaData.PSAL_PREDEPLOYMENT_CALIB_COEFFICIENT))
            o_preCalibCoef = o_metaData.PSAL_PREDEPLOYMENT_CALIB_COEFFICIENT;
         end
         if (isfield(o_metaData, 'PSAL_PREDEPLOYMENT_CALIB_COMMENT') && ~isempty(o_metaData.PSAL_PREDEPLOYMENT_CALIB_COMMENT))
            o_preCalibComment = o_metaData.PSAL_PREDEPLOYMENT_CALIB_COMMENT;
         end
      end

      if (ismember(a_decoderId, g_decArgo_decoderIdListApexApf11Iridium) || ...
            ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5Usea))

         % Apex APF11 Iridium
         % Provor CTS5-USEA
         if (isfield(o_metaData, 'SBE_CNDC_COEF_WBOTC'))
            o_preCalibEq = 'f=instrument_output (Hz)*sqrt(1.0+WBOTC*t)/1000.0; t=temperature (degC); p=pressure (decibars); d=CTcor; e=CPcor; conductivity (S/m)=(g+h*f^2+i*f^3+j*f^4)/(1+d*t+e*p)';
            if (isfield(o_metaData, 'SBE_CNDC_COEF_WBOTC') && ...
                  isfield(o_metaData, 'SBE_CNDC_COEF_CTCOR') && ...
                  isfield(o_metaData, 'SBE_CNDC_COEF_CPCOR') && ...
                  isfield(o_metaData, 'SBE_CNDC_COEF_G') && ...
                  isfield(o_metaData, 'SBE_CNDC_COEF_H') && ...
                  isfield(o_metaData, 'SBE_CNDC_COEF_I') && ...
                  isfield(o_metaData, 'SBE_CNDC_COEF_J'))
               o_preCalibCoef = sprintf('%s; %s; %s; %s, %s, %s, %s', ...
                  o_metaData.SBE_CNDC_COEF_WBOTC, ...
                  o_metaData.SBE_CNDC_COEF_CTCOR, ...
                  o_metaData.SBE_CNDC_COEF_CPCOR, ...
                  o_metaData.SBE_CNDC_COEF_G, ...
                  o_metaData.SBE_CNDC_COEF_H, ...
                  o_metaData.SBE_CNDC_COEF_I, ...
                  o_metaData.SBE_CNDC_COEF_J);
            end
            if (isfield(o_metaData, 'PARAMETER'))
               paramNum = find(strcmp(struct2cell(o_metaData.PARAMETER), o_param));
               fieldName = ['PREDEPLOYMENT_CALIB_COMMENT_' num2str(paramNum)];
               if (isfield(o_metaData, 'PREDEPLOYMENT_CALIB_COMMENT') && ...
                     isfield(o_metaData.PREDEPLOYMENT_CALIB_COMMENT, fieldName))
                  o_preCalibComment = o_metaData.PREDEPLOYMENT_CALIB_COMMENT.(fieldName);
               end
            end
            if (isempty(o_preCalibCoef))
               fprintf('ERROR: Float #%d: inconsistent CTD_CNDC calibration information\n', ...
                  g_decArgo_floatNum);
            end
         end
      end

   case {'NB_SAMPLE_CTD'}
      o_param = 'NB_SAMPLE_CTD';
      o_paramSensor = 'CTD_PRES';
      o_paramUnits = 'dimensionless';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'PRES_MED'}
      o_param = 'PRES_MED';
      o_paramSensor = 'CTD_PRES';
      o_paramUnits = 'decibar';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TEMP_STD'}
      o_param = 'TEMP_STD';
      o_paramSensor = 'CTD_TEMP';
      o_paramUnits = 'degree_Celsius';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TEMP_MED'}
      o_param = 'TEMP_MED';
      o_paramSensor = 'CTD_TEMP';
      o_paramUnits = 'degree_Celsius';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'PSAL_STD'}
      o_param = 'PSAL_STD';
      o_paramSensor = 'CTD_CNDC';
      o_paramUnits = 'psu';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'PSAL_MED'}
      o_param = 'PSAL_MED';
      o_paramSensor = 'CTD_CNDC';
      o_paramUnits = 'psu';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

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

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListOxygen;


paramList = [];
switch (a_decoderId)
   case {4, 19, 25}
      paramList = [ ...
         {'MOLAR_DOXY'} ...
         {'DOXY'} ...
         ];

   case {27, 28, 29, 32}
      paramList = [ ...
         {'TPHASE_DOXY'} ...
         {'DOXY'} ...
         ];

   case {106, 301, 202, 207, 208, 213, 214, 107, 109, 110, 111, 112, 113, 114, 115, ...
         201, 203, 206, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 215, 216, 217, 218, 221, 223, 225}
      if (ismember(a_decoderId, [213, 214, 121, 122, 123, 124, 125, 126, 127, 215, 216, 217, 218, 221, 223, 225]))
         if (a_decoderId == 124) % no optode on CTS5 UVP #6902968
            if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
                  any(strcmp('OPTODE', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
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
      elseif (ismember(a_decoderId, [106, 107, 109, 110, 111, 112, 113, 114, 115])) % CTS3 with PPOX_DOXY
         if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
               any(strcmp('OPTODE', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
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
            {'DOXY'} ...
            ];
      end

   case {209}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'C1PHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'DOXY'} ...
         {'TEMP_DOXY2'} ...
         {'PHASE_DELAY_DOXY'} ...
         {'DOXY2'} ...
         ];

   case {302, 303}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'DPHASE_DOXY'} ...
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

   case {1013, 1015, 1101}
      paramList = [ ...
         {'FREQUENCY_DOXY'} ...
         {'DOXY'} ...
         ];

   case {1104}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'TPHASE_DOXY'} ...
         {'DOXY'} ...
         ];

   case {1105}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'TPHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];

   case {1107, 1113}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'TPHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'DOXY'} ...
         ];

   case {1110, 1111, 1112, 1114}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'TPHASE_DOXY'} ...
         {'C2PHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];

   case {1201}
      paramList = [ ...
         {'TEMP_DOXY'} ...
         {'TPHASE_DOXY'} ...
         {'RPHASE_DOXY'} ...
         {'PPOX_DOXY'} ...
         {'DOXY'} ...
         {'TEMP_DOXY2'} ...
         {'PHASE_DELAY_DOXY2'} ...
         {'DOXY2'} ...
         ];

   case {1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('OPTODE', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'TEMP_DOXY'} ...
            {'C1PHASE_DOXY'} ...
            {'C2PHASE_DOXY'} ...
            {'PPOX_DOXY'} ...
            {'DOXY'} ...
            ];
      end
end

% for a_decoderId = 201 we have 5.61 floats (with DO sensor) and 5.63 floats
% (without DO sensor)
if (a_decoderId == 201)
   if ((isfield(a_metaData, 'DAC_FORMAT_ID')) && (str2num(a_metaData.DAC_FORMAT_ID) == 5.63))
      paramList = [];
   end
end

if (~isempty(g_decArgo_addParamListOxygen))
   paramList = [paramList g_decArgo_addParamListOxygen];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

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

global g_decArgo_doxy_202_204_302_a0;
global g_decArgo_doxy_202_204_302_a1;
global g_decArgo_doxy_202_204_302_a2;
global g_decArgo_doxy_202_204_302_a3;
global g_decArgo_doxy_202_204_302_a4;
global g_decArgo_doxy_202_204_302_a5;
global g_decArgo_doxy_202_204_302_d0;
global g_decArgo_doxy_202_204_302_d1;
global g_decArgo_doxy_202_204_302_d2;
global g_decArgo_doxy_202_204_302_d3;
global g_decArgo_doxy_202_204_302_sPreset;
global g_decArgo_doxy_202_204_302_b0;
global g_decArgo_doxy_202_204_302_b1;
global g_decArgo_doxy_202_204_302_b2;
global g_decArgo_doxy_202_204_302_b3;
global g_decArgo_doxy_202_204_302_c0;
global g_decArgo_doxy_202_204_302_pCoef1;
global g_decArgo_doxy_202_204_302_pCoef2;
global g_decArgo_doxy_202_204_302_pCoef3;

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

global g_decArgo_doxy_202_204_303_a0;
global g_decArgo_doxy_202_204_303_a1;
global g_decArgo_doxy_202_204_303_a2;
global g_decArgo_doxy_202_204_303_a3;
global g_decArgo_doxy_202_204_303_a4;
global g_decArgo_doxy_202_204_303_a5;
global g_decArgo_doxy_202_204_303_d0;
global g_decArgo_doxy_202_204_303_d1;
global g_decArgo_doxy_202_204_303_d2;
global g_decArgo_doxy_202_204_303_d3;
global g_decArgo_doxy_202_204_303_sPreset;
global g_decArgo_doxy_202_204_303_b0;
global g_decArgo_doxy_202_204_303_b1;
global g_decArgo_doxy_202_204_303_b2;
global g_decArgo_doxy_202_204_303_b3;
global g_decArgo_doxy_202_204_303_c0;
global g_decArgo_doxy_202_204_303_pCoef1;
global g_decArgo_doxy_202_204_303_pCoef2;
global g_decArgo_doxy_202_204_303_pCoef3;

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
         return
      end
      sensorModel = a_metaData.SENSOR_MODEL.(['SENSOR_MODEL_' num2str(idF)]);
      if (~strcmp(sensorModel, 'AANDERAA_OPTODE_3830') && ~strcmp(sensorModel, 'AANDERAA_OPTODE_4330'))
         fprintf('WARNING: Float #%d: ''OPTODE_DOXY'' sensor model is inconsistent in JSON meta-data\n', ...
            g_decArgo_floatNum);
         return
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
                  fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                     g_decArgo_floatNum);
                  return
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
                  fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                     g_decArgo_floatNum);
                  return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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
      end

   case {106, 301, 202, 207}
      % CASE_202_205_302
      switch (a_paramName)

         case {'TEMP_DOXY'} % CASE_202_102_001
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP_DOXY^m0*CalPhase^n0+c1*TEMP_DOXY^m1*CalPhase^n1+..+c27*TEMP_DOXY^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP_DOXY+273.15)-4.681*ln(TEMP_DOXY+273.15)])*0.20946]; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=Cstar*44.614*AirSat/100; Pcorr=1+((Pcoef2*TEMP_DOXY+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP_DOXY+273.15))+D2*ln((TEMP_DOXY+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP_DOXY)/(273.15+TEMP_DOXY)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP_DOXY+273.15))]';
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

   case {208, 112, 123, 125}
      % CASE_202_205_303
      switch (a_paramName)

         case {'TEMP_DOXY'} % CASE_202_102_001
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_205_303_sPreset, ...
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

   case {107, 109, 110, 111, 113, 114, 115, ...
         121, 122, 124, 126, 127, 128, 129, 130, 131, ...
         201, 203, 206, 213, 214, 215, 216, 217, 218, 221, 223, 225, ...
         1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, 1322, 1323}
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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

         case {'TEMP_DOXY2'} % CASE_103_102_001
            o_param = 'TEMP_DOXY2';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'degC';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TEMP_DOXY2=1/(TA0+TA1*L+TA2*L^2+TA3*L^3)-273.15; L=ln(100000*TEMP_VOLTAGE_DOXY/(3.3-TEMP_VOLTAGE_DOXY)); TEMP_VOLTAGE_DOXY is the thermistor voltage in volts';
            o_preCalibCoef = 'TA0=not available; TA1=not available; TA2=not available; TA3=not available';
            o_preCalibComment = 'optode temperature, see SBE63 User?s Manual (manual version #007, 10/28/13)';

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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
            if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOXY2';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '3 umol/kg or 2%';
            o_paramResolution = '0.2 umol/kg';
            o_preCalibEq = 'V=(PHASE_DELAY_DOXY+Pcoef1*PRES/1000)/39.457071; Ksv=C0+C1*TEMP_DOXY2+C2*TEMP_DOXY2^2; MLPL_DOXY=[(A0+A1*TEMP_DOXY2+A2*V^2)/(B0+B1*V)-1]/Ksv; O2=MLPL_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(SolB0+SolB1*TS+SolB2*TS^2+SolB3*TS^3)+SolC0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; TS=ln[(298.15?TEMP)/(273.15+TEMP)]; DOXY2[umol/kg]=44.6596*O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
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
            o_preCalibComment = 'see SBE63 User?s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
            o_preCalibComment = 'optode temperature, see SBE63 User?s Manual (manual version #007, 10/28/13)';

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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
            if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
            o_preCalibComment = 'see SBE63 User?s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
            % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
            % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
            if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
            % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
            % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
            if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
            % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
            if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
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

   case {1009, 1107, 1112, 1113}
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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

   case {1013, 1015, 1101}
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
            if (~isempty(find((size(tabDoxyCoef) == [1 6]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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
            o_preCalibComment = 'see Application note #64: SBE43 Dissolved Oxygen Sensor ? Background Information, Deployment Recommendations and Clearing and Storage (revised June 2013); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end

   case {1104, 1105, 1110, 1111}
      % CASE_202_204_302
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP_DOXY^m0*CalPhase^n0+c1*TEMP_DOXY^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP_DOXY+273.15)-4.681*ln(TEMP_DOXY+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_204_302_sPreset, ...
               g_decArgo_doxy_202_204_302_pCoef1, ...
               g_decArgo_doxy_202_204_302_pCoef2, ...
               g_decArgo_doxy_202_204_302_pCoef3, ...
               g_decArgo_doxy_202_204_302_b0, ...
               g_decArgo_doxy_202_204_302_b1, ...
               g_decArgo_doxy_202_204_302_b2, ...
               g_decArgo_doxy_202_204_302_b3, ...
               g_decArgo_doxy_202_204_302_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decArgo_doxy_202_204_302_a0, ...
               g_decArgo_doxy_202_204_302_a1, ...
               g_decArgo_doxy_202_204_302_a2, ...
               g_decArgo_doxy_202_204_302_a3, ...
               g_decArgo_doxy_202_204_302_a4, ...
               g_decArgo_doxy_202_204_302_a5, ...
               g_decArgo_doxy_202_204_302_d0, ...
               g_decArgo_doxy_202_204_302_d1, ...
               g_decArgo_doxy_202_204_302_d2, ...
               g_decArgo_doxy_202_204_302_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';

         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 28 for the
            % Aanderaa standard calibration
            if (~isempty(find((size(tabDoxyCoef) == [5 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP_DOXY^m0*CalPhase^n0+c1*TEMP_DOXY^m1*CalPhase^n1+..+c27*TEMP_DOXY^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP_DOXY+273.15)-4.681*ln(TEMP_DOXY+273.15)])*0.20946]; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=Cstar*44.614*AirSat/100; Pcorr=1+((Pcoef2*TEMP_DOXY+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP_DOXY+273.15))+D2*ln((TEMP_DOXY+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP_DOXY)/(273.15+TEMP_DOXY)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP_DOXY+273.15))]';
            o_preCalibCoef = sprintf('Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_204_302_pCoef1, ...
               g_decArgo_doxy_202_204_302_pCoef2, ...
               g_decArgo_doxy_202_204_302_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               g_decArgo_doxy_202_204_302_a0, ...
               g_decArgo_doxy_202_204_302_a1, ...
               g_decArgo_doxy_202_204_302_a2, ...
               g_decArgo_doxy_202_204_302_a3, ...
               g_decArgo_doxy_202_204_302_a4, ...
               g_decArgo_doxy_202_204_302_a5, ...
               g_decArgo_doxy_202_204_302_d0, ...
               g_decArgo_doxy_202_204_302_d1, ...
               g_decArgo_doxy_202_204_302_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end

   case {1114}
      % CASE_202_204_303
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '8 umol/kg or 10%';
            o_paramResolution = '1 umol/kg';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; O2=MOLAR_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(B0+B1*Ts+B2*Ts^2+B3*Ts^3)+C0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; DOXY=O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; B0=%g, B1=%g, B2=%g, B3=%g; C0=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g, D3=%g', ...
               g_decArgo_doxy_202_204_303_sPreset, ...
               g_decArgo_doxy_202_204_303_pCoef1, ...
               g_decArgo_doxy_202_204_303_pCoef2, ...
               g_decArgo_doxy_202_204_303_pCoef3, ...
               g_decArgo_doxy_202_204_303_b0, ...
               g_decArgo_doxy_202_204_303_b1, ...
               g_decArgo_doxy_202_204_303_b2, ...
               g_decArgo_doxy_202_204_303_b3, ...
               g_decArgo_doxy_202_204_303_c0, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decArgo_doxy_202_204_303_a0, ...
               g_decArgo_doxy_202_204_303_a1, ...
               g_decArgo_doxy_202_204_303_a2, ...
               g_decArgo_doxy_202_204_303_a3, ...
               g_decArgo_doxy_202_204_303_a4, ...
               g_decArgo_doxy_202_204_303_a5, ...
               g_decArgo_doxy_202_204_303_d0, ...
               g_decArgo_doxy_202_204_303_d1, ...
               g_decArgo_doxy_202_204_303_d2, ...
               g_decArgo_doxy_202_204_303_d3 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';

         case {'PPOX_DOXY'}
            % get calibration information
            if (isempty(g_decArgo_calibInfo) || ...
                  ~isfield(g_decArgo_calibInfo, 'OPTODE') || ...
                  ~isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef'))
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
            % Aanderaa standard calibration + an additional two-point adjustment
            if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PPOX_DOXY';
            o_paramSensor = 'OPTODE_DOXY';
            o_paramUnits = 'mbar';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TPHASE_DOXY=C1PHASE_DOXY-C2PHASE_DOXY; Phase_Pcorr=TPHASE_DOXY+Pcoef1*PRES/1000; CalPhase=PhaseCoef0+PhaseCoef1*Phase_Pcorr+PhaseCoef2*Phase_Pcorr^2+PhaseCoef3*Phase_Pcorr^3; deltaP=c0*TEMP^m0*CalPhase^n0+c1*TEMP^m1*CalPhase^n1+..+c27*TEMP^m27*CalPhase^n27; AirSat=deltaP*100/[(1013.25-exp[52.57-6690.9/(TEMP+273.15)-4.681*ln(TEMP+273.15)])*0.20946]; MOLAR_DOXY=Cstar*44.614*AirSat/100; ln(Cstar)=A0+A1*Ts+A2*Ts^2+A3*Ts^3+A4*Ts^4+A5*Ts^5; MOLAR_DOXY=ConcCoef0+ConcCoef1*MOLAR_DOXY; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; MOLAR_DOXY=MOLAR_DOXY*Pcorr; pH2Osat=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)]; Tcorr=44.6596*exp[2.00907+3.22014*Ts+4.05010*Ts^2+4.94457*Ts^3-2.56847e-1*Ts^4+3.88767*Ts^5]; Ts=ln[(298.15-TEMP)/(273.15+TEMP)]; PPOX_DOXY=MOLAR_DOXY*(0.20946*(1013.25-pH2Osat))/Tcorr*exp[0.317*PRES/(8.314*(TEMP+273.15))]';
            o_preCalibCoef = sprintf('Spreset=%g; Pcoef1=%g, Pcoef2=%g, Pcoef3=%g; PhaseCoef0=%g, PhaseCoef1=%g, PhaseCoef2=%g, PhaseCoef3=%g; c0=%g, c1=%g, c2=%g, c3=%g, c4=%g, c5=%g, c6=%g, c7=%g, c8=%g, c9=%g, c10=%g, c11=%g, c12=%g, c13=%g, c14=%g, c15=%g, c16=%g, c17=%g, c18=%g, c19=%g, c20=%g, c21=%g, c22=%g, c23=%g, c24=%g, c25=%g, c26=%g, c27=%g; m0=%g, m1=%g, m2=%g, m3=%g, m4=%g, m5=%g, m6=%g, m7=%g, m8=%g, m9=%g, m10=%g, m11=%g, m12=%g, m13=%g, m14=%g, m15=%g, m16=%g, m17=%g, m18=%g, m19=%g, m20=%g, m21=%g, m22=%g, m23=%g, m24=%g, m25=%g, m26=%g, m27=%g; n0=%g, n1=%g, n2=%g, n3=%g, n4=%g, n5=%g, n6=%g, n7=%g, n8=%g, n9=%g, n10=%g, n11=%g, n12=%g, n13=%g, n14=%g, n15=%g, n16=%g, n17=%g, n18=%g, n19=%g, n20=%g, n21=%g, n22=%g, n23=%g, n24=%g, n25=%g, n26=%g, n27=%g; ConcCoef0=%g, ConcCoef1=%g; A0=%g, A1=%g, A2=%g, A3=%g, A4=%g, A5=%g; D0=%g, D1=%g, D2=%g', ...
               g_decArgo_doxy_202_204_303_sPreset, ...
               g_decArgo_doxy_202_204_303_pCoef1, ...
               g_decArgo_doxy_202_204_303_pCoef2, ...
               g_decArgo_doxy_202_204_303_pCoef3, ...
               tabDoxyCoef(1, 1:4), ...
               tabDoxyCoef(3, 1:28), ...
               tabDoxyCoef(4, 1:28), ...
               tabDoxyCoef(5, 1:28), ...
               tabDoxyCoef(6, 1:2), ...
               g_decArgo_doxy_202_204_303_a0, ...
               g_decArgo_doxy_202_204_303_a1, ...
               g_decArgo_doxy_202_204_303_a2, ...
               g_decArgo_doxy_202_204_303_a3, ...
               g_decArgo_doxy_202_204_303_a4, ...
               g_decArgo_doxy_202_204_303_a5, ...
               g_decArgo_doxy_202_204_303_d0, ...
               g_decArgo_doxy_202_204_303_d1, ...
               g_decArgo_doxy_202_204_303_d2 ...
               );
            o_preCalibComment = 'see TD269 Operating manual oxygen optode 4330, 4835, 4831; see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end

   case {1201}
      % CASE_202_204_304 for AANDERAA
      % CASE_103_208_307 for SBE
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

            % CASE_202_204_304 for AANDERAA

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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
            if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent\n', ...
                  g_decArgo_floatNum);
               return
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

         case {'TEMP_DOXY2'} % CASE_103_102_001
            o_param = 'TEMP_DOXY2';
            o_paramSensor = 'OPTODE_DOXY2';
            o_paramUnits = 'degC';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'TEMP_DOXY2=1/(TA0+TA1*L+TA2*L^2+TA3*L^3)-273.15; L=ln(100000*TEMP_VOLTAGE_DOXY/(3.3-TEMP_VOLTAGE_DOXY)); TEMP_VOLTAGE_DOXY is the thermistor voltage in volts';
            o_preCalibCoef = 'TA0=not available; TA1=not available; TA2=not available; TA3=not available';
            o_preCalibComment = 'optode temperature, see SBE63 User?s Manual (manual version #007, 10/28/13)';

            % CASE_103_208_307 for SBE

         case {'PHASE_DELAY_DOXY2'}
            o_param = 'PHASE_DELAY_DOXY2';
            o_paramSensor = 'OPTODE_DOXY2';
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
               fprintf('ERROR: Float #%d: inconsistent DOXY calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end
            tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
            % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
            if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
               fprintf('ERROR: Float #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOXY2';
            o_paramSensor = 'OPTODE_DOXY2';
            o_paramUnits = 'umol/kg';
            o_paramAccuracy = '3 umol/kg or 2%';
            o_paramResolution = '0.2 umol/kg';
            o_preCalibEq = 'V=(PHASE_DELAY_DOXY+Pcoef1*PRES/1000)/39.457071; Ksv=C0+C1*TEMP_DOXY2+C2*TEMP_DOXY2^2; MLPL_DOXY=[(A0+A1*TEMP_DOXY2+A2*V^2)/(B0+B1*V)-1]/Ksv; O2=MLPL_DOXY*Scorr*Pcorr; Scorr=A*exp[PSAL*(SolB0+SolB1*TS+SolB2*TS^2+SolB3*TS^3)+SolC0*PSAL^2]; A=[(1013.25-pH2O(TEMP,Spreset))/(1013.25-pH2O(TEMP,PSAL))]; pH2O(TEMP,S)=1013.25*exp[D0+D1*(100/(TEMP+273.15))+D2*ln((TEMP+273.15)/100)+D3*S]; Pcorr=1+((Pcoef2*TEMP+Pcoef3)*PRES)/1000; TS=ln[(298.15?TEMP)/(273.15+TEMP)]; DOXY2[umol/kg]=44.6596*O2/rho, where rho is the potential density [kg/L] calculated from CTD data';
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
            o_preCalibComment = 'see SBE63 User?s Manual (manual version #007, 10/28/13); see Processing Argo OXYGEN data at the DAC level, Version 2.2 (DOI: http://dx.doi.org/10.13155/39795)';
      end
end

switch (a_paramName)

   case {'TEMP_DOXY_STD'}
      o_param = 'TEMP_DOXY_STD';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degC';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TEMP_DOXY_MED'}
      o_param = 'TEMP_DOXY_MED';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degC';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'C1PHASE_DOXY_STD'}
      o_param = 'C1PHASE_DOXY_STD';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degree';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'C1PHASE_DOXY_MED'}
      o_param = 'C1PHASE_DOXY_MED';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degree';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'C2PHASE_DOXY_STD'}
      o_param = 'C2PHASE_DOXY_STD';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degree';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'C2PHASE_DOXY_MED'}
      o_param = 'C2PHASE_DOXY_MED';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degree';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'DPHASE_DOXY_STD'}
      o_param = 'DPHASE_DOXY_STD';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degree';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'DPHASE_DOXY_MED'}
      o_param = 'DPHASE_DOXY_MED';
      o_paramSensor = 'OPTODE_DOXY';
      o_paramUnits = 'degree';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

% ------------------------------------------------------------------------------
% Update parameter list for radiometry associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_radiometry(a_metaData, a_decoderId)
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
function [o_metaData] = update_parameter_list_radiometry(a_metaData, a_decoderId)

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListRadiometry;


paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 131}
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
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('MPE', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [paramList ...
            {'VOLTAGE_DOWNWELLING_PAR'} ...
            {'TEMP_DOWNWELLING_PAR'} ...
            {'DOWNWELLING_PAR2'} ...
            ];
      end
   case {130}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('OCR', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'RAW_DOWNWELLING_IRRADIANCE412'} ...
            {'RAW_DOWNWELLING_IRRADIANCE443'} ...
            {'RAW_DOWNWELLING_IRRADIANCE490'} ...
            {'RAW_DOWNWELLING_IRRADIANCE665'} ...
            {'DOWN_IRRADIANCE412'} ...
            {'DOWN_IRRADIANCE443'} ...
            {'DOWN_IRRADIANCE490'} ...
            {'DOWN_IRRADIANCE665'} ...
            ];
      end
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('MPE', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [paramList ...
            {'VOLTAGE_DOWNWELLING_PAR'} ...
            {'TEMP_DOWNWELLING_PAR'} ...
            {'DOWNWELLING_PAR2'} ...
            ];
      end
   case {1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('OCR', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         % for Apex APF11 floats, parameter names is defined from calibration
         % information
         if (isempty(g_decArgo_calibInfo) && isfield(g_decArgo_calibInfo, 'OCR'))
            if (isfield(g_decArgo_calibInfo.OCR, 'A0Lambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0PAR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1PAR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmPAR'))

               paramList = [ ...
                  {'DOWN_IRRADIANCE380'} ...
                  {'DOWN_IRRADIANCE412'} ...
                  {'DOWN_IRRADIANCE490'} ...
                  {'DOWNWELLING_PAR'} ...
                  ];

            elseif (isfield(g_decArgo_calibInfo.OCR, 'A0Lambda443') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda443') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda443') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda555') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda555') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda555') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda670') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda670') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda670'))

               paramList = [ ...
                  {'DOWN_IRRADIANCE443'} ...
                  {'DOWN_IRRADIANCE490'} ...
                  {'DOWN_IRRADIANCE555'} ...
                  {'DOWN_IRRADIANCE670'} ...
                  ];
            end
         end
      end
end

if (~isempty(g_decArgo_addParamListRadiometry))
   paramList = [paramList g_decArgo_addParamListRadiometry];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

% ------------------------------------------------------------------------------
% Update meta-data for radiometry associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_radiometry(a_paramName, a_decoderId)
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
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_radiometry(a_paramName, a_decoderId)

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
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
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

         case {'RAW_DOWNWELLING_IRRADIANCE443'}
            o_param = 'RAW_DOWNWELLING_IRRADIANCE443';
            o_paramSensor = 'RADIOMETER_DOWN_IRR443';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling irradiance measurement at 443 nm';

         case {'RAW_DOWNWELLING_IRRADIANCE490'}
            o_param = 'RAW_DOWNWELLING_IRRADIANCE490';
            o_paramSensor = 'RADIOMETER_DOWN_IRR490';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling irradiance measurement at 490 nm';

         case {'RAW_DOWNWELLING_IRRADIANCE665'}
            o_param = 'RAW_DOWNWELLING_IRRADIANCE665';
            o_paramSensor = 'RADIOMETER_DOWN_IRR665';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated downwelling irradiance measurement at 665 nm';

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
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE380 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda380') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda380'))
               a0Lambda380 = double(g_decArgo_calibInfo.OCR.A0Lambda380);
               a1Lambda380 = double(g_decArgo_calibInfo.OCR.A1Lambda380);
               lmLambda380 = double(g_decArgo_calibInfo.OCR.LmLambda380);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE380 calibration information\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE412 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda412') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda412'))
               a0Lambda412 = double(g_decArgo_calibInfo.OCR.A0Lambda412);
               a1Lambda412 = double(g_decArgo_calibInfo.OCR.A1Lambda412);
               lmLambda412 = double(g_decArgo_calibInfo.OCR.LmLambda412);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE412 calibration information\n', ...
                  g_decArgo_floatNum);
               return
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

         case {'DOWN_IRRADIANCE443'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE443 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda443') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda443') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda443'))
               a0Lambda443 = double(g_decArgo_calibInfo.OCR.A0Lambda443);
               a1Lambda443 = double(g_decArgo_calibInfo.OCR.A1Lambda443);
               lmLambda443 = double(g_decArgo_calibInfo.OCR.LmLambda443);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE443 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOWN_IRRADIANCE443';
            o_paramSensor = 'RADIOMETER_DOWN_IRR443';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE443=0.01*A1_443*(RAW_DOWNWELLING_IRRADIANCE443-A0_443)*lm_443';
            o_preCalibCoef = sprintf('A1_443=%g, A0_443=%g, lm_443=%g', ...
               a1Lambda443, a0Lambda443, lmLambda443);
            o_preCalibComment = '';

         case {'DOWN_IRRADIANCE490'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE490 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda490'))
               a0Lambda490 = double(g_decArgo_calibInfo.OCR.A0Lambda490);
               a1Lambda490 = double(g_decArgo_calibInfo.OCR.A1Lambda490);
               lmLambda490 = double(g_decArgo_calibInfo.OCR.LmLambda490);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE490 calibration information\n', ...
                  g_decArgo_floatNum);
               return
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

         case {'DOWN_IRRADIANCE555'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE555 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda555') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda555') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda555'))
               a0Lambda555 = double(g_decArgo_calibInfo.OCR.A0Lambda555);
               a1Lambda555 = double(g_decArgo_calibInfo.OCR.A1Lambda555);
               lmLambda555 = double(g_decArgo_calibInfo.OCR.LmLambda555);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE555 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOWN_IRRADIANCE555';
            o_paramSensor = 'RADIOMETER_DOWN_IRR555';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE555=0.01*A1_555*(RAW_DOWNWELLING_IRRADIANCE555-A0_555)*lm_555';
            o_preCalibCoef = sprintf('A1_555=%g, A0_555=%g, lm_555=%g', ...
               a1Lambda555, a0Lambda555, lmLambda555);
            o_preCalibComment = '';

         case {'DOWN_IRRADIANCE665'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE665 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda665') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda665') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda665'))
               a0Lambda665 = double(g_decArgo_calibInfo.OCR.A0Lambda665);
               a1Lambda665 = double(g_decArgo_calibInfo.OCR.A1Lambda665);
               lmLambda665 = double(g_decArgo_calibInfo.OCR.LmLambda665);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE665 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOWN_IRRADIANCE665';
            o_paramSensor = 'RADIOMETER_DOWN_IRR665';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE665=0.01*A1_665*(RAW_DOWNWELLING_IRRADIANCE665-A0_665)*lm_665';
            o_preCalibCoef = sprintf('A1_665=%g, A0_665=%g, lm_665=%g', ...
               a1Lambda665, a0Lambda665, lmLambda665);
            o_preCalibComment = '';

         case {'DOWN_IRRADIANCE670'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWN_IRRADIANCE670 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0Lambda670') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1Lambda670') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmLambda670'))
               a0Lambda670 = double(g_decArgo_calibInfo.OCR.A0Lambda670);
               a1Lambda670 = double(g_decArgo_calibInfo.OCR.A1Lambda670);
               lmLambda670 = double(g_decArgo_calibInfo.OCR.LmLambda670);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWN_IRRADIANCE670 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOWN_IRRADIANCE670';
            o_paramSensor = 'RADIOMETER_DOWN_IRR670';
            o_paramUnits = 'W/m^2/nm';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWN_IRRADIANCE670=0.01*A1_670*(RAW_DOWNWELLING_IRRADIANCE670-A0_670)*lm_670';
            o_preCalibCoef = sprintf('A1_670=%g, A0_670=%g, lm_670=%g', ...
               a1Lambda670, a0Lambda670, lmLambda670);
            o_preCalibComment = '';

         case {'DOWNWELLING_PAR'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWNWELLING_PAR calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'OCR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A0PAR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'A1PAR') && ...
                  isfield(g_decArgo_calibInfo.OCR, 'LmPAR'))
               a0PAR = double(g_decArgo_calibInfo.OCR.A0PAR);
               a1PAR = double(g_decArgo_calibInfo.OCR.A1PAR);
               lmPAR = double(g_decArgo_calibInfo.OCR.LmPAR);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWNWELLING_PAR calibration information\n', ...
                  g_decArgo_floatNum);
               return
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

         case {'DOWNWELLING_PAR2'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing DOWNWELLING_PAR2 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'MPE') && ...
                  isfield(g_decArgo_calibInfo.MPE, 'ResponsivityW'))
               responsivityW = str2double(g_decArgo_calibInfo.MPE.ResponsivityW);
            else
               fprintf('ERROR: Float #%d: inconsistent DOWNWELLING_PAR2 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'DOWNWELLING_PAR2';
            o_paramSensor = 'AUX_RADIOMETER_PAR';
            o_paramUnits = 'microMoleQuanta/m^2/sec';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'DOWNWELLING_PAR2=1E4*VOLTAGE_DOWNWELLING_PAR/ResponsivityW';
            o_preCalibCoef = sprintf('ResponsivityW=%.5f', ...
               responsivityW);
            o_preCalibComment = '';

      end
end

switch (a_paramName)

   case {'RAW_DOWNWELLING_IRRADIANCE380_STD'}
      o_param = 'RAW_DOWNWELLING_IRRADIANCE380_STD';
      o_paramSensor = 'RADIOMETER_DOWN_IRR380';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_IRRADIANCE380_MED'}
      o_param = 'RAW_DOWNWELLING_IRRADIANCE380_MED';
      o_paramSensor = 'RADIOMETER_DOWN_IRR380';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_IRRADIANCE412_STD'}
      o_param = 'RAW_DOWNWELLING_IRRADIANCE412_STD';
      o_paramSensor = 'RADIOMETER_DOWN_IRR412';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_IRRADIANCE412_MED'}
      o_param = 'RAW_DOWNWELLING_IRRADIANCE412_MED';
      o_paramSensor = 'RADIOMETER_DOWN_IRR412';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_IRRADIANCE490_STD'}
      o_param = 'RAW_DOWNWELLING_IRRADIANCE490_STD';
      o_paramSensor = 'RADIOMETER_DOWN_IRR490';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_IRRADIANCE490_MED'}
      o_param = 'RAW_DOWNWELLING_IRRADIANCE490_MED';
      o_paramSensor = 'RADIOMETER_DOWN_IRR490';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_PAR_STD'}
      o_param = 'RAW_DOWNWELLING_PAR_STD';
      o_paramSensor = 'RADIOMETER_PAR';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'RAW_DOWNWELLING_PAR_MED'}
      o_param = 'RAW_DOWNWELLING_PAR_MED';
      o_paramSensor = 'RADIOMETER_PAR';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

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

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListBackscattering;


paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 110, 111, 112, 113, 114, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'BETA_BACKSCATTERING700'} ...
            {'BBP700'} ...
            ];
      end
   case {108, 109, 115}
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
   case {1015, 1101, 1105, 1110, 1111, 1112, 1114}
      paramList = [ ...
         {'BETA_BACKSCATTERING700'} ...
         {'BBP700'} ...
         ];
end

if (~isempty(g_decArgo_addParamListBackscattering))
   paramList = [paramList g_decArgo_addParamListBackscattering];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

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
%   a_metaData  : input meta-data
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
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_backscattering(a_paramName, a_decoderId, a_metaData)

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
   case {105, 106, 107, 110, 111, 112, 113, 114, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      switch (a_paramName)

         case {'BETA_BACKSCATTERING700'}
            o_param = 'BETA_BACKSCATTERING700';
            o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';

         case {'BBP700'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'ECO2') && ...
                  isfield(g_decArgo_calibInfo.ECO2, 'ScaleFactBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.ECO2, 'DarkCountBackscatter700') && ...
                  isfield(g_decArgo_calibInfo.ECO2, 'KhiCoefBackscatter'))
               scaleFactBackscatter700 = double(g_decArgo_calibInfo.ECO2.ScaleFactBackscatter700);
               darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO2.DarkCountBackscatter700);
               darkCountBackscatter700_O = [];
               if (isfield(g_decArgo_calibInfo.ECO2, 'DarkCountBackscatter700_O'))
                  darkCountBackscatter700_O = double(g_decArgo_calibInfo.ECO2.DarkCountBackscatter700_O);
               end
               khiCoefBackscatter = double(g_decArgo_calibInfo.ECO2.KhiCoefBackscatter);
               % determine angle of measurement
               % if SENSOR_MODEL == ECO_FLBB => 142?
               % if (ECO_FLBBCD || ECO_FLBB2) == ECO_FLBB => 124?
               angle = 142;
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
               angle = 124;
            else
               fprintf('ERROR: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(darkCountBackscatter700_O))
               o_param = 'BBP700';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at %d angularDeg', ...
                  darkCountBackscatter700, scaleFactBackscatter700, khiCoefBackscatter, angle);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            else
               o_param = 'BBP700';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700_O)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, DARK_BACKSCATTERING700_O=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at %d angularDeg', ...
                  darkCountBackscatter700, darkCountBackscatter700_O, scaleFactBackscatter700, khiCoefBackscatter, angle);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            end

      end

   case {108, 109, 115}
      switch (a_paramName)

         case {'BETA_BACKSCATTERING700'}
            o_param = 'BETA_BACKSCATTERING700';
            o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';

         case {'BBP700'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(darkCountBackscatter700_O))
               o_param = 'BBP700';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter700, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            else
               o_param = 'BBP700';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700_O)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, DARK_BACKSCATTERING700_O=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter700, darkCountBackscatter700_O, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            end

         case {'BETA_BACKSCATTERING532'}
            o_param = 'BETA_BACKSCATTERING532';
            o_paramSensor = 'BACKSCATTERINGMETER_BBP532';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';

         case {'BBP532'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing BBP532 calibration information\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent BBP532 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(darkCountBackscatter532_O))
               o_param = 'BBP532';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP532';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP532=2*pi*khi*((BETA_BACKSCATTERING532-DARK_BACKSCATTERING532)*SCALE_BACKSCATTERING532-BETASW532)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING532=%g, SCALE_BACKSCATTERING532=%g, khi=%g, BETASW532 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter532, scaleFactBackscatter532, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW532 is the contribution by the pure seawater at 532nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            else
               o_param = 'BBP532';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP532';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP532=2*pi*khi*((BETA_BACKSCATTERING532-DARK_BACKSCATTERING532_O)*SCALE_BACKSCATTERING532-BETASW532)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING532=%g, DARK_BACKSCATTERING532_O=%g, SCALE_BACKSCATTERING532=%g, khi=%g, BETASW532 (contribution of pure sea water) is calculated at 124 angularDeg', ...
                  darkCountBackscatter532, darkCountBackscatter532_O, scaleFactBackscatter532, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW532 is the contribution by the pure seawater at 532nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            end

      end

   case {301, 1015, 1101, 1105, 1110, 1111, 1112, 1114}
      switch (a_paramName)

         case {'BETA_BACKSCATTERING700'}
            o_param = 'BETA_BACKSCATTERING700';
            o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated backscattering measurement';

         case {'BBP700'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent BBP700 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(darkCountBackscatter700_O))
               o_param = 'BBP700';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 142 angularDeg', ...
                  darkCountBackscatter700, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            else
               o_param = 'BBP700';
               o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
               o_paramUnits = 'm-1';
               o_paramAccuracy = '';
               o_paramResolution = '';
               o_preCalibEq = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700_O)*SCALE_BACKSCATTERING700-BETASW700)';
               o_preCalibCoef = sprintf('DARK_BACKSCATTERING700=%g, DARK_BACKSCATTERING700_O=%g, SCALE_BACKSCATTERING700=%g, khi=%g, BETASW700 (contribution of pure sea water) is calculated at 142 angularDeg', ...
                  darkCountBackscatter700, darkCountBackscatter700_O, scaleFactBackscatter700, khiCoefBackscatter);
               o_preCalibComment = 'Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916. Reprocessed from the file provided by Andrew Bernard (Seabird) following ADMT18. This file is accessible at http://doi.org/10.17882/54520.';
            end

      end
end

switch (a_paramName)

   case {'BETA_BACKSCATTERING532_STD'}
      o_param = 'BETA_BACKSCATTERING532_STD';
      o_paramSensor = 'BACKSCATTERINGMETER_BBP532';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'BETA_BACKSCATTERING532_MED'}
      o_param = 'BETA_BACKSCATTERING532_MED';
      o_paramSensor = 'BACKSCATTERINGMETER_BBP532';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'BETA_BACKSCATTERING700_STD'}
      o_param = 'BETA_BACKSCATTERING700_STD';
      o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'BETA_BACKSCATTERING700_MED'}
      o_param = 'BETA_BACKSCATTERING700_MED';
      o_paramSensor = 'BACKSCATTERINGMETER_BBP700';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

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

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListChla;


paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, ...
         301, 302, 303, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'FLUORESCENCE_CHLA'} ...
            {'CHLA'} ...
            ];
      end
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('CYCLOPS', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'FLUORESCENCE_VOLTAGE_CHLA'} ...
            {'CHLA2'} ...
            ];
      end
   case {131}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'FLUORESCENCE_CHLA'} ...
            {'CHLA'} ...
            {'FLUORESCENCE_CHLA435'} ...
            {'CHLA435'} ...
            ];
      end
   case {1015, 1101, 1105, 1110, 1111, 1112, 1114}
      paramList = [ ...
         {'FLUORESCENCE_CHLA'} ...
         {'TEMP_CPU_CHLA'} ...
         {'CHLA'} ...
         ];
   case {1014}
      paramList = [ ...
         {'FLUORESCENCE_CHLA'} ...
         {'CHLA'} ...
         ];
end

if (~isempty(g_decArgo_addParamListChla))
   paramList = [paramList g_decArgo_addParamListChla];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

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
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
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
               fprintf('ERROR: Float #%d: missing CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'ECO2') && ...
                  isfield(g_decArgo_calibInfo.ECO2, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.ECO2, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.ECO2.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.ECO2.DarkCountChloroA);
               DarkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.ECO2, 'DarkCountChloroA_O'))
                  DarkCountChloroA_O = double(g_decArgo_calibInfo.ECO2.DarkCountChloroA_O);
               end
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.ECO3.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA);
               DarkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA_O'))
                  DarkCountChloroA_O = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA_O);
               end
            else
               fprintf('ERROR: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(DarkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = '';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, DarkCountChloroA_O);
               o_preCalibComment = '';
            end

         case {'FLUORESCENCE_CHLA435'}
            o_param = 'FLUORESCENCE_CHLA435';
            o_paramSensor = 'AUX_FLUOROMETER_CHLA435';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated chlorophyll-a at 435 nanometers fluorescence measurement';

         case {'CHLA435'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing CHLA435 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'ECO3') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactChloroA435') && ...
                  isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA435'))
               scaleFactChloroA435 = double(g_decArgo_calibInfo.ECO3.ScaleFactChloroA435);
               darkCountChloroA435 = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA435);
            else
               fprintf('ERROR: Float #%d: inconsistent CHLA435 calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'CHLA435';
            o_paramSensor = 'AUX_FLUOROMETER_CHLA435';
            o_paramUnits = 'mg/m3';
            o_paramAccuracy = '0.08 mg/m3';
            o_paramResolution = '0.025 mg/m3';
            o_preCalibEq = 'CHLA435=(FLUORESCENCE_CHLA435-DARK_CHLA435)*SCALE_CHLA435';
            o_preCalibCoef = sprintf('SCALE_CHLA435=%g, DARK_CHLA435=%g', ...
               scaleFactChloroA435, darkCountChloroA435);
            o_preCalibComment = '';

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
               fprintf('ERROR: Float #%d: missing CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'FLNTU') && ...
                  isfield(g_decArgo_calibInfo.FLNTU, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.FLNTU.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA);
               DarkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA_O'))
                  DarkCountChloroA_O = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA_O);
               end
            else
               fprintf('ERROR: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(DarkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = '';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, DarkCountChloroA_O);
               o_preCalibComment = '';
            end

      end

   case {301, 1015, 1101, 1105, 1110, 1111, 1112, 1114}
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
               fprintf('ERROR: Float #%d: missing CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'FLBB') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.FLBB, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.FLBB.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.FLBB.DarkCountChloroA);
               DarkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.FLBB, 'DarkCountChloroA_O'))
                  DarkCountChloroA_O = double(g_decArgo_calibInfo.FLBB.DarkCountChloroA_O);
               end
            else
               fprintf('ERROR: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(DarkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = '';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, DarkCountChloroA_O);
               o_preCalibComment = '';
            end

         case {'FLUORESCENCE_VOLTAGE_CHLA'}
            o_param = 'FLUORESCENCE_VOLTAGE_CHLA';
            o_paramSensor = 'FLUOROMETER_CHLA2';
            o_paramUnits = 'volt';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'n/a';
            o_preCalibCoef = 'n/a';
            o_preCalibComment = '';

         case {'CHLA2'}
            o_param = 'CHLA2';
            o_paramSensor = 'FLUOROMETER_CHLA2';
            o_paramUnits = 'mg/m3';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'n/a';
            o_preCalibCoef = 'n/a';
            o_preCalibComment = '';

      end

   case {1014}
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
               fprintf('ERROR: Float #%d: missing CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'FLNTU') && ...
                  isfield(g_decArgo_calibInfo.FLNTU, 'ScaleFactChloroA') && ...
                  isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA'))
               scaleFactChloroA = double(g_decArgo_calibInfo.FLNTU.ScaleFactChloroA);
               darkCountChloroA = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA);
               DarkCountChloroA_O = [];
               if (isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA_O'))
                  DarkCountChloroA_O = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA_O);
               end
            else
               fprintf('ERROR: Float #%d: inconsistent CHLA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(DarkCountChloroA_O))
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g', ...
                  scaleFactChloroA, darkCountChloroA);
               o_preCalibComment = '';
            else
               o_param = 'CHLA';
               o_paramSensor = 'FLUOROMETER_CHLA';
               o_paramUnits = 'mg/m3';
               o_paramAccuracy = '0.08 mg/m3';
               o_paramResolution = '0.025 mg/m3';
               o_preCalibEq = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA_O)*SCALE_CHLA';
               o_preCalibCoef = sprintf('SCALE_CHLA=%g, DARK_CHLA=%g, DARK_CHLA_O=%g', ...
                  scaleFactChloroA, darkCountChloroA, DarkCountChloroA_O);
               o_preCalibComment = '';
            end

      end
end

switch (a_paramName)

   case {'FLUORESCENCE_CHLA_STD'}
      o_param = 'FLUORESCENCE_CHLA_STD';
      o_paramSensor = 'FLUOROMETER_CHLA';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'FLUORESCENCE_CHLA_MED'}
      o_param = 'FLUORESCENCE_CHLA_MED';
      o_paramSensor = 'FLUOROMETER_CHLA';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'FLUORESCENCE_VOLTAGE_CHLA_STD'}
      o_param = 'FLUORESCENCE_VOLTAGE_CHLA_STD';
      o_paramSensor = 'FLUOROMETER_CHLA';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'FLUORESCENCE_VOLTAGE_CHLA_MED'}
      o_param = 'FLUORESCENCE_VOLTAGE_CHLA_MED';
      o_paramSensor = 'FLUOROMETER_CHLA';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

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

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListCdom;


paramList = [];
switch (a_decoderId)
   case {105, 106, 107, 110, 111, 112, 113, 114, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('ECO3', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'FLUORESCENCE_CDOM'} ...
            {'CDOM'} ...
            ];
      end
end

if (~isempty(g_decArgo_addParamListCdom))
   paramList = [paramList g_decArgo_addParamListCdom];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

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
   case {105, 106, 107, 110, 111, 112, 113, 114, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, ...
         1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128}
      switch (a_paramName)

         case {'FLUORESCENCE_CDOM'}
            o_param = 'FLUORESCENCE_CDOM';
            o_paramSensor = 'FLUOROMETER_CDOM';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Uncalibrated fluorescence from coloured dissolved organic matter sensor';

         case {'CDOM'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing CDOM calibration information\n', ...
                  g_decArgo_floatNum);
               return
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
               fprintf('ERROR: Float #%d: inconsistent CDOM calibration information\n', ...
                  g_decArgo_floatNum);
               return
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
               o_preCalibComment = '';
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

switch (a_paramName)

   case {'FLUORESCENCE_CDOM_STD'}
      o_param = 'FLUORESCENCE_CDOM_STD';
      o_paramSensor = 'FLUOROMETER_CDOM';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'FLUORESCENCE_CDOM_MED'}
      o_param = 'FLUORESCENCE_CDOM_MED';
      o_paramSensor = 'FLUOROMETER_CDOM';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

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
   case {105, 106, 107, 109, 111, 112, 114, 115, ...
         121, 122, 123, 124, 125, 126, 128, 129, 130, 131}
      % check that a SUNA sensor is mounted on the float
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp(struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT), 'SUNA')))
         paramList = [ ...
            {'UV_INTENSITY_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE_STD'} ...
            {'NITRATE'} ...
            {'FIT_ERROR_NITRATE'} ...
            {'TEMP_NITRATE'} ...
            {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
            {'HUMIDITY_NITRATE'} ...
            ];
      end
   case {110, 113, 127}
      % check that a SUNA sensor is mounted on the float
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp(struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT), 'SUNA')))
         paramList = [ ...
            {'UV_INTENSITY_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE_STD'} ...
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

return

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
global g_decArgo_nitrate_e;
global g_decArgo_nitrate_opticalWavelengthOffset;


switch (a_decoderId)
   case {105, 106, 107, 109, 110, 111, 112, 113, 114, 115, ...
         121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131}
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

         case {'UV_INTENSITY_DARK_NITRATE_STD'}
            o_param = 'UV_INTENSITY_DARK_NITRATE_STD';
            o_paramSensor = 'SPECTROPHOTOMETER_NITRATE';
            o_paramUnits = 'count';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Standard deviation of intensity of ultra violet flux dark measurement from nitrate sensor';

         case {'NITRATE'}

            if (~ismember(a_decoderId, [110, 113, 127]))

               % get calibration information
               if (isempty(g_decArgo_calibInfo))
                  fprintf('ERROR: Float #%d: missing NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return
               elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'SunaVerticalOffset') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelBegin') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelEnd'))
                  tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
                  tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
                  tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
                  tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
                  tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
                  sunaVerticalOffset = g_decArgo_calibInfo.SUNA.SunaVerticalOffset;
                  floatPixelBegin = g_decArgo_calibInfo.SUNA.FloatPixelBegin;
                  floatPixelEnd = g_decArgo_calibInfo.SUNA.FloatPixelEnd;
               else
                  fprintf('ERROR: Float #%d: inconsistent NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return
               end

               if (isempty(floatPixelBegin) || isempty(floatPixelEnd))
                  fprintf('WARNING: Float #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing\n', ...
                     g_decArgo_floatNum);
                  return
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

               o_preCalibEq = 'The sensor returns UV_INTENSITY_DARK_NITRATE and UV_INTENSITY_NITRATE(Ntrans), a subset of continuous pixels of UV_INTENSITY_NITRATE(N), N = 1 to 256. The Ntrans indices span the interval [PIXEL_START, PIXEL_END] subset of the original array (1 to 256). Thus Ntrans(i) refers to pixel N = (PIXEL_START+i-1). PIXEL_START and PIXEL_END are defined from calibration data so that the [PIXEL_START, PIXEL_END] interval is the smallest interval of pixels that correspond to the [217 nm, 250 nm] interval of wavelengths. Only a subset of the [PIXEL_START, PIXEL_END] interval is processed to compute nitrate concentration. This subset is defined as the [PIXEL_FIT_START, PIXEL_FIT_END] interval which is the smallest interval of pixels that correspond to the [217 nm, 240 nm] interval of wavelengths (thus PIXEL_FIT_START = PIXEL_START). In the following equations the data are computed for each pixel R = PIXEL_FIT_START to PIXEL_FIT_END; ABSORBANCE_SW(R)=-log10[(UV_INTENSITY_NITRATE(R)-UV_INTENSITY_DARK_NITRATE)/UV_INTENSITY_REF_NITRATE(R)]; DIFF_OPTICAL_WAVELENGTH(R)=OPTICAL_WAVELENGTH_UV(R)-OPTICAL_WAVELENGTH_OFFSET; Tcorr(R,T)=(A*DIFF_OPTICAL_WAVELENGTH(R)^4+B*DIFF_OPTICAL_WAVELENGTH(R)^3+C*DIFF_OPTICAL_WAVELENGTH(R)^2+D*DIFF_OPTICAL_WAVELENGTH(R)+E)*(T-TEMP_CAL_NITRATE); E_SWA_INSITU(R)=E_SWA_NITRATE(R)*exp(Tcorr(R,TEMP)); ABSORBANCE_COR_NITRATE(R)=ABSORBANCE_SW(R)-(E_SWA_INSITU(R)*PSAL)*[1-(0.026*PRES/1000)]; Perform a multilinear regression to get MOLAR_NITRATE with estimated ABSORBANCE_COR_NITRATE(R) with ABSORBANCE_COR_NITRATE(R)=BASELINE_INTERCEPT+BASELINE_SLOPE*OPTICAL_WAVELENGTH_UV(R)+MOLAR_NITRATE*E_NITRATE(R); NITRATE=MOLAR_NITRATE/rho, where rho is the potential density [kg/L] calculated from CTD data';

               % try to set o_preCalibCoef without restriction

               uvIntensityRefNitrateStr = sprintf('%.8f,', tabUvIntensityRefNitrate(floatPixelBegin:floatPixelEnd));
               opticalWavelengthUvStr = sprintf('%.2f,', tabOpticalWavelengthUv(floatPixelBegin:floatPixelEnd));
               eSwaNitrateStr = sprintf('%.8f,', tabESwaNitrate(floatPixelBegin:floatPixelEnd));
               eNitrateStr = sprintf('%.8f,', tabENitrate(floatPixelBegin:floatPixelEnd));
               o_preCalibCoef = [ ...
                  sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
                  floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
                  'UV_INTENSITY_REF_NITRATE(Ntrans)=[' uvIntensityRefNitrateStr(1:end-1) ']; ' ...
                  sprintf('A=%e, B=%e, C=%e, D=%e, E=%e, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
                  g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_e, g_decArgo_nitrate_opticalWavelengthOffset) ...
                  'OPTICAL_WAVELENGTH_UV(Ntrans)=[' opticalWavelengthUvStr(1:end-1) ']; ' ...
                  sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
                  'E_SWA_NITRATE(Ntrans)=[' eSwaNitrateStr(1:end-1) ']; ' ...
                  'E_NITRATE(Ntrans)=[' eNitrateStr(1:end-1) ']' ...
                  ];

               FORMAT_SIZE = 4096;
               if (length(o_preCalibCoef) > FORMAT_SIZE)

                  % even if these floats only measure NITRATE, their SUNA are
                  % configured to send 90 pixels => we should use the
                  % restrictions of "BISULFIDE floats" to be sure to generate a
                  % PREDEPLOYMENT_CALIB_COEFFICIENT of less than 4096 characters
                  uvIntensityRefNitrateStr = [];
                  opticalWavelengthUvStr = [];
                  eSwaNitrateStr = [];
                  eNitrateStr = [];
                  % for id = floatPixelBegin:floatPixelEnd % with floatPixelBegin:floatPixelEnd PREDEPLOYMENT_CALIB_COEFFICIENT exceeds 4096 characters
                  for id = pixelBegin:pixelEnd
                     if (tabUvIntensityRefNitrate(id) == 0)
                        uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%d,', tabUvIntensityRefNitrate(id))];
                     else
                        val = sprintf('%.3f', tabUvIntensityRefNitrate(id));
                        val2 = fliplr(val);
                        idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                        val2(1:idN-1) = [];
                        uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr ',' fliplr(val2)];
                     end

                     if (tabOpticalWavelengthUv(id) == 0)
                        opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%d,', tabOpticalWavelengthUv(id))];
                     else
                        val = sprintf('%.2f', tabOpticalWavelengthUv(id));
                        val2 = fliplr(val);
                        idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                        val2(1:idN-1) = [];
                        opticalWavelengthUvStr = [opticalWavelengthUvStr ',' fliplr(val2)];
                     end

                     if (tabESwaNitrate(id) == 0)
                        eSwaNitrateStr = [eSwaNitrateStr sprintf('%d,', tabESwaNitrate(id))];
                     else
                        val = sprintf('%.8f', tabESwaNitrate(id));
                        val2 = fliplr(val);
                        idN = find(val2 ~= '0', 1, 'first');
                        if (val2(idN) == '.')
                           idN = idN + 1;
                        end
                        val2(1:idN-1) = [];
                        val3 = fliplr(val2);
                        idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                        if (any(val3(1:idN) == '.'))
                           nd = length(val3(idN:end));
                           format = ['%.' num2str(nd-1) 'e'];
                           val4 = sprintf(format, str2double(val3));
                        else
                           val4 = val3;
                        end
                        eSwaNitrateStr = [eSwaNitrateStr ',' val4];
                     end

                     if (tabENitrate(id) == 0)
                        eNitrateStr = [eNitrateStr sprintf('%d,', tabENitrate(id))];
                     else
                        val = sprintf('%.8f', tabENitrate(id));
                        val2 = fliplr(val);
                        idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                        val2(1:idN-1) = [];
                        val3 = fliplr(val2);
                        idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                        if (any(val3(1:idN) == '.'))
                           nd = length(val3(idN:end));
                           format = ['%.' num2str(nd-1) 'e'];
                           val4 = sprintf(format, str2double(val3));
                        else
                           val4 = val3;
                        end
                        eNitrateStr = [eNitrateStr ',' val4];
                     end
                  end
                  o_preCalibCoef = [ ...
                     sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
                     floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
                     'UV_INTENSITY_REF_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' uvIntensityRefNitrateStr(2:end) ']; ' ...
                     sprintf('A=%e, B=%e, C=%e, D=%e, E=%e, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
                     g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_e, g_decArgo_nitrate_opticalWavelengthOffset) ...
                     'OPTICAL_WAVELENGTH_UV(PIXEL_FIT_START:PIXEL_FIT_END)=[' opticalWavelengthUvStr(2:end) ']; ' ...
                     sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
                     'E_SWA_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eSwaNitrateStr(2:end) ']; ' ...
                     'E_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eNitrateStr(2:end) ']' ...
                     ];
               end

               o_preCalibComment = 'Nitrate concentration in umol/kg; see Processing Bio-Argo nitrate concentration at the DAC Level, Version 1.1, March 3rd 2018';
            else

               % get calibration information
               if (isempty(g_decArgo_calibInfo))
                  fprintf('ERROR: Float #%d: missing NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return
               elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabEBisulfide') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'SunaVerticalOffset') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelBegin') && ...
                     isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelEnd'))
                  tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
                  tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
                  tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
                  tabEBisulfide = g_decArgo_calibInfo.SUNA.TabEBisulfide;
                  tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
                  tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
                  sunaVerticalOffset = g_decArgo_calibInfo.SUNA.SunaVerticalOffset;
                  floatPixelBegin = g_decArgo_calibInfo.SUNA.FloatPixelBegin;
                  floatPixelEnd = g_decArgo_calibInfo.SUNA.FloatPixelEnd;
               else
                  fprintf('ERROR: Float #%d: inconsistent NITRATE calibration information\n', ...
                     g_decArgo_floatNum);
                  return
               end

               if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
                  fprintf('WARNING: Float #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing\n', ...
                     g_decArgo_floatNum);
                  return
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

               o_preCalibEq = 'The sensor returns UV_INTENSITY_DARK_NITRATE and UV_INTENSITY_NITRATE(Ntrans), a subset of continuous pixels of UV_INTENSITY_NITRATE(N), N = 1 to 256. The Ntrans indices span the interval [PIXEL_START, PIXEL_END] subset of the original array (1 to 256). Thus Ntrans(i) refers to pixel N = (PIXEL_START+i-1). PIXEL_START and PIXEL_END are defined from calibration data so that the [PIXEL_START, PIXEL_END] interval is the smallest interval of pixels that correspond to the [217 nm, 250 nm] interval of wavelengths. Only a subset of the [PIXEL_START, PIXEL_END] interval is processed to compute nitrate concentration. This subset is defined as the [PIXEL_FIT_START, PIXEL_FIT_END] interval which is the smallest interval of pixels that correspond to the [217 nm, 240 nm] interval of wavelengths (thus PIXEL_FIT_START = PIXEL_START). In the following equations the data are computed for each pixel R = PIXEL_FIT_START to PIXEL_FIT_END; ABSORBANCE_SW(R)=-log10[(UV_INTENSITY_NITRATE(R)-UV_INTENSITY_DARK_NITRATE)/UV_INTENSITY_REF_NITRATE(R)]; DIFF_OPTICAL_WAVELENGTH(R)=OPTICAL_WAVELENGTH_UV(R)-OPTICAL_WAVELENGTH_OFFSET; Tcorr(R,T)=(A*DIFF_OPTICAL_WAVELENGTH(R)^4+B*DIFF_OPTICAL_WAVELENGTH(R)^3+C*DIFF_OPTICAL_WAVELENGTH(R)^2+D*DIFF_OPTICAL_WAVELENGTH(R)+E)*(T-TEMP_CAL_NITRATE); E_SWA_INSITU(R)=E_SWA_NITRATE(R)*exp(Tcorr(R,TEMP)); ABSORBANCE_COR_NITRATE(R)=ABSORBANCE_SW(R)-(E_SWA_INSITU(R)*PSAL)*[1-(0.026*PRES/1000)]; Perform a multilinear regression to get MOLAR_NITRATE with estimated ABSORBANCE_COR_NITRATE(R) with ABSORBANCE_COR_NITRATE(R)=BASELINE_INTERCEPT+BASELINE_SLOPE*OPTICAL_WAVELENGTH_UV(R)+MOLAR_NITRATE*E_NITRATE(R); NITRATE=MOLAR_NITRATE/rho, where rho is the potential density [kg/L] calculated from CTD data';

               % for NITRATE&BISULFIDE we have more pixel and we must squeeze
               % their output as possible
               uvIntensityRefNitrateStr = [];
               opticalWavelengthUvStr = [];
               eSwaNitrateStr = [];
               eNitrateStr = [];
               eBisulfideStr = [];

               for id = pixelBegin:pixelEnd
                  if (tabUvIntensityRefNitrate(id) == 0)
                     uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%d,', tabUvIntensityRefNitrate(id))];
                  else
                     val = sprintf('%.3f', tabUvIntensityRefNitrate(id));
                     val2 = fliplr(val);
                     idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                     val2(1:idN-1) = [];
                     uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr ',' fliplr(val2)];
                  end

                  if (tabOpticalWavelengthUv(id) == 0)
                     opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%d,', tabOpticalWavelengthUv(id))];
                  else
                     val = sprintf('%.2f', tabOpticalWavelengthUv(id));
                     val2 = fliplr(val);
                     idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                     val2(1:idN-1) = [];
                     opticalWavelengthUvStr = [opticalWavelengthUvStr ',' fliplr(val2)];
                  end

                  if (tabESwaNitrate(id) == 0)
                     eSwaNitrateStr = [eSwaNitrateStr sprintf('%d,', tabESwaNitrate(id))];
                  else
                     val = sprintf('%.8f', tabESwaNitrate(id));
                     val2 = fliplr(val);
                     idN = find(val2 ~= '0', 1, 'first');
                     if (val2(idN) == '.')
                        idN = idN + 1;
                     end
                     val2(1:idN-1) = [];
                     val3 = fliplr(val2);
                     idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                     if (any(val3(1:idN) == '.'))
                        nd = length(val3(idN:end));
                        format = ['%.' num2str(nd-1) 'e'];
                        val4 = sprintf(format, str2double(val3));
                     else
                        val4 = val3;
                     end
                     eSwaNitrateStr = [eSwaNitrateStr ',' val4];
                  end

                  if (tabENitrate(id) == 0)
                     eNitrateStr = [eNitrateStr sprintf('%d,', tabENitrate(id))];
                  else
                     val = sprintf('%.8f', tabENitrate(id));
                     val2 = fliplr(val);
                     idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                     val2(1:idN-1) = [];
                     val3 = fliplr(val2);
                     idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                     if (any(val3(1:idN) == '.'))
                        nd = length(val3(idN:end));
                        format = ['%.' num2str(nd-1) 'e'];
                        val4 = sprintf(format, str2double(val3));
                     else
                        val4 = val3;
                     end
                     eNitrateStr = [eNitrateStr ',' val4];
                  end

                  if (tabEBisulfide(id) == 0)
                     eBisulfideStr = [eBisulfideStr sprintf('%d,', tabEBisulfide(id))];
                  else
                     val = sprintf('%.8f', tabEBisulfide(id));
                     val2 = fliplr(val);
                     idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                     val2(1:idN-1) = [];
                     val3 = fliplr(val2);
                     idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                     if (any(val3(1:idN) == '.'))
                        nd = length(val3(idN:end));
                        format = ['%.' num2str(nd-1) 'e'];
                        val4 = sprintf(format, str2double(val3));
                     else
                        val4 = val3;
                     end
                     eBisulfideStr = [eBisulfideStr ',' val4];
                  end
               end

               o_preCalibCoef = [ ...
                  sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
                  floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
                  'UV_INTENSITY_REF_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' uvIntensityRefNitrateStr(2:end) ']; ' ...
                  sprintf('A=%e, B=%e, C=%e, D=%e, E=%e, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
                  g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_e, g_decArgo_nitrate_opticalWavelengthOffset) ...
                  'OPTICAL_WAVELENGTH_UV(PIXEL_FIT_START:PIXEL_FIT_END)=[' opticalWavelengthUvStr(2:end) ']; ' ...
                  sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
                  'E_SWA_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eSwaNitrateStr(2:end) ']; ' ...
                  'E_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eNitrateStr(2:end) ']' ...
                  'E_BISULFIDE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eBisulfideStr(2:end) ']' ...
                  ];

               o_preCalibComment = 'Nitrate concentration in umol/kg; see Processing Bio-Argo nitrate concentration at the DAC Level, Version 1.1, March 3rd 2018';
            end

         case {'BISULFIDE'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('ERROR: Float #%d: missing NITRATE calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabOpticalWavelengthUv') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabENitrate') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabESwaNitrate') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabEBisulfide') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TabUvIntensityRefNitrate') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'TEMP_CAL_NITRATE') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'SunaVerticalOffset') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelBegin') && ...
                  isfield(g_decArgo_calibInfo.SUNA, 'FloatPixelEnd'))
               tabOpticalWavelengthUv = g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv;
               tabENitrate = g_decArgo_calibInfo.SUNA.TabENitrate;
               tabESwaNitrate = g_decArgo_calibInfo.SUNA.TabESwaNitrate;
               tabEBisulfide = g_decArgo_calibInfo.SUNA.TabEBisulfide;
               tabUvIntensityRefNitrate = g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate;
               tempCalNitrate = g_decArgo_calibInfo.SUNA.TEMP_CAL_NITRATE;
               sunaVerticalOffset = g_decArgo_calibInfo.SUNA.SunaVerticalOffset;
               floatPixelBegin = g_decArgo_calibInfo.SUNA.FloatPixelBegin;
               floatPixelEnd = g_decArgo_calibInfo.SUNA.FloatPixelEnd;
            else
               fprintf('ERROR: Float #%d: inconsistent NITRATE calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            if (isempty(floatPixelBegin) || isempty(floatPixelBegin))
               fprintf('WARNING: Float #%d: SUNA information (PIXEL_BEGIN, PIXEL_END) are missing\n', ...
                  g_decArgo_floatNum);
               return
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

            o_preCalibEq = 'The sensor returns UV_INTENSITY_DARK_NITRATE and UV_INTENSITY_NITRATE(Ntrans), a subset of continuous pixels of UV_INTENSITY_NITRATE(N), N = 1 to 256. The Ntrans indices span the interval [PIXEL_START, PIXEL_END] subset of the original array (1 to 256). Thus Ntrans(i) refers to pixel N = (PIXEL_START+i-1). PIXEL_START and PIXEL_END are defined from calibration data so that the [PIXEL_START, PIXEL_END] interval is the smallest interval of pixels that correspond to the [217 nm, 250 nm] interval of wavelengths. Only a subset of the [PIXEL_START, PIXEL_END] interval is processed to compute nitrate concentration. This subset is defined as the [PIXEL_FIT_START, PIXEL_FIT_END] interval which is the smallest interval of pixels that correspond to the [217 nm, 240 nm] interval of wavelengths (thus PIXEL_FIT_START = PIXEL_START). In the following equations the data are computed for each pixel R = PIXEL_FIT_START to PIXEL_FIT_END; ABSORBANCE_SW(R)=-log10[(UV_INTENSITY_NITRATE(R)-UV_INTENSITY_DARK_NITRATE)/UV_INTENSITY_REF_NITRATE(R)]; DIFF_OPTICAL_WAVELENGTH(R)=OPTICAL_WAVELENGTH_UV(R)-OPTICAL_WAVELENGTH_OFFSET; Tcorr(R,T)=(A*DIFF_OPTICAL_WAVELENGTH(R)^4+B*DIFF_OPTICAL_WAVELENGTH(R)^3+C*DIFF_OPTICAL_WAVELENGTH(R)^2+D*DIFF_OPTICAL_WAVELENGTH(R)+E)*(T-TEMP_CAL_NITRATE); E_SWA_INSITU(R)=E_SWA_NITRATE(R)*exp(Tcorr(R,TEMP)); ABSORBANCE_COR_NITRATE(R)=ABSORBANCE_SW(R)-(E_SWA_INSITU(R)*PSAL)*[1-(0.026*PRES/1000)]; Perform a multilinear regression to get MOLAR_NITRATE with estimated ABSORBANCE_COR_NITRATE(R) with ABSORBANCE_COR_NITRATE(R)=BASELINE_INTERCEPT+BASELINE_SLOPE*OPTICAL_WAVELENGTH_UV(R)+MOLAR_NITRATE*E_NITRATE(R); NITRATE=MOLAR_NITRATE/rho, where rho is the potential density [kg/L] calculated from CTD data';

            % for NITRATE&BISULFIDE we have more pixel and we must squeeze
            % their output as possible

            uvIntensityRefNitrateStr = [];
            opticalWavelengthUvStr = [];
            eSwaNitrateStr = [];
            eNitrateStr = [];
            eBisulfideStr = [];

            for id = pixelBegin:pixelEnd
               if (tabUvIntensityRefNitrate(id) == 0)
                  uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr sprintf('%d,', tabUvIntensityRefNitrate(id))];
               else
                  val = sprintf('%.3f', tabUvIntensityRefNitrate(id));
                  val2 = fliplr(val);
                  idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                  val2(1:idN-1) = [];
                  uvIntensityRefNitrateStr = [uvIntensityRefNitrateStr ',' fliplr(val2)];
               end

               if (tabOpticalWavelengthUv(id) == 0)
                  opticalWavelengthUvStr = [opticalWavelengthUvStr sprintf('%d,', tabOpticalWavelengthUv(id))];
               else
                  val = sprintf('%.2f', tabOpticalWavelengthUv(id));
                  val2 = fliplr(val);
                  idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                  val2(1:idN-1) = [];
                  opticalWavelengthUvStr = [opticalWavelengthUvStr ',' fliplr(val2)];
               end

               if (tabESwaNitrate(id) == 0)
                  eSwaNitrateStr = [eSwaNitrateStr sprintf('%d,', tabESwaNitrate(id))];
               else
                  val = sprintf('%.8f', tabESwaNitrate(id));
                  val2 = fliplr(val);
                  idN = find(val2 ~= '0', 1, 'first');
                  if (val2(idN) == '.')
                     idN = idN + 1;
                  end
                  val2(1:idN-1) = [];
                  val3 = fliplr(val2);
                  idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                  if (any(val3(1:idN) == '.'))
                     nd = length(val3(idN:end));
                     format = ['%.' num2str(nd-1) 'e'];
                     val4 = sprintf(format, str2double(val3));
                  else
                     val4 = val3;
                  end
                  eSwaNitrateStr = [eSwaNitrateStr ',' val4];
               end

               if (tabENitrate(id) == 0)
                  eNitrateStr = [eNitrateStr sprintf('%d,', tabENitrate(id))];
               else
                  val = sprintf('%.8f', tabENitrate(id));
                  val2 = fliplr(val);
                  idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                  val2(1:idN-1) = [];
                  val3 = fliplr(val2);
                  idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                  if (any(val3(1:idN) == '.'))
                     nd = length(val3(idN:end));
                     format = ['%.' num2str(nd-1) 'e'];
                     val4 = sprintf(format, str2double(val3));
                  else
                     val4 = val3;
                  end
                  eNitrateStr = [eNitrateStr ',' val4];
               end

               if (tabEBisulfide(id) == 0)
                  eBisulfideStr = [eBisulfideStr sprintf('%d,', tabEBisulfide(id))];
               else
                  val = sprintf('%.8f', tabEBisulfide(id));
                  val2 = fliplr(val);
                  idN = find((val2 ~= '0') & (val2 ~= '.'), 1, 'first');
                  val2(1:idN-1) = [];
                  val3 = fliplr(val2);
                  idN = find((val3 ~= '0') & (val3 ~= '.') & (val3 ~= '-'), 1, 'first');
                  if (any(val3(1:idN) == '.'))
                     nd = length(val3(idN:end));
                     format = ['%.' num2str(nd-1) 'e'];
                     val4 = sprintf(format, str2double(val3));
                  else
                     val4 = val3;
                  end
                  eBisulfideStr = [eBisulfideStr ',' val4];
               end
            end

            o_preCalibCoef = [ ...
               sprintf('PIXEL_START=%d, PIXEL_END=%d, PIXEL_FIT_START=%d, PIXEL_FIT_END=%d; ', ...
               floatPixelBegin, floatPixelEnd, pixelBegin, pixelEnd) ...
               'UV_INTENSITY_REF_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' uvIntensityRefNitrateStr(2:end) ']; ' ...
               sprintf('A=%e, B=%e, C=%e, D=%e, E=%e, OPTICAL_WAVELENGTH_OFFSET=%.1f; ', ...
               g_decArgo_nitrate_a, g_decArgo_nitrate_b, g_decArgo_nitrate_c, g_decArgo_nitrate_d, g_decArgo_nitrate_e, g_decArgo_nitrate_opticalWavelengthOffset) ...
               'OPTICAL_WAVELENGTH_UV(PIXEL_FIT_START:PIXEL_FIT_END)=[' opticalWavelengthUvStr(2:end) ']; ' ...
               sprintf('TEMP_CAL_NITRATE=%g; ', tempCalNitrate) ...
               'E_SWA_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eSwaNitrateStr(2:end) ']; ' ...
               'E_NITRATE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eNitrateStr(2:end) ']' ...
               'E_BISULFIDE(PIXEL_FIT_START:PIXEL_FIT_END)=[' eBisulfideStr(2:end) ']' ...
               ];

            o_preCalibComment = 'Bisulfide concentration in umol/kg; see Processing Bio-Argo nitrate concentration at the DAC Level, Version 1.1, March 3rd 2018';

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

return

% ------------------------------------------------------------------------------
% Update parameter list for ph associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_ph(a_metaData, a_decoderId)
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
%   01/23/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_ph(a_metaData, a_decoderId)

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListPh;


paramList = [];
switch (a_decoderId)
   case {121, 122, 123, 124, 125}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('TRANSISTOR_PH', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'VRS_PH'} ...
            {'VK_PH'} ...
            {'IK_PH'} ...
            {'IB_PH'} ...
            {'PH_IN_SITU_FREE'} ...
            {'PH_IN_SITU_TOTAL'} ...
            ];
      end
   case {1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, ...
         111, 113, 114, 115, ...
         126, 127, 128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('TRANSISTOR_PH', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'VRS_PH'} ...
            {'PH_IN_SITU_FREE'} ...
            {'PH_IN_SITU_TOTAL'} ...
            ];
      end
end

if (~isempty(g_decArgo_addParamListPh))
   paramList = [paramList g_decArgo_addParamListPh];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

% ------------------------------------------------------------------------------
% Update meta-data for ph associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_ph(a_paramName, a_decoderId)
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
%   01/23/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_ph(a_paramName, a_decoderId)

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
   case {121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131}
      switch (a_paramName)

         case {'VRS_PH'}
            o_param = 'VRS_PH';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'volt';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Voltage difference between reference and source from pH sensor (in volt)';

         case {'VK_PH'}
            o_param = 'VK_PH';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'volt';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Counter electrode voltage of pH sensor (in volt)';

         case {'IK_PH'}
            o_param = 'IK_PH';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'nanoampere';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Counter electrode current of pH sensor (in nanoampere)';

         case {'IB_PH'}
            o_param = 'IB_PH';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'nanoampere';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Base current of pH sensor (in nanoampere)';

         case {'PH_IN_SITU_FREE'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: missing PH_IN_SITU_FREE calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif ((isfield(g_decArgo_calibInfo, 'TRANSISTOR_PH')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f1')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f3')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f4')))
               transPhK0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k0);
               transPhK2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k2);
               transPhF0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f0);
               transPhF1 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f1);
               transPhF2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f2);
               transPhF3 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f3);
               transPhF4 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f4);
               transPhF5 = [];
               transPhF6 = [];
               if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5'))
                  transPhF5 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f5);
                  if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6'))
                     transPhF6 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f6);
                  end
               end
            else
               fprintf('ERROR: Float #%d: inconsistent PH_IN_SITU_FREE calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PH_IN_SITU_FREE';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'dimensionless';
            o_paramAccuracy = '0.005';
            o_paramResolution = '0.0004';
            if (~isempty(transPhF5))
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4+f5*PRES^5+f6*PRES^6; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g, f5=%g, f6=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4, transPhF5, transPhF6);
            else
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4);
            end
            o_preCalibComment = '';

         case {'PH_IN_SITU_TOTAL'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: missing PH_IN_SITU_TOTAL calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif ((isfield(g_decArgo_calibInfo, 'TRANSISTOR_PH')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f1')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f3')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f4')))
               transPhK0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k0);
               transPhK2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k2);
               transPhF0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f0);
               transPhF1 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f1);
               transPhF2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f2);
               transPhF3 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f3);
               transPhF4 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f4);
               transPhF5 = [];
               transPhF6 = [];
               if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5'))
                  transPhF5 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f5);
                  if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6'))
                     transPhF6 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f6);
                  end
               end
            else
               fprintf('ERROR: Float #%d: inconsistent PH_IN_SITU_TOTAL calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PH_IN_SITU_TOTAL';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'dimensionless';
            o_paramAccuracy = '0.005';
            o_paramResolution = '0.0004';
            if (~isempty(transPhF5))
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4+f5*PRES^5+f6*PRES^6; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g, f5=%g, f6=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4, transPhF5, transPhF6);
            else
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4);
            end
            o_preCalibComment = '';
      end

   case {1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127, 1128, ...
         111, 113, 114, 115}

      switch (a_paramName)

         case {'VRS_PH'}
            o_param = 'VRS_PH';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'volt';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = 'Voltage difference between reference and source from pH sensor (in volt)';


         case {'PH_IN_SITU_FREE'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: missing PH_IN_SITU_FREE calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif ((isfield(g_decArgo_calibInfo, 'TRANSISTOR_PH')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f1')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f3')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f4')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6')))
               transPhK0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k0);
               transPhK2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k2);
               transPhF0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f0);
               transPhF1 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f1);
               transPhF2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f2);
               transPhF3 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f3);
               transPhF4 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f4);
               transPhF5 = [];
               transPhF6 = [];
               if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5'))
                  transPhF5 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f5);
                  if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6'))
                     transPhF6 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f6);
                  end
               end
            else
               fprintf('ERROR: Float #%d: inconsistent PH_IN_SITU_FREE calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PH_IN_SITU_FREE';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'dimensionless';
            o_paramAccuracy = '0.005';
            o_paramResolution = '0.0004';
            if (~isempty(transPhF5))
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4+f5*PRES^5+f6*PRES^6; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g, f5=%g, f6=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4, transPhF5, transPhF6);
            else
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4);
            end
            o_preCalibComment = '';

         case {'PH_IN_SITU_TOTAL'}

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: missing PH_IN_SITU_TOTAL calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif ((isfield(g_decArgo_calibInfo, 'TRANSISTOR_PH')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f0')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f1')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f2')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f3')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f4')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5')) && ...
                  (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6')))
               transPhK0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k0);
               transPhK2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k2);
               transPhF0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f0);
               transPhF1 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f1);
               transPhF2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f2);
               transPhF3 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f3);
               transPhF4 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f4);
               transPhF5 = [];
               transPhF6 = [];
               if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5'))
                  transPhF5 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f5);
                  if (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6'))
                     transPhF6 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f6);
                  end
               end
            else
               fprintf('ERROR: Float #%d: inconsistent PH_IN_SITU_TOTAL calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_param = 'PH_IN_SITU_TOTAL';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'dimensionless';
            o_paramAccuracy = '0.005';
            o_paramResolution = '0.0004';
            if (~isempty(transPhF5))
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4+f5*PRES^5+f6*PRES^6; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g, f5=%g, f6=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4, transPhF5, transPhF6);
            else
               o_preCalibEq = 'k0T=k0+k2*TEMP; pcorr=f1*PRES+f2*PRES^2+f3*PRES^3+f4*PRES^4; k0TP=k0T+pcorr; Tk=273.15+TEMP; Cltotal=(0.99889/35.453*PSAL/1.80655)/(1-0.001005*PSAL); ADH=3.4286e-6*TEMP^2+6.7524e-4*TEMP+0.49172143; IonS=19.924*PSAL/(1000-1.005*PSAL); log10gammaHCl=[-ADH*sqrt(IonS)/(1+1.394*sqrt(IonS))]+[(0.08885-0.000111*TEMP)*IonS]; deltaVHCl=17.85+0.1044*TEMP-0.001316*TEMP^2; log10gammaHCLtP=log10gammaHCl+[deltaVHCl*(PRES/10)/(R*Tk*ln(10))/2/10]; PH_IN_SITU_FREE=[(VRS_PH-k0TP)/(R*Tk/F*ln(10))]+[ln(Cltotal)/ln(10)]+2*log10gammaHCLtP-log10(1-0.001005*PSAL)';
               o_preCalibCoef = sprintf('R=8.31446; F=96485; k0=%g, k2=%g; f1=%g, f2=%g, f3=%g, f4=%g', ...
                  transPhK0, transPhK2, ...
                  transPhF1, transPhF2, transPhF3, transPhF4);
            end
            o_preCalibComment = '';

         case {'NB_SAMPLE_SFET'}
            o_param = 'NB_SAMPLE_SFET';
            o_paramSensor = 'TRANSISTOR_PH';
            o_paramUnits = 'dimensionless';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'n/a';
            o_preCalibCoef = 'n/a';
            o_preCalibComment = '';

      end
end

switch (a_paramName)

   case {'VRS_PH_STD'}
      o_param = 'VRS_PH_STD';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'VRS_PH_MED'}
      o_param = 'VRS_PH_MED';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'VK_PH_STD'}
      o_param = 'VK_PH_STD';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'VK_PH_MED'}
      o_param = 'VK_PH_MED';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'IK_PH_STD'}
      o_param = 'IK_PH_STD';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'nanoampere';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'IK_PH_MED'}
      o_param = 'IK_PH_MED';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'nanoampere';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'IB_PH_STD'}
      o_param = 'IB_PH_STD';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'nanoampere';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'IB_PH_MED'}
      o_param = 'IB_PH_MED';
      o_paramSensor = 'TRANSISTOR_PH';
      o_paramUnits = 'nanoampere';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

% ------------------------------------------------------------------------------
% Update parameter list for cp associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_cp(a_metaData, a_decoderId)
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
%   01/10/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_cp(a_metaData, a_decoderId)

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts4;
global g_decArgo_decoderIdListNkeCts5Usea;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListCp;


paramList = [];
if (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts4))
   if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
         any(strcmp('CROVER', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
      paramList = [ ...
         {'CP660'} ...
         ];
   end
elseif (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts5Usea))
   if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
         any(strcmp('CROVER', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
      %       paramList = [ ...
      %          {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'} ...
      %          {'CP660'} ... % not processed yet
      %          ];
      paramList = [ ...
         {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'} ...
         ];
   end
end

if (~isempty(g_decArgo_addParamListCp))
   paramList = [paramList g_decArgo_addParamListCp];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

% ------------------------------------------------------------------------------
% Update meta-data for cp associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_cp(a_paramName, a_decoderId)
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
%   01/10/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_cp(a_paramName, a_decoderId)

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

   case {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'}
      o_param = 'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660';
      o_paramSensor = 'TRANSMISSOMETER_CP660';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'CP660'}
      o_param = 'CP660';
      o_paramSensor = 'TRANSMISSOMETER_CP660';
      o_paramUnits = 'm-1';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_STD'}
      o_param = 'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_STD';
      o_paramSensor = 'TRANSMISSOMETER_CP660';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_MED'}
      o_param = 'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_MED';
      o_paramSensor = 'TRANSMISSOMETER_CP660';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'CP660_STD'}
      o_param = 'CP660_STD';
      o_paramSensor = 'TRANSMISSOMETER_CP660';
      o_paramUnits = 'm-1';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'CP660_MED'}
      o_param = 'CP660_MED';
      o_paramSensor = 'TRANSMISSOMETER_CP660';
      o_paramUnits = 'm-1';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

% ------------------------------------------------------------------------------
% Update parameter list for turbidity associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_turbidity(a_metaData, a_decoderId)
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
%   01/10/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_turbidity(a_metaData, a_decoderId)

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts4;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListTurbidity;


paramList = [];
if (ismember(a_decoderId, g_decArgo_decoderIdListNkeCts4))
   if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
         any(strcmp('FLNTU', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
      paramList = [ ...
         {'SIDE_SCATTERING_TURBIDITY'} ...
         {'TURBIDITY'} ...
         ];
   end
elseif (ismember(a_decoderId, [302 303]))
   if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
         any(strcmp('FLNTU', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
      paramList = [ ...
         {'SIDE_SCATTERING_TURBIDITY'} ...
         {'TURBIDITY'} ...
         ];
   end
   if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
         any(strcmp('SEAPOINT', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
      paramList = [ ...
         {'VOLTAGE_TURBIDITY'} ...
         {'TURBIDITY2'} ...
         ];
   end
elseif (ismember(a_decoderId, [1014]))
   paramList = [ ...
      {'SIDE_SCATTERING_TURBIDITY'} ...
      {'TURBIDITY'} ...
      ];
end

if (~isempty(g_decArgo_addParamListTurbidity))
   paramList = [paramList g_decArgo_addParamListTurbidity];
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

% ------------------------------------------------------------------------------
% Update meta-data for turbidity associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_turbidity(a_paramName, a_decoderId)
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
%   01/10/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_turbidity(a_paramName, a_decoderId)

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

   case {'SIDE_SCATTERING_TURBIDITY'}
      o_param = 'SIDE_SCATTERING_TURBIDITY';
      o_paramSensor = 'BACKSCATTERINGMETER_TURBIDITY';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TURBIDITY'}
      o_param = 'TURBIDITY';
      o_paramSensor = 'BACKSCATTERINGMETER_TURBIDITY';
      o_paramUnits = 'ntu';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'VOLTAGE_TURBIDITY'}
      o_param = 'VOLTAGE_TURBIDITY';
      o_paramSensor = 'AUX_BACKSCATTERINGMETER_TURBIDITY2';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'TURBIDITY2'}
      o_param = 'TURBIDITY2';
      o_paramSensor = 'AUX_BACKSCATTERINGMETER_TURBIDITY2';
      o_paramUnits = 'ntu';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'SIDE_SCATTERING_TURBIDITY_STD'}
      o_param = 'SIDE_SCATTERING_TURBIDITY_STD';
      o_paramSensor = 'BACKSCATTERINGMETER_TURBIDITY';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'SIDE_SCATTERING_TURBIDITY_MED'}
      o_param = 'SIDE_SCATTERING_TURBIDITY_MED';
      o_paramSensor = 'BACKSCATTERINGMETER_TURBIDITY';
      o_paramUnits = 'count';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'VOLTAGE_TURBIDITY_STD'}
      o_param = 'VOLTAGE_TURBIDITY_STD';
      o_paramSensor = 'AUX_BACKSCATTERINGMETER_TURBIDITY2';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

   case {'VOLTAGE_TURBIDITY_MED'}
      o_param = 'VOLTAGE_TURBIDITY_MED';
      o_paramSensor = 'AUX_BACKSCATTERINGMETER_TURBIDITY2';
      o_paramUnits = 'volt';
      o_paramAccuracy = '';
      o_paramResolution = '';
      o_preCalibEq = 'n/a';
      o_preCalibCoef = 'n/a';
      o_preCalibComment = '';

end

return

% ------------------------------------------------------------------------------
% Update parameter list for rafos associated parameters.
%
% SYNTAX :
%  [o_metaData] = update_parameter_list_rafos(a_metaData, a_decoderId)
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
%   03/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = update_parameter_list_rafos(a_metaData, a_decoderId)

paramList = [];
switch (a_decoderId)
   case {1125, 1128}
      if (isfield(a_metaData, 'SENSOR_MOUNTED_ON_FLOAT') && ...
            any(strcmp('AUX_ACOUSTIC_GEOLOCATION', struct2cell(a_metaData.SENSOR_MOUNTED_ON_FLOAT))))
         paramList = [ ...
            {'COR'} ...
            {'RAW_TOA'} ...
            {'TOA'} ...
            {'RAFOS_RTC_TIME'} ...
            ];
      end
end

% add parameter associated fields
o_metaData = generate_parameter_fields(a_metaData, paramList);

return

% ------------------------------------------------------------------------------
% Update meta-data for rafos associated parameters.
%
% SYNTAX :
%  [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
%    o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_rafos(a_paramName, a_decoderId)
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
%   03/24/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_param, o_paramSensor, o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_preCalibEq, o_preCalibCoef, o_preCalibComment] = get_meta_data_rafos(a_paramName, a_decoderId)

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
   case {1125, 1128}
      switch (a_paramName)

         case {'COR'}
            o_param = 'COR';
            o_paramSensor = 'AUX_ACOUSTIC_GEOLOCATION';
            o_paramUnits = '';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = '';

         case {'RAW_TOA'}
            o_param = 'RAW_TOA';
            o_paramSensor = 'AUX_ACOUSTIC_GEOLOCATION';
            o_paramUnits = '';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = '';

         case {'TOA'}
            o_param = 'TOA';
            o_paramSensor = 'AUX_ACOUSTIC_GEOLOCATION';
            o_paramUnits = '';
            o_paramAccuracy = '';
            o_paramResolution = '';

            % get calibration information
            if (isempty(g_decArgo_calibInfo))
               fprintf('WARNING: Float #%d: missing TOA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            elseif ((isfield(g_decArgo_calibInfo, 'RAFOS')) && ...
                  (isfield(g_decArgo_calibInfo.RAFOS, 'SlopeRafosTOA')) && ...
                  (isfield(g_decArgo_calibInfo.RAFOS, 'OffsetRafosTOA')))
               slopeRafosTOA = double(g_decArgo_calibInfo.RAFOS.SlopeRafosTOA);
               offsetRafosTOA = double(g_decArgo_calibInfo.RAFOS.OffsetRafosTOA);
            else
               fprintf('ERROR: Float #%d: inconsistent TOA calibration information\n', ...
                  g_decArgo_floatNum);
               return
            end

            o_preCalibEq = 'TOA = RAW_TOA*SlopeRafosTOA + OffsetRafosTOA';
            o_preCalibCoef = sprintf('SlopeRafosTOA=%.4f; OffsetRafosTOA=%d', ...
               slopeRafosTOA, offsetRafosTOA);
            o_preCalibComment = '';

         case {'RAFOS_RTC_TIME'}
            o_param = 'RAFOS_RTC_TIME';
            o_paramSensor = 'AUX_RAFOS_CLOCK';
            o_paramUnits = '';
            o_paramAccuracy = '';
            o_paramResolution = '';
            o_preCalibEq = 'none';
            o_preCalibCoef = 'none';
            o_preCalibComment = '';
      end
end

return

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

   for idP = 1:length(a_paramList)
      idF = find(strcmp(a_paramList{idP}, struct2cell(o_metaData.PARAMETER)) == 1, 1);
      if (isempty(idF))
         fprintf('INFO: Float #%d: adding ''%s'' to float parameter list\n', ...
            g_decArgo_floatNum, a_paramList{idP});

         nbParam = length(struct2cell(o_metaData.PARAMETER)) + 1;
         o_metaData.PARAMETER.(['PARAMETER_' num2str(nbParam)]) = a_paramList{idP};
         for id = 1:length(fieldList)
            o_metaData.(fieldList{id}).([fieldList{id} '_' num2str(nbParam)]) = '';
         end
      end
   end
end

return
