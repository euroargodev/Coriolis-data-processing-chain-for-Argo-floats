% ------------------------------------------------------------------------------
% Read Iridium SBD mail file and extract Iridium information and SBD attachment.
%
% SYNTAX :
%  extract_sbd_mail_attachment('300234064806200_3901645', '300534065560640')
%
% INPUT PARAMETERS :
%   varargin : name of directories to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/14/2025 - RNU - creation
% ------------------------------------------------------------------------------
function extract_sbd_mail_attachment(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% to directory of input data directory
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\CTS3';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\IN\TEST\IN';

% to directory of output data directory
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\TMP';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin == 0)
   % process all directors of input top directory
   dirList = dir(INPUT_DIR_NAME);
   dirList = dirList([dirList.isdir] == 1);
   dirList = dirList(~strcmp({dirList.name}, '.'));
   dirList = dirList(~strcmp({dirList.name}, '..'));
   dirList = {dirList.name};
else
   % directories to process come from input parameters
   dirList = varargin;
end

% create output directory
if ~(exist(OUTPUT_DIR_NAME, 'dir') == 7)
   mkdir(OUTPUT_DIR_NAME);
end

currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% create and start log file recording
logFile = [DIR_LOG_FILE '\' 'extract_sbd_mail_attachment_' currentTime '.log'];
diary(logFile);
tic;

% create output CSV file
csvFilepathName = [DIR_CSV_FILE '\' 'extract_sbd_mail_attachment_' currentTime '.csv'];
fId = fopen(csvFilepathName, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while creating file : %s\n', csvFilepathName);
   return
end

header = '#;Directory;File;Time;Latitude;Longitude;CEP radius;Attachment flag; Attachment size';
fprintf(fId, '%s\n', header);

% process input directories
fileCpt = 1;
for idDir = 1:length(dirList)
   inputDirName = [INPUT_DIR_NAME '\' dirList{idDir} '\'];
   outputDirName = [OUTPUT_DIR_NAME '\' dirList{idDir} '_SBD\'];

   mailFileList = dir([inputDirName '*.*']);
   mailFileList = mailFileList([mailFileList.isdir] == 0);
   mailFileList = mailFileList(~strcmp({mailFileList.name}, '.'));
   mailFileList = mailFileList(~strcmp({mailFileList.name}, '..'));
   mailFileList = {mailFileList.name};

   if (isempty(mailFileList))
      % for IRIDIUM_DATA directory
      inputDirName = [INPUT_DIR_NAME '\' dirList{idDir} '\archive\'];

      mailFileList = dir([inputDirName '*.*']);
      mailFileList = mailFileList([mailFileList.isdir] == 0);
      mailFileList = mailFileList(~strcmp({mailFileList.name}, '.'));
      mailFileList = mailFileList(~strcmp({mailFileList.name}, '..'));
      mailFileList = {mailFileList.name};
   end

   fprintf('%03d/%03d Processing directory %s (%d mail files)\n', ...
      idDir, length(dirList), dirList{idDir}, length(mailFileList));

   % create output directory
   if (exist(outputDirName, 'dir') == 7)
      rmdir(outputDirName, 's');
   end
   mkdir(outputDirName);

   % process mail files
   for idFile = 1:length(mailFileList)

      fprintf('   %03d/%03d Processing file %s\n', ...
         idFile, length(mailFileList), mailFileList{idFile});

      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         mailFileList{idFile}, inputDirName, outputDirName);

      if (~isempty(mailContents))
         fprintf(fId, '%d;%s;%s; %s;%.3f;%.3f;%d;%d;%d\n', ...
            fileCpt, ...
            dirList{idDir}, ...
            mailContents.mailFileName, ...
            julian_2_gregorian_dec_argo(mailContents.timeOfSessionJuld), ...
            mailContents.unitLocationLat, ...
            mailContents.unitLocationLon, ...
            mailContents.cepRadius, ...
            mailContents.attachementFileFlag, ...
            mailContents.messageSize);
      end
   end
end

fclose(fId);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Read and store the Iridium e-mail contents and extract the attachement if any.
%
% SYNTAX :
%  [o_mailContents, o_attachmentFound] = read_mail_and_extract_attachment( ...
%    a_fileName, a_inputDirName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_fileName      : e-mail file name
%   a_inputDirName  : name of input e-mail file directory
%   a_outputDirName : name of output SBD file directory
%
% OUTPUT PARAMETERS :
%   o_mailContents    : e-mail contents
%   o_attachmentFound : attachement exists flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mailContents, o_attachmentFound] = read_mail_and_extract_attachment( ...
   a_fileName, a_inputDirName, a_outputDirName)

% output parameters initialization
o_mailContents = '';
o_attachmentFound = 0;


% patterns used to parse the mail contents
TIME_OF_SESSION = 'Time of Session (UTC):';
MESSAGE_SIZE = 'Message Size (bytes):';
UNIT_LOCATION = 'Unit Location:';
CEP_RADIUS = 'CEPradius =';

% in Arvor 5.45 data received from Massimo Pacciaroni <float.ogs@gmail.com>
% boundary definition is provided without '"'
BOUNDARY = 'boundary="';
BOUNDARY2 = 'boundary=';
% 01/19/2016: in co_20151217T000434Z_300234060350130_001113_000000_6279.txt,
% 001114, 001115, 001116 and 001117 attachment file name is provided without '"'
% (Ex: filename=300234060350130_001113.sbd;)
% SBD_FILE_NAME = 'filename="';
SBD_FILE_NAME = 'filename=';
BOUNDARY_END = '----------';

% mail file path name to process
mailFilePathName = [a_inputDirName '/' a_fileName];

if ~(exist(mailFilePathName, 'file') == 2)
   fprintf('ERROR: Mail file not found: %s\n', mailFilePathName);
   return
end

fId = fopen(mailFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', mailFilePathName);
   return
end

% create a structure to store the data
[o_mailContents, mailContents] = get_iridium_mail_init_struct(a_fileName);

lineNum = 0;
timeOfSessionDone = 0;
messageSizeDone = 0;
unitLocationDone = 0;
cepRadiusDone = 0;

boundaryDone = 0;
boundaryCode = [];
boundaryStart = 0;
attachementFileDone = 0;
sbdDataStart = 0;
sbdData = [];

while 1
   line = fgetl(fId);
   if (line == -1)
      break
   end
   lineNum = lineNum + 1;

   % collect information
   if (~isempty(strfind(line, BOUNDARY))) % BOUNDARY may appear twice, use the last occurence
      idPos = strfind(line, BOUNDARY);
      boundaryCode = strtrim(line(idPos+length(BOUNDARY):end-1));
      boundaryCode = regexprep(boundaryCode, '-', '');
      boundaryDone = 1;
   end
   %       if (boundaryDone == 0) % use the first boundary only
   %          if (~isempty(strfind(line, BOUNDARY)))
   %             idPos = strfind(line, BOUNDARY);
   %             boundaryCode = strtrim(line(idPos+length(BOUNDARY):end-1));
   %             boundaryCode = regexprep(boundaryCode, '-', '');
   %             boundaryDone = 1;
   %          end
   %       end
   if (~isempty(strfind(line, BOUNDARY2)) && (boundaryDone == 0)) % use BOUNDARY if present otherwise BOUNDARY2
      idPos = strfind(line, BOUNDARY2);
      boundaryCode = strtrim(line(idPos+length(BOUNDARY2):end));
      boundaryDone = 1;
   end
   if (timeOfSessionDone == 0)
      if (strncmp(line, TIME_OF_SESSION, length(TIME_OF_SESSION)))
         mailContents.timeOfSession = strtrim(line(length(TIME_OF_SESSION)+1:end));
         timeOfSessionDone = 1;
      end
   end
   if (messageSizeDone == 0)
      if (strncmp(line, MESSAGE_SIZE, length(MESSAGE_SIZE)))
         [messageSize, status] = str2num(strtrim(line(length(MESSAGE_SIZE)+1:end)));
         if (status == 1)
            o_mailContents.messageSize = messageSize;
            messageSizeDone = 1;
         end
      end
   end
   if (unitLocationDone == 0)
      if (strncmp(line, UNIT_LOCATION, length(UNIT_LOCATION)))
         mailContents.unitLocation = strtrim(line(length(UNIT_LOCATION)+1:end));
         unitLocationDone = 1;
      end
   end
   if (cepRadiusDone == 0)
      if (strncmp(line, CEP_RADIUS, length(CEP_RADIUS)))
         [cepRadius, status] = str2num(strtrim(line(length(CEP_RADIUS)+1:end)));
         if (status == 1)
            o_mailContents.cepRadius = cepRadius;
            cepRadiusDone = 1;
         end
      end
   end

   if ((messageSizeDone == 1) && (boundaryDone == 1))
      if (boundaryStart == 0)
         if (~isempty(strfind(line, boundaryCode)))
            boundaryStart = 1;
         end
      else
         if (attachementFileDone == 0)
            if (~isempty(strfind(line, SBD_FILE_NAME)))
               idPos = strfind(line, SBD_FILE_NAME);
               attachementFileName = strtrim(line(idPos+length(SBD_FILE_NAME):end));
               attachementFileName = regexprep(attachementFileName, '"', '');
               idPos2 = strfind(attachementFileName, '.sbd');
               if (~isempty(idPos2))
                  mailContents.attachementFileName = attachementFileName(1:idPos2+length('.sbd')-1);
                  attachementFileDone = 1;
               else
                  fprintf('ERROR: Inconsistent attachement file name in mail file: %s - attachement ignored\n', a_fileName);
               end
            end
         else
            if (sbdDataStart == 0)
               if (isempty(strtrim(line)))
                  sbdDataStart = 1;
               end
            else
               if (~isempty(strfind(line, boundaryCode)))
                  boundaryStart = 0;
               elseif (strncmp(line, BOUNDARY_END, length(BOUNDARY_END)))
                  boundaryStart = 0;
               else
                  sbdData = [sbdData line];
               end
            end
         end
      end
   end
end

fclose(fId);

% convert time of session in Julian days
if (~isempty(mailContents.timeOfSession))
   o_mailContents.timeOfSessionJuld = datenum(mailContents.timeOfSession(4:end), 'mmm  dd HH:MM:SS yyyy') - datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
end

% parse unit location data
if (~isempty(mailContents.unitLocation))
   posLat = strfind(mailContents.unitLocation, 'Lat =');
   posLon = strfind(mailContents.unitLocation, 'Long =');
   if (isempty(posLat) || isempty(posLon))
      fprintf('ERROR: Unable to parse unit location in file: %s\n', a_fileName);
   else
      o_mailContents.unitLocationLat = str2num(mailContents.unitLocation(posLat+length('Lat ='):posLon-1));
      o_mailContents.unitLocationLon = str2num(mailContents.unitLocation(posLon+length('Long ='):end));
      if ((~isempty(o_mailContents.unitLocationLat) && isnan(o_mailContents.unitLocationLat)) || ...
            (~isempty(o_mailContents.unitLocationLon) && isnan(o_mailContents.unitLocationLon)))
         % see co_20240109T200543Z_300534060901620_000000_000000_30480.txt
         o_mailContents.cepRadius = 0; % to ignore the Iridium location
      end
   end
end

% decode and store attachment contents
if (~isempty(sbdData))
   if (~isempty(a_outputDirName))
      if (~isempty(strfind(a_fileName, mailContents.attachementFileName(1:end-4))))
         sbdPathFileName = [a_outputDirName '/' a_fileName(1:end-4) '.sbd'];
         [decodedSbdData] = base64decode(sbdData, sbdPathFileName, 'matlab');
         info = whos('decodedSbdData');
         if (info.bytes ~= o_mailContents.messageSize)
            fprintf('ERROR: Inconsistent attachement size (%d bytes while expecting %d bytes) for mail file: %s\n', ...
               info.bytes, o_mailContents.messageSize, a_fileName);
         end
         o_attachmentFound = 1;
      else
         fprintf('ERROR: Inconsistent attachement file name for mail file: %s - attachement ignored\n', a_fileName);
      end
   end
elseif (o_mailContents.messageSize > 0)
   fprintf('ERROR: Attachement not retrieved for mail file: %s - attachement ignored\n', a_fileName);
end

return

% ------------------------------------------------------------------------------
% Get the basic structure to store Iridium e-mail contents.
%
% SYNTAX :
%  [o_iridiumMail, o_iridiumMailAllBis] = get_iridium_mail_init_struct(a_mailFileName)
%
% INPUT PARAMETERS :
%   a_mailFileName : e-mail file name
%
% OUTPUT PARAMETERS :
%   o_iridiumMail       : e-mail contents (stored)
%   o_iridiumMailAllBis : e-mail contents (not stored)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iridiumMail, o_iridiumMailAllBis] = get_iridium_mail_init_struct(a_mailFileName)

% output parameters initialization
o_iridiumMail = struct( ...
   'mailFileName', a_mailFileName, ...
   'timeOfSessionJuld', nan, ...
   'messageSize', '', ...
   'unitLocationLat', '', ...
   'unitLocationLon', '', ...
   'cepRadius', 0, ... % initialized to 0 (so that the Iridium location is not considered if not present in the mail; Ex: co_20190527T062249Z_300234065420780_000939_000000_10565.txt)
   'attachementFileFlag', 0, ...
   'cycleNumber', -1, ...
   'floatCycleNumber', -1, ...
   'floatProfileNumber', -1, ...
   'locInTrajFlag', 0 ... % in EOL, to process only new incoming locations
   );

o_iridiumMailAllBis = struct( ...
   'timeOfSession', '', ...
   'unitLocation', '', ...
   'attachementFileName', '' ...
   );

return

% ------------------------------------------------------------------------------
% Convert a julian 1950 date to a gregorian date.
%
% SYNTAX :
%   [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)

% output parameters initialization
o_gregorianDate = repmat('9999/99/99 99:99:99', length(a_julDay), 1);

idOk = find(~isnan(a_julDay));
[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(a_julDay(idOk));

for idDate = 1:length(dayNum)
   o_gregorianDate(idOk(idDate), :) = sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
      yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate));
end

return

% ------------------------------------------------------------------------------
% Split of a julian 1950 date in gregorian date parts.
%
% SYNTAX :
%   [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld_dec_argo(a_juld)
%
% INPUT PARAMETERS :
%   a_juld : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_dayNum : julian 1950 day number
%   o_day    : gregorian day
%   o_month  : gregorian month
%   o_year   : gregorian year
%   o_hour   : gregorian hour
%   o_min    : gregorian minute
%   o_sec    : gregorian second
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld_dec_argo(a_juld)

% output parameters initialization
o_dayNum = [];
o_day = [];
o_month = [];
o_year = [];
o_hour = [];
o_min = [];
o_sec = [];

for id = 1:length(a_juld)

   juldStr = num2str(a_juld(id), 11);
   res = sscanf(juldStr, '%5d.%6d');
   o_day(id) = res(1);

   o_dayNum(id) = fix(a_juld(id));

   dateNum = o_day(id) + datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
   ymd = datestr(dateNum, 'yyyy/mm/dd');
   res = sscanf(ymd, '%4d/%2d/%d');
   o_year(id) = res(1);
   o_month(id) = res(2);
   o_day(id) = res(3);

   hms = datestr(a_juld(id), 'HH:MM:SS');
   res = sscanf(hms, '%d:%d:%d');
   o_hour(id) = res(1);
   o_min(id) = res(2);
   o_sec(id) = res(3);

end

return

% ------------------------------------------------------------------------------
function y = base64decode(x, outfname, alg)
%BASE64DECODE Perform base64 decoding on a string.
%
% INPUT:
%   x    - block of data to be decoded.  Can be a string or a numeric
%          vector containing integers in the range 0-255. Any character
%          not part of the 65-character base64 subset set is silently
%          ignored.  Characters occuring after a '=' padding character are
%          never decoded. If the length of the string to decode (after
%          ignoring non-base64 chars) is not a multiple of 4, then a
%          warning is generated.
%
%   outfname - if provided the binary date from decoded string will be
%          saved into a file. Since Base64 coding is often used to embbed
%          binary data in xml files, this option can be used to extract and
%          save them.
%
%   alg  - Algorithm to use: can take values 'java' or 'matlab'. Optional
%          variable defaulting to 'java' which is a little faster. If
%          'java' is chosen than core of the code is performed by a call to
%          a java library. Optionally all operations can be performed using
%          matleb code.
%
% OUTPUT:
%   y    - array of binary data returned as uint8
%
%   This function is used to decode strings from the Base64 encoding specified
%   in RFC 2045 - MIME (Multipurpose Internet Mail Extensions).  The Base64
%   encoding is designed to represent arbitrary sequences of octets in a form
%   that need not be humanly readable.  A 65-character subset ([A-Za-z0-9+/=])
%   of US-ASCII is used, enabling 6 bits to be represented per printable
%   character.
%
%   See also BASE64ENCODE.
%
%   Written by Jarek Tuszynski, SAIC, jaroslaw.w.tuszynski_at_saic.com
%
%   Matlab version based on 2004 code by Peter J. Acklam
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam
%   http://home.online.no/~pjacklam/matlab/software/util/datautil/base64encode.m

if nargin<3, alg='java';  end
if nargin<2, outfname=''; end

%% if x happen to be a filename than read the file
% if (numel(x)<256)
%    if (exist(x, 'file') == 2)
%       fid = fopen(x,'rb');
%       x = fread(fid, 'uint8');
%       fclose(fid);
%    end
% end
% x = uint8(x(:)); % unify format

%% Perform conversion
switch (alg)
   case 'java'
      base64 = org.apache.commons.codec.binary.Base64;
      y = base64.decode(x);
      y = mod(int16(y),256); % convert from int8 to uint8
   case 'matlab'
      %%  Perform the mapping
      %   A-Z  ->  0  - 25
      %   a-z  ->  26 - 51
      %   0-9  ->  52 - 61
      %   + -  ->  62       '-' is URL_SAFE alternative
      %   / _  ->  63       '_' is URL_SAFE alternative
      map = uint8(zeros(1,256)+65);
      map(uint8(['A':'Z', 'a':'z', '0':'9', '+/=']))= 0:64;
      map(uint8('-_'))= 62:63;  % URL_SAFE alternatives
      x = map(x);  % mapping

      x(x>64)=[]; % remove non-base64 chars
      if rem(numel(x), 4)
         warning('Length of base64 data not a multiple of 4; padding input.');
      end
      x(x==64)=[]; % remove padding characters

      %% add padding and reshape
      nebytes = length(x);         % number of encoded bytes
      nchunks = ceil(nebytes/4);   % number of chunks/groups
      if rem(nebytes, 4)>0
         x(end+1 : 4*nchunks) = 0;  % add padding
      end
      x = reshape(uint8(x), 4, nchunks);
      y = repmat(uint8(0), 3, nchunks);            % for the decoded data

      %% Rearrange every 4 bytes into 3 bytes
      %    00aaaaaa 00bbbbbb 00cccccc 00dddddd
      % to form
      %    aaaaaabb bbbbcccc ccdddddd
      y(1,:) = bitshift(x(1,:), 2);                 % 6 highest bits of y(1,:)
      y(1,:) = bitor(y(1,:), bitshift(x(2,:), -4)); % 2 lowest  bits of y(1,:)
      y(2,:) = bitshift(x(2,:), 4);                 % 4 highest bits of y(2,:)
      y(2,:) = bitor(y(2,:), bitshift(x(3,:), -2)); % 4 lowest  bits of y(2,:)
      y(3,:) = bitshift(x(3,:), 6);                 % 2 highest bits of y(3,:)
      y(3,:) = bitor(y(3,:), x(4,:));               % 6 lowest  bits of y(3,:)

      %% remove extra padding
      switch rem(nebytes, 4)
         case 2
            y = y(1:end-2);
         case 3
            y = y(1:end-1);
      end
end

%% reshape to a row vector and make it a character array
y = uint8(reshape(y, 1, numel(y)));

%% save to file if needed
if ~isempty(outfname)
   fid = fopen(outfname,'wb');
   fwrite(fid, y, 'uint8');
   fclose(fid);
end

return