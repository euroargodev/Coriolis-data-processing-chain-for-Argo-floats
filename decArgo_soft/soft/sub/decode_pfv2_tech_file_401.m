% ------------------------------------------------------------------------------
% Decode technical file.
%
% SYNTAX :
% [o_techData] = decode_pfv2_tech_file_401(a_fileName)
%
% INPUT PARAMETERS :
%   a_fileName : technical file name
%
% OUTPUT PARAMETERS :
%   o_techData : decoded TECH data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techData] = decode_pfv2_tech_file_401(a_fileName)

% output parameters initialization
o_techData = [];

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_archiveDataDirectory;

% mission, loop and cycle management
global g_decArgo_missionLoopCycle;

% default values
global g_decArgo_janFirst1950InMatlab;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% unique counter for techTime.groupId
global g_decArgo_tecTimeGroupCpt;

% management of meta-data transmitted in TECH files
global g_decArgo_metaFromTech

% global measurement codes
global g_MC_CycleStartBis;
global g_MC_DST;
global g_MC_FST;
global g_MC_MaxPresInDescToPark;
global g_MC_PST;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_MaxPresInDescToProf;
global g_MC_DPST;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_MedianValueInAscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_TST;
global g_MC_Surface;
global g_MC_Grounded;


% retrieve information from file name
missionNum = nan;
cycleNum = nan;
selfTestDate = nan;
if (any(strfind(a_fileName, '_selftest.hex')))
   fileType = 10;
   selfTestDate = datenum(a_fileName(1:14), 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
else
   [val, count, errmsg, ~] = sscanf(a_fileName, 'M%dC%dTEC%d.hex');
   if (isempty(errmsg) && (count == 3))
      missionNum = val(1);
      cycleNum = val(2);
      if (val(3) == 1) % tech transmission number
         fileType = 11;
      else
         fileType = 12;
      end
   else
      [val, count, errmsg, ~] = sscanf(a_fileName, 'M%dC%dEOL%d.hex');
      if (isempty(errmsg) && (count == 3))
         fileType = 13;
         missionNum = val(1);
         cycleNum = val(2);
      else
         fprintf('ERROR: Float #%d: Inconsistent TECH file name : %s\n', ...
            g_decArgo_floatNum, ...
            a_fileName);
         return
      end
   end
end

% read file data
filePathName = [g_decArgo_archiveDataDirectory '/' a_fileName];
fId = fopen(filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
      g_decArgo_floatNum, ...
      filePathName);
   return
end
dataIn = fread(fId);
fclose(fId);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process data
tabEvt = []; % for CSV output only
tabEvtNum = []; % to check that all events have been checked once by the operator
tabTech = []; % for TECH and TECH_AUX files
tabTechTime = []; % for TECH_AUX file
tabTraj = []; % for TRAJ
tabBuoy = []; % buoyancy activity for TRAJ and TECH_AUX
tabSpy = []; % pressure monitoring for TRAJ
curByte = 1;
cycleLastDate = nan; % to sort files by float dates
while (curByte <= length(dataIn))
   rawData = get_bits(1, 16, dataIn(curByte:curByte+1));
   evtNum = typecast(swapbytes(uint16(rawData)), 'uint16');
   tabEvtNum = [tabEvtNum evtNum];
   curByte = curByte + 2;

   switch (evtNum)
      case 0
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(0);
            evt.class = 'PRODUCT INFORMATION';
            evt.label = 'Float ID';
            rawData = char(dataIn(curByte:curByte+32-1)');
            idEnd = strfind(rawData, char(0));
            evt.valueStr = rawData(1:idEnd(1)-1);
            curByte = curByte + 32;
            tabEvt = [tabEvt evt];
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 0))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 0];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value {evt.valueStr}];
            end

            evt = get_pfv2_tech_event_data_init_struct(1);
            evt.class = 'PRODUCT INFORMATION';
            evt.label = 'Firmware version';
            type = char(dataIn(curByte:curByte+6-1)');
            type(end) = [];
            curByte = curByte + 6;
            [version, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            [subVersion, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            [release, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = sprintf('%s v20%d.%d.%d', type, version, subVersion, release);
            tabEvt = [tabEvt evt];
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 1))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 1];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value {evt.valueStr}];
            end

            evt = get_pfv2_tech_event_data_init_struct(2);
            evt.class = 'PRODUCT INFORMATION';
            evt.label = 'Firmware checksum';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            evt.valueStr = ['0x' dec2hex(data)];
            tabEvt = [tabEvt evt];
         else
            curByte = curByte + 32;

            curByte = curByte + 6;
            [version, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            [subVersion, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            [release, curByte] = get_bytes_pfv2(dataIn, curByte, 1);

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 2))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 2];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end
         end

      case 1
         evt = get_pfv2_tech_event_data_init_struct(100);
         evt.class = 'MISSION INFORMATION';
         evt.label = 'Mission number';
         [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
         evt.valueStr = num2str(data);
         tabEvt = [tabEvt evt];
         g_decArgo_missionLoopCycle.mission = [g_decArgo_missionLoopCycle.mission data];

         evt = get_pfv2_tech_event_data_init_struct(101);
         evt.class = 'MISSION INFORMATION';
         evt.label = 'Cycle number';
         [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
         evt.valueStr = num2str(data);
         tabEvt = [tabEvt evt];
         g_decArgo_missionLoopCycle.cycleNumber = [g_decArgo_missionLoopCycle.cycleNumber data];

         evt = get_pfv2_tech_event_data_init_struct(102);
         evt.class = 'MISSION INFORMATION';
         evt.label = 'Cycle''s loop setting index';
         [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
         evt.valueStr = num2str(data);
         tabEvt = [tabEvt evt];
         g_decArgo_missionLoopCycle.loop = [g_decArgo_missionLoopCycle.loop data];

         evt = get_pfv2_tech_event_data_init_struct(103);
         evt.class = 'MISSION INFORMATION';
         evt.label = 'Cycle setting index';
         [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
         evt.valueStr = num2str(data);
         tabEvt = [tabEvt evt];
         g_decArgo_missionLoopCycle.cycle = [g_decArgo_missionLoopCycle.cycle data];

      case 2
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200);
            evt.class = 'LIFE INFORMATION';
            evt.label = 'Number of profiles done';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(201);
            evt.class = 'LIFE INFORMATION';
            evt.label = 'Total distance profiles (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(202);
            evt.class = 'LIFE INFORMATION';
            evt.label = 'Total duration at sea (days)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            data = data/86400;
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LIFE INFORMATION: Number of profiles done';
            dataStruct.techId = 200;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LIFE INFORMATION: Total distance profiles (dbar)';
            dataStruct.techId = 201;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LIFE INFORMATION: Total duration at sea';
            dataStruct.techId = 202;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            data = data/3600;
            dataStruct.value = format_time_hhmmss_dec_argo(data);
            tabTech = [tabTech dataStruct];
         end

      case 1000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100000);
            evt.class = 'PHASE (BUOYANCY REDUCTION START)';
            evt.label = 'Cycle start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY REDUCTION START): Cycle start time';
            dataStruct.techId = 100000;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_CycleStartBis;
            tabTraj = [tabTraj dataStruct];
         end

      case 1001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100100);
            evt.class = 'PHASE (BUOYANCY REDUCTION END)';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100101);
            evt.class = 'PHASE (BUOYANCY REDUCTION END)';
            evt.label = 'EV lump sum volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100102);
            evt.class = 'PHASE (BUOYANCY REDUCTION END)';
            evt.label = 'EV transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100103);
            evt.class = 'PHASE (BUOYANCY REDUCTION END)';
            evt.label = 'EV action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else            
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY REDUCTION END): Descent start time';
            dataStruct.techId = 100100;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_DST;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY REDUCTION END): EV lump sum volume (cm3)';
            dataStruct.techId = 100101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY REDUCTION END): EV transferred volume (cm3)';
            dataStruct.techId = 100102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY REDUCTION END): EV action number';
            dataStruct.techId = 100103;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 1002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100200);
            evt.class = 'PHASE (BUOYANCY INVERSION START)';
            evt.label = 'Buoyancy inversion start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY INVERSION START): Buoyancy inversion start time';
            dataStruct.techId = 100200;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
         end

      case 1003
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100300);
            evt.class = 'PHASE (BUOYANCY INVERSION END)';
            evt.label = 'Buoyancy inversion end time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100301);
            evt.class = 'PHASE (BUOYANCY INVERSION END)';
            evt.label = 'External pressure offset (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100302);
            evt.class = 'PHASE (BUOYANCY INVERSION END)';
            evt.label = 'External pressure min (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100303);
            evt.class = 'PHASE (BUOYANCY INVERSION END)';
            evt.label = 'EV transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100304);
            evt.class = 'PHASE (BUOYANCY INVERSION END)';
            evt.label = 'EV action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY INVERSION END): Buoyancy inversion end time';
            dataStruct.techId = 100300;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY INVERSION END): External pressure offset (dbar)';
            dataStruct.techId = 100301;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY INVERSION END): External pressure min (dbar)';
            dataStruct.techId = 100302;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY INVERSION END): EV transferred volume (cm3)';
            dataStruct.techId = 100303;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (BUOYANCY INVERSION END): EV action number';
            dataStruct.techId = 100304;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 1004
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100400);
            evt.class = 'PHASE (DESCENT TO PARKING START)';
            evt.label = 'Descent start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            % already in 100100
            % dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'PHASE (DESCENT TO PARKING START): Descent start time';
            % dataStruct.techId = 100400;
            % [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            % dataJuld = epoch2000_2_julian(dataEpoch);
            % dataStruct.measCode = g_MC_DST;
            % dataStruct.julD = dataJuld;
            % tabTraj = [tabTraj dataStruct];
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end

      case 1005
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100500);
            evt.class = 'PHASE (DESCENT TO PARKING END)';
            evt.label = 'Park start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100501);
            evt.class = 'PHASE (DESCENT TO PARKING END)';
            evt.label = 'EV transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100502);
            evt.class = 'PHASE (DESCENT TO PARKING END)';
            evt.label = 'EV action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100503);
            evt.class = 'PHASE (DESCENT TO PARKING END)';
            evt.label = 'Max Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PARKING END): Park start time';
            dataStruct.techId = 100500;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_PST;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PARKING END): EV transferred volume (cm3)';
            dataStruct.techId = 100501;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PARKING END): EV action number';
            dataStruct.techId = 100502;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PARKING END): Max Pres (dbar)';
            dataStruct.techId = 100503;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.measCode = g_MC_MaxPresInDescToPark;
            dataStruct.pres = data;
            tabTraj = [tabTraj dataStruct];
         end

      case 1006
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100600);
            evt.class = 'PHASE (DESCENT TO PROFILE START)';
            evt.label = 'Descent to prof start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            % already in 100900
            % dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'PHASE (DESCENT TO PROFILE START): Park end time';
            % dataStruct.techId = 100600;
            % [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            % dataJuld = epoch2000_2_julian(dataEpoch);
            % dataStruct.measCode = g_MC_PET;
            % dataStruct.julD = dataJuld;
            % tabTraj = [tabTraj dataStruct];
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end

      case 1007
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100700);
            evt.class = 'PHASE (DESCENT TO PROFILE END)';
            evt.label = 'Deep park start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100701);
            evt.class = 'PHASE (DESCENT TO PROFILE END)';
            evt.label = 'EV transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100702);
            evt.class = 'PHASE (DESCENT TO PROFILE END)';
            evt.label = 'EV action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100703);
            evt.class = 'PHASE (DESCENT TO PROFILE END)';
            evt.label = 'Max Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PROFILE END): Deep park start time';
            dataStruct.techId = 100700;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_DPST;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PROFILE END): EV transferred volume (cm3)';
            dataStruct.techId = 100701;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];
            
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PROFILE END): EV action number';
            dataStruct.techId = 100702;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DESCENT TO PROFILE END): Max Pres (dbar)';
            dataStruct.techId = 100703;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.measCode = g_MC_MaxPresInDescToProf;
            dataStruct.pres = data;
            tabTraj = [tabTraj dataStruct];
         end

      case 1008
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100800);
            evt.class = 'PHASE (PARK START TIME)';
            evt.label = 'Park start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            % already in 100500
            % dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'PHASE (PARK START TIME): Park start time';
            % dataStruct.techId = 100800;
            % [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            % dataJuld = epoch2000_2_julian(dataEpoch);
            % dataStruct.measCode = g_MC_PST;
            % dataStruct.julD = dataJuld;
            % tabTraj = [tabTraj dataStruct];
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end

      case 1009
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(100900);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'Park end time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100901);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'Min Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100902);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'Max Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100903);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'Stabilized entrance number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100904);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'Unstabilized entrance number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100905);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'Repositioning number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100906);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'EV transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100907);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'EV action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100908);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'PUMP transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(100909);
            evt.class = 'PHASE (PARK END TIME)';
            evt.label = 'PUMP action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): Park end time';
            dataStruct.techId = 100900;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.measCode = g_MC_PET;
            dataStruct.julD = dataJuld;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): Min Pres (dbar)';
            dataStruct.techId = 100901;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.measCode = g_MC_MinPresInDriftAtPark;
            dataStruct.pres = data;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): Max Pres (dbar)';
            dataStruct.techId = 100902;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.measCode = g_MC_MaxPresInDriftAtPark;
            dataStruct.pres = data;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): Stabilized entrance number';
            dataStruct.techId = 100903;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): Unstabilized entrance number';
            dataStruct.techId = 100904;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): Repositioning number';
            dataStruct.techId = 100905;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): EV transferred volume (cm3)';
            dataStruct.techId = 100906;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): EV action number';
            dataStruct.techId = 100907;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): PUMP transferred volume (cm3)';
            dataStruct.techId = 100908;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PARK END TIME): PUMP action number';
            dataStruct.techId = 100909;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 1010
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101000);
            evt.class = 'PHASE (DEEP PARK START TIME)';
            evt.label = 'Deep park start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            % already in 100700
            % dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'PHASE (DEEP PARK START TIME): Deep park start time';
            % dataStruct.techId = 101000;
            % [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            % dataJuld = epoch2000_2_julian(dataEpoch);
            % dataStruct.measCode = g_MC_DPST;
            % dataStruct.julD = dataJuld;
            % tabTraj = [tabTraj dataStruct];
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end
         
      case 1011
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101100);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'Deep park end time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101101);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'Min Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101102);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'Max Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101103);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'Stabilized entrance number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101104);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'Unstabilized entrance number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101105);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'Repositioning number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101106);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'EV transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101107);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'EV action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101108);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'PUMP transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101109);
            evt.class = 'PHASE (DEEP PARK END TIME)';
            evt.label = 'PUMP action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): Ascent start time';
            dataStruct.techId = 101100;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.measCode = g_MC_AST;
            dataStruct.julD = dataJuld;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): Min Pres (dbar)';
            dataStruct.techId = 101101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.measCode = g_MC_MinPresInDriftAtProf;
            dataStruct.pres = data;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): Max Pres (dbar)';
            dataStruct.techId = 101102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.measCode = g_MC_MaxPresInDriftAtProf;
            dataStruct.pres = data;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): Stabilized entrance number';
            dataStruct.techId = 101103;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): Unstabilized entrance number';
            dataStruct.techId = 101104;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): Repositioning number';
            dataStruct.techId = 101105;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): EV transferred volume (cm3)';
            dataStruct.techId = 101106;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): EV action number';
            dataStruct.techId = 101107;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): PUMP transferred volume (cm3)';
            dataStruct.techId = 101108;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (DEEP PARK END TIME): PUMP action number';
            dataStruct.techId = 101109;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end
         
      case 1012
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101200);
            evt.class = 'PHASE (ASCENT START TIME)';
            evt.label = 'Ascent start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            % already in 101100
            % dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'PHASE (ASCENT START TIME): Ascent start time';
            % dataStruct.techId = 101200;
            % [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            % dataJuld = epoch2000_2_julian(dataEpoch);
            % dataStruct.measCode = g_MC_AST;
            % dataStruct.julD = dataJuld;
            % tabTraj = [tabTraj dataStruct];
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end

      case 1013
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101300);
            evt.class = 'PHASE (ASCENT END TIME)';
            evt.label = 'Ascent end time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;

            evt = get_pfv2_tech_event_data_init_struct(101301);
            evt.class = 'PHASE (ASCENT END TIME)';
            evt.label = 'PUMP transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101302);
            evt.class = 'PHASE (ASCENT END TIME)';
            evt.label = 'PUMP action number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (ASCENT END TIME): Ascent end time';
            dataStruct.techId = 101300;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.measCode = g_MC_AET;
            dataStruct.julD = dataJuld;
            tabTraj = [tabTraj dataStruct];
            cycleLastDate = dataJuld;

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (ASCENT END TIME): PUMP transferred volume (cm3)';
            dataStruct.techId = 101301;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (ASCENT END TIME): PUMP action number';
            dataStruct.techId = 101302;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 1014
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101400);
            evt.class = 'PHASE (EMERGENCE START TIME)';
            evt.label = 'Emergence start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;
         else
            % already in 101300
            % dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'PHASE (EMERGENCE START TIME): Ascent end time';
            % dataStruct.techId = 101400;
            % [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            % dataJuld = epoch2000_2_julian(dataEpoch);
            % dataStruct.measCode = g_MC_AET;
            % dataStruct.julD = dataJuld;
            % tabTraj = [tabTraj dataStruct];
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end

      case 1015
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101500);
            evt.class = 'PHASE (IN AIR START TIME)';
            evt.label = 'In air start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (IN AIR START TIME): In air start time';
            dataStruct.techId = 101500;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];            
         end

      case 1016
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101600);
            evt.class = 'PHASE (TRANSMISSION START TIME)';
            evt.label = 'Transmission start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (TRANSMISSION START TIME): Transmission start time';
            dataStruct.techId = 101600;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.measCode = g_MC_TST;
            dataStruct.julD = dataJuld;
            tabTraj = [tabTraj dataStruct];
            cycleLastDate = dataJuld;
         end

      case 1017
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101700);
            evt.class = 'PHASE (EMERGENCY ASCENT START TIME)';
            evt.label = 'Emergency ascent start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;

            evt = get_pfv2_tech_event_data_init_struct(101701);
            evt.class = 'PHASE (EMERGENCY ASCENT START TIME)';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (EMERGENCY ASCENT START TIME): Emergency ascent start time';
            dataStruct.techId = 101700;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
            cycleLastDate = dataJuld;

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (EMERGENCY ASCENT START TIME): Pres (dbar)';
            dataStruct.techId = 101701;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];
         end

      case 1018
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101800);
            evt.class = 'PHASE (EMERGENCY ASCENT END TIME)';
            evt.label = 'Emergency ascent end time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;

            evt = get_pfv2_tech_event_data_init_struct(101801);
            evt.class = 'PHASE (EMERGENCY ASCENT END TIME)';
            evt.label = 'PUMP transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (EMERGENCY ASCENT END TIME): Emergency ascent end time';
            dataStruct.techId = 101800;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.measCode = g_MC_AET;
            dataStruct.julD = dataJuld;
            tabTraj = [tabTraj dataStruct];
            cycleLastDate = dataJuld;

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (EMERGENCY ASCENT END TIME): PUMP transferred volume (cm3)';
            dataStruct.techId = 101801;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];
         end

      case 1019
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(101900);
            evt.class = 'PHASE (END OF LIFE)';
            evt.label = 'EOL start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;

            evt = get_pfv2_tech_event_data_init_struct(101901);
            evt.class = 'PHASE (END OF LIFE)';
            evt.label = 'Time of last EOL detection';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(101902);
            evt.class = 'PHASE (END OF LIFE)';
            evt.label = 'End of life source';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            evt.valueStr = dec2bin(data, 32);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (END OF LIFE): EOL start time';
            dataStruct.techId = 101900;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
            cycleLastDate = dataJuld;

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (END OF LIFE): Time of last EOL detection';
            dataStruct.techId = 101901;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (END OF LIFE): End of life source';
            dataStruct.techId = 101902;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataStruct.value = dec2bin(data, 32);
            tabTech = [tabTech dataStruct];
         end

      case 1020
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(102000);
            evt.class = 'PHASE (PRESSURE DETECTION START)';
            evt.label = 'Pressure detection start time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PRESSURE DETECTION START): Pressure detection start time';
            dataStruct.techId = 102000;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
         end

      case 1021
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(102100);
            evt.class = 'PHASE (PRESSURE DETECTION END)';
            evt.label = 'Pressure detection end time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(102101);
            evt.class = 'PHASE (PRESSURE DETECTION END)';
            evt.label = 'Pressure detection time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(102102);
            evt.class = 'PHASE (PRESSURE DETECTION END)';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PRESSURE DETECTION END): Pressure detection end time';
            dataStruct.techId = 102100;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PRESSURE DETECTION END): Mission start time';
            dataStruct.techId = 102101;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (PRESSURE DETECTION END): External pressure max (dbar)';
            dataStruct.techId = 102102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 1022
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(102200);
            evt.class = 'PHASE (END OF CYCLE)';
            evt.label = 'Theoretical end of cycle time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PHASE (END OF CYCLE): Theoretical end of cycle time';
            dataStruct.techId = 102200;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
         end

      case 2000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200000);
            evt.class = 'GROUNDING';
            evt.label = 'Grounding time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200001);
            evt.class = 'GROUNDING';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200002);
            evt.class = 'GROUNDING';
            evt.label = 'PUMP transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'GROUNDING: Grounding time';
            dataStruct.techId = 200000;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            [oil, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            oil = oil/10;
            dataStruct.measCode = g_MC_Grounded;
            dataStruct.julD = dataJuld;
            dataStruct.pres = pres;
            dataStruct.value = oil;
            tabTraj = [tabTraj dataStruct];

            % moved to TECH_TIME (in process_trajectory_data_40x)
            % dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'GROUNDING: PUMP transferred volume (cm3)';
            % dataStruct.techId = 200002;
            % dataStruct.value = sprintf('%.1f', oil);
            % tabTech = [tabTech dataStruct];
         end

      case 2001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200100);
            evt.class = 'HANGING';
            evt.label = 'Hanging time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200101);
            evt.class = 'HANGING';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200102);
            evt.class = 'HANGING';
            evt.label = 'PUMP transferred volume (cm3)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'HANGING: Pres (dbar)';
            dataStruct.techId = 200101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'HANGING: PUMP transferred volume (cm3)';
            dataStruct.techId = 200102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 2002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200200);
            evt.class = 'BRAKING';
            evt.label = 'Braking time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200201);
            evt.class = 'BRAKING';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200202);
            evt.class = 'BRAKING';
            evt.label = 'Speed (mm/s)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BRAKING: Pres (dbar)';
            dataStruct.techId = 200201;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BRAKING: Speed (mm/s)';
            dataStruct.techId = 200202;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 2003
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200300);
            evt.class = 'EMERGENCY BRAKING';
            evt.label = 'Emergency braking time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200301);
            evt.class = 'EMERGENCY BRAKING';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200302);
            evt.class = 'EMERGENCY BRAKING';
            evt.label = 'Speed (mm/s)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EMERGENCY BRAKING: Pres (dbar)';
            dataStruct.techId = 200301;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EMERGENCY BRAKING: Speed (mm/s)';
            dataStruct.techId = 200302;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 2004
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200400);
            evt.class = 'ISA DETECTION FILTERING';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200401);
            evt.class = 'ISA DETECTION FILTERING';
            evt.label = 'Detection counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200402);
            evt.class = 'ISA DETECTION FILTERING';
            evt.label = 'Number max of detection before confirming ice’s presence';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ISA DETECTION FILTERING: ISA detection counter';
            dataStruct.techId = 200401;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
         end

      case 2005
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200500);
            evt.class = 'ISA RESULT';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200501);
            evt.class = 'ISA RESULT';
            evt.label = 'Median temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            % moved to TECH_TIME (in techId = 200502)
            % dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'ISA RESULT: Median temperature (degC)';
            % dataStruct.techId = 200501;
            % [medTemp, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            % medTemp = medTemp/1000;
            % dataStruct.value = sprintf('%.3f', medTemp);
            % tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ISA RESULT: Median temperature (degC)';
            dataStruct.techId = 200500;
            [medTemp, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            medTemp = medTemp/1000;
            dataStruct.measCode = g_MC_MedianValueInAscProf;
            dataStruct.julD = dataJuld;
            dataStruct.temp = medTemp;
            tabTraj = [tabTraj dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ISA RESULT: Median temperature (degC)';
            dataStruct.techId = 200502;
            dataStruct.value = medTemp;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 2006
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200600);
            evt.class = 'ICE DETECTION';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200601);
            evt.class = 'ICE DETECTION';
            evt.label = 'Type of detection';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = dec2bin(data, 16);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200605);
            evt.class = 'ICE DETECTION';
            evt.label = 'Emergence prohibited until';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200606);
            evt.class = 'ICE DETECTION';
            evt.label = 'Emergence will be forced at';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ICE DETECTION: Time';
            dataStruct.techId = 200600;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ICE DETECTION: Type of detection';
            dataStruct.techId = 200601;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ICE DETECTION: Emergence prohibited until';
            dataStruct.techId = 200605;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ICE DETECTION: Emergence will be forced at';
            dataStruct.techId = 200606;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
         end

      case 2007
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200700);
            evt.class = 'SECURITY';
            evt.label = 'Deployment mode (0: not armed, 1: armed, 2: armed in pressure detection mode)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SECURITY: Deployment mode';
            dataStruct.techId = 200700;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 2008
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200800);
            evt.class = 'NEW SETPOINT';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200801);
            evt.class = 'NEW SETPOINT';
            evt.label = 'Previous setpoint (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200802);
            evt.class = 'NEW SETPOINT';
            evt.label = 'New setpoint (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'NEW SETPOINT: Previous setpoint (dbar)';
            dataStruct.techId = 200801;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'NEW SETPOINT: New setpoint (dbar)';
            dataStruct.techId = 200802;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 2009
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(200900);
            evt.class = 'EMPTY BALLAST DETECTION';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(200901);
            evt.class = 'EMPTY BALLAST DETECTION';
            evt.label = 'Detection flag';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EMPTY BALLAST DETECTION: Detection flag';
            dataStruct.techId = 200901;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 3000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300000);
            evt.class = 'ALARM WITHOUT VALUE';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300001);
            evt.class = 'ALARM WITHOUT VALUE';
            evt.label = 'Alarm type';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = [num2str(data) ' (' get_alarm_without_value_explanation(data) ')'];
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ALARM WITHOUT VALUE: Alarm type';
            dataStruct.techId = 300001;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.groupId = g_decArgo_tecTimeGroupCpt;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 3001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300100);
            evt.class = 'ALARM WITH VALUE';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300101);
            evt.class = 'ALARM WITH VALUE';
            evt.label = 'Alarm type';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = [num2str(data) ' (' get_alarm_with_value_explanation(data) ')'];
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300102);
            evt.class = 'ALARM WITH VALUE';
            evt.label = 'Value';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300103);
            evt.class = 'ALARM WITH VALUE';
            evt.label = 'Threshold';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ALARM WITH VALUE: Alarm type';
            dataStruct.techId = 300101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ALARM WITH VALUE: Value';
            dataStruct.techId = 300102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'ALARM WITH VALUE: Threshold';
            dataStruct.techId = 300103;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 3002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300200);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Pressure: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300201);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Pressure: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300202);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Pressure: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300203);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Temperature: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300204);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Temperature: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300205);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Temperature: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300206);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Salinity: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300207);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Salinity: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300208);
            evt.class = 'SBE41 LIMIT VALUES';
            evt.label = 'Salinity: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 LIMIT VALUES: Pressure: Number of samples over limits';
            dataStruct.techId = 300200;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300201))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300201];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300202))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300202];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 LIMIT VALUES: Temperature: Number of samples over limits';
            dataStruct.techId = 300203;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300204))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300204];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300205))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300205];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 LIMIT VALUES: Salinity: Number of samples over limits';
            dataStruct.techId = 300206;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300207))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300207];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300208))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300208];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end
         end

      case 3003
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300300);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'C1RPhase: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300301);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'C1RPhase: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300302);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'C1RPhase: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300303);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'C2RPhase: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300304);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'C2RPhase: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300305);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'C2RPhase: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300306);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'Temperature: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300307);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'Temperature: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300308);
            evt.class = 'AANDERAA4330 LIMIT VALUES';
            evt.label = 'Temperature: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'AANDERAA4330 LIMIT VALUES: C1RPhase: Number of samples over limits';
            dataStruct.techId = 300300;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300301))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300301];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300302))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300302];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'AANDERAA4330 LIMIT VALUES: C2RPhase: Number of samples over limits';
            dataStruct.techId = 300303;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300304))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300304];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300305))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300305];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'AANDERAA4330 LIMIT VALUES: Temperature: Number of samples over limits';
            dataStruct.techId = 300306;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300307))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300307];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300308))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300308];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end
         end

      case 3004
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300400);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Pressure: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300401);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Pressure: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300402);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Pressure: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300403);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Temperature: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300404);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Temperature: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300405);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Temperature: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300406);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Salinity: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300407);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Salinity: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300408);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Salinity: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300409);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Coils temperature: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300410);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Coils temperature: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300411);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Coils temperature: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300412);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Salinity corrected: Number of samples over limits';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300413);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Salinity corrected: Min value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300414);
            evt.class = 'RBR LIMIT VALUES';
            evt.label = 'Salinity corrected: Max value expected';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%g', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR LIMIT VALUES: Pressure: Number of samples over limits';
            dataStruct.techId = 300400;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300401))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300401];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300402))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300402];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR LIMIT VALUES: Temperature: Number of samples over limits';
            dataStruct.techId = 300403;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300404))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300404];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300405))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300405];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR LIMIT VALUES: Salinity: Number of samples over limits';
            dataStruct.techId = 300406;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300407))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300407];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300408))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300408];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR LIMIT VALUES: Coils temperature: Number of samples over limits';
            dataStruct.techId = 300409;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300410))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300410];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300411))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300411];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR LIMIT VALUES: Salinity corrected: Number of samples over limits';
            dataStruct.techId = 300412;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300413))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300413];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end

            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 300414))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 300414];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value data];
            end
         end

      case 3005
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300500);
            evt.class = 'SENSOR ERROR';
            evt.label = 'Sensor number (1:SBE41, 2:AANDERAA4330, 3:RBR)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300501);
            evt.class = 'SENSOR ERROR';
            evt.label = 'Number of invalid data';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [sensorNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            switch (sensorNum)
               case {1, 3}
                  shortSensorName = 'Ctd';
               case {2}
                  shortSensorName = 'Optode';
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('SENSOR ERROR: Number of invalid data for sensor ''%s''', shortSensorName);
            dataStruct.techId = 300501;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            dataStruct.shortSensorName = shortSensorName;
            tabTech = [tabTech dataStruct];
         end

      case 3006
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(300600);
            evt.class = 'INVALID FRAME FROM SENSOR';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300601);
            evt.class = 'INVALID FRAME FROM SENSOR';
            evt.label = 'Sensor number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300602);
            evt.class = 'INVALID FRAME FROM SENSOR';
            evt.label = 'Frame size';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            frameSize = data;
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(300603);
            evt.class = 'INVALID FRAME FROM SENSOR';
            evt.label = 'Sensor frame';
            rawData = char(dataIn(curByte:curByte+frameSize-1)');
            evt.valueStr = data;
            curByte = curByte + frameSize;
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            [sensorNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            switch (sensorNum)
               case {1, 3}
                  shortSensorName = 'Ctd';
               case {2}
                  shortSensorName = 'Optode';
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('INVALID FRAME FROM SENSOR: Time of sensor frame for sensor ''%s''', shortSensorName);
            dataStruct.techId = 300600;
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            tabTech = [tabTech dataStruct];

            [frameSize, curByte] = get_bytes_pfv2(dataIn, curByte, 2);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('INVALID FRAME FROM SENSOR: Sensor frame for sensor ''%s''', shortSensorName);
            dataStruct.techId = 300603;
            dataStruct.julD = dataJuld;
            dataStruct.value = char(dataIn(curByte:curByte+frameSize-1)');
            curByte = curByte + frameSize;
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            tabTech = [tabTech dataStruct];
         end

      case 4000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400000);
            evt.class = 'BATTERY INFORMATION';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400001);
            evt.class = 'BATTERY INFORMATION';
            evt.label = 'Voltage (V)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BATTERY INFORMATION: Voltage (V)';
            dataStruct.techId = 400001;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_CycleStartBis;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 4001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400100);
            evt.class = 'BATTERY INFORMATION AT PMAX';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400101);
            evt.class = 'BATTERY INFORMATION AT PMAX';
            evt.label = 'Voltage (V)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400102);
            evt.class = 'BATTERY INFORMATION AT PMAX';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BATTERY INFORMATION AT PMAX: Voltage (V)';
            dataStruct.techId = 400101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_AST;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BATTERY INFORMATION AT PMAX: Pres (dbar)';
            dataStruct.techId = 400102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_AST;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 4002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400200);
            evt.class = 'SERVITUDE INFORMATION';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400201);
            evt.class = 'SERVITUDE INFORMATION';
            evt.label = 'Internal pressure (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400202);
            evt.class = 'SERVITUDE INFORMATION';
            evt.label = 'Internal temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, -2);
            data = data/1000 + 20;
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400203);
            evt.class = 'SERVITUDE INFORMATION';
            evt.label = 'Internal relative humidity (%)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SERVITUDE INFORMATION: Internal pressure (mbar)';
            dataStruct.techId = 400201;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SERVITUDE INFORMATION: Internal temperature (degC)';
            dataStruct.techId = 400202;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, -2);
            data = data/1000 + 20;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SERVITUDE INFORMATION: Internal relative humidity (%)';
            dataStruct.techId = 400203;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 4003
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400300);
            evt.class = 'SERVITUDE INFORMATION';
            evt.label = 'Internal pressure compensed (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SERVITUDE INFORMATION: Internal pressure compensed (mbar)';
            dataStruct.techId = 400300;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 4004
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400400);
            evt.class = 'RESET INFORMATION';
            evt.label = 'Reset time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400401);
            evt.class = 'RESET INFORMATION';
            evt.label = 'Reset source  (bit#, 0:Firewall, 1:Option byte loader, 2:PIN, 3:BOR, 4:software, 5:Independent watchdog, 6:Window watchdog, 7:Low-power)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = dec2bin(data, 8);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RESET INFORMATION: Reset time';
            dataStruct.techId = 400400;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RESET INFORMATION: Reset source  (bit#, 0:Firewall, 1:Option byte loader, 2:PIN, 3:BOR, 4:software, 5:Independent watchdog, 6:Window watchdog, 7:Low-power)';
            dataStruct.techId = 400401;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = dec2bin(data, 8);
            tabTech = [tabTech dataStruct];
         end

      case 4005
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400500);
            evt.class = 'DISK INFORMATION';
            [diskNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            if (diskNum == 0)
               evt.label = 'Flash disk free (%)';
            else
               evt.label = 'SD card free (%)';
            end
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            data = 100 - data*0.5;
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [diskNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            if (diskNum == 0)
               label = 'Flash disk free (%)';
               techId = 400500;
            else
               label = 'SD card free (%)';
               techId = 400501;
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('DISK INFORMATION: %s', label);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            data = 100 - data*0.5;
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 4006
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(400600);
            evt.class = 'LAST LOSS OF INTERNAL VACUUM';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400601);
            evt.class = 'LAST LOSS OF INTERNAL VACUUM';
            evt.label = 'Internal pressure (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400602);
            evt.class = 'LAST LOSS OF INTERNAL VACUUM';
            evt.label = 'Internal temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, -2);
            data = data/1000 + 20;
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(400603);
            evt.class = 'LAST LOSS OF INTERNAL VACUUM';
            evt.label = 'Internal relative humidity (%)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST LOSS OF INTERNAL VACUUM: Internal pressure (mbar)';
            dataStruct.techId = 400601;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST LOSS OF INTERNAL VACUUM: Internal temperature (degC)';
            dataStruct.techId = 400602;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, -2);
            data = data/1000 + 20;
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST LOSS OF INTERNAL VACUUM: Internal relative humidity (%)';
            dataStruct.techId = 400603;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 5000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(500000);
            evt.class = 'LAST PUMPED MEASUREMENT';
            evt.label = 'Pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(500001);
            evt.class = 'LAST PUMPED MEASUREMENT';
            evt.label = 'Temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(500002);
            evt.class = 'LAST PUMPED MEASUREMENT';
            evt.label = 'Salinity (PSU)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];
         else
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            [temp, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            [psal, curByte] = get_bytes_pfv2(dataIn, curByte, 5);

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST PUMPED MEASUREMENT';
            dataStruct.techId = 500000;
            dataStruct.measCode = g_MC_LastAscPumpedCtd;
            dataStruct.pres = pres;
            dataStruct.temp = temp;
            dataStruct.psal = psal;
            tabTraj = [tabTraj dataStruct];
         end

      case 5001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(500100);
            evt.class = 'CTD OFFSET PRESSURE';
            evt.label = 'SBE41 offset pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'CTD OFFSET PRESSURE: SBE41 offset pressure (dbar)';
            dataStruct.techId = 500100;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 5002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(500200);
            evt.class = 'CTD OFFSET PRESSURE';
            evt.label = 'RBR offset pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'CTD OFFSET PRESSURE: RBR offset pressure (dbar)';
            dataStruct.techId = 500200;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 6000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(600000);
            evt.class = 'SELF TEST';
            evt.label = 'FRAM memory result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600001);
            evt.class = 'SELF TEST';
            evt.label = 'FLASH memory result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600002);
            evt.class = 'SELF TEST';
            evt.label = 'SDcard state (0: error, 1: ok, 2: not present)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600003);
            evt.class = 'SELF TEST';
            evt.label = 'XML settings result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600004);
            evt.class = 'SELF TEST';
            evt.label = 'RTC result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600005);
            evt.class = 'SELF TEST';
            evt.label = 'RTC time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600006);
            evt.class = 'SELF TEST';
            evt.label = 'Insulation result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600007);
            evt.class = 'SELF TEST';
            evt.label = 'Insulation value';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600008);
            evt.class = 'SELF TEST';
            evt.label = 'Battery result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600009);
            evt.class = 'SELF TEST';
            evt.label = 'Voltage on load (V)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600010);
            evt.class = 'SELF TEST';
            evt.label = 'EV result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600011);
            evt.class = 'SELF TEST';
            evt.label = 'PUMP result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600012);
            evt.class = 'SELF TEST';
            evt.label = 'Empty ballast sensor result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600013);
            evt.class = 'SELF TEST';
            evt.label = 'Max buoyancy pumping duration (sec)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600014);
            evt.class = 'SELF TEST';
            evt.label = 'Internal pressure result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600015);
            evt.class = 'SELF TEST';
            evt.label = 'Internal pressure (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600016);
            evt.class = 'SELF TEST';
            evt.label = 'Internal pressure compensed (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600017);
            evt.class = 'SELF TEST';
            evt.label = 'Internal temperature result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600018);
            evt.class = 'SELF TEST';
            evt.label = 'Internal temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600019);
            evt.class = 'SELF TEST';
            evt.label = 'Internal relative humidity result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600020);
            evt.class = 'SELF TEST';
            evt.label = 'Internal relative humidity (%)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600021);
            evt.class = 'SELF TEST';
            evt.label = 'GNSS result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600022);
            evt.class = 'SELF TEST';
            evt.label = 'Modem result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            % Dummy buffer (allowing future evolutions)
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 32);
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: FRAM memory result flag (0: ok, 1: error)';
            dataStruct.techId = 600000;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = data;

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: FLASH memory result flag (0: ok, 1: error)';
            dataStruct.techId = 600001;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: SDcard state (0: ok, 1: error, 2: not present)';
            dataStruct.techId = 600002;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            if (data == 0)
               data = 1;
            elseif (data == 1)
               data = 0;
            end
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: XML settings result flag (0: ok, 1: error)';
            dataStruct.techId = 600003;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: RTC result flag (0: ok, 1: error)';
            dataStruct.techId = 600004;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: RTC time';
            dataStruct.techId = 600005;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Insulation result flag (0: ok, 1: error)';
            dataStruct.techId = 600006;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Insulation value';
            dataStruct.techId = 600007;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Battery result flag (0: ok, 1: error)';
            dataStruct.techId = 600008;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Voltage on load (V)';
            dataStruct.techId = 600009;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: EV result flag (0: ok, 1: error)';
            dataStruct.techId = 600010;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: PUMP result flag (0: ok, 1: error)';
            dataStruct.techId = 600011;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Empty ballast sensor result flag (0: ok, 1: error)';
            dataStruct.techId = 600012;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Max buoyancy pumping duration (sec)';
            dataStruct.techId = 600013;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal pressure result flag (0: ok, 1: error)';
            dataStruct.techId = 600014;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal pressure (mbar)';
            dataStruct.techId = 600015;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal pressure compensed (mbar)';
            dataStruct.techId = 600016;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal temperature result flag (0: ok, 1: error)';
            dataStruct.techId = 600017;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal temperature (degC)';
            dataStruct.techId = 600018;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal relative humidity result flag (0: ok, 1: error)';
            dataStruct.techId = 600019;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Internal relative humidity (%)';
            dataStruct.techId = 600020;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: GNSS result flag (0: ok, 1: error)';
            dataStruct.techId = 600021;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Modem result flag (0: ok, 1: error)';
            dataStruct.techId = 600022;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
            errTab = [errTab data];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SELF TEST: Initial check error';
            dataStruct.techId = 600023;
            data = ~any(errTab == 0);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            % Dummy buffer (allowing future evolutions)
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 32);
         end

      case 6001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(600100);
            evt.class = 'SBE41 SELF TEST';
            evt.label = 'Fast pressure result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600101);
            evt.class = 'SBE41 SELF TEST';
            evt.label = 'Fast pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600102);
            evt.class = 'SBE41 SELF TEST';
            evt.label = 'CTD measurement result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600103);
            evt.class = 'SBE41 SELF TEST';
            evt.label = 'CTD Pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600104);
            evt.class = 'SBE41 SELF TEST';
            evt.label = 'CTD temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600105);
            evt.class = 'SBE41 SELF TEST';
            evt.label = 'CTD salinity (PSU)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 SELF TEST: Fast pressure result flag (0: ok, 1: error)';
            dataStruct.techId = 600100;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 SELF TEST: Fast pressure (dbar)';
            dataStruct.techId = 600101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 SELF TEST: CTD measurement result flag (0: ok, 1: error)';
            dataStruct.techId = 600102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 SELF TEST: CTD Pressure (dbar)';
            dataStruct.techId = 600103;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 SELF TEST: CTD temperature (degC)';
            dataStruct.techId = 600104;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SBE41 SELF TEST: CTD salinity (PSU)';
            dataStruct.techId = 600105;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];
         end

      case 6002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(600200);
            evt.class = 'AANDERAA4330 SELF TEST';
            evt.label = 'Measurement result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600201);
            evt.class = 'AANDERAA4330 SELF TEST';
            evt.label = 'Serial number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 600201))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 600201];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value {evt.valueStr}];
            end
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'AANDERAA4330 SELF TEST: Measurement result flag (0: ok, 1: error)';
            dataStruct.techId = 600200;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
         end
         
      case 6003
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(600300);
            evt.class = 'RBR SELF TEST';
            evt.label = 'Fast pressure result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600301);
            evt.class = 'RBR SELF TEST';
            evt.label = 'Fast pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600302);
            evt.class = 'RBR SELF TEST';
            evt.label = 'CTD measurement result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600303);
            evt.class = 'RBR SELF TEST';
            evt.label = 'CTD Pressure (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600304);
            evt.class = 'RBR SELF TEST';
            evt.label = 'CTD temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600305);
            evt.class = 'RBR SELF TEST';
            evt.label = 'CTD salinity (PSU)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600306);
            evt.class = 'RBR SELF TEST';
            evt.label = 'CTD coils temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600307);
            evt.class = 'RBR SELF TEST';
            evt.label = 'CTD corrected salinity (PSU)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(600308);
            evt.class = 'RBR SELF TEST';
            evt.label = 'Serial number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
            if (isempty(g_decArgo_metaFromTech.techId) || ~any(g_decArgo_metaFromTech.techId == 600308))
               g_decArgo_metaFromTech.techId = [g_decArgo_metaFromTech.techId 600308];
               g_decArgo_metaFromTech.value = [g_decArgo_metaFromTech.value {evt.valueStr}];
            end
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: Fast pressure result flag (0: ok, 1: error)';
            dataStruct.techId = 600300;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: Fast pressure (dbar)';
            dataStruct.techId = 600301;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: CTD measurement result flag (0: ok, 1: error)';
            dataStruct.techId = 600302;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: CTD Pressure (dbar)';
            dataStruct.techId = 600303;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: CTD temperature (degC)';
            dataStruct.techId = 600304;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: CTD salinity (PSU)';
            dataStruct.techId = 600305;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: CTD coils temperature (degC)';
            dataStruct.techId = 600306;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RBR SELF TEST: CTD corrected salinity (PSU)';
            dataStruct.techId = 600307;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
         end

      case 6100
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610000);
            evt.class = 'FRAM MEMORY SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'FRAM MEMORY SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610000;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 6101
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610100);
            evt.class = 'FLASH MEMORY SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'FLASH MEMORY SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610100;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 6102
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610200);
            evt.class = 'SDCARD MEMORY SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'SDCARD MEMORY SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610200;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            if (data == 0)
               data = 1;
            elseif (data == 1)
               data = 0;
            end
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 6103
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610300);
            evt.class = 'XML SETTINGS SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'XML SETTINGS SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610300;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 6104
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610400);
            evt.class = 'RTC SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(610401);
            evt.class = 'RTC SELF TEST';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RTC SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610400;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'RTC SELF TEST: Time';
            dataStruct.techId = 610401;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];
         end

      case 6105
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610500);
            evt.class = 'INSULATION SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(610501);
            evt.class = 'INSULATION SELF TEST';
            evt.label = 'Value';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INSULATION SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610500;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INSULATION SELF TEST: Value';
            dataStruct.techId = 610501;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 6106
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610600);
            evt.class = 'BATTERY SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(610601);
            evt.class = 'BATTERY SELF TEST';
            evt.label = 'Voltage on load (V)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BATTERY SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610600;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'BATTERY SELF TEST: Value';
            dataStruct.techId = 610601;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/1000;
            dataStruct.value = sprintf('%.3f', data);
            tabTech = [tabTech dataStruct];
         end

      case 6107
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610700);
            evt.class = 'EV SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EV SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610700;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 6108
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610800);
            evt.class = 'PUMP SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PUMP SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610800;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 6109
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(610900);
            evt.class = 'EMPTY BALLAST SENSOR SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(610901);
            evt.class = 'EMPTY BALLAST SENSOR SELF TEST';
            evt.label = 'Max buoyancy pumping duration (s)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EMPTY BALLAST SENSOR SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 610900;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EMPTY BALLAST SENSOR SELF TEST: Max buoyancy pumping duration (s)';
            dataStruct.techId = 610901;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 6110
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(611000);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal pressure result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(611001);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal pressure (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(611002);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal pressure compensed (mbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(611003);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal temperature result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(611004);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal temperature (degC)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(611005);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal relative humidity result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(611006);
            evt.class = 'INTERNAL MEASUREMENT SELF TEST';
            evt.label = 'Internal relative humidity (%)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal pressure result flag (0: ok, 1: error)';
            dataStruct.techId = 611000;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal pressure (mbar)';
            dataStruct.techId = 611001;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];
         
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal pressure compensed (mbar)';
            dataStruct.techId = 611002;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal temperature result flag (0: ok, 1: error)';
            dataStruct.techId = 611003;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal temperature (degC)';
            dataStruct.techId = 611004;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal relative humidity result flag (0: ok, 1: error)';
            dataStruct.techId = 611005;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'INTERNAL MEASUREMENT SELF TEST: Internal relative humidity (%)';
            dataStruct.techId = 611006;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = sprintf('%.1f', data);
            tabTech = [tabTech dataStruct];         
         end

      case 6111
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(611100);
            evt.class = 'GNSS SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'GNSS SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 611100;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 6112
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(611200);
            evt.class = 'MODEM SELF TEST';
            evt.label = 'Result flag (0: error, 1: ok)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'MODEM SELF TEST: Result flag (0: ok, 1: error)';
            dataStruct.techId = 611200;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data == 0);
            tabTech = [tabTech dataStruct];
         end

      case 7000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(700000);
            evt.class = 'LOCATION';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];
            cycleLastDate = dataJuld;

            evt = get_pfv2_tech_event_data_init_struct(700001);
            evt.class = 'LOCATION';
            evt.label = 'Latitude';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700002);
            evt.class = 'LOCATION';
            evt.label = 'Longitude';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = sprintf('%.3f', data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700003);
            evt.class = 'LOCATION';
            evt.label = 'Number of satellites';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700004);
            evt.class = 'LOCATION';
            evt.label = 'Valid fix';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700005);
            evt.class = 'LOCATION';
            evt.label = 'Clock drift (sec)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700006);
            evt.class = 'LOCATION';
            evt.label = 'Session duration (sec)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            [lat, curByte] = get_bytes_pfv2(dataIn, curByte, 5);

            [lon, curByte] = get_bytes_pfv2(dataIn, curByte, 5);

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LOCATION';
            dataStruct.techId = 700000;
            dataStruct.measCode = g_MC_Surface;
            dataStruct.julD = dataJuld;
            dataStruct.lat = lat;
            dataStruct.lon = lon;
            tabTraj = [tabTraj dataStruct];
            cycleLastDate = dataJuld;

            % moved to TECH_TIME
            % dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'LOCATION: Number of satellites';
            % dataStruct.techId = 700003;
            % [nbSat, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            % dataStruct.value = num2str(nbSat);
            % tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LOCATION: Number of satellites';
            dataStruct.techId = 700007;
            [nbSat, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = nbSat;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_Surface;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LOCATION: Valid fix';
            dataStruct.techId = 700004;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_Surface;
            tabTechTime = [tabTechTime dataStruct];

            % moved to TECH_TIME
            % dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'LOCATION: Clock drift (sec)';
            % dataStruct.techId = 700005;
            % [clockOffset, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            % dataStruct.value = num2str(clockOffset);
            % tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LOCATION: Clock drift (sec)';
            dataStruct.techId = 700008;
            [clockOffset, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = clockOffset;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_Surface;
            tabTechTime = [tabTechTime dataStruct];

            % moved to TECH_TIME
            % dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            % dataStruct.label = 'LOCATION: Session duration (sec)';
            % dataStruct.techId = 700006;
            % [sessionDuration, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            % dataStruct.value = num2str(sessionDuration);
            % tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LOCATION: Session duration (sec)';
            dataStruct.techId = 700009;
            [sessionDuration, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = sessionDuration;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_Surface;
            tabTechTime = [tabTechTime dataStruct];
         end

      case 7001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(700100);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'End time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700101);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Session duration (sec)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700102);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'SBDI success counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700103);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'SBDI total counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700104);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Remote command accepted counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700105);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Remote command refused counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700106);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Remote command unkown counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700107);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Received files number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700108);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Received size (byte)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700109);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Transmitted files number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700110);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Transmitted size (byte)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700111);
            evt.class = 'LAST SBD IRIDIUM SESSION';
            evt.label = 'Files number in waiting of transmission';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: End time';
            dataStruct.techId = 700100;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Session duration (sec)';
            dataStruct.techId = 700101;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: SBDI success counter';
            dataStruct.techId = 700102;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: SBDI total counter';
            dataStruct.techId = 700103;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Remote command accepted counter';
            dataStruct.techId = 700104;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Remote command refused counter';
            dataStruct.techId = 700105;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Remote command unkown counter';
            dataStruct.techId = 700106;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Received files number';
            dataStruct.techId = 700107;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Received size (byte)';
            dataStruct.techId = 700108;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Transmitted files number';
            dataStruct.techId = 700109;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Transmitted size (byte)';
            dataStruct.techId = 700110;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST SBD IRIDIUM SESSION: Files number in waiting of transmission';
            dataStruct.techId = 700111;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 7002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(700200);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'End time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700201);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Session duration (sec)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700202);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Session number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700203);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Remote command accepted counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700204);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Remote command refused counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700205);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Remote command unkown counter';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700206);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Received files number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700207);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Received size (byte)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700208);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Transmitted files number';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700209);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Transmitted size (byte)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(700210);
            evt.class = 'LAST RUDICS IRIDIUM SESSION';
            evt.label = 'Files number in waiting of transmission';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: End time';
            dataStruct.techId = 700200;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            dataStruct.julD = dataJuld;
            dataStruct.value = datestr(dataJuld + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Session duration (sec)';
            dataStruct.techId = 700201;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Session number';
            dataStruct.techId = 700202;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Remote command accepted counter';
            dataStruct.techId = 700203;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Remote command refused counter';
            dataStruct.techId = 700204;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Remote command unkown counter';
            dataStruct.techId = 700205;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Received files number';
            dataStruct.techId = 700206;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Received size (byte)';
            dataStruct.techId = 700207;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Transmitted files number';
            dataStruct.techId = 700208;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Transmitted size (byte)';
            dataStruct.techId = 700209;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 5);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'LAST RUDICS IRIDIUM SESSION: Files number in waiting of transmission';
            dataStruct.techId = 700210;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            tabTech = [tabTech dataStruct];
         end

      case 8000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(800000);
            evt.class = 'FIRST STABILIZATION';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(800001);
            evt.class = 'FIRST STABILIZATION';
            evt.label = 'Stabilization state';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(800002);
            evt.class = 'FIRST STABILIZATION';
            evt.label = 'Pres (dbar)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            data = data/10;
            evt.valueStr = sprintf('%.1f', data);
            tabEvt = [tabEvt evt];
         else
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'FIRST STABILIZATION: Stabilization state';
            dataStruct.techId = 800001;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            dataStruct.value = data;
            dataStruct.julD = dataJuld;
            dataStruct.measCode = g_MC_FST;
            tabTechTime = [tabTechTime dataStruct];

            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'FIRST STABILIZATION';
            dataStruct.techId = 800000;
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            dataStruct.measCode = g_MC_FST;
            dataStruct.julD = dataJuld;
            dataStruct.pres = pres;
            tabTraj = [tabTraj dataStruct];
         end

      case 8001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(800100);
            evt.class = 'PRESSURE MONITORING';
            evt.label = 'Time, Pres (dbar)';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            evt.valueStr = sprintf('%s;%.1f', julian_2_gregorian_dec_argo(dataJuld), pres);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_traj_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PRESSURE MONITORING';
            dataStruct.techId = 8000100;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            dataStruct.julD = dataJuld;
            dataStruct.pres = pres;
            tabSpy = [tabSpy dataStruct];
         end

      case 8002
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(800200);
            evt.class = 'PUMP ACTION';
            evt.label = 'Time, Pres (dbar), Oil (cm3)';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            [oil, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            oil = oil/10;
            evt.valueStr = sprintf('%s;%.1f;%.1f', julian_2_gregorian_dec_argo(dataJuld), pres, oil);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_buoy_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'PUMP ACTION: Time, Pres (dbar), Oil (cm3)';
            dataStruct.techId = 800200;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            [oil, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            oil = oil/10;
            dataStruct.julD = dataJuld;
            dataStruct.pres = pres;
            dataStruct.oil = oil;
            tabBuoy = [tabBuoy dataStruct];
         end

      case 8003
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(800300);
            evt.class = 'EV ACTION';
            evt.label = 'Time, Pres (dbar), Oil (cm3)';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            [oil, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            oil = oil/10;
            evt.valueStr = sprintf('%s;%.1f;%.1f', julian_2_gregorian_dec_argo(dataJuld), pres, oil);
            tabEvt = [tabEvt evt];
         else
            dataStruct = get_pfv2_buoy_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = 'EV ACTION: Time, Pres (dbar), Oil (cm3)';
            dataStruct.techId = 800300;
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            [pres, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            pres = pres/10;
            [oil, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            oil = oil/10;
            dataStruct.julD = dataJuld;
            dataStruct.pres = pres;
            dataStruct.oil = oil;
            tabBuoy = [tabBuoy dataStruct];
         end

      case 9000
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(900000);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900001);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Sensor number (1:SBE41, 2:AANDERAA4330, 3:RBR)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900002);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Phase number (0:descent to park, 2:descent to prof, 4:ascent)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900003);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone1: number of samples';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900004);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone1: treatment type (0x00:raw, 0x80:raw decimated, 0x81:average decimated)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = ['0x' dec2hex(data)];
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900005);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone2: number of samples';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900006);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone2: treatment type (0x00:raw, 0x80:raw decimated, 0x81:average decimated)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = ['0x' dec2hex(data)];
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900007);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone3: number of samples';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900008);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone3: treatment type (0x00:raw, 0x80:raw decimated, 0x81:average decimated)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = ['0x' dec2hex(data)];
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900009);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone4: number of samples';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900010);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone4: treatment type (0x00:raw, 0x80:raw decimated, 0x81:average decimated)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = ['0x' dec2hex(data)];
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900011);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone5: number of samples';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900012);
            evt.class = 'PROFILE SAMPLES PROCESSED';
            evt.label = 'Zone5: treatment type (0x00:raw, 0x80:raw decimated, 0x81:average decimated)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = ['0x' dec2hex(data)];
            tabEvt = [tabEvt evt];
         else
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);

            [sensorNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            switch (sensorNum)
               case {1, 3}
                  shortSensorName = 'Ctd';
               case {2}
                  shortSensorName = 'Optode';
            end

            [phaseNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            switch (phaseNum)
               case {0} % descent to park
                  phaseName = 'descent to park';
                  techId = 900013;
               case {2} % descent to prof
                  phaseName = 'descent to prof';
                  techId = 900014;
               case {4} % ascent
                  phaseName = 'ascent';
                  techId = 900015;
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('PROFILE SAMPLES PROCESSED: Zone1: number of samples for sensor ''%s'' during %s', shortSensorName, phaseName);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            dataStruct.phaseNum = phaseNum;
            dataStruct.depthZoneNum = 1;
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 1);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('PROFILE SAMPLES PROCESSED: Zone2: number of samples for sensor ''%s'' during %s', shortSensorName, phaseName);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            dataStruct.phaseNum = phaseNum;
            dataStruct.depthZoneNum = 2;
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 1);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('PROFILE SAMPLES PROCESSED: Zone3: number of samples for sensor ''%s'' during %s', shortSensorName, phaseName);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            dataStruct.phaseNum = phaseNum;
            dataStruct.depthZoneNum = 3;
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 1);

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('PROFILE SAMPLES PROCESSED: Zone4: number of samples for sensor ''%s'' during %s', shortSensorName, phaseName);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            dataStruct.phaseNum = phaseNum;
            dataStruct.depthZoneNum = 4;
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            
            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('PROFILE SAMPLES PROCESSED: Zone5: number of samples for sensor ''%s'' during %s', shortSensorName, phaseName);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            dataStruct.phaseNum = phaseNum;
            dataStruct.depthZoneNum = 5;
            tabTech = [tabTech dataStruct];

            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
         end

      case 9001
         if (~isempty(g_decArgo_outputCsvFileId))
            evt = get_pfv2_tech_event_data_init_struct(900100);
            evt.class = 'DRIFT SAMPLES PROCESSED';
            evt.label = 'Time';
            [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
            dataJuld = epoch2000_2_julian(dataEpoch);
            evt.valueStr = julian_2_gregorian_dec_argo(dataJuld);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900101);
            evt.class = 'DRIFT SAMPLES PROCESSED';
            evt.label = 'Sensor number (1:SBE41, 2:AANDERAA4330, 3:RBR)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900102);
            evt.class = 'DRIFT SAMPLES PROCESSED';
            evt.label = 'Phase number (1:park drift, 3:deep park drift, 5:surface)';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];

            evt = get_pfv2_tech_event_data_init_struct(900103);
            evt.class = 'DRIFT SAMPLES PROCESSED';
            evt.label = 'Number of samples';
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            evt.valueStr = num2str(data);
            tabEvt = [tabEvt evt];
         else
            [~, curByte] = get_bytes_pfv2(dataIn, curByte, 4);

            [sensorNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            switch (sensorNum)
               case {1, 3}
                  shortSensorName = 'Ctd';
               case {2}
                  shortSensorName = 'Optode';
            end

            [phaseNum, curByte] = get_bytes_pfv2(dataIn, curByte, 1);
            switch (phaseNum)
               case {1} % park drift
                  phaseName = 'park drift';
                  techId = 900104;
               case {3} % deep park drift
                  phaseName = 'deep park drift';
                  techId = 900105;
               case {5} % surface drift
                  phaseName = 'surface drift';
                  techId = 900106;
            end

            dataStruct = get_pfv2_tech_data_init_struct(fileType, missionNum, cycleNum);
            dataStruct.label = sprintf('DRIFT SAMPLES PROCESSED: number of samples for sensor ''%s'' during %s', shortSensorName, phaseName);
            dataStruct.techId = techId;
            [data, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
            dataStruct.value = num2str(data);
            dataStruct.sensorNum = sensorNum;
            dataStruct.shortSensorName = shortSensorName;
            dataStruct.phaseNum = phaseNum;
            tabTech = [tabTech dataStruct];
         end

      otherwise
         fprintf('ERROR: Float #%d: Event #%d (from file ''%s'') not implemented yet\n', ...
            g_decArgo_floatNum, ...
            evtNum, a_fileName);
         break
   end
end

if (~isempty(g_decArgo_outputCsvFileId))
   tabEvtNum = unique(tabEvtNum);
   notCheckedEvtNum = get_not_checked_evt(tabEvtNum);
   if (~isempty(notCheckedEvtNum))
      fprintf('WARNING: Float #%d: Decoding of following event numbers has not been checked yet:', ...
         g_decArgo_floatNum);
      fprintf(' %d', notCheckedEvtNum);
      fprintf('\n');
   end
end

reportedDate = nan;
if (fileType == 10)
   reportedDate = selfTestDate;
elseif (fileType > 11) % tech #2 and EOL
   reportedDate = cycleLastDate;
end

o_techData = [fileType missionNum cycleNum {a_fileName} reportedDate {nan} {nan} {nan} {nan} {nan} {''}];
if (~isempty(g_decArgo_outputCsvFileId))
   o_techData{6} = tabEvt;
else
   o_techData{6} = tabTech;
   o_techData{7} = tabTechTime;
   o_techData{8} = tabTraj;
   o_techData{9} = tabBuoy;
   o_techData{10} = tabSpy;
end

return

% ------------------------------------------------------------------------------
% Retrieve the event numbers that are not already checked (from the decoding
% consistency point of view).
%
% SYNTAX :
% [o_notChecked] = get_not_checked_evt(a_evtNumList)
%
% INPUT PARAMETERS :
%   a_evtNumList : input list of event numbers
%
% OUTPUT PARAMETERS :
%   o_notChecked : output list of not already checked event numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/16/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_notCheckedNumList] = get_not_checked_evt(a_evtNumList)

notCheckedList = [ ...
   1002 ...
   1003 ...
   1020 ...
   1021 ...
   2001 ...
   2002 ...
   2003 ...
   2004 ...
   2005 ...
   2006 ...
   3002 ...
   3003 ...
   3004 ...
   3005 ...
   3006 ...
   5002 ...
   6003 ...
   6106 ...
   7002 ...
   ];

o_notCheckedNumList = intersect(a_evtNumList, notCheckedList);

return

% ------------------------------------------------------------------------------
% Retrieve the explanation of and alarm without value from its type.
%
% SYNTAX :
% [o_alarmExplanation] = get_alarm_without_value_explanation(a_alarmType)
%
% INPUT PARAMETERS :
%   a_alarmType : type of the alarm
%
% OUTPUT PARAMETERS :
%   o_alarmExplanation : explanation of the alarm
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/16/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_alarmExplanation] = get_alarm_without_value_explanation(a_alarmType)

