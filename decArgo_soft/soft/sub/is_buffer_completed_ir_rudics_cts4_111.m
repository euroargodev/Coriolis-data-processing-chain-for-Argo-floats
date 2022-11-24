% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received).
%
% SYNTAX :
%  [o_completed, o_cycleProf, o_cycleInfoStr] = is_buffer_completed_ir_rudics_cts4_111
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_completed    : buffer completed flag (1 if the data can be processed, 0
%                    otherwise)
%   o_cycleProf    : cycle and profiles data in the completed buffer
%   o_cycleInfoStr : information on the completed buffer
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed, o_cycleProf, o_cycleInfoStr] = is_buffer_completed_ir_rudics_cts4_111

% output parameters initialization
o_completed = 0;
o_cycleProf = [];
o_cycleInfoStr = '';

% current float WMO number
global g_decArgo_floatNum;

% arrays to store rough information on received data
global g_decArgo_0TypeReceivedData;
global g_decArgo_250TypeReceivedData;
global g_decArgo_253TypeReceivedData;
global g_decArgo_248TypeReceivedData;
global g_decArgo_249TypeReceivedData;
global g_decArgo_254TypeReceivedData;
global g_decArgo_255TypeReceivedData;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% phase of received data
global g_decArgo_receivedDataPhase;

% no sampled data mode
global g_decArgo_noDataFlag;
g_decArgo_noDataFlag = 0;


