% ------------------------------------------------------------------------------
% Check and report information on current buffer contents.
%
% SYNTAX :
%  print_buffer_info_ir_sbd2_301
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_buffer_info_ir_sbd2_301

% arrays to store rough information on received data
global g_decArgo_0TypeReceivedData;
global g_decArgo_250TypeReceivedData;
global g_decArgo_251TypeReceivedData;
global g_decArgo_252TypeReceivedData;
global g_decArgo_253TypeReceivedData;
global g_decArgo_254TypeReceivedData;
global g_decArgo_255TypeReceivedData;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% sensor list
global g_decArgo_sensorList;

% no sampled data mode
global g_decArgo_noDataFlag;
g_decArgo_noDataFlag = 0;


fprintf('\n**************************************************************************************************\n');
fprintf('* BUFFER_CHECK: START\n');

if (isempty(g_decArgo_250TypeReceivedData))
   fprintf('* BUFFER_CHECK: No SENSOR TECH packet (250)\n');
end

if (isempty(g_decArgo_253TypeReceivedData))
   fprintf('* BUFFER_CHECK: No VECTOR TECH packet (253)\n');
end

if (isempty(g_decArgo_0TypeReceivedData))
   fprintf('* BUFFER_CHECK: No SENSOR DATA packet (0)\n');
end

