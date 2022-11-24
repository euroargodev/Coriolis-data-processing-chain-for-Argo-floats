% ------------------------------------------------------------------------------
% Read format #1 Argos file.
%
% SYNTAX :
%  [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
%    o_argosDataDate, o_argosDataData, o_satLine, o_floatMsgLines, o_floatMsgDuplicatedLines] = ...
%    read_argos_file_fmt1_bis(a_fileName, a_argosId, a_frameLength)
%
% INPUT PARAMETERS :
%   a_fileName     : format #1 Argos file name
%   a_argosId     : Argos Id
%   a_frameLength : Argos data frame length
%
% OUTPUT PARAMETERS :
%   o_argosLocDate            : Argos location dates
%   o_argosLocLon             : Argos location longitudes
%   o_argosLocDate            : Argos location latitudes
%   o_argosLocAcc             : Argos location classes
%   o_argosLocSat             : Argos location satellite names
%   o_argosDataDate           : Argos message dates
%   o_argosDataData           : Argos message data
%   o_satLine                 : line of the satellite header
%   o_floatMsgLines           : lines of each Argos message
%   o_floatMsgDuplicatedLines : flag for duplicated message
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   15/05/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosLocLon, o_argosLocLat, o_argosLocAcc, o_argosLocSat, ...
   o_argosDataDate, o_argosDataData, o_satLine, o_floatMsgLines, o_floatMsgDuplicatedLines] = ...
   read_argos_file_fmt1_bis(a_fileName, a_argosId, a_frameLength)

% output parameters initialization
o_argosLocDate = [];
o_argosLocLon = [];
o_argosLocLat = [];
o_argosLocAcc = [];
o_argosLocSat = [];
o_argosDataDate = [];
o_argosDataData = [];
o_satLine = [];
o_floatMsgLines = [];
o_floatMsgDuplicatedLines = [];


% process the Argos file(s) (in Real Time, the received Argos data can be in
% more than one file)
argosLocNbLines = [];
argosDataSat = [];
argosDataOcc = [];
for id = 1:length(a_fileName)

   fileName = char(a_fileName{id});

   if ~(exist(fileName, 'file') == 2)
      fprintf('ERROR: Argos file not found: %s\n', fileName);
      return
   end

   fId = fopen(fileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening Argos file: %s\n', fileName);
      return
   end

   % parse Argos file contents
   lineNum = 0;
   while (1)
      line = fgetl(fId);
      lineNum = lineNum + 1;
      if (line == -1)
         break
      end

      % empty line
      if (strcmp(deblank(line), ''))
         continue
      end

      % look for satellite pass header
      [val, count, errmsg, nextindex] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%d %f %f %f %d');
      if (~isempty(errmsg) || (count < 5) || (val(2) ~= a_argosId))
         fprintf('ERROR: Error in line #%d: %s (file %s)\n', lineNum, line, fileName);
         break
      end
      satellite = char(val(5));
      o_satLine = line;
      
      % store the Argos location
      if (isempty(errmsg) && (count == 16))
         o_argosLocDate = [o_argosLocDate; ...
            gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
            val(7), val(8), val(9), val(10), val(11), val(12)))];
         o_argosLocLon = [o_argosLocLon; val(14)];
         o_argosLocLat = [o_argosLocLat; val(13)];
         o_argosLocAcc = [o_argosLocAcc char(val(6))];
         o_argosLocSat = [o_argosLocSat satellite];
         argosLocNbLines = [argosLocNbLines; val(3)];
      end

      % read satellite pass Argos messages
      nbLine = val(3);
      idLine = 1;
      date = [];
      sensor = [];
      floatMsg = [];
      while (idLine < nbLine)
         line = fgetl(fId);
         lineNum = lineNum + 1;
         if (line == -1)
            fprintf('ERROR: Unexpected error in line #%d (file %s)\n', lineNum, fileName);
            break
         end

         % look for message header
         [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %2c %2c %2c %2c');
         if (isempty(errmsg) && (count == 11))
            [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %x %x %x %x');
            if (isempty(errmsg) && (count == 11))

               date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                  val(1), val(2), val(3), val(4), val(5), val(6)));
               sensor = [];
               sensor(1:4) = val(8:11);
               dataOcc = val(7);
               floatMsg{end+1} = line;
            end
         elseif (isempty(sensor))
            [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %c %8c %x %x');
            if (isempty(errmsg) && (count == 11))
               
               date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                  val(1), val(2), val(3), val(4), val(5), val(6)));
               sensor = [];
               sensor(1) = hex2dec([char(val(9)) char(val(10))]);
               sensor(2) = hex2dec([char(val(11)) char(val(12))]);
               sensor(3) = hex2dec([char(val(13)) char(val(14))]);
               sensor(4) = hex2dec([char(val(15)) char(val(16))]);
               sensor(5:6) = val(17:18);
               dataOcc = val(7);
               floatMsg{end+1} = line;
            end
         elseif (isempty(sensor))
            [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %8c %x %x %x');
            if (isempty(errmsg) && (count == 11))

               date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                  val(1), val(2), val(3), val(4), val(5), val(6)));
               sensor = [];
               sensor(1) = hex2dec([char(val(8)) char(val(9))]);
               sensor(2) = hex2dec([char(val(10)) char(val(11))]);
               sensor(3) = hex2dec([char(val(12)) char(val(13))]);
               sensor(4) = hex2dec([char(val(14)) char(val(15))]);
               sensor(5:7) = val(16:18);
               dataOcc = val(7);
               floatMsg{end+1} = line;
            end
         else
            % look for message contents
            [val, count, errmsg, nextindex] = sscanf(line, '%x %x %x %x');
            if (isempty(errmsg) && ((count == 3) || (count == 4) || (count == 1)) && (length(sensor) >= 4))
               nbSensor = length(sensor);
               sensor(1+nbSensor:count+nbSensor) = val(1:count);
               floatMsg{end+1} = line;

               if (length(sensor) == a_frameLength)
                  % store date and data Argos message
                  o_argosDataDate = [o_argosDataDate; date];
                  o_argosDataData = [o_argosDataData; [sensor(1:end)]];
                  argosDataSat = [argosDataSat satellite];
                  argosDataOcc = [argosDataOcc dataOcc];
                  o_floatMsgLines{end+1} = floatMsg;
                  date = [];
                  sensor = [];
                  floatMsg = [];
               end
            end
         end

         idLine = idLine + 1;
      end
   end

   fclose(fId);
