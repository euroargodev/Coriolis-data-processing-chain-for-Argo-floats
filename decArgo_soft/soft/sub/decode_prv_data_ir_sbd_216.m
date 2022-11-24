% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech1, o_tabTech2, o_dataCTD, o_dataCTDO, o_evAct, o_pumpAct, ...
%    o_floatParam1, o_cycleNumberList, o_firstDateNextBuffer] = ...
%    decode_prv_data_ir_sbd_216(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)
%
% INPUT PARAMETERS :
%   a_tabData         : data frame to decode
%   a_tabDataDates    : corresponding dates of Iridium SBD
%   a_procLevel       : processing level (0: collect only rough information, 1:
%                       decode the data)
%   a_cycleNumberList : list of cycle to decode
%
% OUTPUT PARAMETERS :
%   o_tabTech1        : decoded data of technical msg #1
%   o_tabTech2        : decoded data of technical msg #2
%   o_dataCTD         : decoded CTD data
%   o_dataCTDO        : decoded CTDO data
%   o_evAct           : EV decoded data from hydraulic packet
%   o_pumpAct         : pump decoded data from hydraulic packet
%   o_floatParam1     : decoded parameter #1 data
%   o_cycleNumberList : list of decoded cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/22/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, o_dataCTD, o_dataCTDO, o_evAct, o_pumpAct, ...
   o_floatParam1, o_cycleNumberList, o_firstDateNextBuffer] = ...
   decode_prv_data_ir_sbd_216(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_dataCTD = [];
o_dataCTDO = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam1 = [];
o_cycleNumberList = [];
o_firstDateNextBuffer = [];

% current float WMO number
global g_decArgo_floatNum;

% offset in cycle number (in case of reset of the float)
global g_decArgo_cycleNumOffset;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_tempDoxyCountsDef;
global g_decArgo_durationDef;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;
global g_decArgo_nbOf7TypePacketReceived;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


% clean duplicates in received data
[a_tabData, a_tabDataDates] = clean_duplicates_in_received_data_216( ...
   a_tabData, a_tabDataDates, a_procLevel);

% initialize information arrays
init_counts;

% decode packet data
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = a_tabDataDates(idMes);
   
   tabDate = [];
   tabPres = [];
   tabTemp = [];
   tabPsal = [];
   tabC1Phase = [];
   tabC2Phase = [];
   tabTempDoxy = [];
   tabDuration = [];
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1

         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            8 8 8  repmat(8, 1, 9) ...
            8 8 16 8 8 8 16 8 8 16 8 ...
            repmat(8, 1, 2) ...
            repmat(8, 1, 7) ...
            16 8 16 ...
            repmat(8, 1, 4) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1) + g_decArgo_cycleNumOffset;
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         if ~(isempty(g_decArgo_0TypePacketReceivedFlag) || ...
               (length(g_decArgo_0TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
               (g_decArgo_0TypePacketReceivedFlag(idFCy) ~= 1))
            o_firstDateNextBuffer = sbdFileDate;
            break;
         end
         g_decArgo_0TypePacketReceivedFlag(idFCy) = 1;

         if (a_procLevel == 0)
            continue;
         end
                  
         % compute the offset between float days and julian days
         startDateInfo = [tabTech1(2:4); tabTech1(6)];
         if (any(startDateInfo ~= 0))
            cycleStartDateDay = datenum(sprintf('%02d%02d%02d', tabTech1(2:4)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
            if (~isempty(g_decArgo_julD2FloatDayOffset))
               if (g_decArgo_julD2FloatDayOffset ~= cycleStartDateDay - tabTech1(5))
                  prevOffsetGregDate = julian_2_gregorian_dec_argo(g_decArgo_julD2FloatDayOffset);
                  prevOffsetGregDate = prevOffsetGregDate(1:10);
                  newOffsetGregDate = julian_2_gregorian_dec_argo(cycleStartDateDay - tabTech1(5));
                  newOffsetGregDate = newOffsetGregDate(1:10);
                  if (g_decArgo_cycleNumOffset == 0)
                     % with no reset this clock jump is an error
                     fprintf('\nERROR: Float #%d Cycle #%d: Shift in float day (previous offset = %d (%s), new offset = %d (%s))\n', ...
                        g_decArgo_floatNum, ...
                        tabTech1(1), ...
                        g_decArgo_julD2FloatDayOffset, ...
                        prevOffsetGregDate, ...
                        cycleStartDateDay - tabTech1(5), ...
                        newOffsetGregDate);
                  else
                     % after a reset this clock jump is nominal
                     fprintf('\nINFO: Float #%d Cycle #%d: Shift in float day (previous offset = %d (%s), new offset = %d (%s))\n', ...
                        g_decArgo_floatNum, ...
                        tabTech1(1), ...
                        g_decArgo_julD2FloatDayOffset, ...
                        prevOffsetGregDate, ...
                        cycleStartDateDay - tabTech1(5), ...
                        newOffsetGregDate);
                  end
               end
            end
            g_decArgo_julD2FloatDayOffset = cycleStartDateDay - tabTech1(5);
         end
         
         % pressure sensor offset
         tabTech1(44) = twos_complement_dec_argo(tabTech1(44), 8)/10;
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech1(38:43)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % compute GPS location
         if (tabTech1(53) == 0)
            signLat = 1;
         else
            signLat = -1;
         end
         gpsLocLat = signLat*(tabTech1(50) + (tabTech1(51) + ...
            tabTech1(52)/10000)/60);
         if (tabTech1(57) == 0)
            signLon = 1;
         else
            signLon = -1;
         end
         gpsLocLon = signLon*(tabTech1(54) + (tabTech1(55) + ...
            tabTech1(56)/10000)/60);
         
         o_tabTech1 = [o_tabTech1; ...
            cycleNum packType tabTech1(1:76)' floatTime gpsLocLon gpsLocLat sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 ...
            8 8 8 16 16 8 16 16 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 9) ...
            8 8 ...
            repmat(8, 1, 40) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
                  
         cycleNum = tabTech2(1) + g_decArgo_cycleNumOffset;

         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         if ~(isempty(g_decArgo_4TypePacketReceivedFlag) || ...
               (length(g_decArgo_4TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
               (g_decArgo_4TypePacketReceivedFlag(idFCy) ~= 1))
            o_firstDateNextBuffer = sbdFileDate;
            break;
         end
         g_decArgo_4TypePacketReceivedFlag(idFCy) = 1;
         
         g_decArgo_nbOf1Or8TypePacketExpected(idFCy) = tabTech2(2);
         g_decArgo_nbOf2Or9TypePacketExpected(idFCy) = tabTech2(3);
         g_decArgo_nbOf3Or10TypePacketExpected(idFCy) = tabTech2(4);
         
         if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
            g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
            g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
            g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
            g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
            g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 0;
         end

         if (a_procLevel == 0)
            continue;
         end
         
         o_tabTech2 = [o_tabTech2; ...
            cycleNum packType tabTech2(1:82)' sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1) + g_decArgo_cycleNumOffset;
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end

         if (~any(ctdValues(2:end) ~= 0))
            fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
               g_decArgo_floatNum, cycleNum, ...
               packType);
            continue;
         end

         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 1)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 2)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 3)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 13)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 14)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         if (a_procLevel == 0)
            continue;
         end
         
         % there are 15 PTS measurements per packet
         
         % store raw data values
         tabDate = [];
         tabPres = [];
         tabTemp = [];
         tabPsal = [];
         for idBin = 1:15
            if (idBin > 1)
               measDate = g_decArgo_dateDef;
            else
               measDate = ctdValues(2)/24 + ctdValues(3)/1440 + ctdValues(4)/86400;
            end
            
            pres = ctdValues(3*(idBin-1)+5);
            temp = ctdValues(3*(idBin-1)+6);
            psal = ctdValues(3*(idBin-1)+7);
            
            if ~((pres == 0) && (temp == 0) && (psal == 0))
               tabDate = [tabDate; measDate];
               tabPres = [tabPres; pres];
               tabTemp = [tabTemp; temp];
               tabPsal = [tabPsal; psal];
            else
               tabDate = [tabDate; g_decArgo_dateDef];
               tabPres = [tabPres; g_decArgo_presCountsDef];
               tabTemp = [tabTemp; g_decArgo_tempCountsDef];
               tabPsal = [tabPsal; g_decArgo_salCountsDef];
            end
         end
         
         o_dataCTD = [o_dataCTD; ...
            cycleNum packType ctdValues(1) tabDate' ones(1, length(tabDate))*-1 ...
            tabPres' tabTemp' tabPsal' sbdFileDate];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {8, 9, 10, 11, 12}
         % CTDO packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 42) ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         ctdoValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdoValues(1) + g_decArgo_cycleNumOffset;
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end

         if (~any(ctdoValues(2:end) ~= 0))
            fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
               g_decArgo_floatNum, cycleNum, ...
               packType);
            continue;
         end

         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 8)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 9)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 10)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 11)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 12)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         if (a_procLevel == 0)
            continue;
         end
         
         % there are 7 PTSO measurements per packet
         
         % store raw data values
         tabDate = [];
         tabPres = [];
         tabTemp = [];
         tabPsal = [];
         tabC1Phase = [];
         tabC2Phase = [];
         tabTempDoxy = [];
         for idBin = 1:7
            if (idBin > 1)
               measDate = g_decArgo_dateDef;
            else
               measDate = ctdoValues(2)/24 + ctdoValues(3)/1440 + ctdoValues(4)/86400;
            end
            
            pres = ctdoValues(6*(idBin-1)+5);
            temp = ctdoValues(6*(idBin-1)+6);
            psal = ctdoValues(6*(idBin-1)+7);
            c1Phase = ctdoValues(6*(idBin-1)+8);
            c2Phase = ctdoValues(6*(idBin-1)+9);
            tempDoxy = ctdoValues(6*(idBin-1)+10);
            
            if ~((pres == 0) && (temp == 0) && (psal == 0) && (c1Phase == 0) && (c2Phase == 0) && (tempDoxy == 0))
               tabDate = [tabDate; measDate];
               tabPres = [tabPres; pres];
               tabTemp = [tabTemp; temp];
               tabPsal = [tabPsal; psal];
               tabC1Phase = [tabC1Phase; c1Phase];
               tabC2Phase = [tabC2Phase; c2Phase];
               tabTempDoxy = [tabTempDoxy; tempDoxy];
            else
               tabDate = [tabDate; g_decArgo_dateDef];
               tabPres = [tabPres; g_decArgo_presCountsDef];
               tabTemp = [tabTemp; g_decArgo_tempCountsDef];
               tabPsal = [tabPsal; g_decArgo_salCountsDef];
               tabC1Phase = [tabC1Phase; g_decArgo_c1C2PhaseDoxyCountsDef];
               tabC2Phase = [tabC2Phase; g_decArgo_c1C2PhaseDoxyCountsDef];
               tabTempDoxy = [tabTempDoxy; g_decArgo_tempDoxyCountsDef];
            end            
         end
         
         o_dataCTDO = [o_dataCTDO; ...
            cycleNum packType ctdoValues(1) tabDate' ones(1, length(tabDate))*-1 ...
            tabPres' tabTemp' tabPsal' tabC1Phase' tabC2Phase' tabTempDoxy' sbdFileDate];
                  
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(8, 1, 6) 16 ...
            16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
            repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 8 8 16 16 16 ...
            16 16 8 8 16 16 8 8 16 8 8 8 8 16 ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(7)-1 + g_decArgo_cycleNumOffset;
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         if ~(isempty(g_decArgo_5TypePacketReceivedFlag) || ...
               (length(g_decArgo_5TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
               (g_decArgo_5TypePacketReceivedFlag(idFCy) ~= 1))
            o_firstDateNextBuffer = sbdFileDate;
            break;
         end
         g_decArgo_5TypePacketReceivedFlag(idFCy) = 1;

         if (a_procLevel == 0)
            continue;
         end
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam1(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % calibration coefficients
         tabParam1(60) = tabParam1(60)/1000;
         tabParam1(61) = -tabParam1(61);
         
         % reference temperature (PG4)
         tabParam1(66) = twos_complement_dec_argo(tabParam1(66), 16)/1000;

         o_floatParam1 = [o_floatParam1; ...
            cycleNum packType tabParam1(7)-1 tabParam1' floatTime sbdFileDate];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {6, 7}
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);         
         
         cycleNum = tabHy(1) + g_decArgo_cycleNumOffset;
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 6)
            if (length(g_decArgo_nbOf6TypePacketReceived) < idFCy)
               g_decArgo_nbOf6TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf6TypePacketReceived(idFCy) = g_decArgo_nbOf6TypePacketReceived(idFCy) + 1;
            end
         else
            if (length(g_decArgo_nbOf7TypePacketReceived) < idFCy)
               g_decArgo_nbOf7TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf7TypePacketReceived(idFCy) = g_decArgo_nbOf7TypePacketReceived(idFCy) + 1;
            end
         end
         
         if (a_procLevel == 0)
            continue;
         end
         
         % there are 15 EV actions per packet
         
         % store data values
         nbAct = 0;
         for idBin = 1:15
            if (idBin == 1)
               refDate = tabHy(2) + tabHy(3)/1440;
            end
            
            refTime = tabHy(3*(idBin-1)+4);
            pres = tabHy(3*(idBin-1)+5);
            duration = tabHy(3*(idBin-1)+6);
            
            if ~((refTime == 0) && (pres == 0) && (duration == 0))
               tabDate = [tabDate; refDate+refTime/1440];
               tabPres = [tabPres; twos_complement_dec_argo(pres, 16)];
               tabDuration = [tabDuration; duration];
               nbAct = nbAct + 1;
            else
               tabDate = [tabDate; g_decArgo_dateDef];
               tabPres = [tabPres; g_decArgo_presCountsDef];
               tabDuration = [tabDuration; g_decArgo_durationDef];
            end
         end
         
         if (packType == 6)
            o_evAct = [o_evAct; ...
               cycleNum packType tabHy(1) tabDate' tabPres' tabDuration' sbdFileDate];
         else
            o_pumpAct = [o_pumpAct; ...
               cycleNum packType tabHy(1) tabDate' tabPres' tabDuration' sbdFileDate];
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

o_cycleNumberList = g_decArgo_cycleList;

if (a_procLevel > 0)

   % collect information on received packet types
   collect_received_packet_type_info;
end

return;

% ------------------------------------------------------------------------------
% Initialize global flags and counters used to decide if a buffer is completed
% or not for a given list of cycles.
%
% SYNTAX :
%  init_counts
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
%   11/22/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_counts

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;
global g_decArgo_nbOf7TypePacketReceived;

% initialize information arrays
g_decArgo_cycleList = [];
g_decArgo_0TypePacketReceivedFlag = [];
g_decArgo_4TypePacketReceivedFlag = [];
g_decArgo_5TypePacketReceivedFlag = [];
g_decArgo_nbOf1Or8TypePacketExpected = [];
g_decArgo_nbOf1Or8TypePacketReceived = [];
g_decArgo_nbOf2Or9TypePacketExpected = [];
g_decArgo_nbOf2Or9TypePacketReceived = [];
g_decArgo_nbOf3Or10TypePacketExpected = [];
g_decArgo_nbOf3Or10TypePacketReceived = [];
g_decArgo_nbOf13Or11TypePacketReceived = [];
g_decArgo_nbOf14Or12TypePacketReceived = [];
g_decArgo_nbOf6TypePacketReceived = [];
g_decArgo_nbOf7TypePacketReceived = [];

return;

% ------------------------------------------------------------------------------
% Collect information on received packet types.
%
% SYNTAX :
%  collect_received_packet_type_info
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
%   11/22/2017 - RNU - creation
% ------------------------------------------------------------------------------
function collect_received_packet_type_info

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;
global g_decArgo_nbOf7TypePacketReceived;

% array ro store statistics on received packets
global g_decArgo_nbDescentPacketsReceived;
global g_decArgo_nbParkPacketsReceived;
global g_decArgo_nbAscentPacketsReceived;
global g_decArgo_nbNearSurfacePacketsReceived;
global g_decArgo_nbInAirPacketsReceived;
global g_decArgo_nbHydraulicPacketsReceived;
global g_decArgo_nbTech1PacketsReceived;
global g_decArgo_nbTech2PacketsReceived;
global g_decArgo_nbParmPacketsReceived;


% adjust the size of the variables
g_decArgo_0TypePacketReceivedFlag = [g_decArgo_0TypePacketReceivedFlag ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_0TypePacketReceivedFlag))];
g_decArgo_4TypePacketReceivedFlag = [g_decArgo_4TypePacketReceivedFlag ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_4TypePacketReceivedFlag))];
g_decArgo_5TypePacketReceivedFlag = [g_decArgo_5TypePacketReceivedFlag ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_5TypePacketReceivedFlag))];
g_decArgo_nbOf1Or8TypePacketReceived = [g_decArgo_nbOf1Or8TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketReceived))];
g_decArgo_nbOf2Or9TypePacketReceived = [g_decArgo_nbOf2Or9TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketReceived))];
g_decArgo_nbOf3Or10TypePacketReceived = [g_decArgo_nbOf3Or10TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketReceived))];
g_decArgo_nbOf13Or11TypePacketReceived = [g_decArgo_nbOf13Or11TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketReceived))];
g_decArgo_nbOf14Or12TypePacketReceived = [g_decArgo_nbOf14Or12TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketReceived))];
g_decArgo_nbOf6TypePacketReceived = [g_decArgo_nbOf6TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf6TypePacketReceived))];
g_decArgo_nbOf7TypePacketReceived = [g_decArgo_nbOf7TypePacketReceived ...
   zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf7TypePacketReceived))];

g_decArgo_nbTech1PacketsReceived = g_decArgo_0TypePacketReceivedFlag;
g_decArgo_nbTech2PacketsReceived = g_decArgo_4TypePacketReceivedFlag;
g_decArgo_nbParmPacketsReceived = g_decArgo_5TypePacketReceivedFlag;
g_decArgo_nbDescentPacketsReceived = g_decArgo_nbOf1Or8TypePacketReceived;
g_decArgo_nbParkPacketsReceived = g_decArgo_nbOf2Or9TypePacketReceived;
g_decArgo_nbAscentPacketsReceived = g_decArgo_nbOf3Or10TypePacketReceived;
g_decArgo_nbNearSurfacePacketsReceived = g_decArgo_nbOf13Or11TypePacketReceived;
g_decArgo_nbInAirPacketsReceived = g_decArgo_nbOf14Or12TypePacketReceived;
g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbOf6TypePacketReceived + g_decArgo_nbOf7TypePacketReceived;

return;