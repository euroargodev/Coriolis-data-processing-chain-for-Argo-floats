% ------------------------------------------------------------------------------
% Decode NOVA packet data.
%
% SYNTAX :
%  [o_tabTech, o_dataCTD, o_dataHydrau, o_dataAck, o_deepCycle] = ...
%    decode_nva_data_ir_sbd_2001(a_tabData, a_tabDataDates, a_procLevel, a_firstDeepCycleDone)
%
% INPUT PARAMETERS :
%   a_tabData            : data frame to decode
%   a_tabDataDates       : corresponding dates of Iridium SBD
%   a_procLevel          : processing level (0: collect only rough information,
%                          1: decode the data)
%   a_firstDeepCycleDone : first deep cycle done flag (1 if the first deep cycle
%                          has been done)
%
% OUTPUT PARAMETERS :
%   o_tabTech    : decoded housekeeping data
%   o_dataCTD    : decoded sensor data
%   o_dataHydrau : decoded hydraulic data
%   o_dataAck    : decoded acknowledgment data
%   o_deepCycle  : deep cycle flag (1 if it is a deep cycle 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech, o_dataCTD, o_dataHydrau, o_dataAck, o_deepCycle] = ...
   decode_nva_data_ir_sbd_2001(a_tabData, a_tabDataDates, a_procLevel, a_firstDeepCycleDone)

% output parameters initialization
o_tabTech = [];
o_dataCTD = [];
o_dataHydrau = [];
o_dataAck = [];
o_deepCycle = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% number of the previous decoded cycle
global g_decArgo_cycleNumPrev;

% offset to consider for cycle numbers
global g_decArgo_cycleNumOffset;

% prelude ended flag
global g_decArgo_preludeDoneFlag;

% default values
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;

% arrays to store rough information on received data
global g_decArgo_1TypePacketReceived;
global g_decArgo_5TypePacketReceived;
global g_decArgo_nbOf2To4TypePacketExpected;
global g_decArgo_nbOf10To29TypePacketExpected;
global g_decArgo_nbOf30To49TypePacketExpected;
global g_decArgo_nbOf50To55TypePacketExpected;
global g_decArgo_nbOf2To4TypePacketReceived;
global g_decArgo_nbOf10To29TypePacketReceived;
global g_decArgo_nbOf30To49TypePacketReceived;
global g_decArgo_nbOf50To55TypePacketReceived;
global g_decArgo_ackPacket;

% decoder configuration values
global g_decArgo_generateNcTech;

% max number of CTD samples in one NOVA sensor data packet
global g_decArgo_maxCTDSampleInNovaDataPacket;
NB_MEAS_MAX_NOVA = g_decArgo_maxCTDSampleInNovaDataPacket;

% EOL mode
global g_decArgo_eolMode;
g_decArgo_eolMode = 0;

% final EOL flag (all remaining transmitted data are processed together)
global g_decArgo_finalEolMode;


