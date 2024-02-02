% ------------------------------------------------------------------------------
% Decode IMU Tilt & Heading data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_imuTiltHeadingData] = decode_apmt_imu_tilt_heading(a_data, a_lastByteNum, a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_data              : input IMU Tilt & Heading data to decode
%   a_lastByteNum       : number of the last useful byte of the data
%   a_inputFilePathName : APMT IMU Tilt & Heading file to decode
%
% OUTPUT PARAMETERS :
%   o_imuTiltHeadingData : IMU Tilt & Heading decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/27/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_imuTiltHeadingData] = decode_apmt_imu_tilt_heading(a_data, a_lastByteNum, a_inputFilePathName)

% output parameters initialization
o_imuTiltHeadingData = [];

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_DW;


% NKE personal communication
TILT_VALUE = [ ...
0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.7,1.8,1.9,2.0,2.1,2.2,2.3,2.4,2.5,2.6,2.7,2.8,2.9,3.0,3.1,3.2,3.3,3.4,3.5,3.6,3.7,3.8,3.9,4.0,4.1,4.2,4.3,4.4,4.5,4.6,4.7,4.8,4.9,5.0, ...
5.2,5.4,5.6,5.8,6.0,6.2,6.4,6.6,6.8,7.0,7.2,7.4,7.6,7.8,8.0,8.2,8.4,8.6,8.8,9.0,9.2,9.4,9.6,9.8,10.0, ...
10.5,11.0,11.5,12.0,12.5,13.0,13.5,14.0,14.5,15.0,15.5,16.0,16.5,17.0,17.5,18.0,18.5,19.0,19.5,20.0, ...
21.0,22.0,23.0,24.0,25.0,26.0,27.0,28.0,29.0,30.0,31.0,32.0,33.0,34.0,35.0,36.0,37.0,38.0,39.0,40.0,41.0,42.0,43.0,44.0,45.0,46.0,47.0,48.0,49.0,50.0,51.0,52.0];

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
   {[16 16 8 8]} ...
   {[16 16 8 8]} ...
   {[]} ... % unused but to be consistent with g_decArgo_cts5Treat_SS (so that 'DW' is g_decArgo_cts5Treat_DW == 7)
   {[16 16 8 8]} ...
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
   
   % the treatment type of PARK, SHORT_PARK and SURFACE measurements is always
   % RAW (NKE personal communication)
   if (ismember(newPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
      newTreatNum = g_decArgo_cts5Treat_RW;
   else

      % look for a new treatment header
      if (inputData(currentByte) == '(')
         for idTreat = 1:length(treatList)
            treatName = treatList{idTreat};
            if (~isempty(treatName))
               if (strcmp(char(inputData(currentByte:currentByte+length(treatName)-1))', treatName))
                  newTreatNum = idTreat;
                  currentByte = currentByte + length(treatName);
                  break
               end
            end
         end
      end
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
      for id = 1:length(tabNbBits)
         if ((tabNbBits(id) == 16) || (id == 1))
            rawData(id) = decode_apmt_meas(rawData(id), tabNbBits(id), 0, a_inputFilePathName);
         elseif (tabNbBits(id) == 32)
            rawData(id) = typecast(uint32(swapbytes(uint32(rawData(id)))), 'single');
         end
      end
      
      data = nan(1, 4);
      if (ismember(currentPhaseNum, [g_decArgo_cts5PhasePark g_decArgo_cts5PhaseShortPark g_decArgo_cts5PhaseSurface]))
         data(1) = epoch_2_julian_dec_argo(rawData(1));
      else
         data(1) = rawData(1);
      end
      data(2) = rawData(2)/10 - 100;
      data(3:end) = rawData(3:end);

      tiltCode = bitand(data(3), 127);
      tiltValue = TILT_VALUE(tiltCode+1);

      headingValue = data(4);
      if (bitand(data(3), 128) == 128)
         headingValue = headingValue*-1;
      end

      data(3) = tiltValue;
      data(4) = headingValue;

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

o_imuTiltHeadingData = dataStruct;

return
