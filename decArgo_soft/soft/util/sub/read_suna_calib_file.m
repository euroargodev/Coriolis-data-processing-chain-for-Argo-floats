% ------------------------------------------------------------------------------
% Read the SUNA calibration data file.
%
% SYNTAX :
%  [o_creationDate, o_tempCalNitrate, o_opticalWavelengthUv, ...
%    o_eNitrate, o_eSwaNitrate, o_eBisulfide, o_uvIntensityRefNitrate] = ...
%    read_suna_calib_file(a_sunaCalibFileName, a_dacFormatId)
%
% INPUT PARAMETERS :
%   a_sunaCalibFileName : SUNA calibration data file
%   a_dacFormatId       : DAC version of the float
%
% OUTPUT PARAMETERS :
%   o_creationDate          : "File creation time" information
%   o_tempCalNitrate        : "T_CAL_SWA" or "T_CAL" information
%   o_opticalWavelengthUv   : "Wavelength" information
%   o_eNitrate              : "NO3" information
%   o_eSwaNitrate           : "SWA" information
%   o_eBisulfide            : "HS" information
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
   o_eNitrate, o_eSwaNitrate, o_eBisulfide, o_uvIntensityRefNitrate] = ...
   read_suna_calib_file(a_sunaCalibFileName, a_dacFormatId)
      
% output parameters initialization
o_creationDate = [];
o_tempCalNitrate = [];
o_opticalWavelengthUv = [];
o_eNitrate = [];
o_eSwaNitrate = [];
o_eBisulfide = [];
o_uvIntensityRefNitrate = [];


% read the calibration file
if ~(exist(a_sunaCalibFileName, 'file') == 2)
   fprintf('ERROR: Input file not found: %s\n', a_sunaCalibFileName);
else
   
   fId = fopen(a_sunaCalibFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', a_sunaCalibFileName);
      return
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

      dataInfo = '';
      idLastH = find(strcmp(calibData, 'H') == 1, 1, 'last');
      if (~isempty(idFirstE) && ~isempty(idLastH))
         dataInfo = calibData(idLastH+1:idFirstE-1);
      end

      data = calibData(idFirstE:end);
      switch (a_dacFormatId)
         case {'5.9', '5.91', '5.92', '5.94', '6.01', '6.11', '6.13', ...
               '7.01', '7.02', '7.03', '7.04', '7.05', ...
               '7.11', '7.14', '7.15', '7.16'}
            if (mod(length(data), 6) == 0)
               o_opticalWavelengthUv = data(2:6:end);
               o_eNitrate = data(3:6:end);
               o_eSwaNitrate = data(4:6:end);
               o_uvIntensityRefNitrate = data(6:6:end);
            else
               o_creationDate = [];
               fprintf('ERROR: Calibration information is missing in file: %s\n', a_sunaCalibFileName);
            end
         case {'5.93', '6.12'}
            if (mod(length(data), 6) == 0)
               o_opticalWavelengthUv = data(2:6:end);
               o_eSwaNitrate = data(3:6:end);
               o_eNitrate = data(4:6:end);
               o_eBisulfide = data(5:6:end);
               o_uvIntensityRefNitrate = data(6:6:end);
            else
               o_creationDate = [];
               fprintf('ERROR: Calibration information is missing in file: %s\n', a_sunaCalibFileName);
            end
         case {'7.12', '7.13'}
            if ((mod(length(data), 7) == 0) && (length(dataInfo) == 6) && ...
                  strcmp(dataInfo{1}, 'Wavelength') && ...
                  strcmp(dataInfo{2}, 'NO3') && ...
                  strcmp(dataInfo{3}, 'SWA') && ...
                  strcmp(dataInfo{6}, 'Reference'))
               o_opticalWavelengthUv = data(2:7:end);
               o_eNitrate = data(3:7:end);
               o_eSwaNitrate = data(4:7:end);
               o_eBisulfide = data(6:7:end);
               o_uvIntensityRefNitrate = data(7:7:end);
            elseif ((mod(length(data), 6) == 0) && (length(dataInfo) == 5) && ...
                  strcmp(dataInfo{1}, 'Wavelength') && ...
                  strcmp(dataInfo{2}, 'NO3') && ...
                  strcmp(dataInfo{3}, 'SWA') && ...
                  strcmp(dataInfo{5}, 'Reference'))
               o_opticalWavelengthUv = data(2:6:end);
               o_eNitrate = data(3:6:end);
               o_eSwaNitrate = data(4:6:end);
               o_uvIntensityRefNitrate = data(6:6:end);
            else
               o_creationDate = [];
               fprintf('ERROR: Calibration information is missing in file: %s\n', a_sunaCalibFileName);
            end
         otherwise
            fprintf('WARNING: Don''t know how to parse SUNA calibration file for float DAC version ''%s''\n', ...
               a_dacFormatId);
      end
   end   
end

return
