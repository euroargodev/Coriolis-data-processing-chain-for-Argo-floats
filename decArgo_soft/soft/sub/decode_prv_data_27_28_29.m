% ------------------------------------------------------------------------------
% Decode PROVOR CTDO and technical messages.
%
% SYNTAX :
%  [o_tabProfCTDO, o_tabDrifCTDO, o_tabTech, ...
%    o_floatClockDrift, o_meanParkPres, o_maxProfPres] = ...
%    decode_prv_data_27_28_29(a_tabSensors, a_tabDates, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabSensors : data frame to decode
%                  contents of "o_sensors" array:
%                  column #1                    : message type
%                  column #2                    : message redundancy
%                  column #3 to #(frameLength+2): message data frame
%   a_tabDates   : corresponding dates of Argos messages
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabProfCTDO     : decoded profile CTDO data
%   o_tabDrifCTDO     : decoded drift CTDO data
%   o_tabTech         : decoded technical data
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
%   11/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfCTDO, o_tabDrifCTDO, o_tabTech, ...
   o_floatClockDrift, o_meanParkPres, o_maxProfPres] = ...
   decode_prv_data_27_28_29(a_tabSensors, a_tabDates, a_decoderId)

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

% output parameters initialization
o_tabProfCTDO = [];
o_tabDrifCTDO = [];
o_tabTech = [];
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

      case 0
         % technical message

         % technical message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [8 7 8 8 4 4 8 4 8 5 5 5 5 7 8 7 8 8 17 6 3 8 8 3 8 8 1 4 4 8 3 5 8 8 1 3 1 4];
         % get item bits
         o_tabTech = get_bits(firstBit, tabNbBits, msgData);

         % compute pressure sensor offset
         o_tabTech(20) = twos_complement_dec_argo(o_tabTech(20), 6);

         % pressure sensor offset is in cbar
         o_tabTech(20) = o_tabTech(20)/10;

         % some pressures are given in bars
         o_tabTech(4) = o_tabTech(4)*10;
         o_tabTech(22) = o_tabTech(22)*10;
         o_tabTech(25) = o_tabTech(25)*10;
         o_tabTech(26) = o_tabTech(26)*10;
         o_tabTech(30) = o_tabTech(30)*10;

         % compute clock float drift
         firstBit = 138;
         tabNbBits = [5 6 6];
         floatTimeParts = get_bits(firstBit, tabNbBits, msgData);
         floatTimeHour = floatTimeParts(1) + floatTimeParts(2)/60 + floatTimeParts(3)/3600;
         utcTimeJuld = a_tabDates(idMes);
         floatTimeJuld = fix(utcTimeJuld)+floatTimeHour/24;
         tabFloatTimeJuld = [floatTimeJuld-1 floatTimeJuld floatTimeJuld+1];
         [unused, idMin] = min(abs(tabFloatTimeJuld-utcTimeJuld));
         floatTimeJuld = tabFloatTimeJuld(idMin);
         o_floatClockDrift = floatTimeJuld - utcTimeJuld;

         % output CSV file
         if (~isempty(g_decArgo_outputCsvFileId))
            print_tech_data_in_csv_4_19_25_27_to_29(o_tabTech, floatTimeParts, utcTimeJuld, o_floatClockDrift)
         end
         
         % try to detect a surface TECH message (only float time and battery
         % voltage)
         techData = o_tabTech;
         techData([19 32]) = []; % ignore float time and battery voltage
         uTechData = unique(techData);
         if ((length(uTechData) == 1) && (uTechData == 0))
            o_tabTech = [];
            continue;
         end
         
         % output NetCDF files
         if (g_decArgo_generateNcTech ~= 0)
            store_tech_data_for_nc_4_19_25_27_to_29(o_tabTech, floatTimeParts, utcTimeJuld, o_floatClockDrift)
         end

      case {4, 6}
         % descent or ascent profile CTDO message

         if (msgType == 4)
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

      case 5
         % submerged drift CTDO message

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
         fprintf('Nothing done for unexpected message type #%d\n', msgType);
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
         if (msgType == 4)
            msgTypeStr = 'descent profile';
         elseif (msgType == 5)
            msgTypeStr = 'submerged drift';
         elseif (msgType == 6)
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
      if (msgType == 5)
         tabDrifCTDO = [tabDrifCTDO; msgOcc firstDriftCtdoDate firstDriftCtdoTime nbMes presCounts presCountsOk tempCounts salCounts oxyCounts];
      else
         tabProfCTDO = [tabProfCTDO; msgType msgOcc firstProfCtdoDate nbMes presCounts presCountsOk tempCounts salCounts oxyCounts];
      end
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
   idAscProf = find(tabProfCTDO(:, 1) == 6);
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
      if (msgTypes(idType) == 6)
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
