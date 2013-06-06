gantt.py is simple Python script that translates 
simulation output into GNUplot commands that draw a Gantt chart.

INPUT
In the simulation output, each tab-separated line represents the
execution of a task on a resource:

resource    start-time  end-time    task

USAGE
gantt.py translates these lines into a set of GNUplot commands,
when called like this:

python gantt.py -o foo.gpl foo.txt

The resulting foo.gpl can be processed by GNUplot as follows:

set terminal postscript eps color solid
set output "foo.eps"
load "foo.gpl"
unset output

GNUplot version 4.2 or newer is required.

COLORS
gantt.py uses a default color set, but the --color option also
allows to specify your own colors. Furhtermore, palette.dat files
can be used in GNUplot to change the default palette.

EXAMPLES
See the examples how to generate appropriate input, 
and create figures with multiple plots.

DISCLAIMER
Your mileage may vary.
