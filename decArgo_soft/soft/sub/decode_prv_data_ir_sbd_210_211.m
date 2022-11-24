% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech1, o_tabTech2, o_dataCTD, o_evAct, o_pumpAct, ...
%    o_floatParam, o_irSessionNum] = ...
%    decode_prv_data_ir_sbd_210_211(a_tabData, a_tabDataDates, a_procLevel, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabData      : data frame to decode
%   a_tabDataDates : corresponding dates of Iridium SBD
%   a_procLevel    : processing level (0: collect only rough information, 1:
%                    decode the data)
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTech1     : decoded data of technical msg #1
%   o_tabTech2     : decoded data of technical msg #2
%   o_dataCTD      : decoded data from CTD
%   o_evAct        : EV decoded data from hydraulic packet
%   o_pumpAct      : pump decoded data from hydraulic packet
%   o_floatParam   : decoded parameter data
%   o_irSessionNum : number of the Iridium session (1 or 2)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, o_dataCTD, o_evAct, o_pumpAct, ...
   o_floatParam, o_irSessionNum] = ...
   decode_prv_data_ir_sbd_210_211(a_tabData, a_tabDataDates, a_procLevel, a_decoderId)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_dataCTD = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam = [];
o_irSessionNum = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_durationDef;

% arrays to store rough information on received data
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
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

% decoder configuration values
global g_decArgo_generateNcTech;

