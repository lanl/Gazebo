#!/usr/bin/env python 
from __future__ import division

#  ###################################################################
#
#  Disclaimer and Notice of Copyright
#  ==================================
#
#  Copyright (c) 2013, Los Alamos National Security, LLC
#  All rights reserved.
#
#  Copyright 2013. Los Alamos National Security, LLC.
#  This software was produced under U.S. Government contract
#  DE-AC52-06NA25396 for Los Alamos National Laboratory (LANL),
#  which is operated by Los Alamos National Security, LLC for
#  the U.S. Department of Energy. The U.S. Government has rights
#  to use, reproduce, and distribute this software.  NEITHER
#  THE GOVERNMENT NOR LOS ALAMOS NATIONAL SECURITY, LLC MAKES
#  ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LIABILITY
#  FOR THE USE OF THIS SOFTWARE.  If software is modified to
#  produce derivative works, such modified software should be
#  clearly marked, so as not to confuse it with the version
#  available from LANL.
#
#  Additionally, redistribution and use in source and binary
#  forms, with or without modification, are permitted provided
#  that the following conditions are met:
#  -  Redistributions of source code must retain the
#     above copyright notice, this list of conditions
#     and the following disclaimer.
#  -  Redistributions in binary form must reproduce the
#     above copyright notice, this list of conditions
#     and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  -  Neither the name of Los Alamos National Security, LLC,
#     Los Alamos National Laboratory, LANL, the U.S. Government,
#     nor the names of its contributors may be used to endorse
#     or promote products derived from this software without
#     specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY LOS ALAMOS NATIONAL SECURITY, LLC
#  AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
#  IN NO EVENT SHALL LOS ALAMOS NATIONAL SECURITY, LLC OR CONTRIBUTORS
#  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
#  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
#  OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
#  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
#  OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
#  OF SUCH DAMAGE.
#
#  ###################################################################


""" 
	Calculates available space on filesystems used by Gazebo app 
	returns boolean value true if okay, false if results indicate 
	cleanup is needed

        LANL specific
"""
__author__	= "Jennifer Green"
__version__ 	= "0.0.1"
__email__	= "jgreen@lanl.gov"
__status__	= "Development"

import sys
import socket
import os 
import re
import getpass
import fnmatch 

def get_routine(path):
        realpath = os.path.realpath(path)
        if os.path.exists(realpath):
                for dir in realpath.split('/'):
                        if fnmatch.fnmatch(dir, '*projects*'):
                                routine = "proj"
                        elif fnmatch.fnmatch(dir, '*panfs*'):
                                routine = "panfs"
                        elif fnmatch.fnmatch(dir, '*users*'):
                                routine = "home"
                        elif fnmatch.fnmatch(dir, '*lustre*'):
                                routine = "lustre"
                return routine, realpath
        else:
                sys.stderr.write('ERROR: No Such File: %s\n' % realpath)
                return 1
def get_projpartition(project):
	if os.access(os.path.join('/yellow', 'usr/projects/', project), os.W_OK):
		partition = "yeti-gpfs"
	elif os.access(os.path.join('/turquoise', 'usr/projects/', project), os.W_OK):
		partition = "turquoise-gpfs"
	return partition

def get_homepartition(home):
	user = getpass.getuser()
	if os.access(os.path.join('/yellow', 'users', user), os.W_OK):
		partition = "yeti-gpfs-home"
	elif os.access(os.path.join('/turquoise', 'users', user), os.W_OK):
		partition = "turquoise-gpfs-home"
	return partition
 
def define_prefixes_project(partition, project):
	if (partition == "yeti-gpfs"):
		color="yellow"
	if (partition == "turquoise-gpfs"):
		color="turquoise"
	color_prefix = os.path.join('/usr/projects/systems/scratchspace', color, 'project')
	partition_prefix = os.path.join('/usr/projects/systems/scratchspace', partition, 'project')
	return color_prefix, partition_prefix

def define_prefixes_home(partition, home):
	partition_prefix = os.path.join('/usr/projects/systems/scratchspace', partition, 'home')
	return partition_prefix 

def get_scratchusage_percentage(*args):
	pass  ## need to write this 
 
def get_homeusage_percentage(prefix, home):
	uid = getuid()
	pass  ## need to write this

def get_projectusage_percentage(prefix, project):
	# don't think I need this anymore :used=open(".".join([prefix,project]))
	file=".".join([prefix,project])
	lines = open(file).readlines()
	pattern = re.compile(r"QUOTA:|,")
	for word in open(file).readlines():
		if word.startswith("QUOTA:"):
			data = pattern.split(word)
			used = data[1]
			quota = data[2]
			used = float(used) * 1024  ## does this need to be 1024 ?? 
			quota = float(quota) * 1024  ## does this need to be 1024 to be accurate? 
			usage = used / quota
	return usage, quota

def get_usage_percentage(prefix, projhome):
	projhome = str(projhome) 
	file = ".".join([prefix, projhome])
	lines = open(file).readlines()
	pattern = re.compile(r"QUOTA:|,")
	for word in open(file).readlines():
		if word.startswith("QUOTA:"):
			data = pattern.split(word)
			used = data[1]
			quota = data[2]
			used = float(used) * 1000 
			quota = float(quota) * 1000
			usage = used / quota
    		try:
        		percent = ret = (float(used) / quota) * 100
    		except ZeroDivisionError:
        		percent = 0
	return percent, quota

def get_projectfrompath(path):
	project=path.split('/')
	return project[4]

