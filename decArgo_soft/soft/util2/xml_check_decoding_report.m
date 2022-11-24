% ------------------------------------------------------------------------------
% Read XML decoding reports and save useful information in CSV file.
%
% SYNTAX :
%   xml_check_decoding_report or xml_check_decoding_report(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to consider
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2021 - RNU - creation
% ------------------------------------------------------------------------------
function xml_check_decoding_report(varargin)

% list of floats to process (if empty, all encountered floats will be processed)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of XML report files files
DIR_INPUT_XML_FILES = 'C:\Users\jprannou\_DATA\XML_report\XLM_A_TRAITER\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% default values initialization
init_default_values;


floatList = '';
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      % floats to process come from floatListFileName
      if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
         fprintf('File not found: %s\n', FLOAT_LIST_FILE_NAME);
         return
      end

      fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
      floatList = load(FLOAT_LIST_FILE_NAME);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

currentTime = datestr(now, 'yyyymmddTHHMMSS');

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'xml_check_decoding_report_' currentTime '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'xml_check_decoding_report_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

header = '#;WMO;NB_REP;DATE;DURATION;DEC_VERSION;NB_CYCLES;NB_INPUT;NB_PROF;REPORT_FILE;DURATION_SEC;DIFF_DURATION(%);NB_STAT;MEAN;STD;MED;DIFF_MED';
fprintf(fidOut, '%s\n', header);

% process input directory contents
fileList = dir([DIR_INPUT_XML_FILES '/*.xml']);
reportDataAll = [];
for idF = 1:length(fileList)
% for idF = 1:500

   fileName = fileList(idF).name;
   filePathName = [DIR_INPUT_XML_FILES '/' fileName];

   fprintf('%03d/%03d %s\n', idF, length(fileList), fileName);
   try
      reportData = process_xml_file(filePathName);
      reportDataAll = [reportDataAll reportData];
   catch
      fprintf('ERROR: error while processing file: %s\n', filePathName);
      continue
   end
end

% compute durations
wmoList  = unique([reportDataAll.wmo]);
for idW = 1:length(wmoList)
   idF = find([reportDataAll.wmo] == wmoList(idW));
   [reportDataAll(idF).nb_rep] = deal(length(idF));
   idF = find(([reportDataAll.wmo] == wmoList(idW)) & ([reportDataAll.nb_mono_prof] <= 2));
   if (length(idF) > 1)
      [reportDataAll(idF).nb_stat] = deal(length(idF));
      [reportDataAll(idF).mean] = deal(mean([reportDataAll(idF).duration]));
      [reportDataAll(idF).std] = deal(std([reportDataAll(idF).duration]));
      [reportDataAll(idF).median] = deal(median([reportDataAll(idF).duration]));
      for idW2 = 1:length(idF)
         if (idW2 > 1)
            reportDataAll(idF(idW2)).diff_duration = (reportDataAll(idF(idW2)).duration - reportDataAll(idF(idW2-1)).duration)*100/reportDataAll(idF(idW2-1)).duration;
         end
         reportDataAll(idF(idW2)).diff_median = reportDataAll(idF(idW2)).duration - reportDataAll(idF(idW2)).median;
      end
   end
end

% sort collected information
dateList = [reportDataAll.date];
[~, idSort] = sort(dateList);
reportDataAll = reportDataAll(idSort);

% save useful data
for idS = 1:length(reportDataAll)
   fprintf(fidOut, '%d;%d;%d;%s;%s;%s;%d;%d;%d;%s;%d;%.1f;%d;%.1f;%.1f;%.1f;%.1f\n', ...
      idS, ...
      reportDataAll(idS).wmo, ...
      reportDataAll(idS).nb_rep, ...
      julian_2_gregorian_dec_argo(reportDataAll(idS).date), ...
      reportDataAll(idS).durationStr, ...
      reportDataAll(idS).decoder_version, ...
      reportDataAll(idS).nb_cycles, ...
      reportDataAll(idS).nb_input_file, ...
      reportDataAll(idS).nb_mono_prof, ...
      reportDataAll(idS).rep_file, ...
      reportDataAll(idS).duration, ...
      reportDataAll(idS).diff_duration, ...
      reportDataAll(idS).nb_stat, ...
      reportDataAll(idS).mean, ...
      reportDataAll(idS).std, ...
      reportDataAll(idS).median, ...
      reportDataAll(idS).diff_median ...
      );
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one XML decoding report.
%
% SYNTAX :
%  [o_reportData] = process_xml_file(a_filePathFileName)
%
% INPUT PARAMETERS :
%   a_filePathFileName : name of the XML decoding report to process
%
% OUTPUT PARAMETERS :
%   o_reportData : output stored information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportData] = process_xml_file(a_filePathFileName)

