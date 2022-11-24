% ------------------------------------------------------------------------------
% Decode PROVOR CTD, technical and parameter messages.
%
% SYNTAX :
%  [o_tabProfCTDO, o_tabDrifCTDO, o_tabTech1, o_tabTech2, o_tabParam, ...
%    o_deepCycle, o_floatClockDrift, o_meanParkPres, o_maxProfPres] = ...
%    decode_prv_data_32(a_tabSensors, a_tabDates)
%
% INPUT PARAMETERS :
%   a_tabSensors : data frame to decode
%                  contents of "o_sensors" array:
%                  column #1                    : message type
%                  column #2                    : message redundancy
%                  column #3 to #(frameLength+2): message data frame
%   a_tabDates   : corresponding dates of Argos messages
%
% OUTPUT PARAMETERS :
%   o_tabProfCTDO     : decoded profile CTDO data
%   o_tabDrifCTDO     : decoded drift CTDO data
%   o_tabTech1        : decoded technical #1 data
%   o_tabTech2        : decoded technical #2 data
%   o_tabParam        : decoded parameter date
%   o_deepCycle       : deep cycle flag
%   o_floatClockDrift : computed float clock drift
%   o_meanParkPres    : mean of the drift measurement pressures
%   o_maxProfPres     : deepest ascending profile measurement
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/07/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfCTDO, o_tabDrifCTDO, o_tabTech1, o_tabTech2, o_tabParam, ...
   o_deepCycle, o_floatClockDrift, o_meanParkPres, o_maxProfPres] = ...
   decode_prv_data_32(a_tabSensors, a_tabDates)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_presDef;
global g_decArgo_presCountsDef;
global g_decArgo_presCountsOkDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_tPhaseDoxyCountsDef;

% configuration values
global g_decArgo_generateNcTech;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output parameters initialization
o_tabProfCTDO = [];
o_tabDrifCTDO = [];
o_tabTech1 = [];
o_tabTech2 = [];
o_tabParam = [];
o_deepCycle = 1;
o_floatClockDrift = [];
o_meanParkPres = g_decArgo_presDef;
o_maxProfPres = g_decArgo_presDef;


