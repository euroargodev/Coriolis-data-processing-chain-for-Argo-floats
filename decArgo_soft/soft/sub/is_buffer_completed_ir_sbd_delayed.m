% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received) for a given list of cycle numbers.
%
% SYNTAX :
%  [o_cycleNumberList, o_bufferCompleted] = ...
%    is_buffer_completed_ir_sbd_delayed(a_whyFlag, a_cycleDecodingDoneList, a_decoderId)
%
% INPUT PARAMETERS :
%   a_whyFlag               : print information on incompleted buffers
%   a_cycleDecodingDoneList : list of already decoded cycles
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cycleNumberList : list of cycle numbers data in the buffer
%   o_cycleNumberList : associated list of completed buffer flags
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumberList, o_bufferCompleted] = ...
   is_buffer_completed_ir_sbd_delayed(a_whyFlag, a_cycleDecodingDoneList, a_decoderId)

% output parameters initialization
o_cycleNumberList = [];
o_bufferCompleted = [];

% current float WMO number
global g_decArgo_floatNum;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketExpectedFlag;
global g_decArgo_7TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketExpected;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketExpected;
global g_decArgo_nbOf14Or12TypePacketReceived;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;

% float configuration
global g_decArgo_floatConfig;

% flag to mention that there is only a parameter packet #2 in the buffer
global g_decArgo_processingOnly7TypePacketFlag;
g_decArgo_processingOnly7TypePacketFlag = [];

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {212, 214, 217}
      % Arvor-ARN-Ice Iridium 5.45
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      % adjust the size of the variables
      g_decArgo_0TypePacketReceivedFlag = [g_decArgo_0TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_0TypePacketReceivedFlag))];
      g_decArgo_4TypePacketReceivedFlag = [g_decArgo_4TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_4TypePacketReceivedFlag))];
      g_decArgo_5TypePacketReceivedFlag = [g_decArgo_5TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_5TypePacketReceivedFlag))];
      g_decArgo_nbOf1Or8TypePacketExpected = [g_decArgo_nbOf1Or8TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketExpected))*-1];
      g_decArgo_nbOf1Or8TypePacketReceived = [g_decArgo_nbOf1Or8TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketReceived))];
      g_decArgo_nbOf2Or9TypePacketExpected = [g_decArgo_nbOf2Or9TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketExpected))*-1];
      g_decArgo_nbOf2Or9TypePacketReceived = [g_decArgo_nbOf2Or9TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketReceived))];
      g_decArgo_nbOf3Or10TypePacketExpected = [g_decArgo_nbOf3Or10TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketExpected))*-1];
      g_decArgo_nbOf3Or10TypePacketReceived = [g_decArgo_nbOf3Or10TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketReceived))];
      g_decArgo_nbOf13Or11TypePacketExpected = [g_decArgo_nbOf13Or11TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketExpected))*-1];
      g_decArgo_nbOf13Or11TypePacketReceived = [g_decArgo_nbOf13Or11TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketReceived))];
      g_decArgo_nbOf14Or12TypePacketExpected = [g_decArgo_nbOf14Or12TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketExpected))*-1];
      g_decArgo_nbOf14Or12TypePacketReceived = [g_decArgo_nbOf14Or12TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketReceived))];
      
      % we must know if parameter packet #2 is expected (and for which cycles)
      
      % we first check if ICE mode is activated
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         
         % if one parameter packet #2 has been received, it means that the ICE mode
         % is activated
         
         % if IC0 = 0, the ice detection algorithm is disabled and parameter #2 packet
         % (type 7) is not sent by the float
         
         % retrieve temporary information
         configTmpCycles = g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES;
         configTmpDates = g_decArgo_floatConfig.DYNAMIC_TMP.DATES;
         configTmpNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
         configTmpValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES;
         
         % retrieve IC0 configuration parameter index
         idIc00PosTmp = find(strncmp('CONFIG_IC00_', configTmpNames, length('CONFIG_IC00_')) == 1, 1);
         
         % retrieve configuration information
         configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
         configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;
         configCycles = g_decArgo_floatConfig.USE.CYCLE;
         configNumbers = g_decArgo_floatConfig.USE.CONFIG;
         [configCycles, idSort] = sort(configCycles);
         configNumbers = configNumbers(idSort);
         
         % retrieve IC0 configuration parameter index
         idIc00Pos = find(strncmp('CONFIG_IC00_', configNames, length('CONFIG_IC00_')) == 1, 1);
         
         if (~isempty(idIc00PosTmp) && ~isempty(idIc00Pos))
            
            g_decArgo_7TypePacketExpectedFlag = ones(size(g_decArgo_cycleList));
            
            % check for each cycle
            for idCy = 1:length(g_decArgo_cycleList)
               
               if (g_decArgo_cycleList(idCy) < g_decArgo_7TypePacketReceivedCyNum)
                  % ICE mode not activated yet
                  g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
               elseif (g_decArgo_cycleList(idCy) == g_decArgo_7TypePacketReceivedCyNum)
                  % cycle of ICE mode activation
                  g_decArgo_7TypePacketExpectedFlag(idCy) = 1;
               elseif (g_decArgo_cycleList(idCy) == g_decArgo_7TypePacketReceivedCyNum+1)
                  % one cycle afer cycle of ICE mode activation
                  % the IC0 value should be retrieved from temporary
                  % configuration
                  idF = find(configTmpCycles == g_decArgo_7TypePacketReceivedCyNum);
                  if (~isempty(idF))
                     [~, idSort] = sort(configTmpDates(idF));
                     iceNoSurfaceDelay = configTmpValues(idIc00PosTmp, idF(idSort(end)));
                     if (iceNoSurfaceDelay == 0)
                        % ice detection algorithm is disabled => parameter packet
                        % #2 is not expected
                        g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
                     end
                  end
               else
                  % ICE mode activated
                  idF = find(configCycles <= g_decArgo_cycleList(idCy));
                  if (~isempty(idF))
                     configNumber = configNumbers(idF(end));
                     iceNoSurfaceDelay = configValues(idIc00Pos, configNumber+1);
                     if (iceNoSurfaceDelay == 0)
                        % ice detection algorithm is disabled => parameter packet
                        % #2 is not expected
                        g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
                     end
                  else
                     % retrieve IC0 configuration value from launch configuration
                     iceNoSurfaceDelay = configValues(idIc00Pos, 1);
                     if (iceNoSurfaceDelay == 0)
                        % ice detection algorithm is disabled => parameter packet #2 is not
                        % expected
                        g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
                     end
                  end
               end
            end
         else
            g_decArgo_7TypePacketExpectedFlag = zeros(size(g_decArgo_cycleList));
            fprintf('WARNING: Float #%d: unable to retrieve IC00 configuration value => ice detection mode is supposed to be disabled\n', ...
               g_decArgo_floatNum);
         end
      else
         % we don't know if the ICE mode is activated
         % we must wait for the first received parameter packet #2
         g_decArgo_7TypePacketExpectedFlag = zeros(size(g_decArgo_cycleList));
      end
      
      if (isempty(g_decArgo_7TypePacketReceivedFlag))
         g_decArgo_7TypePacketReceivedFlag = zeros(size(g_decArgo_cycleList));
      else
         sevenTypePacketReceivedFlag = zeros(size(g_decArgo_cycleList));
         sevenTypePacketReceivedFlag(find(g_decArgo_7TypePacketReceivedFlag == 1)) = 1;
         g_decArgo_7TypePacketReceivedFlag = sevenTypePacketReceivedFlag;
      end
      
      if (a_whyFlag == 0)
         
         o_cycleNumberList = g_decArgo_cycleList;
         o_bufferCompleted = zeros(size(o_cycleNumberList));
         for cyId = 1:length(g_decArgo_cycleList)
            if ( ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_7TypePacketExpectedFlag(cyId) == g_decArgo_7TypePacketReceivedFlag(cyId)) && ...
                  (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == g_decArgo_nbOf1Or8TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == g_decArgo_nbOf2Or9TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == g_decArgo_nbOf3Or10TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf13Or11TypePacketExpected(cyId) == g_decArgo_nbOf13Or11TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf14Or12TypePacketExpected(cyId) == g_decArgo_nbOf14Or12TypePacketReceived(cyId)))
               
               % nominal case
               o_bufferCompleted(cyId) = 1;
            elseif ( ...
                  ~any(g_decArgo_0TypePacketReceivedFlag ~= 0) && ...
                  ~any(g_decArgo_4TypePacketReceivedFlag ~= 0) && ...
                  ~any(g_decArgo_5TypePacketReceivedFlag ~= 0) && ...
                  ~any(g_decArgo_nbOf1Or8TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf1Or8TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf2Or9TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf2Or9TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf3Or10TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf3Or10TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf13Or11TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf13Or11TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf14Or12TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf14Or12TypePacketReceived ~= 0) && ...
                  (g_decArgo_7TypePacketExpectedFlag(cyId) == g_decArgo_7TypePacketReceivedFlag(cyId)))
               
               % buffer with only parameter packet #2
               o_bufferCompleted(cyId) = 1;
               g_decArgo_processingOnly7TypePacketFlag = zeros(size(g_decArgo_cycleList));
               g_decArgo_processingOnly7TypePacketFlag(cyId) = 1;
            end
         end
         
      else
         
         for cyId = 1:length(g_decArgo_cycleList)
            if (isempty(g_decArgo_0TypePacketReceivedFlag) || ...
                  (length(g_decArgo_0TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #1 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_4TypePacketReceivedFlag) || ...
                  (length(g_decArgo_4TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #2 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_5TypePacketReceivedFlag) || ...
                  (length(g_decArgo_5TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Parameter packet #1 is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (g_decArgo_7TypePacketReceivedFlag(cyId) ~= g_decArgo_7TypePacketExpectedFlag(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Parameter packet #2 is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_nbOf1Or8TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf1Or8TypePacketExpected) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf1Or8TypePacketReceived(cyId) ~= g_decArgo_nbOf1Or8TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf1Or8TypePacketExpected(cyId)-g_decArgo_nbOf1Or8TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf2Or9TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf2Or9TypePacketExpected) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf2Or9TypePacketReceived(cyId) ~= g_decArgo_nbOf2Or9TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf2Or9TypePacketExpected(cyId)-g_decArgo_nbOf2Or9TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf3Or10TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf3Or10TypePacketExpected) || ...
                  (length(g_decArgo_nbOf3Or10TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf3Or10TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of ascent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf3Or10TypePacketReceived(cyId) ~= g_decArgo_nbOf3Or10TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf3Or10TypePacketExpected(cyId)-g_decArgo_nbOf3Or10TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf13Or11TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf13Or11TypePacketExpected) || ...
                  (length(g_decArgo_nbOf13Or11TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf13Or11TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of near surface data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf13Or11TypePacketReceived(cyId) ~= g_decArgo_nbOf13Or11TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d near surface data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId)-g_decArgo_nbOf13Or11TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf14Or12TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf14Or12TypePacketExpected) || ...
                  (length(g_decArgo_nbOf14Or12TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf14Or12TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of in air data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf14Or12TypePacketReceived(cyId) ~= g_decArgo_nbOf14Or12TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d in air data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId)-g_decArgo_nbOf14Or12TypePacketReceived(cyId));
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {216} % Arvor-Deep-Ice Iridium 5.65
      
      % adjust the size of the variables
      g_decArgo_0TypePacketReceivedFlag = [g_decArgo_0TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_0TypePacketReceivedFlag))];
      g_decArgo_4TypePacketReceivedFlag = [g_decArgo_4TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_4TypePacketReceivedFlag))];
      g_decArgo_5TypePacketReceivedFlag = [g_decArgo_5TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_5TypePacketReceivedFlag))];
      g_decArgo_nbOf1Or8TypePacketExpected = [g_decArgo_nbOf1Or8TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketExpected))*-1];
      g_decArgo_nbOf1Or8TypePacketReceived = [g_decArgo_nbOf1Or8TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketReceived))];
      g_decArgo_nbOf2Or9TypePacketExpected = [g_decArgo_nbOf2Or9TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketExpected))*-1];
      g_decArgo_nbOf2Or9TypePacketReceived = [g_decArgo_nbOf2Or9TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketReceived))];
      g_decArgo_nbOf3Or10TypePacketExpected = [g_decArgo_nbOf3Or10TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketExpected))*-1];
      g_decArgo_nbOf3Or10TypePacketReceived = [g_decArgo_nbOf3Or10TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketReceived))];
      g_decArgo_nbOf13Or11TypePacketExpected = zeros(1, length(g_decArgo_cycleList))*-1;
      g_decArgo_nbOf13Or11TypePacketReceived = [g_decArgo_nbOf13Or11TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketReceived))];
      g_decArgo_nbOf14Or12TypePacketExpected = zeros(1, length(g_decArgo_cycleList))*-1;
      g_decArgo_nbOf14Or12TypePacketReceived = [g_decArgo_nbOf14Or12TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketReceived))];
      
      % we must know if Near Surface or In Air packets are expected at each
      % cycle and, if so, we compute (from PT30 et PT 31) the number of expected
      % Near Surface or In Air packets (3 being the max allowed number); this
      % should be done because we have no information about that (as these
      % counts are not reported in the TECH data)
      for cyId = 1:length(g_decArgo_cycleList)
         cycleNum = g_decArgo_cycleList(cyId);
         
         % retrieve configuration values
         pm16Value = nan;
         pt21Value = nan;
         pt30Value = nan;
         pt31Value = nan;
         pt33Value = nan;
         
         % from configuration data
         idUsedConf = find(g_decArgo_floatConfig.USE.CYCLE == cycleNum);
         if (~isempty(idUsedConf))
            configNumber = unique(g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
            idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == configNumber);
            configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
            configValues = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);
            
            idPm16Pos = find(strncmp('CONFIG_PM16', configNames, length('CONFIG_PM16')) == 1, 1);
            if (~isempty(idPm16Pos))
               pm16Value = configValues(idPm16Pos);
            end
            idPt21Pos = find(strncmp('CONFIG_PT21', configNames, length('CONFIG_PT21')) == 1, 1);
            if (~isempty(idPt21Pos))
               pt21Value = configValues(idPt21Pos);
            end
            idPt30Pos = find(strncmp('CONFIG_PT30', configNames, length('CONFIG_PT30')) == 1, 1);
            if (~isempty(idPt30Pos))
               pt30Value = configValues(idPt30Pos);
            end
            idPt31Pos = find(strncmp('CONFIG_PT31', configNames, length('CONFIG_PT31')) == 1, 1);
            if (~isempty(idPt31Pos))
               pt31Value = configValues(idPt31Pos);
            end
            idPt33Pos = find(strncmp('CONFIG_PT33', configNames, length('CONFIG_PT33')) == 1, 1);
            if (~isempty(idPt33Pos))
               pt33Value = configValues(idPt33Pos);
            end
         end
         
         % from temporary configuration data
         if (isnan(pt33Value))
            idUsedConf = find(g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES == cycleNum-1);
            if (~isempty(idUsedConf))
               
               % retrieve the data of the concerned configuration
               configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
               configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, idUsedConf);
               
               idPm16Pos = find(strncmp('CONFIG_PM16', configNames, length('CONFIG_PM16')) == 1, 1);
               if (~isempty(idPm16Pos))
                  pm16Value = configValues(idPm16Pos);
               end
               idPt21Pos = find(strncmp('CONFIG_PT21', configNames, length('CONFIG_PT21')) == 1, 1);
               if (~isempty(idPt21Pos))
                  pt21Value = configValues(idPt21Pos);
               end
               idPt30Pos = find(strncmp('CONFIG_PT30', configNames, length('CONFIG_PT30')) == 1, 1);
               if (~isempty(idPt30Pos))
                  pt30Value = configValues(idPt30Pos);
               end
               idPt31Pos = find(strncmp('CONFIG_PT31', configNames, length('CONFIG_PT31')) == 1, 1);
               if (~isempty(idPt31Pos))
                  pt31Value = configValues(idPt31Pos);
               end
               idPt33Pos = find(strncmp('CONFIG_PT33', configNames, length('CONFIG_PT33')) == 1, 1);
               if (~isempty(idPt33Pos))
                  pt33Value = configValues(idPt33Pos);
               end
            end
         end
         
         % compute number of expected Near Surface or In Air packets
         nbOf14Or12TypePacketExpected = 3;
         if (~isnan(pm16Value) && ~isnan(pt21Value) && ~isnan(pt30Value) && ~isnan(pt31Value))
            if (pm16Value == 0) % no second iridium session
               if (pt21Value == 1)
                  % PTSO data
                  nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/7), 3);
               else
                  % PTS data
                  nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/15), 3);
               end
            else % one second Iridium session
               if (~ismember(cycleNum, a_cycleDecodingDoneList))
                  % it is the transmission session
                  if (pt21Value == 1)
                     % PTSO data
                     nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/7), 3);
                  else
                     % PTS data
                     nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/15), 3);
                  end
               else
                  % it is the second Iridium session => no Near Surface or In Air packets
                  nbOf14Or12TypePacketExpected = 0;
               end
            end
         end
         
         if (~isnan(pt33Value))
            if (pt33Value == 0)
               g_decArgo_nbOf13Or11TypePacketExpected(cyId) = 0;
               g_decArgo_nbOf14Or12TypePacketExpected(cyId) = 0;
            elseif (pt33Value == 1)
               if (cycleNum == 0)
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId) = 0;
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
               else
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
               end
            elseif (mod(cycleNum, pt33Value) == 0)
               if (cycleNum == 0)
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId) = 0;
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
               else
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
               end
            end
         else
            fprintf('ERROR: Float #%d: ''CONFIG_PT33'' is not defined for cycle #%d => check configuration data\n', ...
               g_decArgo_floatNum, cycleNum);
         end
      end
      
      if (a_whyFlag == 0)
         
         o_cycleNumberList = g_decArgo_cycleList;
         o_bufferCompleted = zeros(size(o_cycleNumberList));
         for cyId = 1:length(g_decArgo_cycleList)
            if ( ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == g_decArgo_nbOf1Or8TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == g_decArgo_nbOf2Or9TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == g_decArgo_nbOf3Or10TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf13Or11TypePacketExpected(cyId) == g_decArgo_nbOf13Or11TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf14Or12TypePacketExpected(cyId) == g_decArgo_nbOf14Or12TypePacketReceived(cyId)))
               
               o_bufferCompleted(cyId) = 1;
            end
         end
         
      else
         
         for cyId = 1:length(g_decArgo_cycleList)
            if (isempty(g_decArgo_0TypePacketReceivedFlag) || ...
                  (length(g_decArgo_0TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #1 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_4TypePacketReceivedFlag) || ...
                  (length(g_decArgo_4TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #2 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_5TypePacketReceivedFlag) || ...
                  (length(g_decArgo_5TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Parameter packet #1 is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_nbOf1Or8TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf1Or8TypePacketExpected) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf1Or8TypePacketReceived(cyId) ~= g_decArgo_nbOf1Or8TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf1Or8TypePacketExpected(cyId)-g_decArgo_nbOf1Or8TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf2Or9TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf2Or9TypePacketExpected) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf2Or9TypePacketReceived(cyId) ~= g_decArgo_nbOf2Or9TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf2Or9TypePacketExpected(cyId)-g_decArgo_nbOf2Or9TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf13Or11TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf13Or11TypePacketExpected) || ...
                  (length(g_decArgo_nbOf13Or11TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf13Or11TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of ascent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf13Or11TypePacketReceived(cyId) ~= g_decArgo_nbOf13Or11TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d near surface data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId)-g_decArgo_nbOf13Or11TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf14Or12TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf14Or12TypePacketExpected) || ...
                  (length(g_decArgo_nbOf14Or12TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf14Or12TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of ascent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf14Or12TypePacketReceived(cyId) ~= g_decArgo_nbOf14Or12TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d in air data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId)-g_decArgo_nbOf14Or12TypePacketReceived(cyId));
            end
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to explain what is missing in the buffer for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