if (~isempty(g_decArgo_0TypeReceivedData) || ...
      ~isempty(g_decArgo_250TypeReceivedData))
   
   % collect the possible cycle and profile mixing
   cycleProf = [];
   cpt = 0;
   if (~isempty(g_decArgo_0TypeReceivedData))
      cycleProf = g_decArgo_0TypeReceivedData(:, 2:3);
      cpt = cpt + 1;
   end
   if (~isempty(g_decArgo_250TypeReceivedData))
      cycleProf = [cycleProf; ...
         g_decArgo_250TypeReceivedData(:, 2:3)];
      cpt = cpt + 1;
   end
   cycleProf = unique(cycleProf, 'rows');
   
   if (cpt == 1)
      fprintf('* BUFFER_CHECK: expected CYCLE and PROFILE (possibly uncompleted list!)\n');
   else
      fprintf('* BUFFER_CHECK: expected CYCLE and PROFILE\n');
   end
   for idM = 1:size(cycleProf, 1)
      expCy = cycleProf(idM, 1);
      expProf = cycleProf(idM, 2);
      fprintf('   - (cycle,profile):(%d,%d)\n', expCy, expProf);
   end
   
   sensorNum = g_decArgo_sensorList;
   if (~isempty(g_decArgo_0TypeReceivedData) && ...
         ~isempty(g_decArgo_250TypeReceivedData))
      
      % collect the possible sensor numbers
      lut = [0 0 -1 1 1 -1 4 4];
      zeroTypeReceivedData = g_decArgo_0TypeReceivedData;
      zeroTypeReceivedData(:, 1) = lut(zeroTypeReceivedData(:, 1)+1);
      sensorNum = unique([zeroTypeReceivedData(:, 1); g_decArgo_250TypeReceivedData(:, 1)]);
      
      % compare sansor list from data with meta-data one
      fprintf('* BUFFER_CHECK: SENSOR list check');
      if (~isempty(setdiff(sensorNum, g_decArgo_sensorList)) || ...
            ~isempty(setdiff(g_decArgo_sensorList, sensorNum)))
         fprintf(' => KO\n');
         if (~isempty(setdiff(sensorNum, g_decArgo_sensorList)))
            listStr = '';
            list = setdiff(sensorNum, g_decArgo_sensorList);
            for idS = 1:length(list)
               listStr = [listStr get_sensor_name(list(idS)) ' '];
            end
            fprintf('*   - sensors (%s) are missing in meta-data sensor list\n', listStr(1:end-1));
         end
         if (~isempty(setdiff(g_decArgo_sensorList, sensorNum)))
            listStr = '';
            list = setdiff(g_decArgo_sensorList, sensorNum);
            for idS = 1:length(list)
               listStr = [listStr get_sensor_name(list(idS)) ' '];
            end
            fprintf('*   - sensors (%s) are missing in data sensor list\n', listStr(1:end-1));
         end
      else
         fprintf(' => OK (meta-data and data sensor lists match)\n');
      end
   end
   
   if (~isempty(g_decArgo_253TypeReceivedData))
      
      fprintf('* BUFFER_CHECK: VECTOR TECH check\n');
      
      % expecting one 253 type packet with phase #12 for each profile of each
      % cycle
      for idM = 1:size(cycleProf, 1)
         expCy = cycleProf(idM, 1);
         expProf = cycleProf(idM, 2);
         
         koFlag = 0;
         nb = 0;
         if (~isempty(g_decArgo_253TypeReceivedData))
            id253Phase = find(g_decArgo_253TypeReceivedData(:, 3) == g_decArgo_phaseSatTrans);
            if (isempty(id253Phase))
               koFlag = 1;
            else
               id253PhaseCyProf = find( ...
                  (g_decArgo_253TypeReceivedData(id253Phase, 1) == expCy) & ...
                  (g_decArgo_253TypeReceivedData(id253Phase, 2) == expProf));
               nb = length(id253PhaseCyProf);
               if (nb ~= 1)
                  koFlag = 1;
               end
            end
         else
            koFlag = 1;
         end
         if (koFlag)
            if (nb == 0)
               fprintf('*   - No VECTOR TECH packet for (cycle,profile):(%d,%d)\n', expCy, expProf);
            else
               fprintf('*   - %d VECTOR TECH packets for (cycle,profile):(%d,%d)\n', nb, expCy, expProf);
            end
         end
      end
   end
   
   if (~isempty(g_decArgo_0TypeReceivedData) && ...
         ~isempty(g_decArgo_250TypeReceivedData))
      
      % check that all expected data have been received
      fprintf('* BUFFER_CHECK: DATA check\n');
      
      % process each expected cycles and profiles
      for idM = 1:size(cycleProf, 1)
         expCy = cycleProf(idM, 1);
         expProf = cycleProf(idM, 2);
         
         fprintf('*   - (cycle,profile):(%d,%d)\n', expCy, expProf);
         
         % for each sensor check the transmitted/received number of packets
         for idS = 1:length(sensorNum)
            
            fprintf('*      + sensor %s\n', get_sensor_name(sensorNum(idS)));
            
            % transmitted number of packets
            nbTransDesc = [];
            nbTransDrift = [];
            nbTransAsc = [];
            id250SensorCycProf = find( ...
               (g_decArgo_250TypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (g_decArgo_250TypeReceivedData(:, 2) == expCy) & ...
               (g_decArgo_250TypeReceivedData(:, 3) == expProf));
            if (~isempty(id250SensorCycProf))
               nbTransDesc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 4);
               nbTransDrift = g_decArgo_250TypeReceivedData(id250SensorCycProf, 5);
               nbTransAsc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 6);
            end
            
            % received number of packets
            nbRecDesc = 0;
            nbRecDrift = 0;
            nbRecAsc = 0;
            id0SensorCycleProfDesc = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prk) | ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prof)));
            if (~isempty(id0SensorCycleProfDesc))
               nbRecDesc = rem(length(id0SensorCycleProfDesc), 256);
            end
            id0SensorCycleProfDrift = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseParkDrift) | ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseProfDrift)));
            if (~isempty(id0SensorCycleProfDrift))
               nbRecDrift = rem(length(id0SensorCycleProfDrift), 256);
            end
            id0SensorCycleProfAsc = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseAscProf));
            if (~isempty(id0SensorCycleProfAsc))
               nbRecAsc = rem(length(id0SensorCycleProfAsc), 256);
            end
            
            % DESCENT DATA
            if (~isempty(nbTransDesc) && ~isempty(nbRecDesc))
               if (nbTransDesc > nbRecDesc)
                  fprintf('*          ! KO -> DESCENT DATA: MISSING DATA (%d-%d=%d)\n', ...
                     nbTransDesc, nbRecDesc, nbTransDesc-nbRecDesc);
               elseif (nbTransDesc < nbRecDesc)
                  fprintf('*         ! KO -> DESCENT DATA: TOO MUCH DATA (%d-%d=%d)\n', ...
                     nbTransDesc, nbRecDesc, nbRecDesc-nbTransDesc);
               else
                  fprintf('*         OK -> DESCENT DATA: DATA MATCH (%d=%d)\n', ...
                     nbTransDesc, nbRecDesc);
               end
            else
               if (~isempty(nbTransDesc))
                  fprintf('*         ! KO -> DESCENT DATA: no data received (expected number %d)\n', ...
                     nbTransDesc);
               elseif (~isempty(nbRecDesc))
                  fprintf('*         ! KO -> DESCENT DATA: %d data received (expected number unknown)\n', ...
                     nbRecDesc);
               else
                  fprintf('*         ! KO -> DESCENT DATA: no data received (expected number unknown)\n');
               end
            end
            
            % DRIFT DATA
            if (~isempty(nbTransDrift) && ~isempty(nbRecDrift))
               if (nbTransDrift > nbRecDrift)
                  fprintf('*         ! KO -> DRIFT DATA: MISSING DATA (%d-%d=%d)\n', ...
                     nbTransDrift, nbRecDrift, nbTransDrift-nbRecDrift);
               elseif (nbTransDrift < nbRecDrift)
                  fprintf('*         ! KO -> DRIFT DATA: TOO MUCH DATA (%d-%d=%d)\n', ...
                     nbTransDrift, nbRecDrift, nbRecDrift-nbTransDrift);
               else
                  fprintf('*         OK -> DRIFT DATA: DATA MATCH (%d=%d)\n', ...
                     nbTransDrift, nbRecDrift);
               end
            else
               if (~isempty(nbTransDrift))
                  fprintf('*         ! KO -> DRIFT DATA: no data received (expected number %d)\n', ...
                     nbTransDrift);
               elseif (~isempty(nbRecDrift))
                  fprintf('*         ! KO -> DRIFT DATA: %d data received (expected number unknown)\n', ...
                     nbRecDrift);
               else
                  fprintf('*         ! KO -> DRIFT DATA: no data received (expected number unknown)\n');
               end
            end
            
            % ASCENT DATA
            if (~isempty(nbTransAsc) && ~isempty(nbRecAsc))
               if (nbTransAsc > nbRecAsc)
                  fprintf('*         ! KO -> ASCENT DATA: MISSING DATA (%d-%d=%d)\n', ...
                     nbTransAsc, nbRecAsc, nbTransAsc-nbRecAsc);
               elseif (nbTransAsc < nbRecAsc)
                  fprintf('*         ! KO -> ASCENT DATA: TOO MUCH DATA (%d-%d=%d)\n', ...
                     nbTransAsc, nbRecAsc, nbRecAsc-nbTransAsc);
               else
                  fprintf('*         OK -> ASCENT DATA: DATA MATCH (%d=%d)\n', ...
                     nbTransAsc, nbRecAsc);
               end
            else
               if (~isempty(nbTransAsc))
                  fprintf('*         ! KO -> ASCENT DATA: no data received (expected number %d)\n', ...
                     nbTransAsc);
               elseif (~isempty(nbRecAsc))
                  fprintf('*         ! KO -> ASCENT DATA: %d data received (expected number unknown)\n', ...
                     nbRecAsc);
               else
                  fprintf('*         ! KO -> ASCENT DATA: no data received (expected number unknown)\n');
               end
            end
         end
      end
      
   elseif (~isempty(g_decArgo_0TypeReceivedData))
      
      % collect the possible sensor numbers
      lut = [0 0 -1 1 1 -1 4 4];
      zeroTypeReceivedData = g_decArgo_0TypeReceivedData;
      zeroTypeReceivedData(:, 1) = lut(zeroTypeReceivedData(:, 1)+1);
      
      fprintf('* BUFFER_CHECK: DATA received\n');
      
      % process each expected cycles and profiles
      cycleProf = unique(zeroTypeReceivedData(:, 2:3), 'rows');
      for idM = 1:size(cycleProf, 1)
         expCy = cycleProf(idM, 1);
         expProf = cycleProf(idM, 2);
         
         fprintf('*   - (cycle,profile):(%d,%d)\n', expCy, expProf);
         
         % for each sensor print the number of received number of packets
         for idS = 1:length(sensorNum)
            
            fprintf('*      + sensor %s\n', get_sensor_name(sensorNum(idS)));
            
            % received number of packets
            nbRecDesc = 0;
            nbRecDrift = 0;
            nbRecAsc = 0;
            id0SensorCycleProfDesc = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prk) | ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prof)));
            if (~isempty(id0SensorCycleProfDesc))
               nbRecDesc = rem(length(id0SensorCycleProfDesc), 256);
            end
            id0SensorCycleProfDrift = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseParkDrift) | ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseProfDrift)));
            if (~isempty(id0SensorCycleProfDrift))
               nbRecDrift = rem(length(id0SensorCycleProfDrift), 256);
            end
            id0SensorCycleProfAsc = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseAscProf));
            if (~isempty(id0SensorCycleProfAsc))
               nbRecAsc = rem(length(id0SensorCycleProfAsc), 256);
            end
            
            % DESCENT DATA
            fprintf('*          -> DESCENT DATA: %d\n', ...
               nbRecDesc);
            fprintf('*          -> DRIFT DATA: %d\n', ...
               nbRecDrift);
            fprintf('*          -> ASCENT DATA: %d\n', ...
               nbRecAsc);
         end
      end
   end
