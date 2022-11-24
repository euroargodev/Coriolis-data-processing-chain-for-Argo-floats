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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
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

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


for id = 1:length(a_juld)
   juldStr = num2str(a_juld(id), 11);
   res = sscanf(juldStr, '%5d.%6d');
   o_day(id) = res(1);
   
   if (o_day(id) ~= fix(g_decArgo_dateDef))
      o_dayNum(id) = fix(a_juld(id));
      
      dateNum = o_day(id) + g_decArgo_janFirst1950InMatlab;
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
   else
      o_dayNum(id) = 99999;
      o_day(id) = 99;
      o_month(id) = 99;
      o_year(id) = 9999;
      o_hour(id) = 99;
      o_min(id) = 99;
      o_sec(id) = 99;
   end
   
end

return