% flag to detect a second Iridium session
global g_decArgo_secondIridiumSession;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% decode packet data
tabCycleNum = [];
tabIrSessionNum = [];
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = a_tabDataDates(idMes);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         g_decArgo_0TypePacketReceivedFlag = 1;
         if (a_procLevel == 0)
            continue;
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 16 16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            repmat(8, 1, 12) ...
            8 8 16 8 8 8 16 8 8 16 8 16 8 ...
            repmat(8, 1, 10) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         % store cycle number
         tabCycleNum = [tabCycleNum tabTech1(1)];
         
         % store Iridium session number
         tabIrSessionNum = [tabIrSessionNum tabTech1(2)];
         
         % compute the offset between float days and julian days
         startDateInfo = [tabTech1(5:7); tabTech1(9)];
         if ~((length(unique(startDateInfo)) == 1) && (unique(startDateInfo) == 0))
            cycleStartDateDay = datenum(sprintf('%02d%02d%02d', tabTech1(5:7)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
            if (~isempty(g_decArgo_julD2FloatDayOffset))
               if (g_decArgo_julD2FloatDayOffset ~= cycleStartDateDay - tabTech1(8))
                  fprintf('ERROR: Float #%d: Shift in float day (previous offset = %d, new offset = %d)\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_julD2FloatDayOffset, ...
                     cycleStartDateDay);
               end
            end
            g_decArgo_julD2FloatDayOffset = cycleStartDateDay - tabTech1(8);
         end
         
         % pressure sensor offset
         tabTech1(47) = twos_complement_dec_argo(tabTech1(47), 8);
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech1(41:46)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % compute GPS location
         
         if (a_decoderId == 210)
            
            % BE CAREFUL
            % in this firmware version (5900A00), the latitude and longitude
            % orientation bytes are never updated (always set to 0)
            % we use the Iridium location to set the sign of the lat/lon
            idF = find(([g_decArgo_iridiumMailData.timeOfSessionJuld] >= min(a_tabDataDates)) & ...
               ([g_decArgo_iridiumMailData.timeOfSessionJuld] <= max(a_tabDataDates)));
            if (isempty(idF))
               fprintf('ERROR: Float #%d: Unable to retrieve associated Iridium file => GPS location orientation can be erroneous\n', ...
                  g_decArgo_floatNum);
            else
               % we use the more reliable Iridium location (for the 3901872 #12
               % it is not the first one ...)
               [minCepRadius, idMin] = min([g_decArgo_iridiumMailData(idF).cepRadius]);
               idF = idF(idMin);
            end
            
            if (tabTech1(56) == 0)
               signLat = 1;
            else
               signLat = -1;
            end
            if (~isempty(idF))
               signLat = sign(g_decArgo_iridiumMailData(idF).unitLocationLat);
            end
            gpsLocLat = signLat*(tabTech1(53) + (tabTech1(54) + ...
               tabTech1(55)/10000)/60);
            if (tabTech1(60) == 0)
               signLon = 1;
            else
               signLon = -1;
            end
            if (~isempty(idF))
               signLon = sign(g_decArgo_iridiumMailData(idF).unitLocationLon);
            end
            gpsLocLon = signLon*(tabTech1(57) + (tabTech1(58) + ...
               tabTech1(59)/10000)/60);
            
         elseif (a_decoderId == 211)
            
            % for firmware version >= 5900A01 the issue mentioned above has been
            % fixed
            
            if (tabTech1(56) == 0)
               signLat = 1;
            else
               signLat = -1;
            end
            gpsLocLat = signLat*(tabTech1(53) + (tabTech1(54) + ...
               tabTech1(55)/10000)/60);
            if (tabTech1(60) == 0)
               signLon = 1;
            else
               signLon = -1;
            end
            gpsLocLon = signLon*(tabTech1(57) + (tabTech1(58) + ...
               tabTech1(59)/10000)/60);
         end
         
         o_tabTech1 = [o_tabTech1; ...
            packType tabTech1(1:72)' floatTime gpsLocLon gpsLocLat sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 ...
            8 8 8 8 8 16 16 8 16 16 8 8 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 4) ...
            16 8 16 ...
            repmat(8, 1, 9) 16 repmat(8, 1, 5) ...
            repmat(8, 1, 21) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         g_decArgo_4TypePacketReceivedFlag = 1;
         g_decArgo_nbOf1Or8TypePacketExpected = tabTech2(3);
         g_decArgo_nbOf2Or9TypePacketExpected = tabTech2(4);
         g_decArgo_nbOf3Or10TypePacketExpected = tabTech2(5);
         g_decArgo_nbOf13Or11TypePacketExpected = tabTech2(6);
         g_decArgo_nbOf14Or12TypePacketExpected = tabTech2(7);
         if (a_procLevel == 0)
            continue;
         end
         
         % store cycle number
         tabCycleNum = [tabCycleNum tabTech2(1)];
         
         % store Iridium session number
         tabIrSessionNum = [tabIrSessionNum tabTech2(2)];
         
         o_tabTech2 = [o_tabTech2; ...
            packType tabTech2(1:58)' sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         if (a_procLevel == 0)
            if (packType == 1)
               g_decArgo_nbOf1Or8TypePacketReceived = g_decArgo_nbOf1Or8TypePacketReceived + 1;
            elseif (packType == 2)
               g_decArgo_nbOf2Or9TypePacketReceived = g_decArgo_nbOf2Or9TypePacketReceived + 1;
            elseif (packType == 3)
               g_decArgo_nbOf3Or10TypePacketReceived = g_decArgo_nbOf3Or10TypePacketReceived + 1;
            elseif (packType == 13)
               g_decArgo_nbOf13Or11TypePacketReceived = g_decArgo_nbOf13Or11TypePacketReceived + 1;
            elseif (packType == 14)
               g_decArgo_nbOf14Or12TypePacketReceived = g_decArgo_nbOf14Or12TypePacketReceived + 1;
            end
            continue;
         end
         
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
         
         % store cycle number
         tabCycleNum = [tabCycleNum ctdValues(1)];
         
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
            packType tabDate' ones(1, length(tabDate))*-1 tabPres' tabTemp' tabPsal'];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet
         
         g_decArgo_5TypePacketReceivedFlag = 1;
         if (a_procLevel == 0)
            continue;
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            repmat(16, 1, 4) repmat(8, 1, 7) repmat(16, 1, 4) 8 16 16 16 8 8 8 16 16 repmat(8, 1, 6) 16 16 ...
            16 repmat(8, 1, 5) 16 repmat(8, 1, 5) 16 8 16 repmat(8, 1, 8) 16 16 repmat(8, 1, 10) ...
            ];
         % get item bits
         tabParam = get_bits(firstBit, tabNbBits, msgData);
         
         % store cycle number
         tabCycleNum = [tabCycleNum tabParam(1)];
         
         % store Iridium session number
         tabIrSessionNum = [tabIrSessionNum tabParam(2)];
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam(3:8)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % calibration coefficients
         tabParam(65) = tabParam(65)/1000;
         tabParam(66) = -tabParam(66);
         
         o_floatParam = [o_floatParam; ...
            packType tabParam' floatTime sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 6
         % EV or pump packet
         
         if (a_procLevel == 0)
            continue;
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat([8 16 16 16], 1, 13) ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         % there are 13 EV/pump actions per packet
         
         % store data values
         for idBin = 1:13
            if (idBin == 1)
               refDate = tabHy(2) + tabHy(3)/1440;
            end
            
            type = tabHy(4*(idBin-1)+4);
            refTime = tabHy(4*(idBin-1)+5);
            pres = twos_complement_dec_argo(tabHy(4*(idBin-1)+6), 16);
            duration = tabHy(4*(idBin-1)+7);
            
            if ~((refTime == 0) && (pres == 0) && (duration == 0))
               date = refDate+refTime/1440;
               if (type == 0)
                  o_evAct = [o_evAct; ...
                     packType date pres duration];
               else
                  o_pumpAct = [o_pumpAct; ...
                     packType date pres duration];
               end
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

if (a_procLevel > 0)
   
   % set cycle number number
   if (~isempty(tabCycleNum))
      if (length(unique(tabCycleNum)) == 1)
         
         g_decArgo_cycleNum = unique(tabCycleNum);
         fprintf('cyle #%d\n', g_decArgo_cycleNum);
      else
         fprintf('ERROR: Float #%d: Multiple cycle numbers have been received\n', ...
            g_decArgo_floatNum);
      end
   else
      fprintf('WARNING: Float #%d: Cycle number cannot be determined\n', ...
         g_decArgo_floatNum);
   end
   
   % set Iridium session number
   if (~isempty(tabIrSessionNum))
      if (length(unique(tabIrSessionNum)) == 1)
         
         o_irSessionNum = unique(tabIrSessionNum) + 1 ;
         g_decArgo_secondIridiumSession = unique(tabIrSessionNum);
      else
         fprintf('ERROR: Float #%d: Multiple Iridium session numbers have been received\n', ...
            g_decArgo_floatNum);
      end
   end
end

return;
