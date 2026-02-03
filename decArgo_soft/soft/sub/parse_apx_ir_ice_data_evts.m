% ------------------------------------------------------------------------------
% Parse Apex Iridium ICE data from .log file.
%
% SYNTAX :
%  [o_iceDetection, o_techData] = parse_apx_ir_ice_data_evts(a_events, a_techData)
%
% INPUT PARAMETERS :
%   a_events   : input log file event data
%   a_techData : input TECH data
%   a_miscInfo : input misc information
%
% OUTPUT PARAMETERS :
%   o_iceDetection : ice detection data
%   o_techData     : updated TECH data
%   o_miscInfo     : output misc information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/31/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceDetection, o_techData, o_miscInfo] = parse_apx_ir_ice_data_evts(a_events, a_techData, a_miscInfo)

% output parameters initialization
o_iceDetection = [];
o_techData = a_techData;
o_miscInfo = a_miscInfo;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PATTERN_UNUSED = [ ...
   {'Profile cycle truncated. Surface pressure reset to'} ...
   {'Deactivation CP mode failed.'} ...
   ];

PATTERN_ML_SAMPLE = 'Mixed layer sample';
PATTERN_DETECTION_TRUE = 'Ice detection algorithm terminated true';
PATTERN_EVASION_TRUE = 'Ice evasion algorithm initiated.';
PATTERN_EVASION_PERIGEE = 'Ascent perigee detected';
PATTERN_EVASION_PERIGEE_ABORT = 'Surface detected: Ascent-perigee detection aborted';

