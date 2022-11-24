% ------------------------------------------------------------------------------
% Decode IMU Raw data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_imuRawData] = decode_apmt_imu_raw(a_data, a_lastByteNum, a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_data              : input IMU Raw data to decode
%   a_lastByteNum       : number of the last useful byte of the data
%   a_inputFilePathName : APMT IMU Raw file to decode
%
% OUTPUT PARAMETERS :
%   o_imuRawData : IMU Raw decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_imuRawData] = decode_apmt_imu_raw(a_data, a_lastByteNum, a_inputFilePathName)

% output parameters initialization
o_imuRawData = [];

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
   {''} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {''} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {''} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {'(RW)'} ...
   {'(AM)'} ...
   {''} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {'(DW)'} ...
   ];

% list of corresponding bit pattern (used to acces the data)
bitList = [ ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {repmat(16, 1, 12)} ...
   {repmat(16, 1, 12)} ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {repmat(16, 1, 12)} ...
   ];

% list of signed type parameters
signedList = [ ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[0 0 ones(1, 10)]} ...
   {[0 0 ones(1, 10)]} ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[0 0 ones(1, 10)]} ...
   ];

inputData = a_data;
lastByteNum = a_lastByteNum;
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
         if (isempty(treatList{idTreat}))
            continue
         end
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
      nbBytes = sum(tabNbBits)/8;
      rawData = get_bits(1, tabNbBits, inputData(currentByte:currentByte+nbBytes-1));
      tabSignedList = signedList{currentTreatNum};
      for id = 1:length(tabNbBits)
         if ((tabNbBits(id) == 16) || (id == 1))
            rawData(id) = decode_apmt_meas(rawData(id), tabNbBits(id), tabSignedList(id), a_inputFilePathName);
         elseif (tabNbBits(id) == 32)
            rawData(id) = typecast(uint32(swapbytes(uint32(rawData(id)))), 'single');
         end
      end
      
      data = nan(1, 12);
      if (ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
         data(1) = epoch_2_julian_dec_argo(rawData(1));
      else
         data(1) = rawData(1);
      end
      data(2) = rawData(2)/10 - 100;
      data(3:end) = rawData(3:end);

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

o_imuRawData = dataStruct;

return