o_alarmExplanation = '';

% current float WMO number
global g_decArgo_floatNum;


switch (a_alarmType)
   case 11
      o_alarmExplanation = 'External pressure sensor - No pressure information';
   case 12
      o_alarmExplanation = 'Barometer sensor';
   case 13
      o_alarmExplanation = 'Failure on initialization of SBE41 reset offset';
   case 14
      o_alarmExplanation = 'Failure on initialization of SBE41 cut-off';
   case 15
      o_alarmExplanation = 'Error system';
   case 18
      o_alarmExplanation = 'Rescue';
   case 19
      o_alarmExplanation = 'GNSS';
   case 20
      o_alarmExplanation = 'RTC';
   case 22
      o_alarmExplanation = 'DO Aanderaa4330 sensor';
   case 23
      o_alarmExplanation = 'Invalid setting of mission';
   case 24
      o_alarmExplanation = 'Invalid setting of sensor';
   case 25
      o_alarmExplanation = 'Invalid setting of CTD sensor';
   case 26
      o_alarmExplanation = 'Empty ballast sensor';
   case 27
      o_alarmExplanation = 'Flash memory';
   case 28
      o_alarmExplanation = 'SDCard memory';
   case 31
      o_alarmExplanation = 'Ice - Satellite mask';
   case 32
      o_alarmExplanation = 'Clock drift';
   case 33
      o_alarmExplanation = 'CTD SBE41 sensor';
   case 34
      o_alarmExplanation = 'CTD RBR sensor';
   case 35
      o_alarmExplanation = 'CTD RBR reset offset';
   otherwise
      fprintf('ERROR: Float #%d: Unexpected alarm type (%d) for alarm without value information', ...
         g_decArgo_floatNum, ...
         a_alarmType);