if (~isempty(g_decArgo_253TypeReceivedData) && ...
      any(g_decArgo_253TypeReceivedData(:, 3) == g_decArgo_phaseSatTrans))
   
   g_decArgo_receivedDataPhase = g_decArgo_phaseSatTrans;
   
   % transmission after a deep cycle
   % we expect, for each cycle and profile:
   % - one float technical packet (253) with phase g_decArgo_phaseSatTrans (#12)
   % - one sensor technical packet (250) for each sensor
   % - as many measurements (0) as mentionned in the sensor technical packet
   
   if (isempty(g_decArgo_250TypeReceivedData))
      return;
   end
   
   % collect the possible cycle and profile mixing couples
   cycleProf = [];
   cycleProfConfig = [];
   cycleProf = [cycleProf; ...
      g_decArgo_253TypeReceivedData(:, 1:2)];
   cycleProf = [cycleProf; ...
      g_decArgo_250TypeReceivedData(:, 2:3)];
   if (~isempty(g_decArgo_0TypeReceivedData))
      cycleProf = [cycleProf; ...
         g_decArgo_0TypeReceivedData(:, 2:3)];
   end
   if (~isempty(g_decArgo_248TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_248TypeReceivedData(:, 1:2)];
   end
   if (~isempty(g_decArgo_249TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_249TypeReceivedData(:, 1:2)];
   end
   if (~isempty(g_decArgo_254TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_254TypeReceivedData(:, 1:2)];
   end
   if (~isempty(g_decArgo_255TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_255TypeReceivedData(:, 1:2)];
   end
   cycleProfConfig = unique(cycleProfConfig, 'rows');
   cycleProf = unique([cycleProf; cycleProfConfig], 'rows');
   
   % collect the possible sensor numbers
   % to improve robustness, this list is created from received data, not from
   % float meta-data (sensor mounted on float)
   sensorNum = [];
   sensorNum = [sensorNum g_decArgo_250TypeReceivedData(:, 1)'];
   if (~isempty(g_decArgo_0TypeReceivedData))
      lut = [0 0 0 1 1 1 3 3 3 3 3 3 2 2 2 4 4 4 5 5 5 6 6 6 6 6];
      zeroTypeReceivedData = g_decArgo_0TypeReceivedData;
      zeroTypeReceivedData(:, 1) = lut(zeroTypeReceivedData(:, 1)+1);
      sensorNum = [sensorNum zeroTypeReceivedData(:, 1)'];
   end
   if (~isempty(g_decArgo_249TypeReceivedData))
      sensorNum = [sensorNum g_decArgo_249TypeReceivedData(:, 4)'];
   end
   sensorNum = unique(sensorNum);
   
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
         
         % get expected number of packets
         id250SensorCycProf = find( ...
            (g_decArgo_250TypeReceivedData(:, 1) == sensorNum(idS)) & ...
            (g_decArgo_250TypeReceivedData(:, 2) == expCy) & ...
            (g_decArgo_250TypeReceivedData(:, 3) == expProf));
         if (isempty(id250SensorCycProf))
            return;
         else
            if (~isempty(g_decArgo_0TypeReceivedData))
               nbTransDesc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 4);
               nbTransDrift = g_decArgo_250TypeReceivedData(id250SensorCycProf, 5);
               nbTransAsc = g_decArgo_250TypeReceivedData(id250SensorCycProf, 6);
               if (sensorNum(idS) == 2)
                  % packet type 250 is transmitted twice for OCR sensor (to get
                  % calibration coefficients with good resolution)
                  if (length(unique(nbTransDesc')) == 1)
                     nbTransDesc = nbTransDesc(1);
                  end
                  if (length(unique(nbTransDrift')) == 1)
                     nbTransDrift = nbTransDrift(1);
                  end
                  if (length(unique(nbTransAsc')) == 1)
                     nbTransAsc = nbTransAsc(1);
                  end
               end
               
               %                % ANOMALY MANAGEMENT
               %                % the sensor TECH packets could be erroneously transmitted more
               %                % than one (Ex: float 2902243 cycle #29 profile #0)
               %                nbTransDescSize = 1;
               %                if (size(nbTransDesc, 1) > 1)
               %                   if (length(unique(nbTransDesc')) == 1)
               %                      nbTransDescSize = size(nbTransDesc, 1);
               %                      nbTransDesc = nbTransDesc(1);
               %                   end
               %                end
               %                nbTransDriftSize = 1;
               %                if (size(nbTransDrift, 1) > 1)
               %                   if (length(unique(nbTransDrift')) == 1)
               %                      nbTransDriftSize = size(nbTransDrift, 1);
               %                      nbTransDrift = nbTransDrift(1);
               %                   end
               %                end
               %                nbTransAscSize = 1;
               %                if (size(nbTransAsc, 1) > 1)
               %                   if (length(unique(nbTransAsc')) == 1)
               %                      nbTransAscSize = size(nbTransAsc, 1);
               %                      nbTransAsc = nbTransAsc(1);
               %                   end
               %                end
               %                if ((nbTransDescSize > 1) && (nbTransDescSize == nbTransDriftSize) && (nbTransDriftSize == nbTransAscSize))
               %                   fprintf('BUFF_WARNING: Float #%d: msg type 250 received %d times (%d expected)\n', ...
               %                      g_decArgo_floatNum, nbTransDescSize, 1);
               %                end
            else
               nbTransDesc = 0;
               nbTransDrift = 0;
               nbTransAsc = 0;
            end
         end
         
         % check received number of packets
         % for descent profile phase
         id0SensorCycleProfDesc = [];
         if (~isempty(g_decArgo_0TypeReceivedData))
            id0SensorCycleProfDesc = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prk) | ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseDsc2Prof)));
         end
         if (isempty(id0SensorCycleProfDesc) && (nbTransDesc >0))
            return;
         elseif (length(id0SensorCycleProfDesc) ~= nbTransDesc)
            return;
         end
         % for drift phase
         id0SensorCycleProfDrift = [];
         if (~isempty(g_decArgo_0TypeReceivedData))
            id0SensorCycleProfDrift = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               ((zeroTypeReceivedData(:, 4) == g_decArgo_phaseParkDrift) | ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseProfDrift)));
         end
         if (isempty(id0SensorCycleProfDrift) && (nbTransDrift >0))
            return;
         elseif (length(id0SensorCycleProfDrift) ~= nbTransDrift)
            return;
         end
         % for ascent profile phase
         id0SensorCycleProfAsc = [];
         if (~isempty(g_decArgo_0TypeReceivedData))
            id0SensorCycleProfAsc = find( ...
               (zeroTypeReceivedData(:, 1) == sensorNum(idS)) & ...
               (zeroTypeReceivedData(:, 2) == expCy) & ...
               (zeroTypeReceivedData(:, 3) == expProf) & ...
               (zeroTypeReceivedData(:, 4) == g_decArgo_phaseAscProf));
         end
         if (isempty(id0SensorCycleProfAsc) && (nbTransAsc >0))
            return;
         elseif (length(id0SensorCycleProfAsc) ~= nbTransAsc)
            return;
         end
      end
      
      % if at least one cofiguration message (type 248, 249, 254 or 255) has
      % been received for this cycle and profile all configuration messages are
      % expected to be also received
      if (~isempty(cycleProfConfig))
         idCyProfConfig = find( ...
            (cycleProfConfig(:, 1) == expCy) & ...
            (cycleProfConfig(:, 2) == expProf), 1);
         if (~isempty(idCyProfConfig))
            if (isempty(g_decArgo_248TypeReceivedData))
               return;
            else
               id248SensorCycProf = find( ...
                  (g_decArgo_248TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_248TypeReceivedData(:, 2) == expProf));
               if (length(id248SensorCycProf) ~= 1)
                  if (length(id248SensorCycProf) > 1)
                     fprintf('BUFF_WARNING: Float #%d: msg type 248 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id248SensorCycProf), 1);
                  end
               end
            end
            if (isempty(g_decArgo_249TypeReceivedData))
               return;
            else
               id249SensorCycProf = find( ...
                  (g_decArgo_249TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_249TypeReceivedData(:, 2) == expProf));
               if (length(id249SensorCycProf) ~= 2*length(sensorNum))
                  if (length(id249SensorCycProf) > 2*length(sensorNum))
                     fprintf('BUFF_WARNING: Float #%d: msg type 249 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id249SensorCycProf), 2*length(sensorNum));
                  end
               end
            end
            if (isempty(g_decArgo_254TypeReceivedData))
               return;
            else
               id254SensorCycProf = find( ...
                  (g_decArgo_254TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_254TypeReceivedData(:, 2) == expProf));
               if (length(id254SensorCycProf) ~= 1)
                  if (length(id254SensorCycProf) > 1)
                     fprintf('BUFF_WARNING: Float #%d: msg type 254 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id254SensorCycProf), 1);
                  end
               end
            end
            if (isempty(g_decArgo_255TypeReceivedData))
               return;
            else
               id255SensorCycProf = find( ...
                  (g_decArgo_255TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_255TypeReceivedData(:, 2) == expProf));
               if (length(id255SensorCycProf) ~= 1)
                  if (length(id255SensorCycProf) > 1)
                     fprintf('BUFF_WARNING: Float #%d: msg type 255 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id255SensorCycProf), 1);
                  end
               end
            end
         end
      end
   end
   
   % the buffer is complete
   o_completed = 1;
   o_cycleProf = cycleProf;
   if (~isempty(g_decArgo_0TypeReceivedData))
      if (isempty(cycleProfConfig))
         o_cycleInfoStr = '(DEEP CYCLE)';
      else
         o_cycleInfoStr = '(DEEP CYCLE - CONFIG)';
      end
   else
      if (isempty(cycleProfConfig))
         o_cycleInfoStr = '(DEEP CYCLE - NO DATA)';
      else
         o_cycleInfoStr = '(DEEP CYCLE - NO DATA - CONFIG)';
      end
   end
   
elseif (~isempty(g_decArgo_253TypeReceivedData) && ...
      any(g_decArgo_253TypeReceivedData(:, 3) == g_decArgo_phasePreMission))
   
   g_decArgo_receivedDataPhase = g_decArgo_phasePreMission;
   
   % prelude cycle
   % we expect:
   % - one float technical packet (253) with phase g_decArgo_phasePreMission (#0)
   % - all configuration packets (248, 249, 254, 255)
   
   if (isempty(g_decArgo_248TypeReceivedData))
      return;
   end
   if (isempty(g_decArgo_249TypeReceivedData))
      return;
   end
   if (isempty(g_decArgo_254TypeReceivedData))
      return;
   end
   if (isempty(g_decArgo_255TypeReceivedData))
      return;
   end
   
   % collect the possible sensor numbers
   sensorNum = g_decArgo_249TypeReceivedData(:, 4)';
   sensorNum = unique(sensorNum);
   
   expCy = 0;
   expProf = 0;
   
   id248SensorCycProf = find( ...
      (g_decArgo_248TypeReceivedData(:, 1) == expCy) & ...
      (g_decArgo_248TypeReceivedData(:, 2) == expProf));
   if (length(id248SensorCycProf) ~= 1)
      if (length(id248SensorCycProf) > 1)
         fprintf('BUFF_WARNING: Float #%d: msg type 248 received %d times (%d expected)\n', ...
            g_decArgo_floatNum, length(id248SensorCycProf), 1);
      end
   end
   id249SensorCycProf = find( ...
      (g_decArgo_249TypeReceivedData(:, 1) == expCy) & ...
      (g_decArgo_249TypeReceivedData(:, 2) == expProf));
   if (length(id249SensorCycProf) ~= 2*length(sensorNum))
      if (length(id249SensorCycProf) > 2*length(sensorNum))
         fprintf('BUFF_WARNING: Float #%d: msg type 249 received %d times (%d expected)\n', ...
            g_decArgo_floatNum, length(id249SensorCycProf), 2*length(sensorNum));
      end
   end
   id254SensorCycProf = find( ...
      (g_decArgo_254TypeReceivedData(:, 1) == expCy) & ...
      (g_decArgo_254TypeReceivedData(:, 2) == expProf));
   if (length(id254SensorCycProf) ~= 1)
      if (length(id254SensorCycProf) > 1)
         fprintf('BUFF_WARNING: Float #%d: msg type 254 received %d times (%d expected)\n', ...
            g_decArgo_floatNum, length(id254SensorCycProf), 1);
      end
   end
   id255SensorCycProf = find( ...
      (g_decArgo_255TypeReceivedData(:, 1) == expCy) & ...
      (g_decArgo_255TypeReceivedData(:, 2) == expProf));
   if (length(id255SensorCycProf) ~= 1)
      if (length(id255SensorCycProf) > 1)
         fprintf('BUFF_WARNING: Float #%d: msg type 255 received %d times (%d expected)\n', ...
            g_decArgo_floatNum, length(id255SensorCycProf), 1);
      end
   end
   
   % the buffer is complete
   o_completed = 1;
   o_cycleProf = g_decArgo_253TypeReceivedData(:, 1:2);
   o_cycleInfoStr = '(PRELUDE CYCLE)';
   g_decArgo_noDataFlag = 1;
   
elseif (~isempty(g_decArgo_253TypeReceivedData) && ...
      any(g_decArgo_253TypeReceivedData(:, 3) == g_decArgo_phaseSurfWait))
   
   g_decArgo_receivedDataPhase = g_decArgo_phaseSurfWait;
   
   % surface cycle
   % we expect:
   % - one float technical packet (253) with phase g_decArgo_phaseSurfWait (#1)
   % - bug of the firmware 3.01: one sensor technical packet (250) for each sensor
   
   if (isempty(g_decArgo_250TypeReceivedData)) % bug of the firmware 3.01 version
      return;
   end
   
   cycleProfConfig = [];
   if (~isempty(g_decArgo_248TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_248TypeReceivedData(:, 1:2)];
   end
   if (~isempty(g_decArgo_249TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_249TypeReceivedData(:, 1:2)];
   end
   if (~isempty(g_decArgo_254TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_254TypeReceivedData(:, 1:2)];
   end
   if (~isempty(g_decArgo_255TypeReceivedData))
      cycleProfConfig = [cycleProfConfig; ...
         g_decArgo_255TypeReceivedData(:, 1:2)];
   end
   cycleProfConfig = unique(cycleProfConfig, 'rows');
   
   % collect the possible sensor numbers
   sensorNum = g_decArgo_250TypeReceivedData(:, 1)';
   sensorNum = unique(sensorNum);
   
   % check that one tech packet has been received for each sensor
   for idS = 1:length(sensorNum)
      if (~any(g_decArgo_250TypeReceivedData(:, 1) == sensorNum(idS)))
         return;
      end
   end
   
   % process each expected cycles and profiles
   if (~isempty(cycleProfConfig))
      for idM = 1:size(cycleProfConfig, 1)
         expCy = cycleProfConfig(idM, 1);
         expProf = cycleProfConfig(idM, 2);
         
         % if at least one cofiguration message (type 248, 249, 254 or 255) has
         % been received for this cycle and profile all configuration messages are
         % expected to be also received
         idCyProfConfig = find( ...
            (cycleProfConfig(:, 1) == expCy) & ...
            (cycleProfConfig(:, 2) == expProf), 1);
         if (~isempty(idCyProfConfig))
            if (isempty(g_decArgo_248TypeReceivedData))
               return;
            else
               id248SensorCycProf = find( ...
                  (g_decArgo_248TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_248TypeReceivedData(:, 2) == expProf));
               if (length(id248SensorCycProf) ~= 1)
                  if (length(id248SensorCycProf) > 1)
                     fprintf('BUFF_WARNING: Float #%d: msg type 248 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id248SensorCycProf), 1);
                  end
               end
            end
            if (isempty(g_decArgo_249TypeReceivedData))
               return;
            else
               id249SensorCycProf = find( ...
                  (g_decArgo_249TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_249TypeReceivedData(:, 2) == expProf));
               if (length(id249SensorCycProf) ~= 2*length(sensorNum))
                  if (length(id249SensorCycProf) > 2*length(sensorNum))
                     fprintf('BUFF_WARNING: Float #%d: msg type 249 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id249SensorCycProf), 2*length(sensorNum));
                  end
               end
            end
            if (isempty(g_decArgo_254TypeReceivedData))
               return;
            else
               id254SensorCycProf = find( ...
                  (g_decArgo_254TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_254TypeReceivedData(:, 2) == expProf));
               if (length(id254SensorCycProf) ~= 1)
                  if (length(id254SensorCycProf) > 1)
                     fprintf('BUFF_WARNING: Float #%d: msg type 254 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id254SensorCycProf), 1);
                  end
               end
            end
            if (isempty(g_decArgo_255TypeReceivedData))
               return;
            else
               id255SensorCycProf = find( ...
                  (g_decArgo_255TypeReceivedData(:, 1) == expCy) & ...
                  (g_decArgo_255TypeReceivedData(:, 2) == expProf));
               if (length(id255SensorCycProf) ~= 1)
                  if (length(id255SensorCycProf) > 1)
                     fprintf('BUFF_WARNING: Float #%d: msg type 255 received %d times (%d expected)\n', ...
                        g_decArgo_floatNum, length(id255SensorCycProf), 1);
                  end
               end
            end
         end
      end
   end
   
   % the buffer is complete
   o_completed = 1;
   o_cycleProf = g_decArgo_253TypeReceivedData(:, 1:2);
   if (isempty(cycleProfConfig))
      o_cycleInfoStr = '(SURFACE CYCLE)';
   else
      o_cycleInfoStr = '(SURFACE CYCLE - CONFIG)';
   end
   g_decArgo_noDataFlag = 1;
   
end

return;
