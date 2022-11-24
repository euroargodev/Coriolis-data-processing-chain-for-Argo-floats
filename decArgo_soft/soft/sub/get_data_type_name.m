% ------------------------------------------------------------------------------
% Associate a name to a given data type number.
%
% SYNTAX :
%  [o_dataTypeName] = get_data_type_name(a_dataTypeNumber)
%
% INPUT PARAMETERS :
%   a_dataTypeNumber : data type number
%
% OUTPUT PARAMETERS :
%   o_dataTypeName : name of the data type
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataTypeName] = get_data_type_name(a_dataTypeNumber)

o_dataTypeName = '';

switch (a_dataTypeNumber)

   case 0
      o_dataTypeName = 'CTD mean';

   case 1
      o_dataTypeName = 'CTD stDev & med';

   case 2
      o_dataTypeName = 'CTD raw';

   case 3
      o_dataTypeName = 'OXY mean';

   case 4
      o_dataTypeName = 'OXY stDev & med';

   case 5
      o_dataTypeName = 'OXY raw';
      
   case 6
      o_dataTypeName = 'ECO2 mean';

   case 7
      o_dataTypeName = 'ECO2 stDev & med';

   case 8
      o_dataTypeName = 'ECO2 raw';
      
   case 9
      o_dataTypeName = 'ECO3 mean';

   case 10
      o_dataTypeName = 'ECO3 stDev & med';

   case 11
      o_dataTypeName = 'ECO3 raw';

   case 12
      o_dataTypeName = 'OCR mean';

   case 13
      o_dataTypeName = 'OCR stDev & med';

   case 14
      o_dataTypeName = 'OCR raw';

   case 15
      o_dataTypeName = 'FLNTU mean';

   case 16
      o_dataTypeName = 'FLNTU stDev & med';

   case 17
      o_dataTypeName = 'FLNTU raw';
      
   case 18
      o_dataTypeName = 'cROVER mean';

   case 19
      o_dataTypeName = 'cROVER stDev & med';

   case 20
      o_dataTypeName = 'cROVER raw';

   case 21
      o_dataTypeName = 'SUNA mean';

   case 22
      o_dataTypeName = 'SUNA stDev & med';

   case 23
      o_dataTypeName = 'SUNA raw';
      
   case 24
      o_dataTypeName = 'SUNA APF frame';
      
   case 25
      o_dataTypeName = 'SUNA APF2 frame';
      
   case 37
      o_dataTypeName = 'CYCLOPS mean';
      
   case 38
      o_dataTypeName = 'CYCLOPS stDev & med';
      
   case 39
      o_dataTypeName = 'CYCLOPS raw';
      
   case 40
      o_dataTypeName = 'SEAPOINT mean';
      
   case 41
      o_dataTypeName = 'SEAPOINT stDev & med';
      
   case 42
      o_dataTypeName = 'SEAPOINT raw';

   case 46
      o_dataTypeName = 'SEAFET mean';

   case 47
      o_dataTypeName = 'SEAFET stDev & med';

   case 48
      o_dataTypeName = 'SEAFET raw';

   otherwise
      o_dataTypeName = 'UNKNOWN data type';
end

return
