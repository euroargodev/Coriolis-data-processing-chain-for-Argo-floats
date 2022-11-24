% ------------------------------------------------------------------------------
% Try to identify if Argos data are from 27 or 30 decoder Id.
%
% SYNTAX :
%  [o_tabDecoderId] = find_decoder_id(a_tabSensors, a_tabDates)
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
%   o_tabDecoderId : deocder Id of each Argos message
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabDecoderId] = find_decoder_id(a_tabSensors, a_tabDates)

% output parameters initialization
o_tabDecoderId = [];


% decode the Argos data messages
o_tabDecoderId = ones(size(a_tabSensors, 1), 1)*-1;
for idMes = 1:size(a_tabSensors, 1)
   % message type
   msgType = a_tabSensors(idMes, 1);
   % message redundancy
   msgOcc = a_tabSensors(idMes, 2);
   % message data frame
   msgData = a_tabSensors(idMes, 3:end);
   
   presCounts27 = [];
   presCounts27Ok = [];
   tempCounts27 = [];
   salCounts27 = [];
   oxyCounts27 = [];
   
   presCounts30 = [];
   presCounts30Ok = [];
   tempCounts30 = [];
   salCounts30 = [];
   switch (msgType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % decId 27 decoding
         
         % technical message
         
         % technical message coding items are "static" (fixed length)
         % first item bit number
         firstBit = 21;
         % item bit lengths
         tabNbBits = [8 7 8 8 4 4 8 4 8 5 5 5 5 7 8 7 8 8 17 6 3 8 8 3 8 8 1 4 4 8 3 5 8 8 1 3 1 4];
         % get item bits
         tabTech27 = get_bits(firstBit, tabNbBits, msgData);
         
         % try to detect a surface TECH message (only float time and battery
         % voltage)
         surfaceCycle27 = 0;
         techData = tabTech27;
         techData([19 32]) = []; % ignore float time and battery voltage
         uTechData = unique(techData);
         if ((length(uTechData) == 1) && (uTechData == 0))
            surfaceCycle27 = 1;
         end
         
         % compute clock float drift
         firstBit = 138;
         tabNbBits = [5 6 6];
         floatTimeParts27 = get_bits(firstBit, tabNbBits, msgData);
         floatTimeHour = floatTimeParts27(1) + floatTimeParts27(2)/60 + floatTimeParts27(3)/3600;
         utcTimeJuld = a_tabDates(idMes);
         floatTimeJuld = fix(utcTimeJuld)+floatTimeHour/24;
         tabFloatTimeJuld = [floatTimeJuld-1 floatTimeJuld floatTimeJuld+1];
         [unused, idMin] = min(abs(tabFloatTimeJuld-utcTimeJuld));
         floatTimeJuld = tabFloatTimeJuld(idMin);
         floatClockDrift27 = floatTimeJuld - utcTimeJuld;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % decId 30 decoding
         
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
         tabTech30 = get_bits(firstBit, tabNbBits, msgData);
         
         % check if it is a deep cycle
         surfaceCycle30 = 0;
         deepInfo = unique(tabTech30([6:13 19:32]));
         if ((length(deepInfo) == 1) && (deepInfo == 0))
            surfaceCycle30 = 1;
         end
         
         % choose the decoder Id
         if ((surfaceCycle27 == 0) && (surfaceCycle30 == 0))
            if (abs(floatClockDrift27*1440) < 15)
               o_tabDecoderId(idMes) = 27;
            else
               o_tabDecoderId(idMes) = 30;
            end
         elseif ((surfaceCycle27 == 1) && (surfaceCycle30 == 0))
            o_tabDecoderId(idMes) = 27;
         elseif ((surfaceCycle27 == 0) && (surfaceCycle30 == 1))
            o_tabDecoderId(idMes) = 30;
         else
            o_tabDecoderId(idMes) = 0;
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 1
         
         % technical message #2
         o_tabDecoderId(idMes) = 30;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 2
         
         % parameter message
         o_tabDecoderId(idMes) = 30;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {4, 6}
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % decId 27 decoding
         
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
         
         firstProfCtdoDate27 = values(1);
         presCounts27(1) = values(2);
         % pressure is coded on 11 bits (from 0 to 2047 dbar) we must check if it has overflowed
         if (presCounts27(1) == 2047)
            presCounts27Ok(1) = 0;
         else
            presCounts27Ok(1) = 1;
         end
         tempCounts27(1) = values(3);
         salCounts27(1) = values(4);
         oxyCounts27(1) = values(5);
         
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
               presCounts27(curCtdoMes) = value;
               if (value == 2047)
                  presCounts27Ok(curCtdoMes) = 0;
               else
                  presCounts27Ok(curCtdoMes) = 1;
               end
               curBit = curBit + 11;
            else
               relpresCounts27 = get_bits(curBit, 6, msgData);
               if (isempty(relpresCounts27))
                  break;
               end
               presCounts27(curCtdoMes) = presCounts27(curCtdoMes-1) - sign*relpresCounts27;
               presCounts27Ok(curCtdoMes) = 1;
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
               tempCounts27(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               reltempCounts27 = get_bits(curBit, 10, msgData);
               if (isempty(reltempCounts27))
                  break;
               end
               tempCounts27(curCtdoMes) = tempCounts27(curCtdoMes-1) + sign*(reltempCounts27 - 100);
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
               salCounts27(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relsalCounts27 = get_bits(curBit, 8, msgData);
               if (isempty(relsalCounts27))
                  break;
               end
               salCounts27(curCtdoMes) = salCounts27(curCtdoMes-1) + sign*(relsalCounts27 - 25);
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
               oxyCounts27(curCtdoMes) = value;
               curBit = curBit + 13;
            else
               reloxyCounts27 = get_bits(curBit, 9, msgData);
               if (isempty(reloxyCounts27))
                  break;
               end
               oxyCounts27(curCtdoMes) = oxyCounts27(curCtdoMes-1) + reloxyCounts27 - 256;
               curBit = curBit + 9;
            end
            
            curCtdoMes = curCtdoMes + 1;
            if (curCtdoMes == 6)
               break;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % decId 30 decoding
         
         % descent or ascent profile CTD message
         
         if (msgType == 4)
            sign= -1; % descent profile
         else
            sign= 1; % ascent profile
         end
         
         % CTD data message coding items are "dynamic" (length depends on contents)
         % there are between 5 and 7 PTS measurements per Argos message
         
         % get the first PTS date and data
         firstBit = 21;
         tabNbBits = [9 11 15 15];
         values = get_bits(firstBit, tabNbBits, msgData);
         
         firstProfCtdDate30 = values(1);
         presCounts30(1) = values(2);
         % pressure is coded on 11 bits (from 0 to 2047 dbar) we must check if it has overflowed
         if (presCounts30(1) == 2047)
            presCounts30Ok(1) = 0;
         else
            presCounts30Ok(1) = 1;
         end
         tempCounts30(1) = values(3);
         salCounts30(1) = values(4);
         
         % get the other PTS data
         curCtdMes = 2;
         curBit = 71;
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
               presCounts30(curCtdMes) = value;
               if (value == 2047)
                  presCounts30Ok(curCtdMes) = 0;
               else
                  presCounts30Ok(curCtdMes) = 1;
               end
               curBit = curBit + 11;
            else
               relpresCounts30 = get_bits(curBit, 6, msgData);
               if (isempty(relpresCounts30))
                  break;
               end
               presCounts30(curCtdMes) = presCounts30(curCtdMes-1) - sign*relpresCounts30;
               presCounts30Ok(curCtdMes) = 1;
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
               tempCounts30(curCtdMes) = value;
               curBit = curBit + 15;
            else
               reltempCounts30 = get_bits(curBit, 10, msgData);
               if (isempty(reltempCounts30))
                  break;
               end
               tempCounts30(curCtdMes) = tempCounts30(curCtdMes-1) + sign*(reltempCounts30 - 100);
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
               salCounts30(curCtdMes) = value;
               curBit = curBit + 15;
            else
               relsalCounts30 = get_bits(curBit, 8, msgData);
               if (isempty(relsalCounts30))
                  break;
               end
               salCounts30(curCtdMes) = salCounts30(curCtdMes-1) + sign*(relsalCounts30 - 25);
               curBit = curBit + 8;
            end
            
            curCtdMes = curCtdMes + 1;
            if (curCtdMes == 8)
               break;
            end
         end
         
         % shift and store the decoded PTSO data
         if (~isempty(presCounts27))
            % number of PTSO measurements in this Argos message
            nbMes = min([length(presCounts27) length(tempCounts27) length(salCounts27) length(oxyCounts27)]);
            presCounts27(nbMes+1:end) = [];
            tempCounts27(nbMes+1:end) = [];
            salCounts27(nbMes+1:end) = [];
            oxyCounts27(nbMes+1:end) = [];
            idDel = find((presCounts27 == 0) & (tempCounts27 == 0) & (salCounts27 == 0) & (oxyCounts27 == 0));
            presCounts27(idDel) = [];
            tempCounts27(idDel) = [];
            salCounts27(idDel) = [];
            oxyCounts27(idDel) = [];
         end
         
         % shift and store the decoded PTS data
         if (~isempty(presCounts30))
            % number of PTS measurements in this Argos message
            nbMes = min([length(presCounts30) length(tempCounts30) length(salCounts30)]);
            presCounts30(nbMes+1:end) = [];
            tempCounts30(nbMes+1:end) = [];
            salCounts30(nbMes+1:end) = [];
            idDel = find((presCounts30 == 0) & (tempCounts30 == 0) & (salCounts30 == 0));
            presCounts30(idDel) = [];
            tempCounts30(idDel) = [];
            salCounts30(idDel) = [];
         end
         
         % choose the decoder Id
         if (any(salCounts30 == 0))
            o_tabDecoderId(idMes) = 27;
         elseif (any(salCounts27 == 0))
            o_tabDecoderId(idMes) = 30;
         else
            salValues30 = sensor_2_value_for_salinity_argos(salCounts30);
            salValues27 = sensor_2_value_for_salinity_argos(salCounts27);
            if (std(salValues30) > std(salValues27)) && (std(salValues30) > 1)
               o_tabDecoderId(idMes) = 27;
            elseif (std(salValues27) > std(salValues30)) && (std(salValues27) > 1)
               o_tabDecoderId(idMes) = 30;
            else
               presValues = sensor_2_value_for_pressure_argos(presCounts27);
               tempValues = sensor_2_value_for_temperature_argos(tempCounts27);
               salValues = sensor_2_value_for_salinity_argos(salCounts27);
               tPhaseDoxyValues = sensor_2_value_for_tphase_doxy_27_28_29(oxyCounts27);
               [doxyValues] = compute_DOXY_27_bis(tPhaseDoxyValues', ...
                  presValues', tempValues', salValues', ...
                  [0.0027    0.0001    0.0000  233.2640   -0.3682  -52.1783    4.5674]);
               if (any((doxyValues < 130) | (doxyValues > 400)))
                  o_tabDecoderId(idMes) = 30;
               else
                  o_tabDecoderId(idMes) = 27;
               end
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % decId 37 decoding
         
         % submerged drift CTDO message
         
         % CTDO data message coding items are "dynamic" (length depends on contents)
         % there are between 3 and 5 PTSO measurements per Argos message
         
         % get the first PTSO date, time and data
         firstBit = 21;
         tabNbBits = [6 5 11 15 15 13];
         values = get_bits(firstBit, tabNbBits, msgData);
         
         firstDriftCtdoDate27 = values(1);
         firstDriftCtdoTime27 = values(2);
         presCounts27(1) = values(3);
         % pressure is coded on 11 bits (from 0 to 2047 dbar) we must check if it has overflowed
         if (presCounts27(1) == 2047)
            presCounts27Ok(1) = 0;
         else
            presCounts27Ok(1) = 1;
         end
         tempCounts27(1) = values(4);
         salCounts27(1) = values(5);
         oxyCounts27(1) = values(6);
         
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
               presCounts27(curCtdoMes) = value;
               if (value == 2047)
                  presCounts27Ok(curCtdoMes) = 0;
               else
                  presCounts27Ok(curCtdoMes) = 1;
               end
               curBit = curBit + 11;
            else
               relpresCounts27 = twos_complement_dec_argo(get_bits(curBit, 6, msgData), 6);
               if (isempty(relpresCounts27))
                  break;
               end
               presCounts27(curCtdoMes) = presCounts27(curCtdoMes-1) + relpresCounts27;
               presCounts27Ok(curCtdoMes) = 1;
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
               tempCounts27(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relTempCounts27 = twos_complement_dec_argo(get_bits(curBit, 10, msgData), 10);
               if (isempty(relTempCounts27))
                  break;
               end
               tempCounts27(curCtdoMes) = tempCounts27(curCtdoMes-1) + relTempCounts27;
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
               salCounts27(curCtdoMes) = value;
               curBit = curBit + 15;
            else
               relSalCounts27 = twos_complement_dec_argo(get_bits(curBit, 8, msgData), 8);
               if (isempty(relSalCounts27))
                  break;
               end
               salCounts27(curCtdoMes) = salCounts27(curCtdoMes-1) + relSalCounts27;
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
               oxyCounts27(curCtdoMes) = value;
               curBit = curBit + 13;
            else
               relOxyCounts27 = get_bits(curBit, 9, msgData);
               if (isempty(relOxyCounts27))
                  break;
               end
               oxyCounts27(curCtdoMes) = oxyCounts27(curCtdoMes-1) + relOxyCounts27 - 256;
               curBit = curBit + 9;
            end
            
            curCtdoMes = curCtdoMes + 1;
            if (curCtdoMes == 6)
               break;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % decId 30 decoding
         
         % submerged drift CTD message
         
         % CTD data message coding items are "dynamic" (length depends on contents)
         % there are between 5 and 7 PTS measurements per Argos message
         
         % get the first PTS date, time and data
         firstBit = 21;
         tabNbBits = [6 5 11 15 15];
         values = get_bits(firstBit, tabNbBits, msgData);
         
         firstDriftCtdDate30 = values(1);
         firstDriftCtdTime30 = values(2);
         presCounts30(1) = values(3);
         % pressure is coded on 11 bits (from 0 to 2047 dbar) we must check if it has overflowed
         if (presCounts30(1) == 2047)
            presCounts30Ok(1) = 0;
         else
            presCounts30Ok(1) = 1;
         end
         tempCounts30(1) = values(4);
         salCounts30(1) = values(5);
         
         % get the other PTS data
         curCtdMes = 2;
         curBit = 73;
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
               presCounts30(curCtdMes) = value;
               if (value == 2047)
                  presCounts30Ok(curCtdMes) = 0;
               else
                  presCounts30Ok(curCtdMes) = 1;
               end
               curBit = curBit + 11;
            else
               relpresCounts30 = twos_complement_dec_argo(get_bits(curBit, 6, msgData), 6);
               if (isempty(relpresCounts30))
                  break;
               end
               presCounts30(curCtdMes) = presCounts30(curCtdMes-1) + relpresCounts30;
               presCounts30Ok(curCtdMes) = 1;
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
               tempCounts30(curCtdMes) = value;
               curBit = curBit + 15;
            else
               relTempCounts30 = twos_complement_dec_argo(get_bits(curBit, 10, msgData), 10);
               if (isempty(relTempCounts30))
                  break;
               end
               tempCounts30(curCtdMes) = tempCounts30(curCtdMes-1) + relTempCounts30;
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
               salCounts30(curCtdMes) = value;
               curBit = curBit + 15;
            else
               relSalCounts30 = twos_complement_dec_argo(get_bits(curBit, 8, msgData), 8);
               if (isempty(relSalCounts30))
                  break;
               end
               salCounts30(curCtdMes) = salCounts30(curCtdMes-1) + relSalCounts30;
               curBit = curBit + 8;
            end
            
            curCtdMes = curCtdMes + 1;
            if (curCtdMes == 8)
               break;
            end
         end
         
         % shift and store the decoded PTSO data
         if (~isempty(presCounts27))
            % number of PTSO measurements in this Argos message
            nbMes = min([length(presCounts27) length(tempCounts27) length(salCounts27) length(oxyCounts27)]);
            presCounts27(nbMes+1:end) = [];
            tempCounts27(nbMes+1:end) = [];
            salCounts27(nbMes+1:end) = [];
            oxyCounts27(nbMes+1:end) = [];
            idDel = find((presCounts27 == 0) & (tempCounts27 == 0) & (salCounts27 == 0) & (oxyCounts27 == 0));
            presCounts27(idDel) = [];
            tempCounts27(idDel) = [];
            salCounts27(idDel) = [];
            oxyCounts27(idDel) = [];
         end
         
         % shift and store the decoded PTS data
         if (~isempty(presCounts30))
            % number of PTS measurements in this Argos message
            nbMes = min([length(presCounts30) length(tempCounts30) length(salCounts30)]);
            presCounts30(nbMes+1:end) = [];
            tempCounts30(nbMes+1:end) = [];
            salCounts30(nbMes+1:end) = [];
            idDel = find((presCounts30 == 0) & (tempCounts30 == 0) & (salCounts30 == 0));
            presCounts30(idDel) = [];
            tempCounts30(idDel) = [];
            salCounts30(idDel) = [];
         end
         
         % choose the decoder Id
         if (any(salCounts30 == 0))
            o_tabDecoderId(idMes) = 27;
         elseif (any(salCounts27 == 0))
            o_tabDecoderId(idMes) = 30;
         else
            salValues30 = sensor_2_value_for_salinity_argos(salCounts30);
            salValues27 = sensor_2_value_for_salinity_argos(salCounts27);
            if (std(salValues30) > std(salValues27)) && (std(salValues30) > 1)
               o_tabDecoderId(idMes) = 27;
            elseif (std(salValues27) > std(salValues30)) && (std(salValues27) > 1)
               o_tabDecoderId(idMes) = 30;
            else
               presValues = sensor_2_value_for_pressure_argos(presCounts27);
               tempValues = sensor_2_value_for_temperature_argos(tempCounts27);
               salValues = sensor_2_value_for_salinity_argos(salCounts27);
               tPhaseDoxyValues = sensor_2_value_for_tphase_doxy_27_28_29(oxyCounts27);
               [doxyValues] = compute_DOXY_27_bis(tPhaseDoxyValues', ...
                  presValues', tempValues', salValues', ...
                  [0.0027    0.0001    0.0000  233.2640   -0.3682  -52.1783    4.5674]);
               if (any((doxyValues < 130) | (doxyValues > 400)))
                  o_tabDecoderId(idMes) = 30;
               else
                  o_tabDecoderId(idMes) = 27;
               end
            end
         end
         
      otherwise
         fprintf('WARNING: Nothing done for unexpected message type #%d\n', ...
            msgType);
   end
end

return;