iceDetection = get_ice_detection_apx_ir_init_struct;
for idEv = 1:length(a_events)
   dataStr = a_events(idEv).info;
   %    fprintf('''%s''\n', dataStr);
   
   if (any(strfind(dataStr, PATTERN_ML_SAMPLE)))
      
      % parsing "Mixed layer sample 1: p=26.5dbar, t=0.005C"
      dataStr2 = strtrim(dataStr(length(PATTERN_ML_SAMPLE)+1:end));
      [val, count, errmsg, ~] = sscanf(dataStr2, '%d: p=%fdbar, t=%fC');
      if (isempty(errmsg) && (count == 3))
         mlSample = get_ice_sample_apx_ir_init_struct;
         mlSample.sampleTime = a_events(idEv).time;
         mlSample.sampleNum = val(1);
         mlSample.samplePres = val(2);
         mlSample.sampleTemp = val(3);
         iceDetection.mlSample = [iceDetection.mlSample; mlSample];
         iceDetection.notEmptyFlag = 1;

         dataStruct = get_apx_misc_data_init_struct('Ice(log)', [], [], []);
         dataStruct.label = 'Mixed layer sample';
         dataStruct.value = dataStr;
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing Ice information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
      end
      
   elseif (any(strfind(dataStr, PATTERN_DETECTION_TRUE)))
      
      % parsing "Ice detection algorithm terminated true at 14 decibars."
      dataStr2 = strtrim(dataStr(length(PATTERN_DETECTION_TRUE)+1:end));
      [val, count, errmsg, ~] = sscanf(dataStr2, 'at %f decibars.');
      if (isempty(errmsg) && (count == 1))
         iceDetection.isaTime = a_events(idEv).time;
         iceDetection.isaFlag = 1;
         iceDetection.isaPres = val(1);
         iceDetection.notEmptyFlag = 1;

         dataStruct = get_apx_misc_data_init_struct('Ice(log)', [], [], []);
         dataStruct.label = 'Ice detection true';
         dataStruct.value = dataStr;
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing Ice information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
      end

   elseif (any(strfind(dataStr, PATTERN_EVASION_TRUE)))
      
      % parsing "Ice evasion algorithm initiated.  P=14.4dbars, <MLT,N>=<0.01C,6>, t=605890sec, IER=0x01 PistonPosition:119"
      dataStr2 = strtrim(dataStr(length(PATTERN_EVASION_TRUE)+1:end));
      idF1 = strfind(dataStr2, 'IER=');
      idF2 = strfind(dataStr2, 'PistonPosition:');
      dataStr3 = strtrim(dataStr2(1:idF1-1));
      ierStr = strtrim(dataStr2(idF1+length('IER='):idF2-1));
      pistonStr = strtrim(dataStr2(idF2+length('PistonPosition:'):end));
      [val, count, errmsg, ~] = sscanf(dataStr3, 'P=%fdbars, <MLT,N>=<%fC,%d>, t=%dsec,');
      if (isempty(errmsg) && (count == 4))
         iceDetection.evasionTime = a_events(idEv).time;
         iceDetection.evasionPres = val(1);
         iceDetection.evasionMlt = val(2);
         iceDetection.evasionNbSamp = val(3);
         iceDetection.evasionSec = val(4);
         iceDetection.evasionIer = hex2dec(ierStr);
         iceDetection.evasionPiston = str2double(pistonStr);
         iceDetection.notEmptyFlag = 1;

         dataStruct = get_apx_misc_data_init_struct('Ice(log)', [], [], []);
         dataStruct.label = 'Ice evasion true';
         dataStruct.value = dataStr;
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing Ice information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
      end

   elseif (any(strfind(dataStr, PATTERN_EVASION_PERIGEE)))
      
      % parsing "Ascent perigee detected at 11.8dbars."
      dataStr2 = strtrim(dataStr(length(PATTERN_EVASION_PERIGEE)+1:end));
      [val, count, errmsg, ~] = sscanf(dataStr2, 'at %fdbars.');
      if (isempty(errmsg) && (count == 1))
         iceDetection.evasionPerigeeTime = a_events(idEv).time;
         iceDetection.evasionPerigeePres = val(1);
         iceDetection.notEmptyFlag = 1;

         dataStruct = get_apx_misc_data_init_struct('Ice(log)', [], [], []);
         dataStruct.label = 'Ascent perigee';
         dataStruct.value = dataStr;
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing Ice information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
      end

   elseif (any(strfind(dataStr, PATTERN_EVASION_PERIGEE_ABORT)))
      
      % parsing "Ascent perigee detected at 11.8dbars."
      dataStr2 = strtrim(dataStr(length(PATTERN_EVASION_PERIGEE_ABORT)+1:end));
      [val, count, errmsg, ~] = sscanf(dataStr2, 'at %fdbars.');
      if (isempty(errmsg) && (count == 1))
         iceDetection.evasionPerigeeTime = a_events(idEv).time;
         iceDetection.evasionPerigeePres = val(1);
         iceDetection.notEmptyFlag = 1;

         dataStruct = get_apx_misc_data_init_struct('Ice(log)', [], [], []);
         dataStruct.label = 'Ascent perigee';
         dataStruct.value = dataStr;
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing Ice information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
      end

   else
      idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
      if (isempty([idF{:}]))
         fprintf('DEC_INFO: %sAnomaly detected while parsing Ice information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
   end
end

% store TECH information and remove similar ones found from .masg file
% events (from .log file) are prefered because dated

techDataAll = [];
idDel = [];
if (~isempty(o_techData))
   techDataAll = [o_techData{:}];
end

if (iceDetection.isaTime ~= g_decArgo_dateDef)
   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice detection algorithm terminated true: flag';
   techData.techId = 1049;
   techData.value = num2str(1);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice detection algorithm terminated true: time';
   techData.techId = 1050;
   techData.value = datestr(iceDetection.isaTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice detection algorithm terminated true: pres';
   techData.techId = 1051;
   techData.value = num2str(iceDetection.isaPres);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   % remove similar TECH information found from .masg file
   if (~isempty(techDataAll))
      idF = find(ismember([techDataAll.techId], [1042, 1043]));
      idDel = [idDel idF];
   end
end

if (iceDetection.evasionTime ~= g_decArgo_dateDef)
   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice evasion algorithm initiated: flag';
   techData.techId = 1052;
   techData.value = num2str(1);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice evasion algorithm initiated: time';
   techData.techId = 1053;
   techData.value = datestr(iceDetection.evasionTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice evasion algorithm initiated: pres';
   techData.techId = 1054;
   techData.value = num2str(iceDetection.evasionPres);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice evasion algorithm initiated: MLT';
   techData.techId = 1055;
   techData.value = num2str(iceDetection.evasionMlt);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice evasion algorithm initiated: nb sample';
   techData.techId = 1056;
   techData.value = num2str(iceDetection.evasionNbSamp);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ice evasion algorithm initiated: IER';
   techData.techId = 1057;
   techData.value = dec2bin(iceDetection.evasionIer, 8);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   % remove similar TECH information found from .masg file
   if (~isempty(techDataAll))
      idF = find(ismember([techDataAll.techId], [1016, 1017, 1041, 1044, 1045]));
      idDel = [idDel idF];
   end
end

if (iceDetection.evasionPerigeeTime ~= g_decArgo_dateDef)
   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ascent perigee detected: time';
   techData.techId = 1058;
   techData.value = datestr(iceDetection.evasionPerigeeTime + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;

   techData = get_apx_tech_data_init_struct(1);
   techData.label = 'Ascent perigee detected: pres';
   techData.techId = 1059;
   techData.value = num2str(iceDetection.evasionPerigeePres);
   techData.cyNum = g_decArgo_cycleNum;
   o_techData{end+1} = techData;
   techData.techId = 1060;
   o_techData{end+1} = techData;

   % remove similar TECH information found from .masg file
   if (~isempty(techDataAll))
      idF = find(ismember([techDataAll.techId], [1046]));
      idDel = [idDel idF];
   end
end

o_techData(idDel) = [];

% store ICE information from .masg file for TRAJ (if not in .log file)
if (~isempty(o_techData))
   techDataAll = [o_techData{:}];
   idF = find([techDataAll.techId] == 1041); % if present means that it has not been previously removed thus ICE information not in .log file
   if (~isempty(idF))
      % IceMLMedianT
      if (str2double(o_techData{idF(1)}.value) < realmax("single"))
         iceDetection.evasionMlt = str2double(o_techData{idF(1)}.value);
         iceDetection.notEmptyFlag = 1;
      end
   end
   idF = find([techDataAll.techId] == 1046);
   if (~isempty(idF))
      % Ice evasion initiated at P
      iceDetection.evasionPerigeePres = str2double(o_techData{idF(1)}.value);
      iceDetection.notEmptyFlag = 1;
   end

   % add ICE information present only in .msg file
   if (any([techDataAll.techId] == 1047))
      % sat_mask detected
      iceDetection.satmaskFlag = 1;
      iceDetection.notEmptyFlag = 1;
   end
   if (any([techDataAll.techId] == 1048))
      % sat_mask detected
      iceDetection.breakupFlag = 1;
      iceDetection.notEmptyFlag = 1;
   end
end

o_iceDetection = iceDetection;

return

% ------------------------------------------------------------------------------
% Get the basic structure to store APEX Ice sample information.
%
% SYNTAX :
%  [o_iceSample] = get_ice_sample_apx_ir_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_iceSample : APEX Ice sample structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceSample] = get_ice_sample_apx_ir_init_struct

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;

o_iceSample = struct( ...
   'sampleTime', g_decArgo_dateDef, ...
   'sampleTimeAdj', g_decArgo_dateDef, ...
   'sampleNum', '', ...
   'samplePres', g_decArgo_presDef, ...
   'samplePresAdj', g_decArgo_presDef, ...
   'sampleTemp', '' ...
   );

return
