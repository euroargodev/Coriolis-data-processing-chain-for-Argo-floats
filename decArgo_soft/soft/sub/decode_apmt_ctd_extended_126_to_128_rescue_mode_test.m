% ------------------------------------------------------------------------------
% Decode CTD data transmitted by a CTS5-USEA float in extended format.
%
% SYNTAX :
%  [o_ctdData] = decode_apmt_ctd_extended_126(a_data, a_lastByteNum, a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_data              : input CTD data to decode
%   a_lastByteNum       : number of the last useful byte of the data
%   a_inputFilePathName : APMT CTD file to decode
%
% OUTPUT PARAMETERS :
%   o_ctdData : CTD decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ctdData] = decode_apmt_ctd_extended_126_to_128(a_data, a_lastByteNum, a_inputFilePathName)

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_SS;
global g_decArgo_cts5Treat_DW;


% list of cycle phase headers that can be encountered
phaseList = [ ...
   {'[DESCENT]'} ...
   {'[PARK]'} ...
   {'[DEEP_PROFILE]'} ...
   {'[SHORT_PARK]'} ...
   {'[ASCENT]'} ...
   {'[SURFACE]'} ...
   ];

% list of treatment type headers that can be encountered
treatList = [ ...
   {'(AM)(SD)(MD)'} ...
   {'(AM)(SD)'} ...
   {'(AM)(MD)'} ...
   {'(RW)'} ...
   {'(AM)'} ...
   {'(SS)'} ...
   {'(DW)'} ...
   ];

% list of corresponding bit pattern (used to acces the data)
bitList = [ ...
   {[16 16 16 16 4 4 8 8 16 16 16 4 4]} ...
   {[16 16 16 16 4 4 8 8]} ...
   {[16 16 16 16 4 4 16 16 16 4 4]} ...
   {[16 16 16 16 4 4]} ...
   {[16 16 16 16 4 4]} ...
   {[32 16 16 16 4 4]} ...
   {[16 16 16 16 4 4]} ...
   ];

% list of signed type parameters
signedList = [ ...
   {[0 0 0 0 0 0 1 1 0 0 0 0 0 ]} ...
   {[0 0 0 0 0 0 1 1]} ...
   {[0 0 0 0 0 0 0 0 0 0 0]} ...
   {[0 0 0 0 0 0]} ...
   {[0 0 0 0 0 0]} ...
   {[0 0 0 0 0 0]} ...
   {[0 0 0 0 0 0]} ...
   ];

