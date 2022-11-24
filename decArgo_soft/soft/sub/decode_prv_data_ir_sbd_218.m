% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_decodedData] = decode_prv_data_ir_sbd_218(a_tabData, a_sbdFileName, a_sbdFileDate)
%
% INPUT PARAMETERS :
%   a_tabData     : data packet to decode
%   a_sbdFileName : SBD file name
%   a_sbdFileName : SBD file date
%
% OUTPUT PARAMETERS :
%   o_decodedData : decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/02/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_prv_data_ir_sbd_218(a_tabData, a_sbdFileName, a_sbdFileDate)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_tempDoxyCountsDef;


% packet type
packType = a_tabData(1);

% message data frame
msgData = a_tabData(2:end);

% structure to store decoded data
decodedData = get_decoded_data_init_struct;
decodedData.fileName = a_sbdFileName;
decodedData.fileDate = a_sbdFileDate;
decodedData.rawData = msgData;
decodedData.packType = packType;

% decode packet data

switch (packType)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 0
      % technical packet #1
            
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
      
      cycleNum = tabTech1(1);
      
      % compute float time
      floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabTech1(38:43)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;

      % pressure sensor offset
      tabTech1(44) = twos_complement_dec_argo(tabTech1(44), 8)/10;
      
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
      
      % retrieve EOL flag
      eolFlag = tabTech1(63);
      
      tabTech1 = [packType tabTech1(1:76)' floatTime gpsLocLon gpsLocLat a_sbdFileDate];
      decodedData.decData = {tabTech1};
      decodedData.cyNumRaw = cycleNum;
      decodedData.eolFlag = eolFlag;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 4
      % technical packet #2
            
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
      
      cycleNum = tabTech2(1);
      
      % compute last reset date
      floatLastResetTime = datenum(sprintf('%02d%02d%02d', tabTech2(35:40)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
      
      tabTech2 = [packType tabTech2(1:82)' a_sbdFileDate];
      
      decodedData.decData = {tabTech2};
      decodedData.cyNumRaw = cycleNum;
      decodedData.resetDate = floatLastResetTime;
      decodedData.expNbDesc = tabTech2(3);
      decodedData.expNbDrift = tabTech2(4);
      decodedData.expNbAsc = tabTech2(5);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {1, 2, 3, 13, 14}
      % CTD packets
            
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
      
      cycleNum = ctdValues(1);
      
      if (~any(ctdValues(2:end) ~= 0))
         fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
            g_decArgo_floatNum, cycleNum, ...
            packType);
         return
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
      
      dataCTD = [packType ctdValues(1) tabDate' ones(1, length(tabDate))*-1 ...
         tabPres' tabTemp' tabPsal' a_sbdFileDate];
      
      decodedData.decData = {dataCTD};
      decodedData.cyNumRaw = cycleNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {8, 9, 10, 11, 12}
      % CTDO packets
            
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
      
      cycleNum = ctdoValues(1);
      
      if (~any(ctdoValues(2:end) ~= 0))
         fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
            g_decArgo_floatNum, cycleNum, ...
            packType);
         return
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
      
      dataCTDO = [packType ctdoValues(1) tabDate' ones(1, length(tabDate))*-1 ...
         tabPres' tabTemp' tabPsal' tabC1Phase' tabC2Phase' tabTempDoxy' a_sbdFileDate];
      
      decodedData.decData = {dataCTDO};
      decodedData.cyNumRaw = cycleNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 5
      % parameter packet #1
            
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         repmat(8, 1, 6) 16 ...
         16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
         repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 8 8 16 16 ...
         repmat(8, 1, 24) ...
         ];
      % get item bits
      tabParam1 = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = tabParam1(7)-1;
      
      % compute float time
      floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam1(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
      
      % calibration coefficients
      tabParam1(59) = tabParam1(59)/1000;
      tabParam1(60) = -tabParam1(60);
            
      floatParam1 = [packType cycleNum tabParam1' floatTime a_sbdFileDate];
      
      decodedData.decData = {floatParam1};
      decodedData.cyNumRaw = cycleNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 7
      % parameter packet #2
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         repmat(8, 1, 6) 16 ...
         16 16 8 8 8 16 16 8 8 16 8 8 8 8 8 16 ...
         repmat(8, 1, 69) ...
         ];
      % get item bits
      tabParam2 = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = tabParam2(7)-1;
      
      % compute float time
      floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam2(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
            
      % reference temperature (PG5)
      tabParam2(13) = twos_complement_dec_argo(tabParam2(13), 16)/1000;
      
      floatParam2 = [packType cycleNum tabParam2' floatTime a_sbdFileDate];
      
      decodedData.decData = {floatParam2};
      decodedData.cyNumRaw = cycleNum;      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 6
      % EV or pump packet
      
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
      
      cycleNum = tabHy(1);
      
      % there are 13 EV/pump actions per packet
      
      % store data values
      tabEvAct = [];
      tabPumpAct = [];
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
               tabEvAct = [tabEvAct; ...
                  packType cycleNum date pres duration];
            else
               tabPumpAct = [tabPumpAct; ...
                  packType cycleNum date pres duration];
            end
         end
      end
      
      decodedData.decData = {{tabEvAct} {tabPumpAct}};
      decodedData.cyNumRaw = cycleNum;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
         g_decArgo_floatNum, ...
         packType);
      return
end

o_decodedData = decodedData;

return