end

% locations post-processing

% longitudes must be in the [-180, 180[ interval
id = find(o_argosLocLon > 180);
o_argosLocLon(id) = o_argosLocLon(id) - 360;

% sort output data
[o_argosLocDate, idSorted] = sort(o_argosLocDate);
o_argosLocLon = o_argosLocLon(idSorted);
o_argosLocLat = o_argosLocLat(idSorted);
o_argosLocAcc = o_argosLocAcc(idSorted);
o_argosLocSat = o_argosLocSat(idSorted);
argosLocNbLines = argosLocNbLines(idSorted);

% delete duplicated locations (preserve only one location for a given date
% and a given satellite)
idDel = [];
tabDate = unique(o_argosLocDate);
while (~isempty(tabDate))
   idEq = find(o_argosLocDate == tabDate(1));
   if (length(idEq) > 1)

      [idNotSelected] = selectPos( ...
         o_argosLocAcc(idEq), o_argosLocSat(idEq), argosLocNbLines(idEq));
      if (~isempty(idNotSelected))
         idDel = [idDel; idEq(idNotSelected)];
      end
   end

   tabDate(1) = [];
end
o_argosLocDate(idDel) = [];
o_argosLocLon(idDel) = [];
o_argosLocLat(idDel) = [];
o_argosLocAcc(idDel) = [];
o_argosLocSat(idDel) = [];

% data post-processing

% sort output data
[o_argosDataDate, idSorted] = sort(o_argosDataDate);
o_argosDataData = o_argosDataData(idSorted, :);
argosDataSat = argosDataSat(idSorted);
argosDataOcc = argosDataOcc(idSorted);
o_floatMsgLines = o_floatMsgLines(idSorted);

% delete "artificial" redundancy (preserve only a data message for a given date
% and a given satellite)
idDel = [];
tabDate = unique(o_argosDataDate);
while (~isempty(tabDate))
   idEq = find(o_argosDataDate == tabDate(1));
   if (length(idEq) > 1)

      for id = 1:length(idEq)
         dataSensor = sprintf('%03d', o_argosDataData(idEq(id), :));
         data{id} = sprintf('%c_%s', ...
            argosDataSat(idEq(id)), ...
            dataSensor);
      end

      dataRef = unique(data);
      for idRef = 1:length(dataRef)
         idSelect = [];
         for id = 1:length(idEq)
            if (strcmp(char(data(id)), char(dataRef(idRef))) == 1)
               idSelect = [idSelect; idEq(id)];
            end
         end
         if (length(idSelect) > 1)
            [~, idMax] = max(argosDataOcc(idSelect));
            idSelect(idMax) = [];
            idDel = [idDel; idSelect];
         end
      end
   end

   tabDate(1) = [];
end
o_argosDataDate(idDel) = [];
o_argosDataData(idDel, :) = [];
argosDataSat(idDel) = [];
argosDataOcc(idDel) = [];
o_floatMsgLines(idDel) = [];

% duplicate data according to redundancy coefficient
o_floatMsgDuplicatedLines = zeros(length(o_floatMsgLines), 1);
idDataMulti = find(argosDataOcc ~= 1);
if (~isempty(idDataMulti))
   for idD = 1:length(idDataMulti);
      occCoef = argosDataOcc(idDataMulti(idD));
      for id = 1:occCoef-1
         o_argosDataDate(end+1) = o_argosDataDate(idDataMulti(idD));
         o_argosDataData(end+1, :) = o_argosDataData(idDataMulti(idD), :);
         argosDataSat(end+1) = argosDataSat(idDataMulti(idD));
         o_floatMsgLines(end+1) = o_floatMsgLines(idDataMulti(idD));
         o_floatMsgDuplicatedLines(end+1) = 1;
      end
   end
   [o_argosDataDate, idSort] = sort(o_argosDataDate);
   o_argosDataData = o_argosDataData(idSort, :);
   argosDataSat = argosDataSat(idSort);
   o_floatMsgLines = o_floatMsgLines(idSort);
   o_floatMsgDuplicatedLines = o_floatMsgDuplicatedLines(idSort);
end

% sort output data by date and then by satellite
tabDate = unique(o_argosDataDate);
while (~isempty(tabDate))
   idEq = find(o_argosDataDate == tabDate(1));
   if (length(idEq) > 1)

      [~, idSorted] = sort(argosDataSat(idEq));
      o_argosDataDate(idEq) = o_argosDataDate(idEq(idSorted));
      o_argosDataData(idEq, :) = o_argosDataData(idEq(idSorted), :);
      o_floatMsgLines(idEq) = o_floatMsgLines(idEq(idSorted));
      o_floatMsgDuplicatedLines(idEq) = o_floatMsgDuplicatedLines(idEq(idSorted));
      argosDataSat(idEq) = argosDataSat(idEq(idSorted));
   end

   tabDate(1) = [];
end

return

% ------------------------------------------------------------------------------
% Select Argos locations to delete (only one location is preserved for a given
% satellite).
%
% SYNTAX :
%  [o_notSelected] = selectPos(a_posQc, a_satellite, a_nbLines)
%
% INPUT PARAMETERS :
%   a_posQc     : location classes
%   a_satellite : stellite names
%   a_nbLines   : satellite pass lengths
%
% OUTPUT PARAMETERS :
%   o_notSelected : locations to delete
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_notSelected] = selectPos(a_posQc, a_satellite, a_nbLines)

% output parameters initialization
o_notSelected = [];

% preserve only one location by satellite
select = [];
uSatellite = unique(a_satellite);
for id = 1:length(uSatellite)
   idEqSat = find(a_satellite == uSatellite(id));
   if (length(idEqSat) > 1)
      posQc = a_posQc(idEqSat);
      nbLines = a_nbLines(idEqSat);

      [idSortedPosQc] = sortPosQc(posQc);
      idEqQc = find(posQc == posQc(idSortedPosQc(1)));
      if (length(idEqQc) > 1)
         % select satellite pass according to the amount of received data
         [~, idSortedPos] = sort(nbLines(idEqQc), 'descend');
         select = [select; idEqSat(idEqQc(idSortedPos(1)))];
      else
         select = [select; idEqSat(idEqQc)];
      end
   else
      select = [select; idEqSat];
   end
end

o_notSelected = setdiff([1:length(a_posQc)], select);

return

% ------------------------------------------------------------------------------
% Sort Argos locations according to their classes.
%
% SYNTAX :
%  [o_idSorted] = sortPosQc(a_posQc)
%
% INPUT PARAMETERS :
%   a_posQc : Argos location classes
%
% OUTPUT PARAMETERS :
%   o_idSorted : Argos location sorted ids
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_idSorted] = sortPosQc(a_posQc)

% output parameters initialization
o_idSorted = [];

idGps = find(a_posQc == 'G');
a_posQc(idGps) = ones(1, length(idGps))*4;
idDigit = find(isstrprop(a_posQc, 'digit') == 1);
[~, idSorted] = sort(a_posQc(idDigit), 'descend');
o_idSorted = idDigit(idSorted);
idLetter = setdiff([1:length(a_posQc)], idDigit);
[~, idSorted] = sort(a_posQc(idLetter));
o_idSorted = [o_idSorted idLetter(idSorted)];

return

