import seaborn as sns
import matplotlib.pyplot as plt

# This gets used for heatmaps, i.e. all the trail plots.
CMAP = "RdPu"

# Legends and axis labels.
FONTSIZE = 9

# This may or may not do anything if we're exporting to .svgs. Who knows.
DPI = 600

sns.set_context("talk")

# Nature Comms settings.
mm_to_inch = 25.4
two_column_width = 180 / mm_to_inch
one_column_width = 88 / mm_to_inch
sns.set_context("paper")

# Also Nature Comms.
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['Helvetica', 'DejaVu Sans']

# Remove top and right spines.
plt.rc('axes.spines', **{'bottom':True, 'left':True, 'right':False, 'top':False})


# Utility function for adding the a, b, c, etc. for multi-part plots.
def add_letter(subfig, xoffset, yoffset, letter):
    subfig.text(xoffset, yoffset, letter, 
        # This setting means the location (offsets) reference the coordinate
        # system of the subfigure from 0 -> 1.
        transform = subfig.transSubfigure,
        size=20, weight='bold')

# This cmap is just for these 3 colors. We could change these.
palette = "rocket"
COLORS = [
    sns.color_palette(palette)[0],
    sns.color_palette(palette)[2],
    sns.color_palette(palette)[4]]