% default values
global g_decArgo_janFirst1950InMatlab;

% output parameters initialization
o_reportData = [];


if (exist(a_filePathFileName, 'file') == 2)

   % parse the XML data into a Matlab structure
   dataStruct = parse_xml_2_struct(a_filePathFileName);
   if (isempty(dataStruct))
      fprintf('ERROR: Unable to parse file: %s\n', a_filePathFileName);
      return
   end

   % retrieve data from the Matlab structure
   data = read_data_struct(dataStruct);

   if (strcmp(data.status, 'ok') && isfield(data, 'float_1'))

      % store useful information
      reportData = [];
      reportData.wmo = '';
      reportData.nb_rep = 0;
      reportData.date = '';
      reportData.durationStr = '';
      reportData.decoder_version = '';
      reportData.nb_cycles = -1;
      reportData.nb_input_file = 0;
      reportData.nb_meta = 0;
      reportData.nb_meta_aux = 0;
      reportData.nb_mono_prof = 0;
      reportData.nb_mono_prof_aux = 0;
      reportData.nb_traj = 0;
      reportData.nb_traj_aux = 0;
      reportData.nb_tech = 0;
      reportData.nb_tech_aux = 0;
      reportData.rep_file = '';
      reportData.duration = -1;
      reportData.diff_duration = -1;
      reportData.nb_stat = 0;
      reportData.mean = -1;
      reportData.std = -1;
      reportData.median = -1;
      reportData.diff_median = -1;

      reportData.wmo = str2double(data.param_floatwmo{:});
      reportData.date = datenum(data.date{:}, 'dd/mm/yyyy HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
      durationStr = data.duration{:};
      idF = strfind(durationStr, ':');
      duration = str2double(durationStr(1:idF(1)-1))*3600 + str2double(durationStr(idF(1)+1:idF(2)-1))*60 + str2double(durationStr(idF(2)+1:end));
      reportData.durationStr = durationStr;
      reportData.duration = duration;
      reportData.decoder_version = data.decoder_version{:};
      reportData.nb_cycles = str2double(data.float_1.nb_cycles{:});

      if (isfield(data.float_1, 'input_file'))
         reportData.nb_input_file = length(data.float_1.input_file);
      end
      %       if (isfield(data.float_1, 'output_meta_file'))
      %          reportData.nb_meta = length(data.float_1.output_meta_file);
      %       end
      %       if (isfield(data.float_1, 'output_meta_aux_file'))
      %          reportData.nb_meta_aux = length(data.float_1.output_meta_aux_file);
      %       end
      if (isfield(data.float_1, 'output_mono_profile_file'))
         nb = 0;
         for idF = 1:length(data.float_1.output_mono_profile_file)
            [~, name, ~] = fileparts(data.float_1.output_mono_profile_file{idF});
            if (name(1) == 'R')
               nb = nb + 1;
            end
         end
         reportData.nb_mono_prof = nb;
      end
      %       if (isfield(data.float_1, 'output_mono_profile_aux_file'))
      %          reportData.nb_mono_prof_aux = length(data.float_1.output_mono_profile_aux_file);
      %       end
      %       if (isfield(data.float_1, 'output_trajectory_file'))
      %          reportData.nb_traj = length(data.float_1.output_trajectory_file);
      %       end
      %       if (isfield(data.float_1, 'output_trajectory_aux_file'))
      %          reportData.nb_traj_aux = length(data.float_1.output_trajectory_aux_file);
      %       end
      %       if (isfield(data.float_1, 'output_technical_file'))
      %          reportData.nb_tech = length(data.float_1.output_technical_file);
      %       end
      %       if (isfield(data.float_1, 'output_technical_aux_file'))
      %          reportData.nb_tech_aux = length(data.float_1.output_technical_aux_file);
      %       end

      [~, name, ext] = fileparts(a_filePathFileName);
      reportData.rep_file = [name ext];

      o_reportData = reportData;
   end
end

return

% ------------------------------------------------------------------------------
% Read XML decoding report information from a Matlab structure.
%
% SYNTAX :
%  [o_data] = read_data_struct(a_dataStruct)
%
% INPUT PARAMETERS :
%   a_dataStruct : Matlab structure of XML decoding report information
%
% OUTPUT PARAMETERS :
%   o_data : XML decoding report information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = read_data_struct(a_dataStruct)

% output parameters initialization
o_data = [];

% fill the info structure
[infoStruct, ~] = read_child(a_dataStruct.Children, [], '');

o_data = infoStruct;

return

% ------------------------------------------------------------------------------
% Recursively read the XML decoding report information Matlab structure.
%
% SYNTAX :
%  [o_dataStruct, o_path] = read_child(a_children, a_dataStruct, a_path)
%
% INPUT PARAMETERS :
%   a_children   : current children of the structure
%   a_dataStruct : input Matlab structure of XML decoding report information
%   a_path       : input path to structure field
%
% OUTPUT PARAMETERS :
%   o_dataStruct : output Matlab structure of XML decoding report information
%   o_path       : output path to structure field
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct, o_path] = read_child(a_children, a_dataStruct, a_path)

