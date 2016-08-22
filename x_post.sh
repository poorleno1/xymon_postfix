#!/bin/bash

log="/var/log/maillog"
current_date=`date | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`
previous_date=`date -d '5 minutes ago' | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`

messages_sent=$(sed -n "/$previous_date/,/$current_date/p" "$log" | grep status=sent | wc -l)
messages_bounced=$(sed -n "/$previous_date/,/$current_date/p" "$log" | grep status=bounced | wc -l)
messages_deferred=$(sed -n "/$previous_date/,/$current_date/p" "$log" | grep status=deferred | wc -l)


COLOR="green"
TEST="pstfx"


LINE="status $MACHINE.$TEST $COLOR $(date)

<br><br>

messages_sent: $messages_sent
messages_bounced: $messages_bounced
messages_deferred: $messages_deferred


<br><br>

"

echo $LINE


$BB $BBDISP "$LINE"
