#!/bin/bash

function showReminderUsage(){
   echo "
   Reminder: Set a reminder for tomorrow. Shows you what you need to do a the start of each day in an html page

   USAGE: 
   reminder [OPTION]

   -a                   sets the tool to add reminders for today
   --add

   -at                  sets the tool to add reminders for tomorrow
   --add-tomorrow

   -l                   lists out the reminders for today
   --list

   -lt                  lists out the reminders for tomorrow
   --list-tomorrow

   --show               displays today's reminders in an html page (in chrome)

   --show-tomorrow      displays tomorrow's remidners in an html page (in chrome)

   -h                   opens this message
   --help"
}
function showHtml(){
   day="today"
   if [ "$1" == "--tomorrow" ]; then
      day="tomorrow"
   fi
   echo "day: $day"
   todofile=files/$(date --date="$day" +%Y%m%d.md)
   if [ ! -f $todofile ]; then
      addReminder --today
   fi
   start chrome files/$(date --date="$day" +%Y%m%d.html)
}
function listReminders(){
   day="today"
   if [ "$1" == "-t" ] || [ "$1" == "--tomorrow" ]; then
      day="tomorrow"
   fi
   echo "day: $day"
   todofile=files/$(date --date="$day" +%Y%m%d.md)
   if [ ! -f $todofile ]; then
      addReminder --today
   fi
   awk '/##/{y=1;next}y' $todofile | sed '/^$/d'
}
function addReminder(){
   to="tomorrow"
   case $1 in
      -a)               to="today" ;;
      -at)              to="tomorrow" ;;
   esac
   echo "Adding reminders for $to"
   todoname=files/$(date --date="$to" +%Y%m%d)
   todofile=files/$(date --date="$to" +%Y%m%d.md)
   echo $todofile
   if [[ ! -f $todofile ]]; then
      day=$(date --date="$to" +%u)
      case $day in
         1) day="MONDAY" ;;
         2) day="TUESDAY" ;;
         3) day="WEDNESDAY" ;;
         4) day="THURSDAY" ;;
         5) day="FRIDAY" ;;
         6) day="SATURDAY" ;;
         7) day="SUNDAY" ;;
      esac
      echo "# IT'S $day BITCH LET'S GO" >> $todofile
      echo "## Here are your items for the day:" >> $todofile
      echo "" >> $todofile
      readEntries $todofile
      echo "File $todoname has been added to ~/tools/reminder"
      mdtohtml $todoname
   else
      echo "File already exists, do you want to continue adding to the document? (Y/n)"
      read edit
      if [ "$edit" == "Y" ] || [ "$edit" == "y" ]; then
         readEntries $todofile
         echo "File $todoname has been successfuly updated."
         mdtohtml $todoname
      fi
   fi
}
function readEntries(){
   echo ""
   echo "Type in some entries, just enter a blank one when you're done. Type 'ls' at any time to view the list. "
   echo ""
   if [ -z $1 ]; then
      echo "Invalid entry"
   fi
   tmp=tmp.md
   echo "" > $tmp
   read entries
   while [ ! -z "$entries" ]; do
      if [ "$entries" == "ls" ]; then
         echo "
         Here's your list so far"
         echo "
         Original List:" 
         awk '/##/{y=1;next}y' $1 | sed '/^$/d'
         echo "
         Added this session: "
         if [ `wc -l < $tmp` -gt 1 ]; then
            cat $tmp
         else
            echo "---Nothing added yet!---"
         fi
         read entries
      else
         echo $entries >> $tmp
         echo "'$entries' added."
         echo ""
         read entries
      fi
   done
   awk '1;!(NR%1){print "";}' $tmp >> $1
   rm $tmp
}
function mdtohtml(){
   if [ -z $1 ] || [ ! -f "$1.md" ]; then
      echo "Invalid file: '$1'"
   else
      echo "received: $1"
      echo "Converting into HTML. This may take several minutes"

      pandoc -f markdown -t html $1.md -o $1.html

      echo "Finished converting."
      echo "Adding some html markup..."

      echo "<body>"| cat - $1.html > temp && mv temp $1.html
      echo "</head>"| cat - $1.html > temp && mv temp $1.html
      echo "<link rel='stylesheet' href='../style.css' type='text/css'>" | cat - $1.html > temp && mv temp $1.html
      echo "<head>" | cat - $1.html > temp && mv temp $1.html
      echo "<!DOCTYPE HTML>" | cat - $1.html > temp && mv temp $1.html
      echo "</body>" >> $1.html;
      echo "</html>" >> $1.html;

      echo "Successfully converted into HTML."
   fi
}

case $1 in 
   "") addReminder -t ;;
   -a) addReminder -a ;;
   -add) addReminder -a ;;
   -at) addReminder -t ;;
   --add-tomorrow) addReminder -t ;;
   -l) listReminders ;;
   --list) listReminders ;;
   -lt) listReminders -t ;;
   --list-tomorrow) listReminders -t ;;
   --show) showHtml --today ;;
   --show-tomorrow) showHtml --tomorrow ;;
   -h) showReminderUsage ;;
   --help) showReminderUsage ;;
   *) showReminderUsage ;;
esac