% decode packet data
tabCycleNum = [];
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = a_tabDataDates(idMes);
   
   % message data frame
   msgData = a_tabData(idMes, 3:a_tabData(idMes, 2)+2);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 1
         % housekeeping packet
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(16, 1, 6) ...
            repmat(8, 1, 12) ...
            16 8 16 8 16 8 8 ...
            16 16 repmat(8, 1, 10) 32 32 8 16 8 8 8 16 8 8 8 16 8 ...
            ];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         g_decArgo_1TypePacketReceived = 1;
         g_decArgo_nbOf2To4TypePacketExpected = tabTech(25);
         g_decArgo_nbOf10To29TypePacketExpected = tabTech(22);
         g_decArgo_nbOf30To49TypePacketExpected = tabTech(20);
         g_decArgo_nbOf50To55TypePacketExpected = tabTech(24);
         if (a_procLevel == 0)
            continue
         end
         
         % store cycle number
         tabCycleNum = [tabCycleNum tabTech(30)];
         
         % determine if it is a deep cycle
         if (g_decArgo_finalEolMode == 0)
            if (any(tabTech([20 22 24]) ~= 0))
               o_deepCycle = 1;
            else
               o_deepCycle = 0;
            end
         else
            o_deepCycle = 0;
         end
         
         % decode the retrieved data
         tabTech([1:6 41 45]) = tabTech([1:6 41 45])*0.001;
         tabTech(26) = tabTech(26)*0.1 - 3276.8;
         tabTech(31) = tabTech(31)*0.1;
         tabTech(38:39) = tabTech(38:39)*1e-7 - 214.7483648;
         tabTech(48) = tabTech(48) + 2000;
         tabTech(50) = tabTech(50)*2;
         
         o_tabTech = [o_tabTech; ...
            tabTech(30) tabTech' sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {2, 3, 4}
         % hydraulic packet
         
         g_decArgo_nbOf2To4TypePacketReceived = g_decArgo_nbOf2To4TypePacketReceived + 1;
         if (a_procLevel == 0)
            continue
         end
         
         % compute the number of pressure points in the hydraulic packet
         nbPresPoints = floor((a_tabData(idMes, 2) - 1)/7); % 7 bytes for each
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            8 ...
            repmat([8 16 16 16], 1, nbPresPoints) ...
            ];
         % get item bits
         tabHydrau = get_bits(firstBit, tabNbBits, msgData);
         
         if (rem(a_tabData(idMes, 2) - 1, 7) ~= 0)
            fprintf('WARNING: Float #%d cycle #%d: Number of bytes of the hydraulic packet doesn''t fit a completed number of valve/pump activations\n', ...
               g_decArgo_floatNum, tabHydrau(1));
         end
         
         % store cycle number
         tabCycleNum = [tabCycleNum tabHydrau(1)];
         
         % decode the retrieved data
         tabHydrau((0:nbPresPoints-1)*4+3) = tabHydrau((0:nbPresPoints-1)*4+3)*0.1;
         for idH = 1:nbPresPoints
            o_dataHydrau = [o_dataHydrau; ...
               packType tabHydrau(1) tabHydrau((idH-1)*4+2:(idH-1)*4+5)' sbdFileDate];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {5}
         % acknowledgment packet
         
         g_decArgo_5TypePacketReceived = 1;
         if (a_procLevel == 0)
            continue
         end
         
         % determine if it is a deep cycle
         o_deepCycle = 0;
         
         % compute the number of commands in the acknowledgment packet
         nbCmd = floor(a_tabData(idMes, 2)/5); % 5 bytes for each
         
         if (rem(a_tabData(idMes, 2), 5) ~= 0)
            fprintf('WARNING: Float #%d: Number of bytes of the acknowledgment packet doesn''t fit a completed number of commands\n', ...
               g_decArgo_floatNum);
         end
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat([8 8 16 8], 1, nbCmd) ...
            ];
         % get item bits
         tabAck = get_bits(firstBit, tabNbBits, msgData);
         
         % decode the retrieved data
         for idC = 1:nbCmd
            o_dataAck = [o_dataAck; ...
               tabAck((idC-1)*4+1:(idC-1)*4+4)' sbdFileDate];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, ...
            30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, ...
            50, 51, 52, 53, 54, 55}
         % ascent data packet
         % descent data packet
         % drift data packet
         
         if ((packType >= 10) && (packType <= 29))
            % ascent data packet
            g_decArgo_nbOf10To29TypePacketReceived = g_decArgo_nbOf10To29TypePacketReceived + 1;
         elseif ((packType >= 30) && (packType <= 49))
            % descent data packet
            g_decArgo_nbOf30To49TypePacketReceived = g_decArgo_nbOf30To49TypePacketReceived + 1;
         elseif ((packType >= 50) && (packType <= 55))
            % drift data packet
            g_decArgo_nbOf50To55TypePacketReceived = g_decArgo_nbOf50To55TypePacketReceived + 1;
         end
         if (a_procLevel == 0)
            continue
         end
         
         % determine if it is a deep cycle
         o_deepCycle = 1;
         
         % compute the number Of CTD samples in the data packet
         nbMeas = floor((a_tabData(idMes, 2) - 2)/6); % 6 bytes for each
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            8 8 ...
            repmat([16 16 16], 1, nbMeas) ...
            ];
         % get item bits
         tabData = get_bits(firstBit, tabNbBits, msgData);
         
         if (nbMeas > NB_MEAS_MAX_NOVA)
            fprintf('ERROR: Float #%d cycle #%d: Number of CTD samples in data packet (%d) exceeds the max expected one (%d)\n', ...
               g_decArgo_floatNum, tabData(1), ...
               nbMeas, NB_MEAS_MAX_NOVA);
         end
         
         if (rem(a_tabData(idMes, 2) - 2, 6) ~= 0)
            fprintf('WARNING: Float #%d cycle #%d: Number of bytes of the sensor data packet doesn''t fit a completed number of levels\n', ...
               g_decArgo_floatNum, tabData(1));
         end
         
         % store cycle number
         tabCycleNum = [tabCycleNum tabData(1)];
         
         % decode the retrieved data
         tabDate = ones(NB_MEAS_MAX_NOVA, 1)*g_decArgo_dateDef;
         tabPres = ones(NB_MEAS_MAX_NOVA, 1)*g_decArgo_presCountsDef;
         tabTemp = ones(NB_MEAS_MAX_NOVA, 1)*g_decArgo_tempCountsDef;
         tabPsal = ones(NB_MEAS_MAX_NOVA, 1)*g_decArgo_salCountsDef;
         for idM = 1:nbMeas
            
            if (idM > 1)
               measDate = g_decArgo_dateDef;
            else
               measDate = tabData(2)*0.1;
            end
            
            tabDate(idM) = measDate;
            
            if ~((tabData(3*(idM-1)+5) == 65306) && ...
                  (tabData(3*(idM-1)+4) == 0) && ...
                  (tabData(3*(idM-1)+3) == 55536))
               tabPres(idM) = tabData(3*(idM-1)+5);
               tabTemp(idM) = tabData(3*(idM-1)+4);
               tabPsal(idM) = tabData(3*(idM-1)+3);
            end
         end
         
         o_dataCTD = [o_dataCTD; ...
            packType tabData(1) nbMeas tabDate' tabPres' tabTemp' tabPsal' sbdFileDate];
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

