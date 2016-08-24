#!/bin/bash

log="/var/log/maillog"
current_date=`date | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`

previous_date=`date -d '10 minutes ago' | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`
previous_date10=`date -d '15 minutes ago' | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`

#previous_date=`date -d '24 hours ago' | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`
#previous_date10=`date -d '24 hours ago' | awk 'BEGIN{FS="[ :]+"}; {print $2" "$3" "$4":"$5}'`

messages_sent=$(sed -n "/$previous_date/,/$current_date/p" "$log" | grep status=sent | wc -l)
messages_bounced=$(sed -n "/$previous_date/,/$current_date/p" "$log" | grep status=bounced | wc -l)
messages_deferred=$(sed -n "/$previous_date/,/$current_date/p" "$log" | grep status=deferred | wc -l)



BBTMP="/tmp"
COLOR="green"
TEST="pstfx"
LINE="status $MACHINE.$TEST $COLOR $(date)
<br><br>
messages_sent: $messages_sent
messages_bounced: $messages_bounced
messages_deferred: $messages_deferred
<br><br>
"

if [ -f "$BBTMP/deferred_processed" ]
then
        echo "Found old file $BBTMP/deferred_processed. Deleting.."
        rm $BBTMP/deferred_processed
        if [ -f $BBTMP/deferred_processed ] ; then
                echo "File $BBTMP/deferred_processed deleted successfully."
        fi
else
        echo "File $BBTMP/deferred_processed not found,moving on.."
fi

if [ -f $BBTMP/deferred_processed ] ; then
echo "File $BBTMP/deferred_processed deleted successfully."
fi

if [ -f "$BBTMP/bounced_processed" ]
then
        echo "Found old $BBTMP/bounced_processed. Deleting.."
        rm $BBTMP/bounced_processed
        if [ -f $BBTMP/deferred_processed ] ; then
                echo "File $BBTMP/deferred_processed deleted successfully."
        fi
else
        echo "File $BBTMP/bounced_processed not found, moving on.."
fi



sed -n "/$previous_date10/,/$current_date/p" "$log" > $BBTMP/maillog10
sed -n "/$previous_date/,/$current_date/p" "$log" > $BBTMP/maillog

from=$(head -n 1 /tmp/maillog | awk '{print $1" "$2" "$3}')
to=$(tail -n 1 /tmp/maillog | awk '{print $1" "$2" "$3}')
grep status=bounced /tmp/maillog | sed  -e 's/\(.*\)>,.*said:\ /\1;/g' > $BBTMP/bounced


if [ -f $BBTMP/bounced ]; then

#LINE+="<H1>Bounced mails</H1>"

while read p; do
message=$(echo $p | awk -F' ' '{print $6}')
clientip=$(grep $message $BBTMP/maillog10|grep client|   awk -F'[' '{print $3}' | awk -F']' '{print $1}')
#LINE+=$p" SourceIP:"$clientip
echo "Echo" $p "SourceIP:" $clientip >> $BBTMP/bounced_processed
done <$BBTMP/bounced
echo "----------------------------------------Scanning data from $from to $to----------------------------------------------" > $BBTMP/mail_body
echo -e "\n" >> $BBTMP/mail_body
echo "----------------------------------------------------BOUNCED MAILS----------------------------------------------------" >> $BBTMP/mail_body

#cat $BBTMP/bounced_processed | sed -e 's/.*to=<//g' -e 's/>,.*said://g' | sed -e 's/\(;\).*\(SourceIP\)/\1\2/' | sort| uniq -c >> $BBTMP/mail_body

if [ -f $BBTMP/bounced_processed ] ; then
cat /tmp/bounced_processed | sed -e 's/.*to=<//g' -e 's/>,.*said://g'  | sort | uniq -c >> $BBTMP/mail_body
fi

echo -e "\n" >> $BBTMP/mail_body
echo "----------------------------------------------------DEFERRED MAILS---------------------------------------------------" >> $BBTMP/mail_body
#rm $BBTMP/bounced
fi

grep status=deferred /tmp/maillog | sed  -e 's/\(.*\)>,.*said:\ /\1;/g' > $BBTMP/deferred

if [ -f $BBTMP/deferred ]; then

#LINE+="<H1>Deferred mails</H1>"

while read p; do
message=$(echo $p | awk -F' ' '{print $6}')
clientip=$(grep $message $BBTMP/maillog10|grep client|   awk -F'[' '{print $3}' | awk -F']' '{print $1}')
echo $p "SourceIP:" $clientip >> $BBTMP/deferred_processed
#LINE+=$p" SourceIP:"$clientip
done <$BBTMP/deferred

if [ -f $BBTMP/deferred_processed ] ; then
cat $BBTMP/deferred_processed | sed -e 's/.*to=<//g' -e 's/>,.*deferred//g' | sort| uniq -c >> $BBTMP/mail_body
fi
#rm $BBTMP/deferred
fi

#rm $BBTMP/maillog10
#rm $BBTMP/maillog

cat $BBTMP/mail_body | mail -s "Bounced and Deferred mails on `hostname`"  name@gmail.com