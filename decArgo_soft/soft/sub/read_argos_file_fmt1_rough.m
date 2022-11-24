% ------------------------------------------------------------------------------
% Read format #1 Argos file without checking the consistency of the PRV/DS
% format (except for the time lines) and retrieve only time information.
%
% SYNTAX :
%  [o_argosLocDate, o_argosDataDate] = ...
%    read_argos_file_fmt1_rough(a_fileName, a_argosId)
%
% INPUT PARAMETERS :
%   a_fileName : format #1 Argos file name
%   a_argosId  : float Argos Id
%
% OUTPUT PARAMETERS :
%   o_argosLocDate  : Argos location dates
%   o_argosDataDate : Argos message dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocDate, o_argosDataDate] = ...
   read_argos_file_fmt1_rough(a_fileName, a_argosId)

% output parameters initialization
o_argosLocDate = [];
o_argosDataDate = [];


% read dates (location and message) of the file without checking the
% consistency of the PRV/DS format

if ~(exist(a_fileName, 'file') == 2)
   fprintf('ERROR: Argos file not found: %s\n', a_fileName);
   return
end

fId = fopen(a_fileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening Argos file: %s\n', a_fileName);
   return
end

% read Argos file
lineNum = 0;
while (1)
   line = fgetl(fId);
   lineNum = lineNum + 1;
   if (line == -1)
      break
   end

   % empty line
   if (strcmp(deblank(line), ''))
      continue
   end

   % look for satellite pass header
   [val, count, errmsg, nextindex] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%d %f %f %f %d');
   if (isempty(errmsg) && (count >= 5) && (val(2) == a_argosId))
      
      if (isempty(errmsg) && (count == 16))

         o_argosLocDate = [o_argosLocDate; ...
            gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
            val(7), val(8), val(9), val(10), val(11), val(12)))];
      end
      
   else
      % look for message header
      [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %2c %2c %2c %2c');
      
      if (isempty(errmsg) && (count == 11))

         o_argosDataDate = [o_argosDataDate; ...
            gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
            val(1), val(2), val(3), val(4), val(5), val(6)))];
      else
         [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %8c %x %x %x');
         if (isempty(errmsg) && (count == 11))

            o_argosDataDate = [o_argosDataDate; ...
               gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
               val(1), val(2), val(3), val(4), val(5), val(6)))];
            %          else
            %             fprintf('NO DATE IN: %s\n', line);
         end
      end
   end
end

fclose(fId);

% reduce and sort output data
o_argosLocDate = sort(unique(o_argosLocDate));
o_argosDataDate = sort(unique(o_argosDataDate));

return
