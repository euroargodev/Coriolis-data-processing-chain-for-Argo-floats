% ------------------------------------------------------------------------------
% Add error ellipses of Argos locations in Trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas] = add_argos_error_ellipses(a_floatArgosId, a_tabTrajNMeas)
%
% INPUT PARAMETERS :
%   a_floatArgosId : float PTT number
%   a_tabTrajNMeas : input trajectory N_MEASUREMENT measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas : output trajectory N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = add_argos_error_ellipses(a_floatArgosId, a_tabTrajNMeas)

% global measurement codes
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;

% Argos error ellipses input directories
global g_decArgo_dirInputErrorEllipsesMail;
global g_decArgo_dirInputErrorEllipsesWs;


% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;

% path to error llipses received by mail
mailErrorEllipsesDirectory = g_decArgo_dirInputErrorEllipsesMail;

% path to error ellipses collected by web service
webServiceErrorEllipsesDirectory = g_decArgo_dirInputErrorEllipsesWs;


fprintf('INFO: ARGOS ERROR ELLIPSES INSERTION: Start\n');
tic;

% retrieve error ellipses data
ellipsesDataStruct = get_argos_error_ellipses(a_floatArgosId, ...
   mailErrorEllipsesDirectory, ...
   webServiceErrorEllipsesDirectory ...
   );

% add error ellipses data in trajectories
for id = 1:length(o_tabTrajNMeas)
   if (o_tabTrajNMeas(id).outputCycleNumber >= 0)
      cycleFmt = [];
      idFmt = find([o_tabTrajNMeas(id).tabMeas.measCode] == g_MC_FMT);
      if (~isempty(idFmt))
         cycleFmt = o_tabTrajNMeas(id).tabMeas(idFmt).juld;
      end
      cycleLmt = [];
      idLmt = find([o_tabTrajNMeas(id).tabMeas.measCode] == g_MC_LMT);
      if (~isempty(idLmt))
         cycleLmt = o_tabTrajNMeas(id).tabMeas(idLmt).juld;
      end
      idFix = find([o_tabTrajNMeas(id).tabMeas.measCode] == g_MC_Surface);
      o_tabTrajNMeas(id).tabMeas(idFix) = ...
         update_traj_data(o_tabTrajNMeas(id).tabMeas(idFix), ...
         cycleFmt, cycleLmt, o_tabTrajNMeas(id).outputCycleNumber, ellipsesDataStruct);
   end
end

ellapsedTime = toc;
fprintf('INFO: ARGOS ERROR ELLIPSES INSERTION: Elapsed time is %.1f seconds\n', ellapsedTime);

return

% ------------------------------------------------------------------------------
% Add error ellipses data in trajectory data
%
% SYNTAX :
%  [o_tabMeas] = update_traj_data(a_tabMeas, a_cycleFmt, a_cycleLmt, a_cycleNumber, a_errData)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas : input trajectory N_MEASUREMENT measurement structures
%   a_cycleFmt     : cycle FMT
%   a_cycleLmt     : cycle LMT
%   a_cycleNumber  : cycle number
%   a_errData      : error ellipses data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas : output trajectory N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/26/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabMeas] = update_traj_data(a_tabMeas, a_cycleFmt, a_cycleLmt, a_cycleNumber, a_errData)

% output parameters initialization
o_tabMeas = a_tabMeas;

% current float WMO number
global g_decArgo_floatNum;

% global default values
global g_decArgo_minNonTransDurForNewCycle;


% look for concerned error ellipses data
idErr = find(([a_errData.fixDate] > min([a_cycleFmt [o_tabMeas.juld] a_cycleLmt]) - g_decArgo_minNonTransDurForNewCycle/24) & ...
   ([a_errData.fixDate] <= max([a_cycleFmt [o_tabMeas.juld] a_cycleLmt]) + g_decArgo_minNonTransDurForNewCycle/24));
