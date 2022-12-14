% ------------------------------------------------------------------------------
% Create calibration and RTOffset configuration structures from JSON meta-data
% information.
%
% SYNTAX :
%  [o_floatRudicsId, o_stopFlag] = init_float_config_apx_ir(a_decoderId)
%
% INPUT PARAMETERS :
%    a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatRudicsId : float Rudics Id
%   o_stopFlag      : stop flag (when meta.json file is not found)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatRudicsId, o_stopFlag] = init_float_config_apx_ir(a_decoderId)

% output parameters initialization
o_floatRudicsId = [];
o_stopFlag = 0;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% Argos (1), Iridium RUDICS (2), Iridium SBD (3) float
global g_decArgo_floatTransType;

% json meta-data
global g_decArgo_jsonMetaData;


if (g_decArgo_floatTransType == 3)
   
   % for Iridium SBD floats only
   if (isfield(g_decArgo_jsonMetaData, 'FLOAT_RUDICS_ID'))
      [o_floatRudicsId, status] = str2num(g_decArgo_jsonMetaData.FLOAT_RUDICS_ID);
      if (status == 0)
         fprintf('ERROR: FLOAT_RUDICS_ID is not correct in Json meta-data file\n');
         return
      end
   end
   if (isempty(o_floatRudicsId))
      fprintf('ERROR: FLOAT_RUDICS_ID is mandatory, it should be set in Json meta-data file\n');
      return
   end
end

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(g_decArgo_jsonMetaData);

% add DO calibration coefficients
if (ismember(a_decoderId, [1101, 1104, 1105, 1107, 1110, 1111, 1112, 1113, 1114, 1201]))
   
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
      
      case {1101}
         
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
                  return
               end
            end
            g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef = tabDoxyCoef;
         end
         
      case {1104, 1105, 1110, 1111, 1114}
         
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
            
            % as tempValues come from the CTD or from TEMP_DOXY, we don't use TempCoefI, so
            tabDoxyCoef(2, 1:6) = [0 1 0 0 0 0];

            for id = 0:5
               fieldName = ['TempCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(2, id+1) = calibData.(fieldName);
                  %                else
                  %                   fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  %                   return
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
            if (a_decoderId == 1114)
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
         end         
         
      case {1107, 1112, 1113}
         
         if (isfield(g_decArgo_calibInfo, 'OPTODE'))
            calibData = g_decArgo_calibInfo.OPTODE;
            
            tabDoxyCoef = [];
            
            tabDoxyCoef(1, 1:4) = [0 1 0 0];

            for id = 0:3
               fieldName = ['PhaseCoef' num2str(id)];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef(1, id+1) = calibData.(fieldName);
                  %                else
                  %                   fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  %                   return
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
         
      case {1201}
         
         if (isfield(g_decArgo_calibInfo, 'OPTODE'))
            calibData = g_decArgo_calibInfo.OPTODE;
            
            % for Aanderaa 4330
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
            
            % for SBE 63
            tabDoxyCoef = [];
            coefNameList = [{'A0'} {'A1'} {'A2'} {'B0'} {'B1'} {'C0'} {'C1'} {'C2'} {'E'}];
            for id = 1:length(coefNameList)
               fieldName = ['SBEOptode' coefNameList{id}];
               if (isfield(calibData, fieldName))
                  tabDoxyCoef = [tabDoxyCoef calibData.(fieldName)];
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                  return
               end
            end
            g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef = tabDoxyCoef;
         end                 

   end
end

return
