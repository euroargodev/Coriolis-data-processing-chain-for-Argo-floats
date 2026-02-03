% ------------------------------------------------------------------------------
% Read the RAMSES calibration data files.
%
% SYNTAX :
% [o_darkPixel, o_cisCoef, o_wavelength, o_back1, o_back2, o_calAq] = ...
%   read_ramses_calib_files(a_ramsesCalibDirName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_ramsesCalibDirName : RAMSES calibration directory files
%   a_floatNum           : float WMO
%
% OUTPUT PARAMETERS :
%   o_darkPixel  : dark pixel begin/end
%   o_cisCoef    : c0s to c4s coefficients used to compute wavelengths
%                  associated to the pixels
%   o_wavelength : wavelengths associated to the pixels
%   o_back1      : background spectrum
%   o_back2      : background spectrum
%   o_calAq      : sensitivity of the sensor in water
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/18/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_darkPixel, o_cisCoef, o_wavelength, o_back1, o_back2, o_calAq] = ...
   read_ramses_calib_files(a_ramsesCalibDirName, a_floatNum)
      
% output parameters initialization
o_darkPixel = [];
o_darkPixel.begin = '';
o_darkPixel.end = '';
o_cisCoef = [];
o_cisCoef.c0s = nan;
o_cisCoef.c1s = nan;
o_cisCoef.c2s = nan;
o_cisCoef.c3s = nan;
o_cisCoef.c4s = nan;
o_wavelength = [];
o_back1 = [];
o_back2 = [];
o_calAq = [];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the SAM_*.ini file

files = dir([a_ramsesCalibDirName '/SAM_*.ini']);
if (length(files) == 1)

   filePathName = [a_ramsesCalibDirName '/' files.name];
   fId = fopen(filePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', filePathName);
      return
   end
   data = textscan(fId, '%s', 'delimiter', '=');
   data = strtrim(data{:});
   fclose(fId);

   idF = find(strcmpi(data, 'DarkPixelStart'));
   if (~isempty(idF))
      o_darkPixel.begin = data{idF+1};
   end
   idF = find(strcmpi(data, 'DarkPixelStop'));
   if (~isempty(idF))
      o_darkPixel.end = data{idF+1};
   end
   for id = 0:4
      idF = find(strcmp(data, ['c' num2str(id) 's']));
      if (~isempty(idF))
         o_cisCoef.(['c' num2str(id) 's']) = data{idF+1};
      else
         if (id == 4)
            % c4s can be missing in the file, in that case set is value to 0
            o_cisCoef.(['c' num2str(id) 's']) = '0';
         else
            fprintf('ERROR: Float %d: RAMSES calibration: ''%s'' coefficient not found in file %s\n', ...
               a_floatNum, ['c' num2str(id) 's'], filePathName);
         end
      end
   end

elseif (isempty(files))
   fprintf('ERROR: RAMSES calibration: SAM_*.ini file is missing for float %d\n', ...
      a_floatNum);
else
   fprintf('ERROR: RAMSES calibration: many SAM_*.ini files for float %d\n', ...
      a_floatNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% compute WAVELENGTH

o_wavelength = repmat({'nan'}, 255, 1);
c0s = str2double(o_cisCoef.c0s);
c1s = str2double(o_cisCoef.c1s);
c2s = str2double(o_cisCoef.c2s);
c3s = str2double(o_cisCoef.c3s);
c4s = str2double(o_cisCoef.c4s);
for id = 1:255
   wavelength = c0s + c1s*(id+1) + c2s*(id+1)*(id+1) + c3s*(id+1)*(id+1)*(id+1) + c4s*(id+1)*(id+1)*(id+1)*(id+1);
   o_wavelength{id} = sprintf('%.11f', wavelength);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the Back_SAM_*.dat file

files = dir([a_ramsesCalibDirName '/Back_SAM_*.dat']);
if (length(files) == 1)

   filePathName = [a_ramsesCalibDirName '/' files.name];
   fId = fopen(filePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', filePathName);
      return
   end

   start = 0;
   o_back1 = repmat({'nan'}, 255, 1);
   o_back2 = repmat({'nan'}, 255, 1);
   id = 1;
   while (1)
      line = fgetl(fId);
      if (line == -1)
         break
      end
      if ((start == 1) && any(strfind(line, '[END]')))
         break
      end
      if (start == 1)
         data = textscan(strtrim(line), '%s', 'delimiter', ' ');
         data = data{:};
         if (str2double(data{1}) > 0)
            o_back1(id) = data(2);
            o_back2(id) = data(3);
            id = id + 1;
         end
      end
      if (any(strfind(line, '[DATA]')))
         start = 1;
      end
   end

   fclose(fId);

elseif (isempty(files))
   fprintf('ERROR: RAMSES calibration: Back_SAM_*.dat file is missing for float %d\n', ...
      a_floatNum);
else
   fprintf('ERROR: RAMSES calibration: many Back_SAM_*.dat files for float %d\n', ...
      a_floatNum);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read the CalAQ_SAM_*.dat file

files = dir([a_ramsesCalibDirName '/CalAQ_SAM_*.dat']);
if (length(files) == 1)

   filePathName = [a_ramsesCalibDirName '/' files.name];
   fId = fopen(filePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', filePathName);
      return
   end

   start = 0;
   o_calAq = repmat({'nan'}, 255, 1);
   id = 1;
   while (1)
      line = fgetl(fId);
      if (line == -1)
         break
      end
      if ((start == 1) && any(strfind(line, '[END]')))
         break
      end
      if (start == 1)
         data = textscan(strtrim(line), '%s', 'delimiter', ' ');
         data = data{:};
         if (str2double(data{1}) > 0)
            o_calAq(id) = data(2);
            id = id + 1;
         end
      end
      if (any(strfind(line, '[DATA]')))
         start = 1;
      end
   end

   fclose(fId);

elseif (isempty(files))
   fprintf('ERROR: RAMSES calibration: CalAQ_SAM_*.dat file is missing for float %d\n', ...
      a_floatNum);
else
   fprintf('ERROR: RAMSES calibration: many CalAQ_SAM_*.dat files for float %d\n', ...
      a_floatNum);
end

return