if (~isempty(idErr))
   
   epochDateList = julian_2_epoch70([o_tabMeas.juld]);
   for idP = 1:length(idErr)
      idF = find((epochDateList == a_errData(idErr(idP)).fixDateEpoch) & ...
         (strcmp({o_tabMeas.satelliteName}, a_errData(idErr(idP)).satName(end)) == 1));
      if (~isempty(idF))
         if (length(idF) > 1)
            %             fprintf('ERROR: Float #%d: Cycle #%d: %d Argos fixes with the same date\n', ...
            %                g_decArgo_floatNum, a_cycleNumber, length(idF));
         else
            if ~((abs(o_tabMeas(idF).latitude - a_errData(idErr(idP)).fixLat) > 1e-2) || ...
                  (abs(o_tabMeas(idF).longitude - a_errData(idErr(idP)).fixLon) > 1e-2) || ...
                  (o_tabMeas(idF).posAccuracy ~= a_errData(idErr(idP)).fixClass))
               
               % update the Argos fix
               o_tabMeas(idF).posAxErrEllMajor = a_errData(idErr(idP)).fixEllMajorAxis;
               o_tabMeas(idF).posAxErrEllMinor = a_errData(idErr(idP)).fixEllMinorAxis;
               o_tabMeas(idF).posAxErrEllAngle = a_errData(idErr(idP)).fixEllAngle;
               
               %                fprintf('INFO: Float #%d: Cycle #%d: Argos fix updated with error ellipse data\n', ...
               %                   g_decArgo_floatNum, a_cycleNumber);
            else
               %                fprintf('ERROR: Float #%d: Cycle #%d: Argos error ellipse not set because fixes differ\n', ...
               %                   g_decArgo_floatNum, a_cycleNumber);
            end
         end
      else
         %          fprintf('ERROR: Float #%d: Cycle #%d: New Argos fix from error ellipses data\n', ...
         %             g_decArgo_floatNum, a_cycleNumber);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve Argos error ellipses from storage files.
%
% SYNTAX :
%  [o_ellipsesDataStruct] = get_argos_error_ellipses(a_floatArgosId, ...
%    a_mailErrorEllipsesDirectory, ...
%    a_webServiceErrorEllipsesDirectory)
%
% INPUT PARAMETERS :
%   a_floatArgosId                     : float PTT number
%   a_mailErrorEllipsesDirectory       : directory where error ellipses
%                                        received by mail are stored
%   a_webServiceErrorEllipsesDirectory : directory of error
%                                        ellipses collected by web service
%
% OUTPUT PARAMETERS :
%   o_ellipsesDataStruct : output structure of Argos error ellipses data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ellipsesDataStruct] = get_argos_error_ellipses(a_floatArgosId, ...
   a_mailErrorEllipsesDirectory, ...
   a_webServiceErrorEllipsesDirectory)

% output parameters initialization
o_ellipsesDataStruct = [];

% current float WMO number
global g_decArgo_floatNum;


% error ellipses received by mail
rawDataMail = [];
if (~isempty(a_mailErrorEllipsesDirectory))
   if (exist(a_mailErrorEllipsesDirectory, 'dir') == 7)
      rawDataMail = get_argos_error_ellipses_mail(a_floatArgosId, a_mailErrorEllipsesDirectory);
   else
      fprintf('ERROR: Float #%d: Directory of mail Argos error ellipses not found (%s)\n', ...
         g_decArgo_floatNum, a_mailErrorEllipsesDirectory);
   end
end

% error ellipses collected by WS
rawDataWs = [];
if (~isempty(a_webServiceErrorEllipsesDirectory))
   if (exist(a_webServiceErrorEllipsesDirectory, 'dir') == 7)
      rawDataWs = get_argos_error_ellipses_ws(a_floatArgosId, a_webServiceErrorEllipsesDirectory);
   else
      fprintf('ERROR: Float #%d: Directory of archive WS Argos error ellipses not found (%s)\n', ...
         g_decArgo_floatNum, a_webServiceErrorEllipsesDirectory);
   end
end

% clean WS data from duplicated lines - NOT NEEDED ANYMORE (DONE BY CORIOLIS)
% if (~isempty(rawDataWs))
%    idDel = [];
%    for id1 = 1:size(rawDataWs, 1)-1
%       if (any(idDel == id1))
%          continue
%       end
%       for id2 = id1+1:size(rawDataWs, 1)
%          if (any(idDel == id2))
%             continue
%          end
%          if (~any(strcmp(rawDataWs(id1, :), rawDataWs(id2, :)) ~= 1))
%             idDel = [idDel id2];
%          end
%       end
%    end
%    rawDataWs(idDel, :) = [];
% end

% process collected data
if (~isempty(rawDataMail) || ~isempty(rawDataWs))
   o_ellipsesDataStruct = process_error_ellipses_data(rawDataMail, rawDataWs);
end

return

% ------------------------------------------------------------------------------
% Convert and merge Argos error ellipses data.
%
% SYNTAX :
%  [o_ellipsesDataStruct] = process_error_ellipses_data(a_rawDataMail, a_rawDataWs)
%
% INPUT PARAMETERS :
%   a_rawDataMail : error ellipses data received by mail
%   a_rawDataWs   : error ellipses data collected by web service
%
% OUTPUT PARAMETERS :
%   o_ellipsesDataStruct : output structure of Argos error ellipses data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ellipsesDataStruct] = process_error_ellipses_data(a_rawDataMail, a_rawDataWs)

