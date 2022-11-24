% ------------------------------------------------------------------------------
% Read the SUNA calibration data file.
%
% SYNTAX :
%  [o_creationDate, o_tempCalNitrate, o_opticalWavelengthUv, ...
%    o_eNitrate, o_eSwaNitrate, o_uvIntensityRefNitrate] = read_suna_calib_file(a_sunaCalibFileName)
%
% INPUT PARAMETERS :
%   a_sunaCalibFileName : SUNA calibration data file
%
% OUTPUT PARAMETERS :
%   o_creationDate          : "File creation time" information
%   o_tempCalNitrate        : "T_CAL_SWA" or "T_CAL" information
%   o_opticalWavelengthUv   : "Wavelength" information
%   o_eNitrate              : "NO3" information
%   o_eSwaNitrate           : "SWA" information
%   o_uvIntensityRefNitrate : "Reference" information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/08/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_creationDate, o_tempCalNitrate, o_opticalWavelengthUv, ...
   o_eNitrate, o_eSwaNitrate, o_uvIntensityRefNitrate] = read_suna_calib_file(a_sunaCalibFileName)
      
% output parameters initialization
o_creationDate = [];
o_tempCalNitrate = [];
o_opticalWavelengthUv = [];
o_eNitrate = [];
o_eSwaNitrate = [];
o_uvIntensityRefNitrate = [];


% read the calibration file
if ~(exist(a_sunaCalibFileName, 'file') == 2)
   fprintf('ERROR: Input file not found: %s\n', a_sunaCalibFileName);
else
   
   fId = fopen(a_sunaCalibFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', a_sunaCalibFileName);
      return;
   end
   
   calibData = textscan(fId, '%s', 'delimiter', ',');
   
   fclose(fId);
   
   calibData = calibData{:};

   % parse calibration data
   idFirstDate = find(strncmp(calibData, 'File creation time', length('File creation time')) == 1, 1);
   if (~isempty(idFirstDate))
      creationDate = calibData{idFirstDate};
      creationDate = strtrim(creationDate(length('File creation time ')+1:end));
      o_creationDate = creationDate;
   end

   idTempCalNitrate = find(strncmp(calibData, 'T_CAL_SWA', length('T_CAL_SWA')) == 1, 1);
   if (~isempty(idTempCalNitrate))
      tempCalNitrate = calibData{idTempCalNitrate};
      tempCalNitrate = strtrim(tempCalNitrate(length('T_CAL_SWA')+1:end));
      o_tempCalNitrate = tempCalNitrate;
   else
      idTempCalNitrate = find(strncmp(calibData, 'T_CAL', length('T_CAL')) == 1, 1);
      if (~isempty(idTempCalNitrate))
         tempCalNitrate = calibData{idTempCalNitrate};
         tempCalNitrate = strtrim(tempCalNitrate(length('T_CAL')+1:end));
         o_tempCalNitrate = tempCalNitrate;
      end
   end
   
   idFirstE = find(strcmp(calibData, 'E') == 1, 1);
   if (~isempty(idFirstE))
      data = calibData(idFirstE:end);
      if (mod(length(data), 6) == 0)
         o_opticalWavelengthUv = data(2:6:end);
         o_eNitrate = data(3:6:end);
         o_eSwaNitrate = data(4:6:end);
         o_uvIntensityRefNitrate = data(6:6:end);
      else
         o_creationDate = [];
         fprintf('ERROR: Calibration information is missing in file: %s\n', a_sunaCalibFileName);
      end
   end   
end

return;