% decode the Argos data messages
tabProfCTDO = [];
tabDrifCTDO = [];
for idMes = 1:size(a_tabSensors, 1)
   % message type
   msgType = a_tabSensors(idMes, 1);
   % message redundancy
   msgOcc = a_tabSensors(idMes, 2);
   % message data frame
   msgData = a_tabSensors(idMes, 3:end);

   firstProfCtdoDate = [];
   firstDriftCtdoDate = [];
   firstDriftCtdoTime = [];
   presCounts = [];
   presCountsOk = [];
   tempCounts = [];
   salCounts = [];
   oxyCounts = [];
   switch (msgType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical message #1
         
         % technical message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [ ...
            9 ...
            1 ...
            8 9 1 ...
            5 5 ...
            3 4 5 5 ...
            5 5 ...
            8 4 8 3 3 ...
            3 3 5 5 ...
            5 5 ...
            5 5 5 7 8 8 7 8 ...
            3 3 7 1 2 4 2 1 5 4 ...
            3 8 5 6 4 ...
            ];
         % get item bits
         o_tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         % some pressures are given in bars
         o_tabTech1(14) = o_tabTech1(14)*10;
         if (o_tabTech1(45) ~= 0)
            o_tabTech1(45) = (o_tabTech1(45)+200)*10;
         end
         
         % BE CAREFUL
         % there is an issue with grounding day
         % => the decoded value should be 16 - transmitted value
         if (o_tabTech1(18) > 0)
            o_tabTech1(15) = mod(16 - o_tabTech1(15), 16);
         end
         
         % output CSV file
         if (~isempty(g_decArgo_outputCsvFileId))
            print_tech1_data_in_csv_30_32(o_tabTech1);
         end
         
         % check if it is a deep cycle
         deepInfo = unique(o_tabTech1([6:13 19:32]));
         if ((length(deepInfo) == 1) && (deepInfo == 0))
            o_deepCycle = 0;
         end
         
         % check cycle number consistency
         offset = o_deepCycle;
         if ((o_tabTech1(1) + offset) ~= g_decArgo_cycleNum)
            fprintf('ERROR: Float #%d Cycle #%d: Cycle number of Argos file name (%d) and transmitted cycle number (%d) are inconsistent\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNum, o_tabTech1(1));
         end
         
         % store technical message #1 redundancy
         if (g_decArgo_generateNcTech ~= 0)
            g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
               g_decArgo_cycleNum 1000];
            g_decArgo_outputNcParamValue{end+1} = msgOcc;
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 1
         % technical message #2
         
         % technical message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [ ...
            9 11 ...
            5 4 11 ...
            11 8 11 8 8 ...
            5 11 11 ...
            11 8 8 ...
            8 8 ...
            11 11 ...
            5 6 6 5 7 ...
            5 8 6 ...
            2 ...
            ];
         % get item bits
         o_tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         % compute pressure sensor offset
         o_tabTech2(25) = twos_complement_dec_argo(o_tabTech2(25), 7);
         
         % some pressures are given in bars
         o_tabTech2(9) = o_tabTech2(9)*10;
         o_tabTech2(10) = o_tabTech2(10)*10;
         o_tabTech2(16) = o_tabTech2(16)*10;
         o_tabTech2(17) = o_tabTech2(17)*10;
         o_tabTech2(18) = o_tabTech2(18)*10;
         
         % compute clock float drift
         firstBit = 199;
         tabNbBits = [5 6 6];
         floatTimeParts = get_bits(firstBit, tabNbBits, msgData);
         floatTimeHour = floatTimeParts(1) + floatTimeParts(2)/60 + floatTimeParts(3)/3600;
         utcTimeJuld = a_tabDates(idMes);
         floatTimeJuld = fix(utcTimeJuld)+floatTimeHour/24;
         tabFloatTimeJuld = [floatTimeJuld-1 floatTimeJuld floatTimeJuld+1];
         [~, idMin] = min(abs(tabFloatTimeJuld-utcTimeJuld));
         floatTimeJuld = tabFloatTimeJuld(idMin);
         % check consistency of float day (gregorain calendar)
         [dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(floatTimeJuld);
         if (o_tabTech2(24) ~= dd)
            fprintf('WARNING: Float #%d Cycle #%d: Computed float day (%d) differs from transmitted one (%d)\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               dd, o_tabTech2(24));
         end
         o_floatClockDrift = floatTimeJuld - utcTimeJuld;
         
         % output CSV file
         if (~isempty(g_decArgo_outputCsvFileId))
            print_tech2_data_in_csv_30_32(o_tabTech2, utcTimeJuld, o_floatClockDrift);
         end
         
         % check if it is a deep cycle
         deepInfo = unique(o_tabTech2([3:5 6:8 11 14 15 19 20]));
         if ((length(deepInfo) == 1) && (deepInfo == 0))
            o_deepCycle = 0;
         end
         
         % check cycle number consistency
         offset = o_deepCycle;
         if ((o_tabTech2(1) + offset) ~= g_decArgo_cycleNum)
            fprintf('ERROR: Float #%d Cycle #%d: Cycle number of Argos file name (%d) and transmitted cycle number (%d) are inconsistent\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNum, o_tabTech2(1));
         end
         
         % output NetCDF files
         if (g_decArgo_generateNcTech ~= 0)
            store_tech2_data_for_nc_30_32(o_tabTech2, floatTimeParts, utcTimeJuld, o_floatClockDrift, o_deepCycle);
            
            % store technical message #2 redundancy
            g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
               g_decArgo_cycleNum 1001];
            g_decArgo_outputNcParamValue{end+1} = msgOcc;
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 2
         % parameter message
         
         % parameter message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [ ...
            9 9 10 10 4 5 repmat(8, 1, 4) repmat(11, 1, 9) 10 8 1 11 8 3 ...
            9 ...
            ];
         % get item bits
         o_tabParam = get_bits(firstBit, tabNbBits, msgData);
                           
         % check if it is a deep cycle
         o_deepCycle = 0;
         
         % output CSV file
         if (~isempty(g_decArgo_outputCsvFileId))
            print_param_data_in_csv_30_32(o_tabParam);
         end
         
         % store parameter message redundancy
         if (g_decArgo_generateNcTech ~= 0)
            if (g_decArgo_cycleNum == 0)
               g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
                  g_decArgo_cycleNum 1002];
               g_decArgo_outputNcParamValue{end+1} = msgOcc;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {7, 9}
         % descent or ascent profile CTDO message

         if (msgType == 7)
            sign= -1; % descent profile
         else
            sign= 1; % ascent profile
         end

         % CTDO data message coding items are "dynamic" (length depends on contents)
         % there are between 3 and 5 PTSO measurements per Argos message

         % get the first PTSO date and data
         firstBit = 21;
         tabNbBits = [9 11 15 15 13];
         values = get_bits(firstBit, tabNbBits, msgData);

         firstProfCtdoDate = values(1);
         presCounts(1) = values(2);
         % pressure is coded on 11 bits (from 0 to 2047 dbar) we must check if it has overflowed
         if (presCounts(1) == 2047)
            presCountsOk(1) = 0;
         else
            presCountsOk(1) = 1;
         end
         tempCounts(1) = values(3);
         salCounts(1) = values(4);
         oxyCounts(1) = values(5);

         % get the other PTSO data
         curCtdoMes = 2;
         curBit = 84;
         while (1)
            % pressure
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 11, msgData);
               if (isempty(value))
                  break;
               end
               presCounts(curCtdoMes) = value;
               if (value == 2047)
                  presCountsOk(curCtdoMes) = 0;
               else
                  presCountsOk(curCtdoMes) = 1;
               end
               curBit = curBit + 11;
            else
               relPresCounts = get_bits(curBit, 6, msgData);
               if (isempty(relPresCounts))
                  break;
               end
               presCounts(curCtdoMes) = presCounts(curCtdoMes-1) - sign*relPresCounts;
               presCountsOk(curCtdoMes) = 1;
               curBit = curBit + 6;
            end

            % temperature
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 15, msgData);
               if (isempty(value))
                  break;
               end
               tempCounts(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relTempCounts = get_bits(curBit, 10, msgData);
               if (isempty(relTempCounts))
                  break;
               end
               tempCounts(curCtdoMes) = tempCounts(curCtdoMes-1) + sign*(relTempCounts - 100);
               curBit = curBit + 10;
            end

            % salinity
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 15, msgData);
               if (isempty(value))
                  break;
               end
               salCounts(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relSalCounts = get_bits(curBit, 8, msgData);
               if (isempty(relSalCounts))
                  break;
               end
               salCounts(curCtdoMes) = salCounts(curCtdoMes-1) + sign*(relSalCounts - 25);
               curBit = curBit + 8;
            end

            % oxygen
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 13, msgData);
               if (isempty(value))
                  break;
               end
               oxyCounts(curCtdoMes) = value;
               curBit = curBit + 13;
            else
               relOxyCounts = get_bits(curBit, 9, msgData);
               if (isempty(relOxyCounts))
                  break;
               end
               oxyCounts(curCtdoMes) = oxyCounts(curCtdoMes-1) + relOxyCounts - 256;
               curBit = curBit + 9;
            end

            curCtdoMes = curCtdoMes + 1;
            if (curCtdoMes == 6)
               break;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 8
         % submerged drift CTD message

         % CTDO data message coding items are "dynamic" (length depends on contents)
         % there are between 3 and 5 PTSO measurements per Argos message

         % get the first PTSO date, time and data
         firstBit = 21;
         tabNbBits = [6 5 11 15 15 13];
         values = get_bits(firstBit, tabNbBits, msgData);

         firstDriftCtdoDate = values(1);
         firstDriftCtdoTime = values(2);
         presCounts(1) = values(3);
         % pressure is coded on 11 bits (from 0 to 2047 dbar) we must check if it has overflowed
         if (presCounts(1) == 2047)
            presCountsOk(1) = 0;
         else
            presCountsOk(1) = 1;
         end
         tempCounts(1) = values(4);
         salCounts(1) = values(5);
         oxyCounts(1) = values(6);

         % get the other PTSO data
         curCtdoMes = 2;
         curBit = 86;
         while (1)
            % pressure
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 11, msgData);
               if (isempty(value))
                  break;
               end
               presCounts(curCtdoMes) = value;
               if (value == 2047)
                  presCountsOk(curCtdoMes) = 0;
               else
                  presCountsOk(curCtdoMes) = 1;
               end
               curBit = curBit + 11;
            else
               relPresCounts = twos_complement_dec_argo(get_bits(curBit, 6, msgData), 6);
               if (isempty(relPresCounts))
                  break;
               end
               presCounts(curCtdoMes) = presCounts(curCtdoMes-1) + relPresCounts;
               presCountsOk(curCtdoMes) = 1;
               curBit = curBit + 6;
            end

            % temperature
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 15, msgData);
               if (isempty(value))
                  break;
               end
               tempCounts(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relTempCounts = twos_complement_dec_argo(get_bits(curBit, 10, msgData), 10);
               if (isempty(relTempCounts))
                  break;
               end
               tempCounts(curCtdoMes) = tempCounts(curCtdoMes-1) + relTempCounts;
               curBit = curBit + 10;
            end

            % salinity
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 15, msgData);
               if (isempty(value))
                  break;
               end
               salCounts(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relSalCounts = twos_complement_dec_argo(get_bits(curBit, 8, msgData), 8);
               if (isempty(relSalCounts))
                  break;
               end
               salCounts(curCtdoMes) = salCounts(curCtdoMes-1) + relSalCounts;
               curBit = curBit + 8;
            end

            % oxygen
            formatBit = get_bits(curBit, 1, msgData);
            if (isempty(formatBit))
               break;
            end
            curBit = curBit + 1;
            if (formatBit == 0)
               value = get_bits(curBit, 13, msgData);
               if (isempty(value))
                  break;
               end
               oxyCounts(curCtdoMes) = value;
               curBit = curBit + 13;
            else
               relOxyCounts = get_bits(curBit, 9, msgData);
               if (isempty(relOxyCounts))
                  break;
               end
               oxyCounts(curCtdoMes) = oxyCounts(curCtdoMes-1) + relOxyCounts - 256;
               curBit = curBit + 9;
            end

            curCtdoMes = curCtdoMes + 1;
            if (curCtdoMes == 6)
               break;
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done for unexpected message type #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            msgType);
   end
   
   % shift and store the decoded PTSO data
   if (~isempty(presCounts))
      % number of PTSO measurements in this Argos message
      nbMes = min([length(presCounts) length(tempCounts) length(salCounts) length(oxyCounts)]);
      presCounts(nbMes+1:end) = [];
      presCountsOk(nbMes+1:end) = [];
      tempCounts(nbMes+1:end) = [];
      salCounts(nbMes+1:end) = [];
      oxyCounts(nbMes+1:end) = [];

      if (~isempty(find(presCountsOk == 0, 1)))
         msgTypeStr = [];
         if (msgType == 7)
            msgTypeStr = 'descent profile';
         elseif (msgType == 8)
            msgTypeStr = 'submerged drift';
         elseif (msgType == 9)
            msgTypeStr = 'ascent profile';
         end
         fprintf('WARNING: Float #%d Cycle #%d:  "2047 dbar": overflow detected in transmitted pressure counts (%d value(s) involved in %s measurements)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(find(presCountsOk == 0)), msgTypeStr);
      end

      % store the data
      presCounts(nbMes+1:5) = ones(1, 5-(nbMes+1)+1)*g_decArgo_presCountsDef;
      presCountsOk(nbMes+1:5) = ones(1, 5-(nbMes+1)+1)*g_decArgo_presCountsOkDef;
      tempCounts(nbMes+1:5) = ones(1, 5-(nbMes+1)+1)*g_decArgo_tempCountsDef;
      salCounts(nbMes+1:5) = ones(1, 5-(nbMes+1)+1)*g_decArgo_salCountsDef;
      oxyCounts(nbMes+1:5) = ones(1, 5-(nbMes+1)+1)*g_decArgo_tPhaseDoxyCountsDef;
      if (msgType == 8)
         tabDrifCTDO = [tabDrifCTDO; msgOcc firstDriftCtdoDate firstDriftCtdoTime nbMes presCounts presCountsOk tempCounts salCounts oxyCounts];
      else
         tabProfCTDO = [tabProfCTDO; msgType msgOcc firstProfCtdoDate nbMes presCounts presCountsOk tempCounts salCounts oxyCounts];
      end
   end
end

% output NetCDF files
if (g_decArgo_generateNcTech ~= 0)
   if (~isempty(o_tabTech1))
      floatClockDrift = o_floatClockDrift;
      if (isempty(floatClockDrift))
         floatClockDrift = 0;
      end
      store_tech1_data_for_nc_32(o_tabTech1, floatClockDrift, o_deepCycle);
   end
end

% compute mean value of drift pressures
if (~isempty(tabDrifCTDO))
   parkPres = reshape(tabDrifCTDO(:, 5:9), size(tabDrifCTDO, 1)*5, 1);
   parkPresOk = reshape(tabDrifCTDO(:, 10:14), size(tabDrifCTDO, 1)*5, 1);
   parkPres(find(parkPresOk == 0)) = g_decArgo_presCountsDef;
   parkPres(find(parkPres == g_decArgo_presCountsDef)) = [];
   if (~isempty(parkPres))
      o_meanParkPres = mean(parkPres);
   end
end

% compute deepest value of ascending profile
if (~isempty(tabProfCTDO))
   idAscProf = find(tabProfCTDO(:, 1) == 9);
   if (~isempty(idAscProf))
      profPres = reshape(tabProfCTDO(idAscProf, 5:9), size(idAscProf, 1)*5, 1);
      profPresOk = reshape(tabProfCTDO(idAscProf, 10:14), size(idAscProf, 1)*5, 1);
      profPres(find(profPresOk == 0)) = g_decArgo_presCountsDef;
      profPres(find(profPres == g_decArgo_presCountsDef)) = [];
      if (~isempty(profPres))
         o_maxProfPres = max(profPres);
      end
   end
end

% sort profile CTDO data by pressure (of dated measurement)
if (~isempty(tabProfCTDO))
   nextLine = 1;
   msgTypes = sort(unique(tabProfCTDO(:, 1)));
   for idType = 1:length(msgTypes)
      idForType = find(tabProfCTDO(:, 1) == msgTypes(idType));
      if (msgTypes(idType) == 9)
         [sorted, idSorted] = sort(tabProfCTDO(idForType, 5), 'descend');
      else
         [sorted, idSorted] = sort(tabProfCTDO(idForType, 5), 'ascend');
      end
      o_tabProfCTDO((nextLine-1)+1:(nextLine-1)+length(idForType), :) = ...
         tabProfCTDO(idForType(idSorted), :);
      nextLine = nextLine + length(idForType);
   end
end

% sort drift CTDO data by date
if (~isempty(tabDrifCTDO))
   msgdate = tabDrifCTDO(:, 2);
   [sorted, idSorted] = sort(msgdate);
   o_tabDrifCTDO = tabDrifCTDO(idSorted, :);
   msgDate = unique(msgdate);
   for idDate = 1:length(msgDate)
      idForDate = find(o_tabDrifCTDO(:, 2) == msgDate(idDate));
      [sorted, idSorted] = sort(o_tabDrifCTDO(idForDate, 3));
      o_tabDrifCTDO(idForDate, :) = ...
         o_tabDrifCTDO(idForDate(idSorted), :);
   end
end

return;