% output parameters initialization
o_ellipsesDataStruct = [];

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_janFirst1970InJulD;


% store data in dedicated structure
dataAll = [];
for idL = 1:size(a_rawDataMail, 1)
   
   data = a_rawDataMail(idL, :);
   dataStruct = get_error_ellipse_init_struct;
   
   dataStruct.satName = data{3};
   dataStruct.fixDate = datenum(data{4}, 'yyyy/mm/dd HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   dataStruct.fixLat = str2double(data{6});
   dataStruct.fixLon = str2double(data{7});
   dataStruct.fixClass = data{5};
   dataStruct.fixFreq = str2double(data{8});
   dataStruct.fixAlt = str2double(data{9});
   dataStruct.fixErrorRadius = str2double(data{10});
   dataStruct.fixEllMajorAxis = str2double(data{11});
   dataStruct.fixEllMinorAxis = str2double(data{12});
   dataStruct.fixEllAngle = str2double(data{13});
   dataStruct.fixDateEpoch = uint64(round((dataStruct.fixDate - g_decArgo_janFirst1970InJulD)*86400));

   dataAll = [dataAll dataStruct];
end
for idL = 1:size(a_rawDataWs, 1)
   
   data = a_rawDataWs(idL, :);
   dataStruct = get_error_ellipse_init_struct;
   
   dataStruct.satName = data{3};
   dataStruct.fixDate = datenum(data{4}, 'yyyy-mm-ddTHH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   dataStruct.fixLat = str2double(data{6});
   dataStruct.fixLon = str2double(data{7});
   dataStruct.fixClass = data{5};
   dataStruct.fixFreq = str2double(data{8});
   dataStruct.fixAlt = str2double(data{9});
   dataStruct.fixErrorRadius = str2double(data{10});
   dataStruct.fixEllMajorAxis = str2double(data{11});
   dataStruct.fixEllMinorAxis = str2double(data{12});
   dataStruct.fixEllAngle = str2double(data{13});
   dataStruct.fixDateEpoch = uint64(round((dataStruct.fixDate - g_decArgo_janFirst1970InJulD)*86400));

   dataAll = [dataAll dataStruct];
end

% clean duplicates (satName, fixDateEpoch)
uDateList = unique([dataAll.fixDateEpoch]);
idDel = [];
for idD = 1:length(uDateList)
   idF1 = find([dataAll.fixDateEpoch] == uDateList(idD));
   if (length(idF1) > 1)
      uSatList = unique({dataAll(idF1).satName});
      for idS = 1:length(uSatList)
         idF2 = find(strcmp({dataAll(idF1).satName}, uSatList{idS}) == 1);
         if (length(idF2) > 1)
            locErrRad = [dataAll(idF1(idF2)).fixErrorRadius];
            [~, idMin] = min(locErrRad);
            idDel = [idDel setdiff(idF1(idF2), idF1(idF2(idMin)))];
         end
      end
   end
end
dataAll(idDel) = [];

[~, idSort] = sort([dataAll.fixDateEpoch]);
o_ellipsesDataStruct = dataAll(idSort);

return

% ------------------------------------------------------------------------------
% Get the basic structure to store Argos error ellipse information.
%
% SYNTAX :
%  [o_errorEllipseStruct] = get_error_ellipse_init_struct(a_cycleNumber)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_gpsFixStruct : Argos error ellipse structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_errorEllipseStruct] = get_error_ellipse_init_struct

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% output parameters initialization
o_errorEllipseStruct = struct( ...
   'satName', '', ...
   'fixDate', g_decArgo_dateDef, ...
   'fixLat', g_decArgo_argosLatDef, ...
   'fixLon', g_decArgo_argosLonDef, ...
   'fixClass', '', ...
   'fixFreq', -1, ...
   'fixAlt', -1, ...
   'fixErrorRadius', -1, ...
   'fixEllMajorAxis', -1, ...
   'fixEllMinorAxis', -1, ...
   'fixEllAngle', -1, ...
   'fixDateEpoch', -1 ...
   );

return

% ------------------------------------------------------------------------------
% Retrieve WS Argos error ellipses from collected data.
%
% SYNTAX :
%  [o_data] = get_argos_error_ellipses_ws(a_floatArgosId, a_inputDir)
%
% INPUT PARAMETERS :
%   a_floatArgosId : float PTT number
%   a_inputDir     : directory where error ellipses collected by web service
%                    are stored
%
% OUTPUT PARAMETERS :
%   o_data : output data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = get_argos_error_ellipses_ws(a_floatArgosId, a_inputDir)

% output parameters initialization
o_data = [];

% current float WMO number
global g_decArgo_floatNum;


floatArgosIdStr = num2str(sprintf('%06d', a_floatArgosId));
dataDirPathName = [a_inputDir '/' floatArgosIdStr];
if (exist(dataDirPathName, 'dir') == 7)
   dataFilePathName = [dataDirPathName '/' floatArgosIdStr '_error_ellipses.csv'];
   if (exist(dataFilePathName, 'file') == 2)
      o_data = read_argos_error_ellipses_ws_file(dataFilePathName);
   else
      fprintf('WARNING: Float #%d: Empty directory of WS Argos error ellipses (%s)\n', ...
         g_decArgo_floatNum, dataDirPathName);
   end
end

return

% ------------------------------------------------------------------------------
% Read WS file of Argos error ellipses and retrieve useful data.
%
% SYNTAX :
%  [o_data] = read_argos_error_ellipses_ws_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : WS file of Argos error ellipses
%
% OUTPUT PARAMETERS :
%   o_data : output data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = read_argos_error_ellipses_ws_file(a_filePathName)

% output parameters initialization
o_data = [];

% current float WMO number
global g_decArgo_floatNum;


% patterns used to parse the mail contents
CSV_HEADER = 'programNumber;platformId;platformType;platformModel;platformName;satellite;bestMsgDate;duration;nbMessage;message120;bestLevel;frequency;locationDate;latitude;longitude;altitude;locationClass;gpsSpeed;gpsHeading;index;nopc;errorRadius;semiMajor;semiMinor;orientation;hdop';


if ~(exist(a_filePathName, 'file') == 2)
   fprintf('ERROR: Float #%d: File not found: %s\n', ...
      g_decArgo_floatNum, a_filePathName);
   return
end

fId = fopen(a_filePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Float #%d: Unable to open file: %s\n', ...
      g_decArgo_floatNum, a_filePathName);
   return
end

lineNum = 0;
startRecording = 0;
while 1
   line = fgetl(fId);
   if (line == -1)
      break
   end
   lineNum = lineNum + 1;
   
   if (isempty(line))
      continue
   end
   
   if (any(strfind(line, CSV_HEADER(1:14))))
      if (any(strfind(line, CSV_HEADER)))
         startRecording = 1;
         continue
      else
         fprintf('ERROR: Not managed header in line #%d: %s\n', lineNum, line);
      end
   end
   
   if (startRecording)
      data = textscan(line, '%s', 'delimiter', ';');
      data = data{:};
      if (length(data) >= 25)
         if (~isempty(data{13}))
            o_data = [o_data; data([1 2 6 13 17 14 15 12 16 22:25])'];
         end
      else
         fprintf('ERROR: Anomaly in line #%d: %s\n', lineNum, line);
      end
   end

end

fclose(fId);

return

% ------------------------------------------------------------------------------
% Retrieve mail Argos error ellipses from storage files.
%
% SYNTAX :
%  [o_data] = get_argos_error_ellipses_mail(a_floatArgosId, a_inputDir)
%
% INPUT PARAMETERS :
%   a_floatArgosId : float PTT number
%   a_inputDir     : directory where error ellipses received by mail are stored
%
% OUTPUT PARAMETERS :
%   o_data : output data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_data] = get_argos_error_ellipses_mail(a_floatArgosId, a_inputDir)

% output parameters initialization
o_data = [];

% current float WMO number
global g_decArgo_floatNum;


floatArgosIdStr = num2str(sprintf('%06d', a_floatArgosId));
dataDirPathName = [a_inputDir '/' floatArgosIdStr];
if (exist(dataDirPathName, 'dir') == 7)
   dataFilePathName = [dataDirPathName '/' floatArgosIdStr '_error_ellipses.csv'];
   if (exist(dataFilePathName, 'file') == 2)
      o_data = read_argos_error_ellipses_csv_file(dataFilePathName);
   else
      fprintf('WARNING: Float #%d: Empty directory of mail Argos error ellipses (%s)\n', ...
         g_decArgo_floatNum, dataDirPathName);
   end
end

return

% ------------------------------------------------------------------------------
% Read CSV file of Argos error ellipses received by mail.
%
% SYNTAX :
%  [a_data] = read_argos_error_ellipses_csv_file(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : name of output file
%
% OUTPUT PARAMETERS :
%   o_data : processed data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [a_data] = read_argos_error_ellipses_csv_file(a_filePathName)

% output parameters initialization
a_data = [];


fidOut = fopen(a_filePathName, 'r');
if (fidOut == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_filePathName);
   return
end

a_data = textscan(fidOut, '%s', 'delimiter', ';');

fclose(fidOut);

a_data = a_data{:};
a_data = reshape(a_data, 13, size(a_data, 1)/13)';
a_data(1, :) = [];

return
