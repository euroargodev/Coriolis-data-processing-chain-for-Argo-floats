% ------------------------------------------------------------------------------
% Decode RAMSES data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_ramsesData] = decode_apmt_ramses(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT RAMSES file to decode
%
% OUTPUT PARAMETERS :
%   o_ramsesData : RAMSES decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ramsesData] = decode_apmt_ramses(a_inputFilePathName)

% output parameters initialization
o_ramsesData = [];

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_RW;
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
   {''} ...
   {''} ...
   {''} ...
   {'(RW)'} ...
   {''} ...
   {''} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {'(DW)'} ...
   ];

% list of corresponding bit pattern (used to acces the data)
bitList = [ ...
   {[]} ...
   {[]} ...
   {[]} ...
   {[repmat(16, 1, 8) 8]} ... % the number of channels is provided in the data (bit pattern will be updated later)
   {[]} ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[repmat(16, 1, 8) 8]} ... % the number of channels is provided in the data (bit pattern will be updated later)
   ];

% list of signed type parameters
signedList = [ ...
   {[]} ...
   {[]} ...
   {[]} ...
   {zeros(1, 9)} ... % the number of channels is provided in the data (list of signed type parameters will be updated later)
   {[]} ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {zeros(1, 9)} ... % the number of channels is provided in the data (list of signed type parameters will be updated later)
   ];

if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_ramses: File not found: %s\n', a_inputFilePathName);
   return
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return
end
inputData = fread(fId);
fclose(fId);

if (inputData(1) ~= 23)
   fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
   return
end

% find the position of the last useful byte
lastByteNum = get_last_byte_number(inputData, hex2dec('1a'));

currentPhaseNum = -1;
currentTreatNum = -1;
dataStruct = [];
currentDataStruct = [];
currentByte = 2;
while (currentByte <= lastByteNum)
   
   newPhaseNum = -1;
   newTreatNum = -1;
   
   % look for a new phase header
   if (inputData(currentByte) == '[')
      for idPhase = 1:length(phaseList)
         phaseName = phaseList{idPhase};
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
         if (~ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
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
      if (ismember(currentPhaseNum, [g_decArgo_cts5PhaseDescent g_decArgo_cts5PhaseDeepProfile g_decArgo_cts5PhaseAscent]))
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
      
      % first decoding to retrieve the number of channels
      nbBytes = sum(tabNbBits)/8;
      rawData = get_bits(1, tabNbBits, inputData(currentByte:currentByte+nbBytes-1));
      nbChannels = rawData(end);
      
      tabNbBits = [tabNbBits repmat(16, 1, nbChannels)];
      nbBytes = sum(tabNbBits)/8;
      rawData = get_bits(1, tabNbBits, inputData(currentByte:currentByte+nbBytes-1));
      tabSignedList = signedList{currentTreatNum};
      tabSignedList = [tabSignedList zeros( 1, nbChannels)];
      for id = 1:length(tabNbBits)
         rawData(id) = decode_apmt_meas(rawData(id), tabNbBits(id), tabSignedList(id), a_inputFilePathName);
      end
      
      if (ismember(currentTreatNum, [g_decArgo_cts5Treat_RW g_decArgo_cts5Treat_DW]))
         % raw data
         if (ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
            data(1) = epoch_2_julian_dec_argo(rawData(1));
         else
            data(1) = rawData(1);
         end
         data(2) = rawData(2)/10 - 100;
         data(3) = rawData(3);
         data(4) = rawData(4)/20 - 100;
         data(5) = rawData(5)/20 - 100;
         data(6) = rawData(6)/10;
         data(7) = rawData(7)/10;
         data(8) = rawData(8);
         data(9) = rawData(9);
         data(10:9+nbChannels) = rawData(10:end);
      else
         fprintf('ERROR: Treatment #%d not managed\n', currentTreatNum);
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
   if (~ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
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

o_ramsesData = dataStruct;

return
