% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech, ...
%    o_dataCTD, o_dataCTDO, ...
%    o_evAct, o_pumpAct, o_floatParam, o_deepCycle] = ...
%    decode_prv_data_ir_sbd_201_203(a_tabData, a_tabDataDates, ...
%    a_procLevel, a_firstDeepCycleDone, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabData            : data frame to decode
%   a_tabDataDates       : corresponding dates of Iridium SBD
%   a_procLevel          : processing level (0: collect only rough information,
%                          1: decode the data)
%   a_firstDeepCycleDone : first deep cycle done flag (1 if the first deep cycle
%                          has been done)
%   a_decoderId          : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTech     : decoded technical data
%   o_dataCTD     : decoded data from CTD
%   o_dataCTDO    : decoded data from CTD + Optode
%   o_evAct       : decoded hydraulic (EV) data
%   o_pumpAct     : decoded hydraulic (pump) data
%   o_floatParam  : decoded parameter data
%   o_deepCycle   : deep cycle flag (1 if it is a deep cycle 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech, ...
   o_dataCTD, o_dataCTDO, ...
   o_evAct, o_pumpAct, o_floatParam, o_deepCycle] = ...
   decode_prv_data_ir_sbd_201_203(a_tabData, a_tabDataDates, ...
   a_procLevel, a_firstDeepCycleDone, a_decoderId)

% output parameters initialization
o_tabTech = [];
o_dataCTD = [];
o_dataCTDO = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam = [];
o_deepCycle = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% shift to apply to transmitted cycle number (see 6901248)
global g_decArgo_cycleNumShift;

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
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% decoder configuration values
global g_decArgo_generateNcTech;


% initialize information arrays
init_counts;

% decode packet data
floatCycleNumber = [];
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
         % float technical #1 packet
         
         g_decArgo_0TypePacketReceivedFlag = 1;
         if (a_procLevel == 0)
            continue
         end
         
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
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         % set float cycle number
         floatCycleNumber = tabTech(1);
         if (a_firstDeepCycleDone == 0)
            g_decArgo_cycleNumShift = floatCycleNumber - 1;
         end
         
         % compute the offset between float days and julian days
         startDateInfo = [tabTech(2:4); tabTech(6)];
         if (any(startDateInfo ~= 0))
            cycleStartDateDay = datenum(sprintf('%02d%02d%02d', tabTech(2:4)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
            if (~isempty(g_decArgo_julD2FloatDayOffset))
               if (g_decArgo_julD2FloatDayOffset ~= cycleStartDateDay - tabTech(5))
                  prevOffsetGregDate = julian_2_gregorian_dec_argo(g_decArgo_julD2FloatDayOffset);
                  prevOffsetGregDate = prevOffsetGregDate(1:10);
                  newOffsetGregDate = julian_2_gregorian_dec_argo(cycleStartDateDay - tabTech(5));
                  newOffsetGregDate = newOffsetGregDate(1:10);
                  fprintf('ERROR: Float #%d Cycle #%d: Shift in float day (previous offset = %d (%s), new offset = %d (%s))\n', ...
                     g_decArgo_floatNum, ...
                     tabTech(1), ...
                     g_decArgo_julD2FloatDayOffset, ...
                     prevOffsetGregDate, ...
                     cycleStartDateDay - tabTech(5), ...
                     newOffsetGregDate);
               end
            end
            g_decArgo_julD2FloatDayOffset = cycleStartDateDay - tabTech(5);
         end
         
         % pressure sensor offset
         tabTech(44) = twos_complement_dec_argo(tabTech(44), 8)/10;
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech(38:43)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % compute GPS location
         if (tabTech(53) == 0)
            signLat = 1;
         else
            signLat = -1;
         end
         gpsLocLat = signLat*(tabTech(50) + (tabTech(51) + ...
            tabTech(52)/10000)/60);
         if (tabTech(57) == 0)
            signLon = 1;
         else
            signLon = -1;
         end
         gpsLocLon = signLon*(tabTech(54) + (tabTech(55) + ...
            tabTech(56)/10000)/60);
         
         tabTech = [packType tabTech(1:76)' ones(1, 4)*-1 floatTime gpsLocLon gpsLocLat sbdFileDate];
         
         o_tabTech = [o_tabTech; tabTech];
                  
         %          fprintf('Packet type : %d\n', packType);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % float technical #2 packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            8 8 8 16 16 8 16 16 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 9) ...
            8 ...
            repmat(8, 1, 43) ...
            ];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         g_decArgo_4TypePacketReceivedFlag = 1;
         g_decArgo_nbOf1Or8TypePacketExpected = tabTech(1);
         g_decArgo_nbOf2Or9TypePacketExpected = tabTech(2);
         g_decArgo_nbOf3Or10TypePacketExpected = tabTech(3);
         if (a_procLevel == 0)
            continue
         end
         
         % message and measurement counts are set to 0 for a surface cycle
         if ((length(unique(tabTech(1:8))) == 1) && (unique(tabTech(1:8)) == 0))
            o_deepCycle = 0;
         else
            o_deepCycle = 1;
         end
         
         % set cycle number
         if (~isempty(floatCycleNumber))
            if ((a_firstDeepCycleDone == 0) && (o_deepCycle == 0))
               g_decArgo_cycleNum = 0;
            else
               g_decArgo_cycleNum = floatCycleNumber - g_decArgo_cycleNumShift;
            end
         else
            fprintf('ERROR: Float #%d Cycle #%d: Msg tech#2 has been received before Msg tech#1\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
         end
         fprintf('Cycle #%d\n', g_decArgo_cycleNum);
         
         tabTech = [packType tabTech(1:83)' sbdFileDate];
         
         o_tabTech = [o_tabTech; tabTech];
                  
         %          fprintf('Packet type : %d\n', packType);
         %          fprintf('- nb packets CTDO desc. : %d\n', tabTech(2));
         %          fprintf('- nb packets CTDO drift : %d\n', tabTech(3));
         %          fprintf('- nb packets CTDO asc. : %d\n', tabTech(4));
         %          fprintf('- nb meas CTDO desc. : %d\n', tabTech(5)+tabTech(6));
         %          fprintf('- nb meas CTDO drift : %d\n', tabTech(7));
         %          fprintf('- nb meas CTDO asc. : %d\n', tabTech(8)+tabTech(9));
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3}
         % CTD packets
         
         o_deepCycle = 1;

         if (packType == 1)
            g_decArgo_nbOf1Or8TypePacketReceived = g_decArgo_nbOf1Or8TypePacketReceived + 1;
         elseif (packType == 2)
            g_decArgo_nbOf2Or9TypePacketReceived = g_decArgo_nbOf2Or9TypePacketReceived + 1;
         elseif (packType == 3)
            g_decArgo_nbOf3Or10TypePacketReceived = g_decArgo_nbOf3Or10TypePacketReceived + 1;
         end
         if (a_procLevel == 0)
            continue
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 5) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         % there are 15 PTS measurements per packet
         
         % store raw data values
         nbMeas = 0;
         for idBin = 1:15
            if (idBin > 1)
               measDate = g_decArgo_dateDef;
            else
               measDate = ctdValues(1)/24 + ...
                  ctdValues(2)/1440 + ctdValues(3)/86400;
            end
            
            pres = ctdValues(3*(idBin-1)+4);
            temp = ctdValues(3*(idBin-1)+5);
            psal = ctdValues(3*(idBin-1)+6);
            
            if ~((pres == 0) && (temp == 0) && (psal == 0))
               tabDate = [tabDate; measDate];
               tabPres = [tabPres; pres];
               tabTemp = [tabTemp; temp];
               tabPsal = [tabPsal; psal];
               nbMeas = nbMeas + 1;
            else
               tabDate = [tabDate; g_decArgo_dateDef];
               tabPres = [tabPres; g_decArgo_presCountsDef];
               tabTemp = [tabTemp; g_decArgo_tempCountsDef];
               tabPsal = [tabPsal; g_decArgo_salCountsDef];
            end
         end
         
         o_dataCTD = [o_dataCTD; ...
            packType tabDate' ones(1, length(tabDate))*-1 tabPres' tabTemp' tabPsal'];
         
         %          fprintf('Packet type : %d\n', packType);
         %          fprintf('- nb meas CTD : %d\n', nbMeas);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {8, 9, 10}
         % CTDO packets
         
         o_deepCycle = 1;
         
         if (packType == 8)
            g_decArgo_nbOf1Or8TypePacketReceived = g_decArgo_nbOf1Or8TypePacketReceived + 1;
         elseif (packType == 9)
            g_decArgo_nbOf2Or9TypePacketReceived = g_decArgo_nbOf2Or9TypePacketReceived + 1;
         elseif (packType == 10)
            g_decArgo_nbOf3Or10TypePacketReceived = g_decArgo_nbOf3Or10TypePacketReceived + 1;
         end
         if (a_procLevel == 0)
            continue
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 8 ...
            repmat(16, 1, 42) ...
            repmat(8, 1, 11) ...
            ];
         % get item bits
         ctdoValues = get_bits(firstBit, tabNbBits, msgData);
         
         % there are 7 PTSO measurements per packet
         
         % store raw data values
         nbMeas = 0;
         for idBin = 1:7
            if (idBin > 1)
               measDate = g_decArgo_dateDef;
            else
               measDate = ctdoValues(1)/24 + ...
                  ctdoValues(2)/1440 + ctdoValues(3)/86400;
            end
            
            pres = ctdoValues(6*(idBin-1)+4);
            temp = ctdoValues(6*(idBin-1)+5);
            psal = ctdoValues(6*(idBin-1)+6);
            c1Phase = ctdoValues(6*(idBin-1)+7);
            c2Phase = ctdoValues(6*(idBin-1)+8);
            tempDoxy = ctdoValues(6*(idBin-1)+9);
            
            if ~((pres == 0) && (temp == 0) && (psal == 0) && (c1Phase == 0) && (c2Phase == 0) && (tempDoxy == 0))
               tabDate = [tabDate; measDate];
               tabPres = [tabPres; pres];
               tabTemp = [tabTemp; temp];
               tabPsal = [tabPsal; psal];
               tabC1Phase = [tabC1Phase; c1Phase];
               tabC2Phase = [tabC2Phase; c2Phase];
               tabTempDoxy = [tabTempDoxy; tempDoxy];
               nbMeas = nbMeas + 1;
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
         
         % if the float has no OPTODE sensor and PT21 is set to 1, the CTD data
         % are transmitted with packet type 8, 9 and 10
         doData = [ ...
            tabC1Phase(find(tabC1Phase ~= g_decArgo_c1C2PhaseDoxyCountsDef)); ...
            tabC2Phase(find(tabC2Phase ~= g_decArgo_c1C2PhaseDoxyCountsDef)); ...
            tabTempDoxy(find(tabTempDoxy ~= g_decArgo_tempDoxyCountsDef)) ...
            ];
         uDoData = unique(doData);
         if ~((length(uDoData) == 1) && (uDoData == 65535))
            o_dataCTDO = [o_dataCTDO; ...
               packType tabDate' ones(1, length(tabDate))*-1 tabPres' tabTemp' tabPsal' tabC1Phase' tabC2Phase' tabTempDoxy'];
         else
            tabDate = [tabDate; ones(8, 1)*g_decArgo_dateDef];
            tabPres = [tabPres; ones(8, 1)*g_decArgo_presCountsDef];
            tabTemp = [tabTemp; ones(8, 1)*g_decArgo_tempCountsDef];
            tabPsal = [tabPsal; ones(8, 1)*g_decArgo_salCountsDef];
            
            o_dataCTD = [o_dataCTD; ...
               packType-7 tabDate' ones(1, length(tabDate))*-1 tabPres' tabTemp' tabPsal'];
            
            fprintf('INFO: Float #%d Cycle #%d: CTD data transmitted in CTDO packets\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
         end
         
         %          fprintf('Packet type : %d\n', packType);
         %          fprintf('- nb meas CTDO : %d\n', nbMeas);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {6, 7}
         % EV or pump packet
         
         if (a_procLevel == 0)
            continue
         end
         
         g_decArgo_nbOf6TypePacketReceived = g_decArgo_nbOf6TypePacketReceived + 1;
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 5) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         % there are 15 EV actions per packet
         
         % store data values
         nbAct = 0;
         for idBin = 1:15
            if (idBin == 1)
               refDate = tabHy(1) + tabHy(2)/1440;
            end
            
            refTime = tabHy(3*(idBin-1)+3);
            pres = tabHy(3*(idBin-1)+4);
            duration = tabHy(3*(idBin-1)+5);
            
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
               packType tabDate' tabPres' tabDuration'];
         else
            o_pumpAct = [o_pumpAct; ...
               packType tabDate' tabPres' tabDuration'];
         end
         
         %          fprintf('Packet type : %d\n', packType);
         %          fprintf('- nb act Hydrau : %d\n', nbAct);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet
         
         g_decArgo_5TypePacketReceivedFlag = 1;
         if (a_procLevel == 0)
            continue
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(8, 1, 6) 16 ...
            16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
            repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 ...
            repmat(8, 1, 30) ...
            ];
         % get item bits
         tabParam = get_bits(firstBit, tabNbBits, msgData);
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % calibration coefficients
         tabParam(55) = tabParam(55)/1000;
         if (tabParam(56) < 32768) % 32768 = 65536/2
            tabParam(56) = -tabParam(56);
         else
            tabParam(56) = 65536 - tabParam(56);
         end
         
         % specific: for float 6901763 replace PT21=2 by PT21=0
         if (g_decArgo_floatNum == 6901763)
            if (tabParam(46) == 2)
               tabParam(46) = 0;
            end
         end
         
         o_floatParam = [o_floatParam; ...
            packType tabParam' floatTime sbdFileDate];
         
         %          fprintf('Packet type : %d\n', packType);
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

% output NetCDF files
if (a_procLevel ~= 0)
   if (g_decArgo_generateNcTech ~= 0)
      if (~isempty(o_tabTech))
         idFTech1 = find(o_tabTech(:, 1) == 0);
         store_tech1_data_for_nc_201_to_203_215_216_218(o_tabTech(idFTech1, :), o_deepCycle);
         idFTech2 = find(o_tabTech(:, 1) == 4);
         store_tech2_data_for_nc_201_203_215(o_tabTech(idFTech2, :), o_deepCycle, a_decoderId);
      end
   end
end
         
% if the DO sensor failed during the profile some packets have CTD only and
% others CTDO (Ex: 6901760 descending profile #1)
% we should merge data so that only o_dataCTDO output array should be empty
if (~isempty(o_dataCTD) && ~isempty(o_dataCTDO))
   
   o_dataCTD(:, [9:16 24:31 39:46 54:61 69:76]) = [];
   o_dataCTD(:, 1) = o_dataCTD(:, 1) + 7;
   o_dataCTD = [o_dataCTD ...
      ones(size(o_dataCTD, 1), 7)*g_decArgo_c1C2PhaseDoxyCountsDef ...
      ones(size(o_dataCTD, 1), 7)*g_decArgo_c1C2PhaseDoxyCountsDef ...
      ones(size(o_dataCTD, 1), 7)*g_decArgo_tempDoxyCountsDef ...
      ];
   o_dataCTDO = cat(1, o_dataCTDO, o_dataCTD);
   
   % when the DO sensor fails the measurement is 65535
   c1c2PhaseDoxy = o_dataCTDO(:, 37:50);
   idDef = find(c1c2PhaseDoxy == 65535);
   c1c2PhaseDoxy(idDef) = g_decArgo_c1C2PhaseDoxyCountsDef;
   o_dataCTDO(:, 37:50) = c1c2PhaseDoxy;
   tempDoxy = o_dataCTDO(:, 51:57);
   idDef = find(tempDoxy == 65535);
   tempDoxy(idDef) = g_decArgo_tempDoxyCountsDef;
   o_dataCTDO(:, 51:57) = tempDoxy;
   
   o_dataCTD = [];
end

if (a_procLevel > 0)

   % collect information on received packet types
   collect_received_packet_type_info;
end

return

% ------------------------------------------------------------------------------
% Initialize global flags and counters used to decide if a buffer is completed
% or not.
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
%   03/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_counts

% arrays to store rough information on received data
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8Or11Or14TypePacketExpected;
global g_decArgo_nbOf1Or8Or11Or14TypePacketReceived;
global g_decArgo_nbOf2Or9Or12Or15TypePacketExpected;
global g_decArgo_nbOf2Or9Or12Or15TypePacketReceived;
global g_decArgo_nbOf3Or10Or13Or16TypePacketExpected;
global g_decArgo_nbOf3Or10Or13Or16TypePacketReceived;
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
global g_decArgo_nbOf6TypePacketReceived;

% initialize information arrays
g_decArgo_0TypePacketReceivedFlag = 0;
g_decArgo_4TypePacketReceivedFlag = 0;
g_decArgo_5TypePacketReceivedFlag = 0;
g_decArgo_nbOf1Or8Or11Or14TypePacketExpected = -1;
g_decArgo_nbOf1Or8Or11Or14TypePacketReceived = 0;
g_decArgo_nbOf2Or9Or12Or15TypePacketExpected = -1;
g_decArgo_nbOf2Or9Or12Or15TypePacketReceived = 0;
g_decArgo_nbOf3Or10Or13Or16TypePacketExpected = -1;
g_decArgo_nbOf3Or10Or13Or16TypePacketReceived = 0;
g_decArgo_nbOf1Or8TypePacketExpected = -1;
g_decArgo_nbOf1Or8TypePacketReceived = 0;
g_decArgo_nbOf2Or9TypePacketExpected = -1;
g_decArgo_nbOf2Or9TypePacketReceived = 0;
g_decArgo_nbOf3Or10TypePacketExpected = -1;
g_decArgo_nbOf3Or10TypePacketReceived = 0;
g_decArgo_nbOf13Or11TypePacketExpected = -1;
g_decArgo_nbOf13Or11TypePacketReceived = 0;
g_decArgo_nbOf14Or12TypePacketExpected = -1;
g_decArgo_nbOf14Or12TypePacketReceived = 0;
g_decArgo_nbOf6TypePacketReceived = 0;

% items not concerned by this decoder
g_decArgo_7TypePacketReceivedFlag = 1;

g_decArgo_nbOf1Or8Or11Or14TypePacketExpected = 0;
g_decArgo_nbOf2Or9Or12Or15TypePacketExpected = 0;
g_decArgo_nbOf3Or10Or13Or16TypePacketExpected = 0;
g_decArgo_nbOf13Or11TypePacketExpected = 0;
g_decArgo_nbOf14Or12TypePacketExpected = 0;

return

% ------------------------------------------------------------------------------
% Collect information on received packet types
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
%   05/29/2017 - RNU - creation
% ------------------------------------------------------------------------------
function collect_received_packet_type_info

% arrays to store rough information on received data
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8Or11Or14TypePacketReceived;
global g_decArgo_nbOf2Or9Or12Or15TypePacketReceived;
global g_decArgo_nbOf3Or10Or13Or16TypePacketReceived;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;

% array ro store statistics on received packets
global g_decArgo_nbDescentPacketsReceived;
global g_decArgo_nbParkPacketsReceived;
global g_decArgo_nbAscentPacketsReceived;
global g_decArgo_nbNearSurfacePacketsReceived;
global g_decArgo_nbInAirPacketsReceived;
global g_decArgo_nbHydraulicPacketsReceived;
global g_decArgo_nbTechPacketsReceived;
global g_decArgo_nbTech1PacketsReceived;
global g_decArgo_nbTech2PacketsReceived;
global g_decArgo_nbParmPacketsReceived;
global g_decArgo_nbParm1PacketsReceived;
global g_decArgo_nbParm2PacketsReceived;

g_decArgo_nbDescentPacketsReceived = g_decArgo_nbOf1Or8TypePacketReceived;
g_decArgo_nbParkPacketsReceived = g_decArgo_nbOf2Or9TypePacketReceived;
g_decArgo_nbAscentPacketsReceived = g_decArgo_nbOf3Or10TypePacketReceived;
g_decArgo_nbHydraulicPacketsReceived = g_decArgo_nbOf6TypePacketReceived;
g_decArgo_nbTech1PacketsReceived = g_decArgo_0TypePacketReceivedFlag;
g_decArgo_nbTech2PacketsReceived = g_decArgo_4TypePacketReceivedFlag;
g_decArgo_nbParmPacketsReceived = g_decArgo_5TypePacketReceivedFlag;

return
