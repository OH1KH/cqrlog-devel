#!/bin/bash
# //audio file name (prefix) played on alert
# //can be:'my'  = ansver to my cq,
# //       'loc' = new main grid,
# //       'text'= text found from monitor line 
# //       'call'= text fits to the callsign
# // create files you want to be played using these as filenames 1st part 
#(I.E my.wav or my.mp3 ... etc Note:! use low case letters in name)

# scirpt is seeking names with '.wav' suffix! Change if needed    
# select audio card(if needed) here:


# next line does the whole job! $1 is replaced by cqrlog to suffixes listed

aplay ~/.config/cqrlog/voice_keyer/$1.wav
