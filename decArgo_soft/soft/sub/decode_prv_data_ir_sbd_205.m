% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech, o_dataCTD, o_floatParam, o_deepCycle] = ...
%    decode_prv_data_ir_sbd_205(a_tabData, a_tabDataDates, a_procLevel, a_firstDeepCycleDone)
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
%   o_tabTech     : decoded technical data
%   o_dataCTD     : decoded data from CTD
%   o_floatParam  : decoded parameter data
%   o_deepCycle   : deep cycle flag (1 if it is a deep cycle 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech, o_dataCTD, o_floatParam, o_deepCycle] = ...
   decode_prv_data_ir_sbd_205(a_tabData, a_tabDataDates, a_procLevel, a_firstDeepCycleDone)

% output parameters initialization
o_tabTech = [];
o_dataCTD = [];
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

% flag to detect a second Iridium session
global g_decArgo_secondIridiumSession;


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
            8 16 ...
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
            repmat(8, 1, 11) ...
            ];
         % get item bits
         tabTech = get_bits(firstBit, tabNbBits, msgData);
         
         % subsurface information are set to 0 for a surface cycle
         if ~((length(unique(tabTech(3:42))) == 1) && (unique(tabTech(3:42)) == 0))
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
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % float technical #1 packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            8 16 ...
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
            repmat(8, 1, 11) ...
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
         
         % subsurface information are set to 0 for a surface cycle
         if (g_decArgo_secondIridiumSession == 0)
            if ((length(unique(tabTech(3:42))) == 1) && (unique(tabTech(3:42)) == 0))
               o_deepCycle = 0;
            else
               o_deepCycle = 1;
            end
         else
            o_deepCycle = 0;
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
         % CTD packets
         
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
            repmat(16, 1, 45) ...
            repmat(8, 1, 5) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         % there are 15 PTS measurements per packet
         
         % store raw data values
         tabDate = [];
         tabPres = [];
         tabTemp = [];
         tabPsal = [];
         nbMeas = 0;
         for idBin = 1:15
            if (idBin > 1)
               measDate = g_decArgo_dateDef;
            else
%                fprintf('Relative day: %f\n', ctdValues(1)/24);
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
            repmat(8, 1, 7) 16 ...
            16 repmat(8, 1, 6) 16 16 8 16 8 8 8 16 16 ...
            repmat(8, 1, 22) 16 16 ...
            repmat(8, 1, 42) ...
            ];
         % get item bits
         tabParam = get_bits(firstBit, tabNbBits, msgData);
         tabParam(8) = tabParam(8) + 1;

         % compute float time
         floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         % calibration coefficients
         tabParam(47) = tabParam(47)/1000;
         tabParam(48) = -tabParam(48);
         
         o_floatParam = [o_floatParam; ...
            packType tabParam' floatTime sbdFileDate];
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

return;
