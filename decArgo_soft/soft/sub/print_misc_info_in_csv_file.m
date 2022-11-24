% ------------------------------------------------------------------------------
% Print miscellaneous information in output CSV file.
%
% SYNTAX :
%  print_misc_info_in_csv_file(a_miscInfo, a_FileType)
%
% INPUT PARAMETERS :
%   a_miscInfo : miscellaneous information structure
%   a_FileType : type of file from which the information has been retrieved
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_misc_info_in_csv_file(a_miscInfo, a_FileType)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


% process each input information
for idL = 1:length(a_miscInfo)
   format = [];
   data = [];
   dataStruct = a_miscInfo{idL};
   
   format = [format '%d'];
   data{end+1} = g_decArgo_floatNum;
   format = [format ';%d'];
   data{end+1} = g_decArgo_cycleNum;
   format = [format ';%s'];
   data{end+1} = dataStruct.msgType;
   if (~isempty(a_FileType))
      format = [format ';%s'];
      data{end+1} = a_FileType;
   end
   if (~isempty(dataStruct.msgNum))
      format = [format ';%d'];
      data{end+1} = dataStruct.msgNum;
   else
      format = [format ';-'];
   end
   format = [format ';%s'];
   data{end+1} = dataStruct.label;
   if (~isempty(dataStruct.raw))
      format = [format ';' dataStruct.rawFormat];
      data{end+1} = dataStruct.raw;
      if (~isempty(dataStruct.rawUnit))
         format = [format ';%s'];
         data{end+1} = dataStruct.rawUnit;
      end
      format = [format ';=>'];
   end
   if (~isempty(dataStruct.value))
      format = [format ';' dataStruct.format];
      data{end+1} = dataStruct.value;
      if (~isempty(dataStruct.unit))
         format = [format ';%s'];
         data{end+1} = dataStruct.unit;
      end
   end
   if (~isempty(dataStruct.valueAdj))
      format = [format ';=>;' dataStruct.format];
      data{end+1} = dataStruct.valueAdj;
      if (~isempty(dataStruct.unit))
         format = [format ';%s'];
         data{end+1} = dataStruct.unit;
      end
   end
   format = [format '\n'];
   fprintf(g_decArgo_outputCsvFileId, format, data{:});
end

return;
