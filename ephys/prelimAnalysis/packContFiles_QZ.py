import sys
sys.path.insert(0, 'D:\\DCN_project\\Github\\analysis-tools\\Python3')
from OpenEphys import pack_2



# get input arguments
file_dir = 'Z:\\obstacleData\\sessions\\201014_000\\ephys_2020-10-14_15-49-13'
source = 100
fs = 30000
highpass = 300
dref = 'ave'
connected_channels = 'all'

# format input arguments appropriately
fs = int(fs)
highpass = int(highpass)
if dref=='None': dref=None


print('running pack_2...')
pack_2(folderpath = file_dir, filename = '', channels = 'all', chprefix = 'CH', highpass=highpass, fs = fs,
           dref = dref, session = '0', source = '107')