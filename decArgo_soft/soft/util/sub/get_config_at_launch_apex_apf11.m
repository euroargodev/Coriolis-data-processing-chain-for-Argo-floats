% ------------------------------------------------------------------------------
% Retrieve configuration information from mission.cfg, system.cfg, sensors.cfg
% and sample.cfg files managed by Apex APF11 floats.
%
% SYNTAX :
%  [o_missionConfData, o_systemConfData, ...
%    o_sensorsConfData, o_sampleConfData] = get_config_at_launch_apex_apf11( ...
%    a_configDirName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_configDirName : directory name of the configuration files
%   a_floatNum      : float WMO number
%
% OUTPUT PARAMETERS :
%   o_missionConfData : retrieved mission.cfg file configuration information
%   o_systemConfData  : retrieved system.cfg file configuration information
%   o_sensorsConfData : retrieved sensors.cfg file configuration information
%   o_sampleConfData  : retrieved sample.cfg file configuration information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_missionConfData, o_systemConfData, ...
   o_sensorsConfData, o_sampleConfData] = get_config_at_launch_apex_apf11( ...
   a_configDirName, a_floatNum)

% output parameters initialization
o_missionConfData = [];
o_systemConfData = [];
o_sensorsConfData = [];
o_sampleConfData = [];


% mission.cfg file
missionFileName = [a_configDirName '/' num2str(a_floatNum) '_*_mission.cfg'];
files = dir(missionFileName);
if (length(files) == 1)
   missionFilePathName = [a_configDirName '/' files(1).name];
   o_missionConfData = parse_mission_system_file_apx_apf11(missionFilePathName);
   if (isfield(o_missionConfData, 'IceMonths') && ~isempty(o_missionConfData.IceMonths{:} ))
      o_missionConfData.IceMonths{:} = regexprep(o_missionConfData.IceMonths{:} , '0x', '');
      o_missionConfData.IceMonths{:}  = ['0x' o_missionConfData.IceMonths{:}];
   end
   if (isfield(o_missionConfData , 'VitalsMask') && ~isempty(o_missionConfData.VitalsMask{:} ))
      o_missionConfData.VitalsMask{:}  = regexprep(o_missionConfData.VitalsMask{:} , '0x', '');
      o_missionConfData.VitalsMask{:}  = ['0x' o_missionConfData.VitalsMask{:} ];
   end
elseif (isempty(files))
   fprintf('WARNING: mission.cfg file is missing for float %d in directory ''%s''\n', ...
      a_floatNum, a_configDirName);
elseif (length(files) > 1)
   fprintf('WARNING: %d mission.cfg files found for float %d in directory ''%s''\n', ...
      length(files), a_floatNum, a_configDirName);
end

% system.cfg file
systemFileName = [a_configDirName '/' num2str(a_floatNum) '_*_system.cfg'];
files = dir(systemFileName);
if (length(files) == 1)
   systemFilePathName = [a_configDirName '/' files(1).name];
   o_systemConfData = parse_mission_system_file_apx_apf11(systemFilePathName);
elseif (isempty(files))
   fprintf('WARNING: system.cfg file is missing for float %d in directory ''%s''\n', ...
      a_floatNum, a_configDirName);
elseif (length(files) > 1)
   fprintf('WARNING: %d system.cfg files found for float %d in directory ''%s''\n', ...
      length(files), a_floatNum, a_configDirName);
end

% sample.cfg file
sampleFileName = [a_configDirName '/' num2str(a_floatNum) '_*_sample.cfg'];
files = dir(sampleFileName);
if (length(files) == 1)
   sampleFilePathName = [a_configDirName '/' files(1).name];
   o_sampleConfData = parse_sample_file_apx_apf11(sampleFilePathName);
elseif (isempty(files))
   fprintf('WARNING: sample.cfg file is missing for float %d in directory ''%s''\n', ...
      a_floatNum, a_configDirName);
elseif (length(files) > 1)
   fprintf('WARNING: %d sample.cfg files found for float %d in directory ''%s''\n', ...
      length(files), a_floatNum, a_configDirName);
end

return

% ------------------------------------------------------------------------------
% Parse mission.cfg and system.cfg files contents.
%
% SYNTAX :
%  [o_confData] = parse_mission_system_file_apx_apf11(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : input file name
%
% OUTPUT PARAMETERS :
%   o_confData  : configuration information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confData] = parse_mission_system_file_apx_apf11(a_filePathName)

% output parameters initialization
o_confData = [];


