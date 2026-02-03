% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_decodedData] = decode_prv_data_ir_sbd_228( ...
%    a_tabData, a_sbdFileName, a_sbdFileDate, a_launchDate)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/22/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_prv_data_ir_sbd_228( ...
   a_tabData, a_sbdFileName, a_sbdFileDate, a_launchDate)

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
global g_decArgo_durationDef;


% packet type
packType = a_tabData(1);

% consider only parameter packets for data received before launch date
if (a_sbdFileDate < a_launchDate)
   if (~ismember(packType, [5, 7]))
      return
   end
end

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
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
            
      % store clock offset
      if (tabTech1(58)) % clock offset is relevant only on a valid GPS fix
         store_clock_offset_prv_ir(cycleNum, floatTime, tabTech1(73));
      end

      tabTech1 = [packType tabTech1(1:72)' floatTime gpsLocLon gpsLocLat a_sbdFileDate];
      decodedData.decData = {tabTech1};
      decodedData.cyNumRaw = cycleNum;
      decodedData.eolFlag = eolFlag;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
         8 ...
         8 ...
         repmat(8, 1, 40) ...
         ];
      % get item bits
      tabTech2 = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = tabTech2(1);
      
      % compute last reset date
      floatLastResetTime = datenum(sprintf('%02d%02d%02d', tabTech2(35:40)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
      
      tabTech2 = [packType tabTech2(1:42)' a_sbdFileDate];
      
      decodedData.decData = {tabTech2};
      decodedData.cyNumRaw = cycleNum;
      decodedData.resetDate = floatLastResetTime;
      decodedData.expNbDesc = tabTech2(3);
      decodedData.expNbDrift = tabTech2(4);
      decodedData.expNbAsc = tabTech2(5);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 26
      % technical packet dedicated to 3T prototype
            
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         16 ...
         repmat(8, 1, 8) ...
         repmat(16, 1, 11) ...
         repmat(16, 1, 11) 8 ...
         repmat(16, 1, 11) 8 ...
         repmat(16, 1, 7) 8 ...
         repmat(8, 1, 6) ...
         ];
      % get item bits
      tabTech3 = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = tabTech3(1);
            
      tabTech3 = [packType tabTech3(1:52)' a_sbdFileDate];
      
      decodedData.decData = {tabTech3};
      decodedData.cyNumRaw = cycleNum;
      decodedData.expNbDesc3T = tabTech3(8);
      decodedData.expNbDrift3T = tabTech3(9);
      decodedData.expNbAsc3T = tabTech3(10);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {23, 24, 25}
      % CTD packets dedicated to 3T prototype
            
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         16 8 8 ...
         repmat(16, 1, 40) ...
         repmat(8, 1, 15) ...
         ];
      % get item bits
      ctdValues = get_bits(firstBit, tabNbBits, msgData);
                  
      % there are 4 PTS measurements from each sensor per packet
      
      % store raw data values
      tabDate = [];
      tabPresSbe41 = [];
      tabTempSbe41 = [];
      tabPsalSbe41 = [];
      tabPresSbe61 = [];
      tabTempSbe61 = [];
      tabPsalSbe61 = [];
      tabPresRbr = [];
      tabTempRbr = [];
      tabPsalRbr = [];
      tabTempCndcRbr = [];
      for idBin = 1:4
         if (idBin > 1)
            measDate = g_decArgo_dateDef;
         else
            measDate = ctdValues(1)/24 + ctdValues(2)/1440 + ctdValues(3)/86400;
         end

         presSbe41 = ctdValues(10*(idBin-1)+4);
         tempSbe41 = ctdValues(10*(idBin-1)+5);
         psalSbe41 = ctdValues(10*(idBin-1)+6);

         presSbe61 = ctdValues(10*(idBin-1)+7);
         tempSbe61 = ctdValues(10*(idBin-1)+8);
         psalSbe61 = ctdValues(10*(idBin-1)+9);

         presRbr = ctdValues(10*(idBin-1)+10);
         tempRbr = ctdValues(10*(idBin-1)+11);
         psalRbr = ctdValues(10*(idBin-1)+12);
         tempCndcRbr = ctdValues(10*(idBin-1)+13);

         if ~((presSbe41 == 0) && (tempSbe41 == 0) && (psalSbe41 == 0) && ...
               (presSbe61 == 0) && (tempSbe61 == 0) && (psalSbe61 == 0) && ...
               (presRbr == 0) && (tempRbr == 0) && (psalRbr == 0) && (tempCndcRbr == 0))

            tabDate = [tabDate; measDate];

            if ~((presSbe41 == 0) && (tempSbe41 == 0) && (psalSbe41 == 0))
               tabPresSbe41 = [tabPresSbe41; presSbe41];
               tabTempSbe41 = [tabTempSbe41; tempSbe41];
               tabPsalSbe41 = [tabPsalSbe41; psalSbe41];
            else
               tabPresSbe41 = [tabPresSbe41; g_decArgo_presCountsDef];
               tabTempSbe41 = [tabTempSbe41; g_decArgo_tempCountsDef];
               tabPsalSbe41 = [tabPsalSbe41; g_decArgo_salCountsDef];
            end

            if ~((presSbe61 == 0) && (tempSbe61 == 0) && (psalSbe61 == 0))
               tabPresSbe61 = [tabPresSbe61; presSbe61];
               tabTempSbe61 = [tabTempSbe61; tempSbe61];
               tabPsalSbe61 = [tabPsalSbe61; psalSbe61];
            else
               tabPresSbe61 = [tabPresSbe61; g_decArgo_presCountsDef];
               tabTempSbe61 = [tabTempSbe61; g_decArgo_tempCountsDef];
               tabPsalSbe61 = [tabPsalSbe61; g_decArgo_salCountsDef];
            end

            if ~((presRbr == 0) && (tempRbr == 0) && (psalRbr == 0) && (tempCndcRbr == 0))
               tabPresRbr = [tabPresRbr; presRbr];
               tabTempRbr = [tabTempRbr; tempRbr];
               tabPsalRbr = [tabPsalRbr; psalRbr];
               tabTempCndcRbr = [tabTempCndcRbr; tempCndcRbr];
            else
               tabPresRbr = [tabPresRbr; g_decArgo_presCountsDef];
               tabTempRbr = [tabTempRbr; g_decArgo_tempCountsDef];
               tabPsalRbr = [tabPsalRbr; g_decArgo_salCountsDef];
               tabTempCndcRbr = [tabTempCndcRbr; g_decArgo_tempCountsDef];
            end
         else
            tabDate = [tabDate; g_decArgo_dateDef];
            tabPresSbe41 = [tabPresSbe41; g_decArgo_presCountsDef];
            tabTempSbe41 = [tabTempSbe41; g_decArgo_tempCountsDef];
            tabPsalSbe41 = [tabPsalSbe41; g_decArgo_salCountsDef];
            tabPresSbe61 = [tabPresSbe61; g_decArgo_presCountsDef];
            tabTempSbe61 = [tabTempSbe61; g_decArgo_tempCountsDef];
            tabPsalSbe61 = [tabPsalSbe61; g_decArgo_salCountsDef];
            tabPresRbr = [tabPresRbr; g_decArgo_presCountsDef];
            tabTempRbr = [tabTempRbr; g_decArgo_tempCountsDef];
            tabPsalRbr = [tabPsalRbr; g_decArgo_salCountsDef];
            tabTempCndcRbr = [tabTempCndcRbr; g_decArgo_tempCountsDef];
         end
      end

      dataCTD = [packType nan tabDate' ones(1, length(tabDate))*-1 ...
         tabPresSbe41' tabTempSbe41' tabPsalSbe41' ...
         tabPresSbe61' tabTempSbe61' tabPsalSbe61' ...
         tabPresRbr' tabTempRbr' tabPsalRbr' tabTempCndcRbr' a_sbdFileDate];

      decodedData.decData = {dataCTD};

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 5
      % parameter packet
            
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         repmat(8, 1, 6) 16 ...
         16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
         repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 8 8 16 16 16 ...
         16 16 8 8 16 16 8 8 16 8 8 8 8 16 ...
         8 ...
         8 ...
         ];
      % get item bits
      tabParam = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = tabParam(7)-1;
      
      % compute float time
      floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
      
      % alternated profile pressure
      tabParam(42) = tabParam(42)*10;
      
      % calibration coefficients
      tabParam(60) = tabParam(60)/1000;
      if (tabParam(61) < 32768) % 32768 = 65536/2
         tabParam(61) = -tabParam(61);
      else
         tabParam(61) = 65536 - tabParam(61);
      end
      
      % reference temperature (PG4)
      tabParam(66) = twos_complement_dec_argo(tabParam(66), 16)/1000;

      floatParam = [packType cycleNum tabParam' floatTime a_sbdFileDate];
      
      decodedData.decData = {floatParam};
      decodedData.cyNumRaw = cycleNum;
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 27
      % parameter paket dedicated to 3T prototype
            
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         repmat(8, 1, 6) 16 ...
         repmat(16, 1, 20) ...
         repmat(8, 1, 51) ...
         ];
      % get item bits
      tabParam3T = get_bits(firstBit, tabNbBits, msgData);
      
      cycleNum = tabParam3T(7)-1;

      % cbar => dbar conversion
      tabParam3T(14) = tabParam3T(14)/10;
      tabParam3T(15) = tabParam3T(15)/10;
      tabParam3T(20) = tabParam3T(20)/10;
      tabParam3T(21) = tabParam3T(21)/10;
      tabParam3T(22) = tabParam3T(22)/10;
      tabParam3T(23) = tabParam3T(23)/10;
      tabParam3T(24) = tabParam3T(24)/10;
      
      % compute float time
      floatTime = datenum(sprintf('%02d%02d%02d%02d%02d%02d', tabParam3T(1:6)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
      
      floatParam3T = [packType cycleNum tabParam3T' floatTime a_sbdFileDate];
      
      decodedData.decData = {floatParam3T};
      decodedData.cyNumRaw = cycleNum;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {6, 7}
      % EV or pump packet
            
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
      
      cycleNum = tabHy(1);
            
      % there are 15 EV actions per packet
      
      % store data values
      tabDate = [];
      tabPres = [];
      tabDuration = [];
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
         else
            tabDate = [tabDate; g_decArgo_dateDef];
            tabPres = [tabPres; g_decArgo_presCountsDef];
            tabDuration = [tabDuration; g_decArgo_durationDef];
         end
      end
      
      hydroAct = [packType tabHy(1) tabDate' ones(size(tabDate'))*g_decArgo_dateDef tabPres' tabDuration' a_sbdFileDate];
      
      decodedData.decData = {hydroAct};
      decodedData.cyNumRaw = cycleNum;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
         g_decArgo_floatNum, ...
         packType);
      return
end

% parameter packets received before launch date are assigned to cycle number -1
if (a_sbdFileDate < a_launchDate)
   decodedData.cyNumRaw = -1;
end

o_decodedData = decodedData;

return
