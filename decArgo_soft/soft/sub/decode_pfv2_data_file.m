% ------------------------------------------------------------------------------
% Decode measurement file.
%
% SYNTAX :
% [o_measData] = decode_pfv2_data_file(a_fileName)
%
% INPUT PARAMETERS :
%   a_fileName : measurement file name
%
% OUTPUT PARAMETERS :
%   o_measData : decoded measurement data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measData] = decode_pfv2_data_file(a_fileName)

% output parameters initialization
o_measData = [];

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_archiveDataDirectory;


% retrieve information from file name
[val, count, errmsg, ~] = sscanf(a_fileName, 'M%dC%dS%dF%d%c%d.hex');
if (isempty(errmsg) && (count == 6))
   missionNum = val(1);
   cycleNum = val(2);
   sensorNum = val(3);
   formatNum = val(4);
   switch (char(val(5))) % phase
      case 'D'
         fileType = 20;
      case 'P'
         fileType = 21;
      case 'T'
         fileType = 22;
      case 'B'
         fileType = 23;
      case 'A'
         fileType = 24;
      case 'I'
         fileType = 25;
      otherwise
         fileType = -1;
         fprintf('ERROR: Float #%d: Cycle phase ''%c'' not managed yet\n', ...
            g_decArgo_floatNum, char(val(5)));
   end
   dateFreq = val(6);
else
   fprintf('ERROR: Float #%d: Inconsistent DATA file name : %s\n', ...
      g_decArgo_floatNum, a_fileName);
   return
end

% read file data
filePathName = [g_decArgo_archiveDataDirectory '/' a_fileName];
fId = fopen(filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
      g_decArgo_floatNum, a_fileName);
   return
end
dataIn = fread(fId);
fclose(fId);