end

if (isempty(g_decArgo_250TypeReceivedData) && isempty(g_decArgo_0TypeReceivedData))
   fprintf('* BUFFER_CHECK: Surface cycle with\n');
   
   if (~isempty(g_decArgo_253TypeReceivedData))
      cycleProfPhase = unique(g_decArgo_253TypeReceivedData, 'rows');
      for idM = 1:size(cycleProfPhase, 1)
         expCy = cycleProfPhase(idM, 1);
         expProf = cycleProfPhase(idM, 2);
         expPhase = cycleProfPhase(idM, 3);
         
         idF = find( ...
            (g_decArgo_253TypeReceivedData(:, 1) == expCy) & ...
            (g_decArgo_253TypeReceivedData(:, 2) == expProf) & ...
            (g_decArgo_253TypeReceivedData(:, 3) == expPhase));
         fprintf('*   - %d VECTOR TECH packet(s) for (cycle,profile,phase):(%d,%d,%s)\n', length(idF), expCy, expProf, get_phase_name(expPhase));
      end
   end
   
   if (~isempty(g_decArgo_254TypeReceivedData))
      cycleProf = unique(g_decArgo_254TypeReceivedData, 'rows');
      for idM = 1:size(cycleProf, 1)
         expCy = cycleProf(idM, 1);
         expProf = cycleProf(idM, 2);
         
         idF = find( ...
            (g_decArgo_254TypeReceivedData(:, 1) == expCy) & ...
            (g_decArgo_254TypeReceivedData(:, 2) == expProf));
         fprintf('*   - %d PT TECH packet(s) for (cycle,profile):(%d,%d)\n', length(idF), expCy, expProf);
      end
   end
   
   if (~isempty(g_decArgo_255TypeReceivedData))
      cycleProf = unique(g_decArgo_255TypeReceivedData, 'rows');
      for idM = 1:size(cycleProf, 1)
         expCy = cycleProf(idM, 1);
         expProf = cycleProf(idM, 2);
         
         idF = find( ...
            (g_decArgo_255TypeReceivedData(:, 1) == expCy) & ...
            (g_decArgo_255TypeReceivedData(:, 2) == expProf));
         fprintf('*   - %d PV & PM packet(s) for (cycle,profile):(%d,%d)\n', length(idF), expCy, expProf);
      end
   end
   
   if (~isempty(g_decArgo_251TypeReceivedData))
      fprintf('*   - %d PC SENSOR packet(s)\n', g_decArgo_251TypeReceivedData);
   end
   
   if (~isempty(g_decArgo_252TypeReceivedData))
      cycleProfPhase = unique(g_decArgo_252TypeReceivedData, 'rows');
      for idM = 1:size(cycleProfPhase, 1)
         expCy = cycleProfPhase(idM, 1);
         expProf = cycleProfPhase(idM, 2);
         expPhase = cycleProfPhase(idM, 3);
         
         idF = find( ...
            (g_decArgo_252TypeReceivedData(:, 1) == expCy) & ...
            (g_decArgo_252TypeReceivedData(:, 2) == expProf) & ...
            (g_decArgo_252TypeReceivedData(:, 3) == expPhase));
         fprintf('*   - %d VECTOR PRESSURE packet(s) for (cycle,profile,phase):(%d,%d,%s)\n', length(idF), expCy, expProf, get_phase_name(expPhase));
      end
   end
   
end

fprintf('* BUFFER_CHECK: STOP\n');
fprintf('**************************************************************************************************\n\n');

return

% ------------------------------------------------------------------------------
% Retrieve the name of a provided sensor number.
%
% SYNTAX :
%  [o_sensorName] = get_sensor_name(a_sensorNumber)
%
% INPUT PARAMETERS :
%   a_sensorNumber : sensor number
%
% OUTPUT PARAMETERS :
%   o_sensorName : sensor name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorName] = get_sensor_name(a_sensorNumber)

o_sensorName = '';

switch (a_sensorNumber)
   
   case 0
      o_sensorName = 'CTD';
      
   case 1
      o_sensorName = 'OPTODE';
            
   case 4
      o_sensorName = 'FLBB';
      
   otherwise
      o_sensorName = 'ERROR';
end

return
