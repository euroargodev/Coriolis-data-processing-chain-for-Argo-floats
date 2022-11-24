% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received).
%
% SYNTAX :
%  [o_completed, o_cycleProf] = is_buffer_completed_ir_rudics_cts4_105_to_110
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_completed : buffer completed flag (1 if the data can be processed, 0
%   otherwise)
%   o_cycleProf : cycle and profiles data in the completed buffer
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed, o_cycleProf] = is_buffer_completed_ir_rudics_cts4_105_to_110

% output parameters initialization
o_completed = 0;
o_cycleProf = [];

% arrays to store rough information on received data
global g_decArgo_0TypeReceivedData;
global g_decArgo_250TypeReceivedData;
global g_decArgo_253TypeReceivedData;

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

% at least one packet of each type
if (~isempty(g_decArgo_0TypeReceivedData) && ...
      ~isempty(g_decArgo_250TypeReceivedData) && ...
      ~isempty(g_decArgo_253TypeReceivedData))
   
   % collect the possible cycle and profile mixing
   cycleProf = g_decArgo_0TypeReceivedData(:, 2:3);
   cycleProf = [cycleProf; ...
      g_decArgo_250TypeReceivedData(:, 2:3)];
   cycleProf = unique(cycleProf, 'rows');
   
   % collect the possible sensor numbers
   lut = [0 0 0 1 1 1 -1 -1 -1 3 3 3 2 2 2 4 4 4 5 5 5 6 6 6 6 6];
   zeroTypeReceivedData = g_decArgo_0TypeReceivedData;
   zeroTypeReceivedData(:, 1) = lut(zeroTypeReceivedData(:, 1)+1);
   sensorNum = unique([zeroTypeReceivedData(:, 1); g_decArgo_250TypeReceivedData(:, 1)]);
   
   % process each expected cycles and profiles
   for idM = 1:size(cycleProf, 1)
      expCy = cycleProf(idM, 1);
      expProf = cycleProf(idM, 2);

      % expecting one 253 type packet with phase #12 for each profile of each
      % cycle
      id253Phase = find(g_decArgo_253TypeReceivedData(:, 3) == g_decArgo_phaseSatTrans);
      if (isempty(id253Phase))
         return;
      else
         id253PhaseCyProf = find( ...
            (g_decArgo_253TypeReceivedData(id253Phase, 1) == expCy) & ...
            (g_decArgo_253TypeReceivedData(id253Phase, 2) == expProf), 1);
         if (isempty(id253PhaseCyProf))
            return;
         end
      end
      
      % for each sensor check the transmitted/received number of packets
      for idS = 1:length(sensorNum)
         
         % transmitted number of packets
         id250SensorCycProf = find( ...
            (g_decArgo_250TypeReceivedData(:, 1) == sensorNum(idS)) & ...
            (g_decArgo_250TypeReceivedData(:, 2) == expCy) & ...
            (g_decArgo_250TypeReceivedData(:, 3) == expProf));
         if (isempty(id250SensorCycProf))
            return;
         else
            nbTransDesc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 4);
            nbTransDrift = g_decArgo_250TypeReceivedData(id250SensorCycProf, 5);
            nbTransAsc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 6);            
         end
         
         % received number of packets
         id0SensorCycleProfDesc = find( ...
            (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
            (zeroTypeReceivedData(:, 2) == expCy) & ...
            (zeroTypeReceivedData(:, 3) == expProf) & ...
            ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prk) | ...
            (zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prof)));
         if (isempty(id0SensorCycleProfDesc) && (nbTransDesc >0))
            return;
         elseif (length(id0SensorCycleProfDesc) ~= nbTransDesc)
            return;
         end
         id0SensorCycleProfDrift = find( ...
            (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
            (zeroTypeReceivedData(:, 2) == expCy) & ...
            (zeroTypeReceivedData(:, 3) == expProf) & ...
            ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseParkDrift) | ...
            (zeroTypeReceivedData(:, 4) == g_decArgo_phaseProfDrift)));
         if (isempty(id0SensorCycleProfDrift) && (nbTransDrift >0))
            return;
         elseif (length(id0SensorCycleProfDrift) ~= nbTransDrift)
            return;
         end
         id0SensorCycleProfAsc = find( ...
            (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
            (zeroTypeReceivedData(:, 2) == expCy) & ...
            (zeroTypeReceivedData(:, 3) == expProf) & ...
            (zeroTypeReceivedData(:, 4) == g_decArgo_phaseAscProf));
         if (isempty(id0SensorCycleProfAsc) && (nbTransAsc >0))
            return;
         elseif (length(id0SensorCycleProfAsc) ~= nbTransAsc)
            return;
         end
         
      end
   end
   
   % the buffer is complete
   o_completed = 1;
   o_cycleProf = cycleProf;

elseif (~isempty(g_decArgo_250TypeReceivedData) && ...
      ~isempty(g_decArgo_253TypeReceivedData))
   
   % if the float didn't sample any data
   
   % collect the possible cycle and profile mixing
   cycleProf = g_decArgo_250TypeReceivedData(:, 2:3);
   cycleProf = unique(cycleProf, 'rows');
   
   % retrieve sensor numbers from configuration
   sensorNum = g_decArgo_sensorList;
   
   % process each expected cycles and profiles
   for idM = 1:size(cycleProf, 1)
      expCy = cycleProf(idM, 1);
      expProf = cycleProf(idM, 2);
      
      % expecting one 253 type packet with phase #12 for each profile of each
      % cycle
      id253Phase = find(g_decArgo_253TypeReceivedData(:, 3) == g_decArgo_phaseSatTrans);
      if (isempty(id253Phase))
         return;
      else
         id253PhaseCyProf = find( ...
            (g_decArgo_253TypeReceivedData(id253Phase, 1) == expCy) & ...
            (g_decArgo_253TypeReceivedData(id253Phase, 2) == expProf), 1);
         if (isempty(id253PhaseCyProf))
            return;
         end
      end
      
      % check that all sensors have not sampled any data
      for idS = 1:length(sensorNum)
         
         % transmitted number of packets
         id250SensorCycProf = find( ...
            (g_decArgo_250TypeReceivedData(:, 1) == sensorNum(idS)) & ...
            (g_decArgo_250TypeReceivedData(:, 2) == expCy) & ...
            (g_decArgo_250TypeReceivedData(:, 3) == expProf));
         if (isempty(id250SensorCycProf))
            return;
         else
            nbTransDesc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 4);
            nbTransDrift = g_decArgo_250TypeReceivedData(id250SensorCycProf, 5);
            nbTransAsc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 6);
            if (~isempty(find([nbTransDesc nbTransDrift nbTransAsc] ~= 0, 1)))
               return;
            end
         end
         
      end
   end
   
   % the buffer is complete
   o_completed = 1;
   o_cycleProf = cycleProf;
   g_decArgo_noDataFlag = 1;
   
end

return;
