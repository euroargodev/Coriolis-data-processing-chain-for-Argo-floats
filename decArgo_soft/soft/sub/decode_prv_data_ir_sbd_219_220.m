% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_decodedData] = decode_prv_data_ir_sbd_219_220(a_tabData, a_sbdFileName, a_sbdFileDate)
%
% INPUT PARAMETERS :
%   a_tabData     : data packet to decode
%   a_sbdFileName : SBD file name
%   a_sbdFileDate : SBD file date
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
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = decode_prv_data_ir_sbd_219_220(a_tabData, a_sbdFileName, a_sbdFileDate)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_presCountsDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;


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
      % technical packet
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      % item bit lengths
      tabNbBits = [ ...
         repmat(16, 1, 6) ...
         16 16 16 8 8 8 ...
         repmat(8, 1, 10) ...
         8 8 16 8 8 8 16 8 ...
         8 8 ...
         448 ...
         ];
      % get item bits
      tabTech = get_bits(firstBit, tabNbBits, msgData);
      
      %       if (~any(tabTech([1:12 22]) ~= 0))
      if (~any(tabTech([1:5 22]) ~= 0))
         deepCycle = 0;
      else
         deepCycle = 1;
      end

      % compute float time
      floatTimeSec = tabTech(13)*3600 + tabTech(14)*60 + tabTech(15);
      floatTime = fix(a_sbdFileDate) + floatTimeSec/86400;
      if (floatTime > (floor(a_sbdFileDate*1440)/1440))
         floatTime = floatTime - round((floor(a_sbdFileDate*1440)/1440)-floatTime);
      end
      
      % pressure sensor offset
      tabTech(16) = twos_complement_dec_argo(tabTech(16), 8);
      
      % compute GPS location
      if (tabTech(26) == 0)
         signLat = 1;
      else
         signLat = -1;
      end
      gpsLocLat = signLat*(tabTech(23) + (tabTech(24) + ...
         tabTech(25)/10000)/60);
      if (tabTech(30) == 0)
         signLon = 1;
      else
         signLon = -1;
      end
      gpsLocLon = signLon*(tabTech(27) + (tabTech(28) + ...
         tabTech(29)/10000)/60);
      
      gpsValidFlag = 1;
      if (~any(tabTech([23:25 27 28]) ~= 0)) % tabTech(29) can be ~= 0 on a bad GPS fix (Ex: 6901477 #40)
         gpsValidFlag = 0;
      end
      
      tabTech = [packType tabTech(1:32)' gpsValidFlag deepCycle floatTime gpsLocLon gpsLocLat a_sbdFileDate];
      
      decodedData.decData = {tabTech};
      decodedData.expNbAsc = tabTech(23);
      decodedData.deep = deepCycle;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case 1
      % CTD packets
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      tabNbBits = [ ...
         repmat(16, 1, 49) ...
         8 ...
         ];
      % get item bits
      ctdValues = get_bits(firstBit, tabNbBits, msgData);
      
      if (~any(ctdValues(2:end) ~= 0))
         fprintf('WARNING: Float #%d: One empty packet type #%d has been received\n', ...
            g_decArgo_floatNum, ...
            packType);
         return
      end
      
      % there are 1 PTS measurement and 23 TS measurements per packet
      
      % store raw data values
      tabPres = ones(24, 1)*g_decArgo_presCountsDef;
      tabTemp = ones(24, 1)*g_decArgo_tempCountsDef;
      tabPsal = ones(24, 1)*g_decArgo_salCountsDef;
      nbMeas = 0;
      pres = ctdValues(1);
      presOri = pres;
      temp = ctdValues(2);
      psal = ctdValues(3);
      if ~((pres == 0) && (temp == 0) && (psal == 0))
         tabPres(1) = pres;
         tabTemp(1) = temp;
         tabPsal(1) = psal;
         nbMeas = nbMeas + 1;
      end
      for idBin = 1:23
         
         temp = ctdValues(2*(idBin-1)+4);
         psal = ctdValues(2*(idBin-1)+5);
         
         if ~((temp == 0) && (psal == 0))
            tabPres(idBin+1) = presOri - idBin*10; % 10 cBar between each pressures of a given packet
            tabTemp(idBin+1) = temp;
            tabPsal(idBin+1) = psal;
            nbMeas = nbMeas + 1;
         end
      end
      
      dataCTD = [packType tabPres' tabTemp' tabPsal'];
      
      decodedData.decData = {dataCTD};
      decodedData.deep = 1;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
         g_decArgo_floatNum, ...
         packType);
      return
end

o_decodedData = decodedData;

return