fId = fopen(a_filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file: %s\n', a_filePathName);
   return
end

while (1)
   line = fgetl(fId);
   if (line == -1)
      break
   end
   line = deblank(line);
   if (any(line == '#'))
      idF = strfind(line, '#');
      line = line(1:idF(1)-1);
   end

   % empty line
   if (isempty(line))
      continue
   end
   
   info = textscan(line, '%s', 'delimiter', ' ');
   info = info{:};
   o_confData.(info{1}) = [];
   o_confData.(info{1}) = info(2:end)';
end

fclose(fId);

return

% ------------------------------------------------------------------------------
% Parse sample.cfg file contents.
%
% SYNTAX :
%  [o_confData] = parse_sample_file_apx_apf11(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : input file name
%
% OUTPUT PARAMETERS :
%   o_confData  : configuration information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confData] = parse_sample_file_apx_apf11(a_filePathName)

% output parameters initialization
o_confData = [];


fId = fopen(a_filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file: %s\n', a_filePathName);
   return
end

phase = '';
lineNum = 0;
while (1)
   line = fgetl(fId);
   if (line == -1)
      break
   end
   lineNum = lineNum + 1;
   line = strtrim(line);

   % empty line
   if (isempty(line))
      continue
   end
   
   if ((line(1) == '<') && (line(end) == '>'))
      
      phase = line(2:end-1);
      if (~isfield(o_confData, phase))
         o_confData.(phase) = [];
      end
      
   elseif (strncmpi(line, 'SAMPLE', length('SAMPLE')))
      
      sampType = 'SAMPLE';
      if (~isfield(o_confData.(phase), sampType))
         o_confData.(phase).(sampType) = [];
      end
      
      % default values
      start = 2500;
      stop = 0;
      interval = 0;
      units = 1; % 1: DBAR, 2:SEC
      count = 1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'SAMPLE'))
         fprintf('ERROR: Inconsistent data line #%d of file: %s\n', lineNum, a_filePathName);
         return
      end
      
      idF = find(strcmp('DBAR', info), 1);
      if (~isempty(idF))
         units = 1;
         info(idF) = [];
      end
      idF = find(strcmp('SEC', info), 1);
      if (~isempty(idF))
         units = 2;
         info(idF) = [];
      end
      
      sensor = info{2};
      if (~isfield(o_confData.(phase).(sampType), sensor))
         o_confData.(phase).(sampType).(sensor) = [];
      end
      
      if (length(info) >= 3)
         start = str2num(info{3});
      end
      if (length(info) >= 4)
         stop = str2num(info{4});
      end
      if (length(info) >= 5)
         interval = str2num(info{5});
      end
      if (length(info) >= 6)
         count = str2num(info{6});
      end
      
      o_confData.(phase).(sampType).(sensor) = [o_confData.(phase).(sampType).(sensor); ...
         start stop interval units count];
      
   elseif (strncmpi(line, 'PROFILE', length('PROFILE')))
      
      sampType = 'PROFILE';
      if (~isfield(o_confData.(phase), sampType))
         o_confData.(phase).(sampType) = [];
      end
      
      % default values
      start = 2000;
      stop = 0;
      bin_size = 2;
      rate = 1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'PROFILE'))
         fprintf('ERROR: Inconsistent data line #%d of file: %s\n', lineNum, a_filePathName);
         return
      end
            
      sensor = info{2};
      if (strcmp(sensor, 'PTSH'))
         sensor = 'PH';
         bin_size = 1;
         rate = -1;
      end
      if (~isfield(o_confData.(phase).(sampType), sensor))
         o_confData.(phase).(sampType).(sensor) = [];
      end
      
      if (length(info) >= 3)
         start = str2num(info{3});
      end
      if (length(info) >= 4)
         stop = str2num(info{4});
      end
      if (length(info) >= 5)
         bin_size = str2num(info{5});
      end
      if (length(info) >= 6)
         rate = str2num(info{6});
      end
      
      o_confData.(phase).(sampType).(sensor) = [o_confData.(phase).(sampType).(sensor); ...
         start stop bin_size rate];
      
   elseif (strncmpi(line, 'MEASURE', length('MEASURE')))
      
      sampType = 'MEASURE';
      if (~isfield(o_confData.(phase), sampType))
         o_confData.(phase).(sampType) = [];
      end
      
      % default values
      start = -1;
      stop = -1;
      interval = -1;
      count = -1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'MEASURE'))
         fprintf('ERROR: Inconsistent data line #%d of file: %s\n', lineNum, a_filePathName);
         return
      end
            
      sensor = info{2};
      if (~isfield(o_confData.(phase).(sampType), sensor))
         o_confData.(phase).(sampType).(sensor) = [];
      end
            
      o_confData.(phase).(sampType).(sensor) = [o_confData.(phase).(sampType).(sensor); ...
         start stop interval count];
      
   elseif (strncmpi(line, 'LISTEN', length('LISTEN')))
      
      sampType = 'LISTEN';
      if (~isfield(o_confData.(phase), sampType))
         o_confData.(phase).(sampType) = [];
      end
      
      % default values
      startDayTime = 0;
      duration = 120;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'LISTEN'))
         fprintf('ERROR: Inconsistent data line #%d of file: %s\n', lineNum, a_filePathName);
         return
      end
            
      sensor = info{2};
      if (~isfield(o_confData.(phase).(sampType), sensor))
         o_confData.(phase).(sampType).(sensor) = [];
      end
            
      if (length(info) >= 3)
         startDayTime = str2num(info{3});
      end
      if (length(info) >= 4)
         duration = str2num(info{4});
      end
      
      o_confData.(phase).(sampType).(sensor) = [o_confData.(phase).(sampType).(sensor); ...
         startDayTime duration];
      
   elseif (strncmpi(line, 'POWER', length('POWER')))
      
      sampType = 'POWER';
      if (~isfield(o_confData.(phase), sampType))
         o_confData.(phase).(sampType) = [];
      end
      
      % default values
      start = -1;
      stop = -1;
      
      info = textscan(line, '%s');
      info = info{:};
      
      if (~strcmpi(info{1}, 'POWER'))
         fprintf('ERROR: Inconsistent data line #%d of file: %s\n', lineNum, a_filePathName);
         return
      end
            
      sensor = info{2};
      if (~isfield(o_confData.(phase).(sampType), sensor))
         o_confData.(phase).(sampType).(sensor) = [];
      end
            
      if (length(info) >= 3)
         start = str2num(info{3});
      end
      if (length(info) >= 4)
         stop = str2num(info{4});
      end
      
      o_confData.(phase).(sampType).(sensor) = [o_confData.(phase).(sampType).(sensor); ...
         start stop];      

   else
      
      fprintf('ERROR: Not managed line #%d of file: %s\n', lineNum, a_filePathName);
      fclose(fId);
         
   end
end

fclose(fId);

return