def get_projectuser_bytes(prefix, project):
	user=getpass.getuser()
	#user="dog"
	file=".".join([prefix, project])
	lines = open(file).readlines()
	word=[y.split(' ')[3].rstrip('\n') for y in lines if user in y]
	for x in word:
		if ( 'T' in x ):
			xbyte = x.replace("T", "")
			multiplier = 1099511627776
		elif ( 'G' in x ):  
			xbyte = x.replace("G", "") 				 	
			multiplier = 1073741824
		elif ( 'M' in x ):
			xbyte = x.replace("M", "")
			multiplier = 1048576
		elif ( 'K' in x):
			xbyte = x.replace("K", "")
			multiplier = 1024
		elif ( 'B' in x):
			xbyte = x.replace("B", "") 
			multiplier = 1 
	bytes = float(xbyte) * multiplier 
	return bytes, user

def find_mountpoint(path):
        for l in open("/proc/mounts", "r"):
                mp = l.split(" ")[1]
        return None

def get_project_usage_threshold():
	threshold = int(sys.argv[1])
	return threshold
def get_boolean(usage, threshold):
	if ( float(usage) <= float(threshold)):
		boolean_val = True
	else:	
		boolean_val = False
	return boolean_val

def disk_usage(path):
    """Return disk usage associated with path."""
    st = os.statvfs(path)
    free = (st.f_bavail * st.f_frsize)
    total = (st.f_blocks * st.f_frsize)
    used = (st.f_blocks - st.f_bfree) * st.f_frsize
    try:
        percent = ret = (float(used) / total) * 100
    except ZeroDivisionError:
        percent = 0
    return total, used, free, round(percent, 1)

def generic(workspace_path_string):
	total, used, free, percent = disk_usage(workspace_path_string)
	print "TOTAL: %i USED: %i FREE: %i PERCENT: %d " % (total, used, free, percent)
	boolean_val = get_boolean(percent, threshold)
        print "Boolean_val is %s" % (boolean_val)
	return boolean_val

def main():
	try:
		workspace_path_string = sys.argv[2]
		routine, realpath = get_routine(workspace_path_string)
                threshold = get_project_usage_threshold()
		print "Threshold: %i", threshold
		print "Workspace_path ", workspace_path_string
		if ( routine == 1 ):
                        routine = get_routine(os.getcwd())
		if routine == "proj":
			project = get_projectfrompath(realpath)
			partition = get_projpartition(realpath)	
			color_prefix, partition_prefix = define_prefixes_project(partition, project)			
			projectpercent, quota = get_usage_percentage(partition_prefix, project)
                	userbytes, user = get_projectuser_bytes(color_prefix, project)
                	try:
				userpercent = ( float(userbytes) / quota ) * 100
                	except ZeroDivisionError:
				userpercent = 0
                	boolean_val = get_boolean(projectpercent, threshold)
		elif routine == "home":
			partition = get_homepartition(workspace_path_string)
			uid = os.getuid() 
			partition_prefix = define_prefixes_home(partition, uid)
			homepercent, quota = get_usage_percentage(partition_prefix, uid) 
			boolean_val = get_boolean(homepercent, threshold)
		elif routine == "panfs":
			total, used, free, percent = disk_usage(workspace_path_string)
			boolean_val = get_boolean(percent, threshold)
		elif routine == "lustre":
			usage_lustre = disk_usage(workspace_path_string)
			boolean_val = get_boolean(percent, threshold)
		else:
			print('ERROR: Appropriate Routine cannot be determined!')
		return 0
	
	except Exception, err:
		sys.stderr.write('ERROR: %s\n' % str(err))
		return 1

if __name__ == '__main__':
	workspace_path_string = sys.argv[2]
	print workspace_path_string
	routine, realpath = get_routine(workspace_path_string)
	print routine
	threshold = get_project_usage_threshold()
	if ( routine == 1 ):
		routine = get_routine(os.getcwd())
		print "Routine is %s" % (routine)
	if routine == "proj":
		project = get_projectfrompath(realpath)
		partition = get_projpartition(realpath)
		color_prefix, partition_prefix = define_prefixes_project(partition, project)
		projectpercent, quota = get_usage_percentage(partition_prefix, project)
		print "The project usage percentage is %i percent" % projectpercent
		userbytes, user = get_projectuser_bytes(color_prefix, project)
		print "%s, you're using %.2f bytes of %s quota of %d bytes" % (user, float(userbytes), project, float(quota))
		try:
			userpercent = ( float(userbytes) / quota ) * 100
		except ZeroDivisionError:
			userpercent = 0
		print "which means you're using %.2f percent of %s project space" % (round(userpercent,2), project)
		print "The threshold passed to script is %s" % (threshold)
		boolean_val = get_boolean(projectpercent, threshold)
		print "Boolean_val is %s" % (boolean_val)
	elif routine == "home":
		partition = get_homepartition(workspace_path_string)
		uid = os.getuid()
		partition_prefix = define_prefixes_home(partition, uid)
		homepercent, quota = get_usage_percentage(partition_prefix, uid)
		print "The home usage percentage is %i percent" % homepercent
		boolean_val = get_boolean(homepercent, threshold)
		print "Boolean_val is %s" % (boolean_val)
	elif routine == "panfs":
		total, used, free, percent = disk_usage(workspace_path_string)
		print "TOTAL: %i USED: %i FREE: %i PERCENT: %d " % (total, used, free, percent)
		boolean_val = get_boolean(percent, threshold)
		print "Boolean_val is %s" % (boolean_val)
	elif routine == "lustre":
		usage_lustre = disk_usage(workspace_path_string)
		print usage_lustre
	else:
	
		print('ERROR: Appropriate Routine cannot be determined!')
                #mp = find_mountpoint(realpath)
                #print "MP:", mp


