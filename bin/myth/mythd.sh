#!/bin/sh
# Startup script for mythd
#
# chkconfig: 345 99 01
# description: Run mythd

# Source function library.
. /etc/rc.d/init.d/functions

[ -x /usr/bin/mythd ] || exit 0

PROG='mythd'

start() {
    echo -n $"Starting $PROG: " 
    /usr/bin/$PROG
    RETVAL=$?
    [ $RETVAL -eq 0 ] && touch /var/lock/subsys/$PROG
    echo
    return $RETVAL
}

startfresh() {
    echo -n $"Starting $PROG: " 
    /usr/bin/$PROG -f
    RETVAL=$?
    [ $RETVAL -eq 0 ] && touch /var/lock/subsys/$PROG
    echo
    return $RETVAL
}

stop() {
    if test "x`pidof -x $PROG`" != x; then
	echo -n $"Stopping $PROG: "
	killproc $PROG
	echo
    fi
    RETVAL=$?
    [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/$PROG
    return $RETVAL
}

case "$1" in
	startfresh)
	    startfresh
	    ;;
	
	start)
	    start
	    ;;
	
	stop)
	    stop
	    ;;
	
	status)
	    status $PROG
	    ;;

	restart)
	    stop
	    start
	    ;;
	
	*)
	    echo $"Usage: $0 {start|stop|restart|status|startfresh}"
	    exit 1

esac

exit 0