% output parameters initialization
o_dataStruct = a_dataStruct;
o_path = a_path;

unusedList = [ ...
   {'function'} ...
   {'comment'} ...
   {'param_xmlreport'} ...
   {'param_rsynclog'} ...
   {'float_wmo'} ...
   {'cycle_list'} ...
   {'decoding_info'} ...
   {'decoding_warning'} ...
   {'decoding_error'} ...
   ];
ignoreList = [ ...
   {char([10 32 32 32])} ...
   {char([10 32 32 32 32 32 32])} ...
   {char(10)} ...
   ];
for idChild = 1:length(a_children)
   childData = a_children(idChild);
   if (any(strcmp(childData.Name, unusedList)))
      continue
   end
   if (strcmp(childData.Name, 'output_mono-profile_file'))
      childData.Name = 'output_mono_profile_file';
   end
   if (strcmp(childData.Name, 'output_mono-profile_aux_file'))
      childData.Name = 'output_mono_profile_aux_file';
   end
   if (strcmp(childData.Name, '#text'))
      if (~any(strcmp(childData.Data, ignoreList)))
         if (~is_field_recursive(o_dataStruct, o_path(2:end)))
            eval(['o_dataStruct' o_path ' = '''';']);
         end
         eval(['o_dataStruct' o_path '{end+1} = childData.Data;']);
      end
   else
      pathTmp = o_path;
      o_path = [o_path '.' childData.Name];
      [o_dataStruct, o_path] = read_child(childData.Children, o_dataStruct, o_path);
      o_path = pathTmp;
   end
end

return

% ------------------------------------------------------------------------------
% Recursively check fields in a structure.
%
% SYNTAX :
%  [o_bool] = is_field_recursive(a_struct, a_fields)
%
% INPUT PARAMETERS :
%   a_struct : structure to check
%   a_fields : fields to check
%
% OUTPUT PARAMETERS :
%   o_bool : 1 if final field exists, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bool] = is_field_recursive(a_struct, a_fields)

% output data initialization
o_bool = 1;


idP = strfind(a_fields, '.');
start = 1;
subPath = [];
for id = 1:length(idP)+1
   if (id == length(idP)+1)
      curField = a_fields(start:end);
   else
      curField = a_fields(start:idP(id)-1);
   end
   if (isempty(subPath))
      if (~isfield(a_struct, curField))
         o_bool = 0;
         break
      end
      subPath = curField;
   else
      if (~isfield(a_struct.(subPath), curField))
         o_bool = 0;
         break
      end
      subPath = [subPath '.' curField];
   end
   if (id < length(idP)+1)
      start = idP(id)+1;
   end
end

return
