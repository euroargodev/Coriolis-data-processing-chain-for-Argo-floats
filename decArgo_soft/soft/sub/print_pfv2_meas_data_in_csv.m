% ------------------------------------------------------------------------------
% Print measurement data in a CSV file.
%
% SYNTAX :
% print_pfv2_meas_data_in_csv(a_floatData)
%
% INPUT PARAMETERS :
%   a_floatData : float data information
%                 1: fileType
%                 2: missionNum
%                 3: cycleNum
%                 4: fileName
%                 5: tabTechEvt or tabTech or measData or confLabels
%                 6: tabTechTime or confValues
%                 7: tabTechTraj
%                 8: tabTechBuoy
%                 9: tabTechSpy
%                 10: selfTestDate or settingDate
%                 11: float HEX base file Name
%                 12: float final file name
%                 13: zip file size
%                 14: final file size
%                 15: SBD file information (1: SBD file name, 2: SBD file date, 3: SBD file size, 4: data file size
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/10/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_pfv2_meas_data_in_csv(a_floatData)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_floatData))
   return
end

fileType = a_floatData{1};
missionNum = a_floatData{2};
cycleNum = a_floatData{3};
fileName = a_floatData{4};
sensorNum = a_floatData{5};
formatNum = a_floatData{6};
measData = a_floatData{7};

switch (fileType)
   case 20 % Desc2Park
      fileTypeStr = 'Desc2Park';
      measTypeStr = 'profile meas.';
   case 21 % ParkDrift
      fileTypeStr = 'ParkDrift';
      measTypeStr = 'dift meas';
   case 22 % Desc2Prof
      fileTypeStr = 'Desc2Prof';
      measTypeStr = 'profile meas';
   case 23 % ProfDrift
      fileTypeStr = 'ProfDrift';
      measTypeStr = 'dift meas';
   case 24 % AscProf
      fileTypeStr = 'AscProf';
      measTypeStr = 'profile meas';
   case 25 % InAir
      fileTypeStr = 'InAir';
      measTypeStr = 'surf meas';
end

sensorName = get_sensor_name(sensorNum);
fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s\n', ...
   g_decArgo_floatNum, ...
   missionNum, ...
   cycleNum, ...
   fileTypeStr, ...
   fileName);

switch (sensorNum)
   case 1 % SBE41

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;%s;Description;Float time;PRES(dbar);TEMP(degC); PSAL(PSU)\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum, ...
         fileTypeStr, ...
         sensorName);

      for idMeas = 1:size(measData, 1)
         measTime = '';
         if (~isnan(measData(idMeas, 1)))
            measTime = julian_2_gregorian_dec_argo(measData(idMeas, 1));
         end
         fprintf(g_decArgo_outputCsvFileId, ['%d;%d;%d;%s;%s;' measTypeStr ' #%d; %s;%.1f;%.3f;%.3f\n'], ...
            g_decArgo_floatNum, ...
            missionNum, ...
            cycleNum, ...
            fileTypeStr, ...
            sensorName, ...
            idMeas, ...
            measTime, ...
            measData(idMeas, 2), ...
            measData(idMeas, 3), ...
            measData(idMeas, 4));
      end

   case 2 % Aanderaa 4330

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;%s;Description;Float time;PRES(dbar);C1PHASE_DOXY (degree);C2PHASE_DOXY (degree);TEMP_DOXY (degC)\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum, ...
         fileTypeStr, ...
         sensorName);

      for idMeas = 1:size(measData, 1)
         measTime = '';
         if (~isnan(measData(idMeas, 1)))
            measTime = julian_2_gregorian_dec_argo(measData(idMeas, 1));
         end
         fprintf(g_decArgo_outputCsvFileId, ['%d;%d;%d;%s;%s;' measTypeStr ' #%d; %s;%.1f;%.3f;%.3f;%.3f\n'], ...
            g_decArgo_floatNum, ...
            missionNum, ...
            cycleNum, ...
            fileTypeStr, ...
            sensorName, ...
            idMeas, ...
            measTime, ...
            measData(idMeas, 2), ...
            measData(idMeas, 3), ...
            measData(idMeas, 4), ...
            measData(idMeas, 5));
      end

   case 3 % RBRargo3

      fprintf('ERROR: Float #%d: Data decoding not implemented yet for RBRargo3\n', ...
         g_decArgo_floatNum);
      return

   otherwise
      fprintf('ERROR: Float #%d: Unexpected sensor number (%d) in file %\n', ...
         g_decArgo_floatNum, ...
         sensorNum, ...
         filePathName);
      return
end

return

% ------------------------------------------------------------------------------
% Retrieve the sensor name from its number.
%
% SYNTAX :
% [o_sensorName] = get_sensor_name(a_sensorNum)
%
% INPUT PARAMETERS :
%   a_sensorNum : input sensor number
%
% OUTPUT PARAMETERS :
%   o_sensorName : output sensor name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorName] = get_sensor_name(a_sensorNum)

% output parameters initialization
o_sensorName = '';

% current float WMO number
global g_decArgo_floatNum;


switch (a_sensorNum)
   case 1
      o_sensorName = 'SBE41';
   case 2
      o_sensorName = 'AANDERAA_OPTODE_4330';
   case 3
      o_sensorName = 'RBR_ARGO3';
   otherwise
      fprintf('ERROR: Float #%d: Unexpected sensor number (%d)\n', ...
         g_decArgo_floatNum, ...
         sensorNum);
end

return
