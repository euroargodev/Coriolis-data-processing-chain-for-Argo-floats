% ------------------------------------------------------------------------------
% Generate json float information files for floats not declared in the Coriolis
% data base and not decoded by the Argos Matlab decoder.
%
% SYNTAX :
%  generate_json_float_info_complement2()
%
% INPUT PARAMETERS :
%  
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2014 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_info_complement2()

% list of Argos Id to ignore
ignoredArgosIdListFile = 'C:\users\RNU\Argo\Aco\12833_update_decPrv_pour_RT_TRAJ3\lists\ignored_argos_id.txt';

fprintf('Generating json info files for Argos Ids listed in file: %s\n', ignoredArgosIdListFile);

% directory of individual json float information files
outputDirName = ['C:\users\RNU\Argo\work\json_unused_float_info_files_' datestr(now, 'yyyymmddTHHMMSS')];


if ~(exist(ignoredArgosIdListFile, 'file') == 2)
   fprintf('ERROR: Ignored Argos Id list file not found: %s\n', ignoredArgosIdListFile);
   return;
end

% create the list of Argos Id to ignore
ignoredArgosIdList = load(ignoredArgosIdListFile);

mkdir(outputDirName);

for idArgosId = 1:length(ignoredArgosIdList)
   
   fprintf('%3d/%3d %d\n', idArgosId, length(ignoredArgosIdList), ignoredArgosIdList(idArgosId));

   fprintf('=> JSON\n');
   
   outputFileName = [outputDirName '/' sprintf('WWWWWWW_%d_info.json', ...
      ignoredArgosIdList(idArgosId))];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
      return;
   end
      
   fprintf(fidOut, '{\n');
   fprintf(fidOut, '   "WMO" : "Unknown",\n');
   fprintf(fidOut, '   "PTT" : "%d",\n', ignoredArgosIdList(idArgosId));
   fprintf(fidOut, '   "FLOAT_TYPE" : "Unknown",\n');
   fprintf(fidOut, '   "DECODER_VERSION" : "Unknown",\n');
   fprintf(fidOut, '   "DECODER_ID" : "-1",\n');
   fprintf(fidOut, '   "LAUNCH_DATE" : "Unknown",\n');
   fprintf(fidOut, '   "LAUNCH_LON" : "Unknown",\n');
   fprintf(fidOut, '   "LAUNCH_LAT" : "Unknown"\n');
   fprintf(fidOut, '}\n');
   
   fclose(fidOut);

end

fprintf('done\n');

return;