% convert data counts to physical values
if (~isempty(o_dataCTD))
   o_dataCTD(:, 4+NB_MEAS_MAX_NOVA:4+2*NB_MEAS_MAX_NOVA-1) = sensor_2_value_for_pressure_nva(o_dataCTD(:, 4+NB_MEAS_MAX_NOVA:4+2*NB_MEAS_MAX_NOVA-1));
   o_dataCTD(:, 4+2*NB_MEAS_MAX_NOVA:4+3*NB_MEAS_MAX_NOVA-1) = sensor_2_value_for_temperature_nva(o_dataCTD(:, 4+2*NB_MEAS_MAX_NOVA:4+3*NB_MEAS_MAX_NOVA-1));
   o_dataCTD(:, 4+3*NB_MEAS_MAX_NOVA:4+4*NB_MEAS_MAX_NOVA-1) = sensor_2_value_for_salinity_nva(o_dataCTD(:, 4+3*NB_MEAS_MAX_NOVA:4+4*NB_MEAS_MAX_NOVA-1));
end

% set cycle number and store tech data for nc output
if (a_procLevel > 0)
   if (g_decArgo_ackPacket == 0)
      if (~isempty(tabCycleNum))
         
         % during EOL mode, current cycle data and cycle #255 data can be
         % transmitted simultaneously (see 6903195 #123)
         if (length(unique(tabCycleNum)) ~= 1)
            uTabCycleNumBis = unique(tabCycleNum(find(tabCycleNum ~= 255)));
            if (length(uTabCycleNumBis) == 1)
               tabCycleNum(find(tabCycleNum == 255)) = uTabCycleNumBis;
            end
         end
         
         if (length(unique(tabCycleNum)) == 1)
            g_decArgo_cycleNum = unique(tabCycleNum);
                        
            if ((g_decArgo_cycleNum ~= 255) && (g_decArgo_cycleNum > 0))
               g_decArgo_preludeDoneFlag = 1;
            end
            
            % add 1 to cycle number except for PRELUDE cycle
            if (o_deepCycle == 0)
               if (g_decArgo_preludeDoneFlag == 0)
                  % PRELUDE cycle
                  if (g_decArgo_cycleNum == 255)
                     g_decArgo_cycleNum = 0;
                  end
               else
                  g_decArgo_cycleNum = g_decArgo_cycleNum + 1;
               end
            else
               g_decArgo_cycleNum = g_decArgo_cycleNum + 1;
            end
            
            if (o_deepCycle == 1)
               % float #6901885 transmitted profiles with cycle numbers
               % 0, 1, 2, ..., 253, 254, 255, 255, 255, etc...
               if (g_decArgo_cycleNum <= g_decArgo_cycleNumPrev)
                  % add 1 to g_decArgo_cycleNumPrev
                  g_decArgo_cycleNumOffset = g_decArgo_cycleNumPrev - g_decArgo_cycleNum + 1;
                  g_decArgo_cycleNum = g_decArgo_cycleNum + g_decArgo_cycleNumOffset;
               end
            else
               if (g_decArgo_cycleNum < g_decArgo_cycleNumPrev)
                  % keep the same g_decArgo_cycleNumPrev
                  g_decArgo_cycleNum = g_decArgo_cycleNumPrev;
               end
            end
                        
            % EOL mode
            if ((~isempty(o_deepCycle) && (o_deepCycle == 0)) && ...
                  (g_decArgo_preludeDoneFlag == 1) && ...
                  (g_decArgo_cycleNum == g_decArgo_cycleNumPrev))
               g_decArgo_eolMode = 1;
               g_decArgo_finalEolMode = 1;
            end
            
            % output NetCDF files
            if (g_decArgo_generateNcTech ~= 0)
               store_tech_data_for_nc_2001(o_tabTech, o_deepCycle);
            end
            
         else
            cycleListStr = sprintf('%d ', unique(tabCycleNum));
            
            if (g_decArgo_finalEolMode == 0)
               
               if (isempty(o_dataCTD))
                  fprintf('ERROR: Float #%d: Multiple cycle numbers (%s) have been received - buffer ignored (no CTD data lost)\n', ...
                     g_decArgo_floatNum, cycleListStr(1:end-1));
               else
                  fprintf('ERROR: Float #%d: Multiple cycle numbers (%s) have been received - buffer ignored (CTD data lost)\n', ...
                     g_decArgo_floatNum, cycleListStr(1:end-1));
               end
               
               o_tabTech = [];
               o_dataCTD = [];
               o_dataHydrau = [];
               o_dataAck = [];
               o_deepCycle = [];
               g_decArgo_cycleNum = g_decArgo_cycleNumPrev;
            else
               
               if (isempty(o_dataCTD))
                  fprintf('WARNING: Float #%d: Multiple cycle numbers (%s) have been received - buffer ignored (no CTD data lost)\n', ...
                     g_decArgo_floatNum, cycleListStr(1:end-1));
               else
                  fprintf('ERROR: Float #%d: Multiple cycle numbers (%s) have been received - buffer ignored (CTD data lost)\n', ...
                     g_decArgo_floatNum, cycleListStr(1:end-1));
               end
               
               o_dataCTD = [];
               o_dataHydrau = [];
               o_dataAck = [];
               o_deepCycle = 0;
               g_decArgo_cycleNum = g_decArgo_cycleNumPrev;
            end
         end
      else
         fprintf('WARNING: Float #%d: Cycle number cannot be determined\n', ...
            g_decArgo_floatNum);
      end
   end
   
   % specific
   if (ismember(g_decArgo_floatNum, [6901887]))
      switch g_decArgo_floatNum
         case 6901887
            if (g_decArgo_cycleNum == 25)
               o_tabTech(41) = 13; % "Day in the month of last GPS fix" = 28 not consistent, it is 13
            end
      end
   end
end

return