% process data
MEAS_DATA_LINE = 10;
MEAS_DATA_COL = 5;
switch (sensorNum)
   case 1 % SBE41

      switch (formatNum)
         case 0

            curByte = 1;
            nMeas = 0;
            measData = nan(MEAS_DATA_LINE, MEAS_DATA_COL);
            cpt = 1;
            while (curByte <= length(dataIn))

               if (cpt > size(measData, 1))
                  measData = cat(1, measData, nan(MEAS_DATA_LINE, MEAS_DATA_COL));
               end

               if (rem(nMeas, dateFreq+1) == 0)
                  if (curByte+3 <= length(dataIn))
                     [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
                     measJuld = epoch2000_2_julian(dataEpoch);
                     nMeas = 1;

                     measData(cpt, 1) = measJuld;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               else
                  if (curByte+5 <= length(dataIn))
                     [presCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [tempCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [psalCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     nMeas = nMeas + 1;

                     measData(cpt, 2) = presCount/10 - 100;
                     measData(cpt, 3) = tempCount/1000 - 10;
                     measData(cpt, 4) = psalCount/1000;
                     cpt = cpt + 1;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               end
            end
            measData(cpt:end, :) = [];

         case 1

            fprintf('ERROR: Float #%d: Format #%d of sensor #%d not implemented yet\n', ...
               g_decArgo_floatNum, ...
               formatNum, sensorNum);
            return

         case 2

            curByte = 1;
            nMeas = 0;
            measData = nan(MEAS_DATA_LINE, MEAS_DATA_COL);
            cpt = 1;
            while (curByte <= length(dataIn))

               if (cpt > size(measData, 1))
                  measData = cat(1, measData, nan(MEAS_DATA_LINE, MEAS_DATA_COL));
               end

               if (rem(nMeas, dateFreq+1) == 0)
                  if (curByte+3 <= length(dataIn))
                     [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
                     measJuld = epoch2000_2_julian(dataEpoch);
                     nMeas = 1;

                     measData(cpt, 1) = measJuld;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               else
                  if (curByte+5 <= length(dataIn))
                     [presCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [tempCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [psalCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     nMeas = nMeas + 1;

                     measData(cpt, 2) = presCount/20 - 100;
                     measData(cpt, 3) = tempCount/1000 - 10;
                     measData(cpt, 4) = psalCount/1000;
                     cpt = cpt + 1;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               end
            end
            measData(cpt:end, :) = [];

         otherwise
            fprintf('ERROR: Float #%d: Unexpected data format (#%d for sensor #%d) in file %\n', ...
               g_decArgo_floatNum, ...
               formatNum, sensorNum, a_fileName);
            return
      end

   case 2 % Aanderaa 4330

      switch (formatNum)
         case 0

            curByte = 1;
            nMeas = 0;
            measData = nan(MEAS_DATA_LINE, MEAS_DATA_COL);
            cpt = 1;
            while (curByte <= length(dataIn))

               if (cpt > size(measData, 1))
                  measData = cat(1, measData, nan(MEAS_DATA_LINE, MEAS_DATA_COL));
               end

               if (rem(nMeas, dateFreq+1) == 0)
                  if (curByte+3 <= length(dataIn))
                     [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
                     measJuld = epoch2000_2_julian(dataEpoch);
                     nMeas = 1;

                     measData(cpt, 1) = measJuld;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               else
                  if (curByte+5 <= length(dataIn))
                     [presCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [C1PhaseDoxyCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [C2PhaseDoxyCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [tempDoxyCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     nMeas = nMeas + 1;

                     measData(cpt, 2) = presCount/10 - 100;
                     measData(cpt, 3) = C1PhaseDoxyCount/500 - 40;
                     measData(cpt, 4) = C2PhaseDoxyCount/500 - 40;
                     measData(cpt, 5) = tempDoxyCount/1000 - 10;
                     cpt = cpt + 1;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               end
            end
            measData(cpt:end, :) = [];

         case 1

            fprintf('ERROR: Float #%d: Format #%d of sensor #%d not implemented yet\n', ...
               g_decArgo_floatNum, ...
               formatNum, sensorNum);
            return

         case 2

            curByte = 1;
            nMeas = 0;
            measData = nan(MEAS_DATA_LINE, MEAS_DATA_COL);
            cpt = 1;
            while (curByte <= length(dataIn))

               if (cpt > size(measData, 1))
                  measData = cat(1, measData, nan(MEAS_DATA_LINE, MEAS_DATA_COL));
               end

               if (rem(nMeas, dateFreq+1) == 0)
                  if (curByte+3 <= length(dataIn))
                     [dataEpoch, curByte] = get_bytes_pfv2(dataIn, curByte, 4);
                     measJuld = epoch2000_2_julian(dataEpoch);
                     nMeas = 1;

                     measData(cpt, 1) = measJuld;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               else
                  if (curByte+5 <= length(dataIn))
                     [presCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [C1PhaseDoxyCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [C2PhaseDoxyCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     [tempDoxyCount, curByte] = get_bytes_pfv2(dataIn, curByte, 2);
                     nMeas = nMeas + 1;

                     measData(cpt, 2) = presCount/20 - 100;
                     measData(cpt, 3) = C1PhaseDoxyCount/500 - 40;
                     measData(cpt, 4) = C2PhaseDoxyCount/500 - 40;
                     measData(cpt, 5) = tempDoxyCount/1000 - 10;
                     cpt = cpt + 1;
                  else
                     fprintf('ERROR: Float #%d: Unexpected end of file in file : %s\n', ...
                        g_decArgo_floatNum, a_fileName);
                     break
                  end
               end
            end
            measData(cpt:end, :) = [];

         otherwise
            fprintf('ERROR: Float #%d: Unexpected data format (#%d for sensor #%d) in file %\n', ...
               g_decArgo_floatNum, ...
               formatNum, sensorNum, a_fileName);
            return
      end

   case 3 % RBRargo3

      fprintf('ERROR: Float #%d: Data decoding not implemented yet for RBRargo3\n', ...
         g_decArgo_floatNum);
      return

   otherwise
      fprintf('ERROR: Float #%d: Unexpected sensor number (%d) in file %\n', ...
         g_decArgo_floatNum, ...
         sensorNum, ...
         a_fileName);
      return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% specific PFV2
if (g_decArgo_floatNum == 2904006)
   % remove the last measurement of M3C2S1F0P15.hex, M3C3S1F0P15.hex and M3C4S1F0P15.hex files
   if (strcmp(a_fileName, 'M3C2S1F0P15.hex') || ...
         strcmp(a_fileName, 'M3C3S1F0P15.hex') || ...
         strcmp(a_fileName, 'M3C4S1F0P15.hex'))
      measData(end, :) = [];
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

o_measData = [fileType missionNum cycleNum {a_fileName} sensorNum formatNum measData];

return
