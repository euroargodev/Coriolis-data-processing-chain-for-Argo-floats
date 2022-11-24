% ------------------------------------------------------------------------------
% Decode msg file from one cycle of APEX Iridium Rudics data.
%
% SYNTAX :
%  [o_miscInfo, o_configInfo, o_techInfo, o_techData, ...
%    o_pMarkData, o_driftData, o_parkData, o_parkDataEng, ...
%    o_profLrData, o_profHrData, o_profEndDate, ...
%    o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfData, ...
%    o_gpsData, o_gpsInfo, ...
%    o_presOffsetData] = ...
%    decode_msg_apx_ir_rudics(a_msgFileList, a_presOffsetData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_msgFileList    : msg file name
%   a_presOffsetData : input pressure offset information
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo                : misc information
%   o_configInfo              : configuration information
%   o_techInfo                : TECH information
%   o_techData                : TECH data
%   o_pMarkDataMsg            : P marks
%   o_driftData               : drift data
%   o_parkData                : park data
%   o_parkDataEng             : park data from engineering data
%   o_profLrData              : profile LR data
%   o_profHrData              : profile HR data
%   o_profEndDate             : profile end date
%   o_nearSurfData            : NS data
%   o_surfDataBladderDeflated : surface data (bladder deflated)
%   o_surfDataBladderInflated : surface data (bladder inflated)
%   o_surfData                : surface data from engineering data
%   o_gpsData                 : GPS data
%   o_gpsInfo                 : GPS information
%   o_presOffsetData          : updated pressure offset information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_configInfo, o_techInfo, o_techData, ...
   o_pMarkData, o_driftData, o_parkData, o_parkDataEng, ...
   o_profLrData, o_profHrData, o_profEndDate, ...
   o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated, o_surfData, ...
   o_gpsData, o_gpsInfo, ...
   o_presOffsetData] = ...
   decode_msg_apx_ir_rudics(a_msgFileList, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_configInfo = [];
o_techInfo = [];
o_techData = [];
o_pMarkData = [];
o_driftData = [];
o_parkData = [];
o_parkDataEng = [];
o_profLrData = [];
o_profHrData = [];
o_profEndDate = [];
o_nearSurfData = [];
o_surfDataBladderDeflated = [];
o_surfDataBladderInflated = [];
o_surfData = [];
o_gpsData = [];
o_gpsInfo = [];
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_msgFileList))
   return;
end