end

return

% ------------------------------------------------------------------------------
% Retrieve the explanation of and alarm with value from its type.
%
% SYNTAX :
% [o_alarmExplanation] = get_alarm_with_value_explanation(a_alarmType)
%
% INPUT PARAMETERS :
%   a_alarmType : type of the alarm
%
% OUTPUT PARAMETERS :
%   o_alarmExplanation : explanation of the alarm
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/16/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_alarmExplanation] = get_alarm_with_value_explanation(a_alarmType)

o_alarmExplanation = '';

% current float WMO number
global g_decArgo_floatNum;


switch (a_alarmType)
   case 0
      o_alarmExplanation = 'Low battery voltage';
   case 1
      o_alarmExplanation = 'Low external pressure';
   case 2
      o_alarmExplanation = 'High external pressure';
   case 3
      o_alarmExplanation = 'Low internal pressure';
   case 4
      o_alarmExplanation = 'High internal pressure';
   case 5
      o_alarmExplanation = 'Low internal temperature';
   case 6
      o_alarmExplanation = 'High internal temperature';
   case 7
      o_alarmExplanation = 'Low internal humidity';
   case 8
      o_alarmExplanation = 'High internal humidity';
   case 9
      o_alarmExplanation = 'Gap on external pressure';
   case 10
      o_alarmExplanation = 'High speed of descent';
   case 16
      o_alarmExplanation = 'Grounding - Volume max reached';
   case 21
      o_alarmExplanation = 'Insulation voltage';
   case 29
      o_alarmExplanation = 'Hanging - Volume max reached';
   case 30
      o_alarmExplanation = 'ISA detection - Number max of detection reached';
   otherwise
      fprintf('ERROR: Float #%d: Unexpected alarm type (%d) for alarm with value information', ...
         g_decArgo_floatNum, ...
         a_alarmType);
end

return
