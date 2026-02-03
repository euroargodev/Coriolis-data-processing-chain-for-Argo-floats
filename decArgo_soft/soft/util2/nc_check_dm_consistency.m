% ------------------------------------------------------------------------------
% Check consistency between PROF file name, DATA_MODE and
% PARAMETER_DATA_MODE.
%
% SYNTAX :
%   nc_check_dm_consistency
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_dm_consistency

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\201809-ArgoData\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_check_dm_consistency_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;


% output CSV file header
header = ['DAC; WMO; FILE; PI NAME; VERSION; N_PROF; PROF#; DATA_MODE; PARAMETER_DATA_MODE'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)

   dacDirName = dacDir(idDir).name;

   %    if (~strcmp(dacDirName, 'coriolis'))
   %       continue
   %    end

   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))

      fprintf('\nProcessing directory: %s\n', dacDirName);

      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_check_dm_consistency_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);

      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)

         floatDirName = floatDir(idDir2).name;

         %          if (~strcmp(floatDirName, '1900943'))
         %             continue
         %          end

         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)

            floatProfDirPathName = [dacDirPathName '/' floatDirName '/profiles/'];

            if (exist(floatProfDirPathName, 'dir') == 7)

               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);

               profDir = dir(floatProfDirPathName);
               for idFProf = 1:length(profDir)

                  profFileName = profDir(idFProf).name;
                  if (profFileName(1) == 'M')
                     continue
                  end
                  profFilePathName = [floatProfDirPathName '/' profFileName];
                  if (exist(profFilePathName, 'file') == 2)

                     % retrieve information from profile file
                     wantedInputVars = [ ...
                        {'PI_NAME'} ...
                        {'FORMAT_VERSION'} ...
                        {'DATA_MODE'} ...
                        {'PARAMETER_DATA_MODE'} ...
                        ];
                     [profData] = get_data_from_nc_file(profFilePathName, wantedInputVars);

                     piName = deblank(get_data_from_name('PI_NAME', profData)');
                     formatVersion = deblank(get_data_from_name('FORMAT_VERSION', profData)');
                     dataMode = get_data_from_name('DATA_MODE', profData)';
                     parameterDataMode = get_data_from_name('PARAMETER_DATA_MODE', profData)';

                     errorProf = [];
                     % check consistency between file name and DATA_MODE
                     if ((profFileName(1) == 'D') || (profFileName(2) == 'D')) && ...
                           ~any(dataMode == 'D')
                        idF = find(dataMode == 'D');
                        errorProf = idF;
                        fprintf('   ERROR: %s\n', profFileName);
                     end

                     % check consistency between DATA_MODE and PARAMETER_DATA_MODE
                     for idProf = 1:size(parameterDataMode, 1)
                        if ((((dataMode(idProf) == 'D') && ...
                              ~any(parameterDataMode(idProf, :) == 'D'))) || ...
                              ((dataMode(idProf) == 'A') && ...
                              (any(parameterDataMode(idProf, :) == 'D') || ~any(parameterDataMode(idProf, :) == 'A'))) || ...
                              ((dataMode(idProf) == 'R') && ...
                              (any(parameterDataMode(idProf, :) == 'D') || any(parameterDataMode(idProf, :) == 'A'))))
                           errorProf = [errorProf idProf];
                           fprintf('   ERROR: %s\n', profFileName);
                        end
                     end

                     if (~isempty(errorProf))
                        for id = 1:length(errorProf)
                           fprintf(fidOut, '%s; %s; %s; %s; %s; %d; %d; %c; %s\n', ...
                              dacDirName, floatDirName, profFileName, piName(idProf, :), formatVersion, length(dataMode), errorProf(id), dataMode(errorProf(id)), parameterDataMode(errorProf(id), :));
                        end
                     end
                  end
               end
            end
         end
      end
      fclose(fidOut);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