if (length(a_msgFileList) > 1)
   fprintf('DEC_WARNING: Float #%d Cycle #%d: multiple (%d) msg file for this cycle => only the first one is considered (except for GPS fixes which are retrieved from all files)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_msgFileList));
end

for idFile = 1:length(a_msgFileList)
   
   msgFilePathName = a_msgFileList{1};
   
   % read input file
   [error, ...
      configDataStr, ...
      driftMeasDataStr, ...
      profInfoDataStr, ...
      profLowResMeasDataStr, ...
      profHighResMeasDataStr, ...
      gpsFixDataStr, ...
      engineeringDataStr, ...
      nearSurfaceDataStr ...
      ] = read_apx_ir_rudics_msg_file(msgFilePathName);
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, msgFilePathName);
      return;
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(configDataStr))
         configData = parse_apx_ir_rudics_config_data(configDataStr);
         
         fields = fieldnames(configData);
         for idConf = 1:2:length(fields)
            dataStruct = get_apx_misc_data_init_struct('Config', [], [], []);
            dataStruct.label = fields{idConf};
            dataStruct.value = configData.(fields{idConf});
            dataStruct.format = '%s';
            dataStruct.unit = configData.(fields{idConf+1});
            o_configInfo{end+1} = dataStruct;
         end
      end
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(driftMeasDataStr))
         o_driftData = parse_apx_ir_rudics_drift_data(driftMeasDataStr, a_decoderId);
      end
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(profInfoDataStr))
         profInfo = parse_apx_ir_rudics_profile_info(profInfoDataStr);
         
         if (isfield(profInfo, 'CyNum'))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Profile number';
            dataStruct.value = profInfo.CyNum;
            dataStruct.format = '%s';
            o_miscInfo{end+1} = dataStruct;
         end
         if (isfield(profInfo, 'ProfTime'))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Profile terminated date';
            dataStruct.value = julian_2_gregorian_dec_argo(profInfo.ProfTime);
            dataStruct.format = '%s';
            o_miscInfo{end+1} = dataStruct;
            o_profEndDate = profInfo.ProfTime;
         end
      end
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(profLowResMeasDataStr))
         [o_parkData, o_profLrData, expectedProfLrNbSamples] = parse_apx_ir_rudics_LR_profile_data(profLowResMeasDataStr, a_decoderId);
         
         if (~isempty(expectedProfLrNbSamples))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Expected number of profile LR samples';
            dataStruct.value = expectedProfLrNbSamples;
            dataStruct.format = '%d';
            o_miscInfo{end+1} = dataStruct;
         end
      end
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(profHighResMeasDataStr))
         [o_profHrData, profHrInfo] = decode_apx_ir_rudics_HR_profile_data(profHighResMeasDataStr, a_decoderId);
         
         if (isfield(profHrInfo, 'ProfTime'))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Profile HR terminated date';
            dataStruct.value = julian_2_gregorian_dec_argo(profHrInfo.ProfTime);
            dataStruct.format = '%s';
            o_miscInfo{end+1} = dataStruct;
         end
         if (isfield(profHrInfo, 'Sbe41cpSN'))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Sbe41cp serial number';
            dataStruct.value = profHrInfo.Sbe41cpSN;
            dataStruct.format = '%d';
            o_miscInfo{end+1} = dataStruct;
         end
         if (isfield(profHrInfo, 'ProfNbSample'))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Profile HR nb sample';
            dataStruct.value = profHrInfo.ProfNbSample;
            dataStruct.format = '%d';
            o_miscInfo{end+1} = dataStruct;
         end
         if (isfield(profHrInfo, 'ProfNbBin'))
            dataStruct = get_apx_misc_data_init_struct('Profile', [], [], []);
            dataStruct.label = 'Profile HR nb bin';
            dataStruct.value = profHrInfo.ProfNbBin;
            dataStruct.format = '%d';
            o_miscInfo{end+1} = dataStruct;
         end
      end
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(nearSurfaceDataStr) && ~isempty(nearSurfaceDataStr{1}))
         [o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated] = ...
            parse_nvs_ir_rudics_near_surface_data(nearSurfaceDataStr, a_decoderId);
      end
   end
   
   if (~isempty(gpsFixDataStr))
      [o_gpsData, o_gpsInfo, o_techData] = process_apx_ir_rudics_gps_data(gpsFixDataStr, o_techData, o_gpsData);
      
      if (~isempty(o_gpsInfo.FailedAcqTime))
         info = o_gpsInfo.FailedAcqTime;
         for id = 1:length(info)
            dataStruct = get_apx_misc_data_init_struct('Gps', [], [], []);
            dataStruct.label = 'Attempt to get GPS fix failed after';
            dataStruct.value = info{id};
            dataStruct.format = '%d';
            dataStruct.unit = 'second';
            o_miscInfo{end+1} = dataStruct;
         end
      end
      if (~isempty(o_gpsInfo.FailedIce))
         info = o_gpsInfo.FailedIce;
         for id = 1:length(info)
            dataStruct = get_apx_misc_data_init_struct('Gps', [], [], []);
            dataStruct.label = 'Ice evasion initiated at';
            dataStruct.value = info{id};
            dataStruct.format = '%f';
            dataStruct.unit = 'dbar';
            o_miscInfo{end+1} = dataStruct;
         end
      end
   end
   
   if (idFile == length(a_msgFileList))
      if (~isempty(engineeringDataStr))
         engData = parse_apx_ir_rudics_engineering_data(engineeringDataStr);
         
         for idEng = 1:length(engData)
            [techInfo, techData, pMarkData, parkData, surfData] = ...
               process_apx_ir_rudics_engineering_data(engData{idEng}, idEng, a_decoderId);
            o_techInfo = [o_techInfo techInfo];
            o_techData = [o_techData techData];
            o_pMarkData = [o_pMarkData pMarkData];
            o_parkDataEng = [o_parkDataEng parkData];
            o_surfData = [o_surfData surfData];
            
            % retrieve and store surface pressure measurement in the dedicated
            % structure
            if (~isempty(techInfo))
               infoList = [techInfo{:}];
               if (any(strcmp({infoList.label}, 'SurfacePressure')))
                  idF = find(strcmp({infoList.label}, 'SurfacePressure'));
                  if (~any([o_presOffsetData.cycleNum] == g_decArgo_cycleNum))
                     o_presOffsetData.cycleNum(end+1) = g_decArgo_cycleNum;
                     o_presOffsetData.cyclePresOffset(end+1) = str2double(techInfo{idF}.value);
                  end
               end
            end
         end
      end
   end
end

return;
