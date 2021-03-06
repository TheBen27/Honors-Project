function [ times, names ] = import_labels( filename )
%IMPORT_LABEL Import label csv file
%   Format has columns "time", "activity"
%   with times being yyyy/MM/dd HH:mm:ss
%   and names being potentially blank

table = readtable(filename, 'delimiter', ',');
if any(table.time{1} == '.')
   times = datetime(table.time, 'InputFormat', 'yyyy/MM/dd HH:mm:ss.SS');
else
   times = datetime(table.time, 'InputFormat', 'yyyy/MM/dd HH:mm:ss');
end

names = table.activity;

end

