% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
% function [o_tabTech, o_dataCTDO, o_floatParam, o_deepCycle] = ...
%    decode_prv_data_ir_sbd_206_207_208(a_tabData, a_tabDataDates, a_procLevel, a_firstDeepCycleDone)
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
%   o_tabTech    : decoded technical data
%   o_dataCTDO   : CTDO decoded data
%   o_floatParam : decoded parameter data
%   o_deepCycle  : deep cycle flag (1 if it is a deep cycle 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech, o_dataCTDO, o_floatParam, o_deepCycle] = ...
   decode_prv_data_ir_sbd_206_207_208(a_tabData, a_tabDataDates, a_procLevel, a_firstDeepCycleDone)

% output parameters initialization
o_tabTech = [];
o_dataCTDO = [];
o_floatParam = [];
o_deepCycle = [];

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
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_tempDoxyCountsDef;

% arrays to store rough information on received data
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8Or11Or14TypePacketExpected;
global g_decArgo_nbOf1Or8Or11Or14TypePacketReceived;
global g_decArgo_nbOf2Or9Or12Or15TypePacketExpected;
global g_decArgo_nbOf2Or9Or12Or15TypePacketReceived;
global g_decArgo_nbOf3Or10Or13Or16TypePacketExpected;
global g_decArgo_nbOf3Or10Or13Or16TypePacketReceived;

% decoder configuration values
global g_decArgo_generateNcTech;


% if it is the first deep cycle or if the first deep cycle already occured, we
% add 1 to cycle numbers
if (a_procLevel ~= 0)
   if (a_firstDeepCycleDone == 0)
      
      % we try to find if it is the first deep cycle
      idTechPacket = find(a_tabData(:, 1) == 0);
      for idMes = 1:length(idTechPacket)
         
         % message data frame
         msgData = a_tabData(idTechPacket(idMes), 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 ...
            16 8 ...
            16 16 16 8 8 8 8 ...
            repmat(8, 1, 6) ...
            16 16 8 8 8 ...
            repmat(8, 1, 6) ...
            16 16 8 ...
            repmat(8, 1, 8) ...
            8 16 16 ...
            repmat(8, 1, 11) ...
            8 8 8 16 ...
            8 16 8 8 8 ...
            8 8 ...
            8 8 16 8 8 8 16 8 8 ...
            repmat(8, 1, 10) ...
            ];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         % subsurface information are set to 0 for a surface cycle
         if ~((length(unique(tabTech(32:39))) == 1) && (unique(tabTech(32:39)) == 0))
            a_firstDeepCycleDone = 1;
            break;
         end
      end
   end
end

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
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % float technical packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 ...
            16 8 ...
            16 16 16 8 8 8 8 ...
            repmat(8, 1, 6) ...
            16 16 8 8 8 ...
            repmat(8, 1, 6) ...
            16 16 8 ...
            repmat(8, 1, 8) ...
            8 16 16 ...
            repmat(8, 1, 11) ...
            8 8 8 16 ...
            8 16 8 8 8 ...
            8 8 ...
            8 8 16 8 8 8 16 8 8 ...
            repmat(8, 1, 10) ...
            ];
         
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         if (a_procLevel == 0)
            g_decArgo_0TypePacketReceivedFlag = 1;
            g_decArgo_nbOf1Or8Or11Or14TypePacketExpected = tabTech(32);
            g_decArgo_nbOf2Or9Or12Or15TypePacketExpected = tabTech(33);
            g_decArgo_nbOf3Or10Or13Or16TypePacketExpected = tabTech(34);
            continue;
         end
         
         % add one to cycle numbers (except for the prelude phase)
         tabTech(2) = tabTech(2) + a_firstDeepCycleDone;
         
         % some pressures are given in bars
         tabTech(10) = tabTech(10)*10;
         tabTech(11) = tabTech(11)*10;
         tabTech(14) = tabTech(14)*10;
         tabTech(15) = tabTech(15)*10;
         tabTech(22) = tabTech(22)*10;
         tabTech(27) = tabTech(27)*10;
         tabTech(28) = tabTech(28)*10;
         tabTech(55) = tabTech(55)*10;
         tabTech(60) = tabTech(60)*10;

         % set cycle number
         g_decArgo_cycleNum = tabTech(2);
         fprintf('cyle #%d\n', g_decArgo_cycleNum);
         
         % all subsurface information (tabTech(3:42)) are not set to 0 for a
         % surface cycle (see 6901470 #164 and #165)
         % => only message and measurement counts (tabTech(32:39)) are checked
         % to choose between a deep or a surface cycle
         if ((length(unique(tabTech(32:39))) == 1) && (unique(tabTech(32:39)) == 0))
            o_deepCycle = 0;
         else
            o_deepCycle = 1;
         end
         
         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech(43:48)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % compute GPS location
         if (tabTech(68) == 0)
            signLat = 1;
         else
            signLat = -1;
         end
         gpsLocLat = signLat*(tabTech(65) + (tabTech(66) + ...
            tabTech(67)/10000)/60);
         if (tabTech(72) == 0)
            signLon = 1;
         else
            signLon = -1;
         end
         gpsLocLon = signLon*(tabTech(69) + (tabTech(70) + ...
            tabTech(71)/10000)/60);
         
         o_tabTech = [o_tabTech; ...
            packType tabTech(1:73)' floatTime gpsLocLon gpsLocLat sbdFileDate];

         % output NetCDF files
         if (g_decArgo_generateNcTech ~= 0)
            store_tech_data_for_nc_204_to_208(o_tabTech, o_deepCycle);
         end
                  
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3}
         % CTDO packets
         
         o_deepCycle = 1;

         if (a_procLevel == 0)
            if (packType == 1)
               g_decArgo_nbOf1Or8Or11Or14TypePacketReceived = g_decArgo_nbOf1Or8Or11Or14TypePacketReceived + 1;
            elseif (packType == 2)
               g_decArgo_nbOf2Or9Or12Or15TypePacketReceived = g_decArgo_nbOf2Or9Or12Or15TypePacketReceived + 1;
            elseif (packType == 3)
               g_decArgo_nbOf3Or10Or13Or16TypePacketReceived = g_decArgo_nbOf3Or10Or13Or16TypePacketReceived + 1;
            end
            continue;
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
         
         o_dataCTDO = [o_dataCTDO; ...
            packType tabDate' ones(1, length(tabDate))*-1 tabPres' tabTemp' tabPsal' tabC1Phase' tabC2Phase' tabTempDoxy'];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % parameter packet
         
         if (a_procLevel == 0)
            g_decArgo_4TypePacketReceivedFlag = 1;
            continue;
         end
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(8, 1, 6) 16 16 ...
            16 repmat(8, 1, 6) 16 16 8 16 8 8 8 16 16 8 ...
            16 repmat(8, 1, 25) 16 16 ...
            repmat(8, 1, 35) ...
            ];
         % get item bits
         tabParam = get_bits(firstBit, tabNbBits, msgData);
         tabParam(8) = tabParam(8) + 1;

         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % calibration coefficients
         tabParam(52) = tabParam(52)/1000;
         tabParam(53) = -tabParam(53);
         
         o_floatParam = [o_floatParam; ...
            packType tabParam' floatTime sbdFileDate];
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

return;