inputData = a_data;
lastByteNum = a_lastByteNum;
currentPhaseNum = -1;
currentTreatNum = -1;
dataStruct = [];
currentDataStruct = [];
currentByte = 2;
rescueMode = 0;
while (currentByte <= lastByteNum)

   newPhaseNum = -1;
   newTreatNum = -1;

   % look for a new phase header
   if (inputData(currentByte) == '[')
      for idPhase = 1:length(phaseList)
         phaseName = phaseList{idPhase};
         if (any((currentByte:currentByte+length(phaseName)-1) > length(inputData)))
            fprintf('ERROR: Unexpected end of file in file: %s\n', a_inputFilePathName);
            rescueMode = 1;
            break
         end
         if (strcmp(char(inputData(currentByte:currentByte+length(phaseName)-1))', phaseName))
            newPhaseNum = idPhase;
            currentByte = currentByte + length(phaseName);
            break
         end
      end
   end

   % look for a new treatment header
   if (inputData(currentByte) == '(')
      for idTreat = 1:length(treatList)
         treatName = treatList{idTreat};
         if (any((currentByte:currentByte+length(treatName)-1) > length(inputData)))
            fprintf('ERROR: Unexpected end of file in file: %s\n', a_inputFilePathName);
            rescueMode = 1;
            break
         end
         if (strcmp(char(inputData(currentByte:currentByte+length(treatName)-1))', treatName))
            newTreatNum = idTreat;
            currentByte = currentByte + length(treatName);
            break
         end
      end
   end

   % the treatment type of PARK, SHORT_PARK and SURFACE measurements is always
   % RAW (NKE personal communication)
   if (ismember(newPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
      newTreatNum = g_decArgo_cts5Treat_RW;
   end

   % consider modification of phase or treatment
   if ((newPhaseNum ~= -1) || (newTreatNum ~= -1))
      if (~isempty(currentDataStruct))

         % finalize decoded data
         % compute the dates
         if (~ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]) && ...
               (currentTreatNum ~= g_decArgo_cts5Treat_SS))
            date = currentDataStruct.data(:, 1);
            date(1) = date(1) + currentDataStruct.date;
            for id = 2:length(date)
               date(id) = date(id-1) + date(id);
            end
            currentDataStruct.data(:, 1) = epoch_2_julian_dec_argo(date);
         end

         % store decoded data
         dataStruct{end+1} = currentDataStruct;
         currentDataStruct = [];
      end

      if (newPhaseNum ~= -1)
         currentPhaseNum = newPhaseNum;
      end
      if (newTreatNum ~= -1)
         currentTreatNum = newTreatNum;
      end
      phaseName = phaseList{currentPhaseNum};
      treatName = treatList{currentTreatNum};
      %       fprintf('%s %s\n', phaseName, treatName);
      currentDataStruct.phase = phaseName;
      currentDataStruct.phaseId = currentPhaseNum;
      currentDataStruct.treat = treatName;
      currentDataStruct.treatId = currentTreatNum;
      currentDataStruct.date = [];
      currentDataStruct.data = [];

      % the absolute date is provided in the beginning of descent/ascent phase
      % data
      if (ismember(currentPhaseNum, [g_decArgo_cts5PhaseDescent g_decArgo_cts5PhaseDeepProfile g_decArgo_cts5PhaseAscent]) && ...
            (currentTreatNum ~= g_decArgo_cts5Treat_SS))
         if (any((currentByte:currentByte+3) > length(inputData)))
            fprintf('ERROR: Unexpected end of file in file: %s\n', a_inputFilePathName);
            rescueMode = 1;
            break
         end
         data = get_bits(1, 32, inputData(currentByte:currentByte+3));
         currentDataStruct.date = typecast(swapbytes(uint32(data)), 'uint32');
         currentByte = currentByte + 4;
      end
   end

   % read the data
   if ((currentPhaseNum ~= -1) && (currentTreatNum ~= -1))
      tabNbBits = bitList{currentTreatNum};
      % absolute date during PARK, SHORT_PARK and SURFACE phases
      if (ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
         tabNbBits(1) = 32;
      end
      nbBytes = sum(tabNbBits)/8;
      if (any((currentByte:currentByte+nbBytes-1) > length(inputData)))
         fprintf('ERROR: Unexpected end of file in file: %s\n', a_inputFilePathName);
         rescueMode = 1;
         break
      end
      rawData = get_bits(1, tabNbBits, inputData(currentByte:currentByte+nbBytes-1));
      tabSignedList = signedList{currentTreatNum};
      for id = 1:length(tabNbBits)
         if (tabNbBits(id) > 8)
            rawData(id) = decode_apmt_meas(rawData(id), tabNbBits(id), tabSignedList(id), a_inputFilePathName);
         end
      end

      if (ismember(currentTreatNum, [g_decArgo_cts5Treat_RW g_decArgo_cts5Treat_DW]))
         % raw data
         if (ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
            data(1) = epoch_2_julian_dec_argo(rawData(1));
         else
            data(1) = rawData(1);
         end
         data(2) = rawData(2)/10 - 100 + rawData(5)*0.01;
         data(3) = rawData(3)/1000 - 5 + rawData(6)*0.0001;
         data(4) = rawData(4)/1000;
      elseif (currentTreatNum == g_decArgo_cts5Treat_SS)
         % sub-surface point
         data(1) = epoch_2_julian_dec_argo(rawData(1));
         data(2) = rawData(2)/10 - 100 + rawData(5)*0.01;
         data(3) = rawData(3)/1000 - 5 + rawData(6)*0.0001;
         data(4) = rawData(4)/1000;
      else
         % mean data
         switch (currentTreatNum)
            case g_decArgo_cts5Treat_AM_SD_MD
               data(1) = rawData(1);
               data(2) = rawData(2)/10 - 100 + rawData(5)*0.01;
               data(3) = rawData(3)/1000 - 5 + rawData(6)*0.0001;
               data(4) = rawData(4)/1000;
               data(5) = rawData(7)/1000;
               data(6) = rawData(8)/1000;
               data(7) = rawData(9)/10 - 100 + rawData(12)*0.01;
               data(8) = rawData(10)/1000 - 5 + rawData(13)*0.0001;
               data(9) = rawData(11)/1000;
            case g_decArgo_cts5Treat_AM_SD
               data(1) = rawData(1);
               data(2) = rawData(2)/10 - 100 + rawData(5)*0.01;
               data(3) = rawData(3)/1000 - 5 + rawData(6)*0.0001;
               data(4) = rawData(4)/1000;
               data(5) = rawData(7)/1000;
               data(6) = rawData(8)/1000;
            case g_decArgo_cts5Treat_AM_MD
               data(1) = rawData(1);
               data(2) = rawData(2)/10 - 100 + rawData(5)*0.01;
               data(3) = rawData(3)/1000 - 5 + rawData(6)*0.0001;
               data(4) = rawData(4)/1000;
               data(5) = rawData(7)/10 - 100 + rawData(10)*0.01;
               data(6) = rawData(8)/1000 - 5 + rawData(11)*0.0001;
               data(7) = rawData(9)/1000;
            case g_decArgo_cts5Treat_AM
               data(1) = rawData(1);
               data(2) = rawData(2)/10 - 100 + rawData(5)*0.01;
               data(3) = rawData(3)/1000 - 5 + rawData(6)*0.0001;
               data(4) = rawData(4)/1000;
            otherwise
               fprintf('ERROR: Treatment #%d not managed\n', currentTreatNum);
         end
      end
      currentDataStruct.data = [currentDataStruct.data; data];
      currentByte = currentByte + nbBytes;
   else
      fprintf('ERROR: This should not happen\n');
      break
   end
end

if (~isempty(currentDataStruct))

   % finalize decoded data
   % compute the dates
   if (~ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]) && ...
         (currentTreatNum ~= g_decArgo_cts5Treat_SS))
      date = currentDataStruct.data(:, 1);
      date(1) = date(1) + currentDataStruct.date;
      for id = 2:length(date)
         date(id) = date(id-1) + date(id);
      end
      currentDataStruct.data(:, 1) = epoch_2_julian_dec_argo(date);
   end

   % store decoded data
   dataStruct{end+1} = currentDataStruct;
end

if (rescueMode == 1)
   dataStruct = clean_data(dataStruct);
end

o_ctdData = dataStruct;

return

function [o_ctdData] = clean_data(a_ctdData)

% output parameters initialization
o_ctdData = a_ctdData;

% array to store USEA technical data
global g_decArgo_useaTechData;

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;


% remove duplicated data
dataAll = [o_ctdData{:}];
phaseTreatList = [[dataAll.phaseId]' [dataAll.treatId]'];
uPhaseTreatList = unique(phaseTreatList, 'rows');

idDel = [];
for id1 = 1:size(uPhaseTreatList, 1)
   idF = find((phaseTreatList(:, 1) == uPhaseTreatList(id1, 1)) & ...
      (phaseTreatList(:, 2) == uPhaseTreatList(id1, 2)));
   if (length(idF) > 1)
      for id2 = 1:length(idF)-1
         if (~ismember(idF(id2), idDel))
            for id3 = id2+1:length(idF)
               if ((size(dataAll(idF(id2)).data, 1) == size(dataAll(idF(id3)).data, 1)) && ...
                     (size(dataAll(idF(id2)).data, 2) == size(dataAll(idF(id3)).data, 2)))
                  if (all(all(dataAll(idF(id2)).data == dataAll(idF(id3)).data)))
                     idDel = [idDel idF(id3)];
                  end
               end
            end
         end
      end
   end
end
o_ctdData(idDel) = [];

% clean erroneous measurements
techLabels = g_decArgo_useaTechData{10, 4}.DATA.name';
idDesc = find(strcmp('number of SBE41 samples during descent to parking depth', techLabels));
nbDesc = g_decArgo_useaTechData{10, 4}.DATA.data{idDesc};
idDrift = find(strcmp('number of SBE41 samples during drift at parking depth', techLabels));
nbDrift = g_decArgo_useaTechData{10, 4}.DATA.data{idDrift};
idAsc = find(strcmp('number of SBE41 samples during ascent to surface', techLabels));
nbAsc = g_decArgo_useaTechData{10, 4}.DATA.data{idAsc};
idSurf = find(strcmp('number of SBE41 surface samples', techLabels));
nbSurf = g_decArgo_useaTechData{10, 4}.DATA.data{idSurf};
idSs = find(strcmp('number of SBE41 sub-surface samples', techLabels));
nbSs = g_decArgo_useaTechData{10, 4}.DATA.data{idSs};

dataAll = [o_ctdData{:}];
phaseList = [dataAll.phaseId];
uPhaseList = unique(phaseList);
for id1 = 1:length(uPhaseList)
   switch uPhaseList(id1)
      case g_decArgo_cts5PhaseDescent
         nbMeas = nbDesc;
      case g_decArgo_cts5PhasePark
         nbMeas = nbDrift;
      case g_decArgo_cts5PhaseAscent
         nbMeas = nbAsc + nbSs;
      case g_decArgo_cts5PhaseSurface
         nbMeas = nbSurf;
      otherwise
         continue
   end
   idF = find(phaseList == uPhaseList(id1));
   nb = 0;
   for id2 = 1:length(idF)
      nb = nb + size(dataAll(idF(id2)).data, 1);
   end
   if (nb ~= nbMeas)
%       a=1
   end
end

g_decArgo_cts5PhaseDescent = 1;
g_decArgo_cts5PhasePark = 2;
g_decArgo_cts5PhaseDeepProfile = 3;
g_decArgo_cts5PhaseShortPark = 4;
g_decArgo_cts5PhaseAscent = 5;
g_decArgo_cts5PhaseSurface = 6;



%       phase: '[SURFACE]'
%     phaseId: 6
%       treat: '(RW)'
%     treatId: 4
%        date: []
%        data: [22×4 double]

% g_decArgo_useaTechData{10, 4}.DATA.name'
return
