#!/bin/bash


 
# debugging on 
# set -x 
#  =================================  Disk Daemon Management ================================================
#
# AUTHOR: Usman O. Olanrewaju (Blu3-Sky) 
# CREATED: 2026/06/08 
#
# STEPS USED: shoutout to  tlp for me using there steps for this deamon setups 
#
# PURPOSE: 
# this deamon helps to manage mounted dir
# lvm
# autofs
# nfs 
# dev 

# ===========================================================================================================

# locator for config

Locator="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$Locator/dsk-daemon.conf"

if [ ! -f "$CONF_FILE" ]; then 
	    echo "Configuration file not found: $CONF_FILE"   
	exit 20

  fi 

# source lib/conf
 . "$CONF_FILE"



rotated= 



# Verify if the path is Directory or not 

if [[ ! -d "$WATCH_PATH" ]]; then
    echo -e  "\n [ERROR]WATCH_PATH does not exist or is not a directory: $WATCH_PATH " >> "$LOG_FILE"  
    exit 21
fi


# Return Used % of filesystem: visit man df or df --help for configuration also (delete sign % ) 
 

get_fs_usage_percent() {
    df "$WATCH_PATH" --output=pcent 2>/dev/null \
        | tail -1 \
        | tr -d ' %'
} 


# Return  human readable filesysetem size, filesystem type and size for  log rotation 

get_fs_info(){
    df -h "$WATCH_PATH" --output=fstype,source,size 2>/dev/null | tail -1
}

# unknown user input control 
show_usage() {
    echo "Usage: $0 {start|stop|status|run|restart}" 1>&2
}

# Returns total human-readable size of WATCH_PATH 

get_dir_size() {
    du -sh "$WATCH_PATH" 2>/dev/null | awk '{print $1}'
}



# Rotate log if it has grown beyond MAX_LOG_LINES 

rotate_log_if_needed() {
    local lines

    if [[ -f "$LOG_FILE" ]]; then

        lines=$(wc -l < "$LOG_FILE")


# lines is beyond default size 250  the it rotate 

        if (( lines > MAX_LOG_LINES )); then

# handle the log_file. date with hrs and sec 

             rotated="${LOG_FILE}-$(date +%Y%m%d-%I:%S)"



# then we mv full log file to log.date we going to have (dsk.log.date) 
            mv "$LOG_FILE" "$rotated"

            echo "[$(date '+%Y-%m-%d %I:%M:%S')] Log rotated -->  $rotated" >> "$LOG_FILE"
        fi
    fi
}

# The real engine of  the daemon 
core_machine_loop(){ 

 
echo -e  "Daemon Started  [$(date '+%Y-%m-%d %I:%M:%S')]. Watching: "$WATCH_PATH" Info: $(get_fs_info)" 


# Output for logfile 
 
echo -e  "\nDaemon Started [$(date '+%Y-%m-%d %I:%M:%S')]. Watchings: $WATCH_PATH Info: $(get_fs_info) " >> "$LOG_FILE"


# Daemon running 

 while true; do
      local Set_timestamp dir_size fs_used_pct  path_all_size msg plain_msg 
       Set_timestamp=$(date '+%Y-%m-%d %I:%M:%S') 
      
     dir_size=$(get_dir_size)
 
       fs_used_pct=$(get_fs_usage_percent)
 
   	 path_all_size=$(get_fs_info | awk '{print $3}')

{    
		echo "===============================================================" 
		echo "  Timestamp : $Set_timestamp"
		echo "  Path      : $WATCH_PATH" 
		echo "  Dir size  : $dir_size"
            	echo "  FS used   : ${fs_used_pct}%"
		echo "  Path Disk size: $path_all_size"

        } >> "$LOG_FILE"

            
# break if the path i not mounted or just a dir
 if ! mountpoint -q "$WATCH_PATH"; then
            echo "(ERROR)[$Set_timestamp] $WATCH_PATH is no longer mounted or is just a dir —->  daemon stopping" >> "$LOG_FILE"
            logger -i "(ERROR)[$Set_timestamp] $WATCH_PATH is no longer mounted or just a dir — daemon stopping"
            exit 33
        fi


# thresold trigger setting i.e if the percentage grows beyond the warn percent it triggers 
if (( fs_used_pct >= WARN_PERCENT )); then

breaks="(Warning)[$Set_timestamp] Filesystem at ${fs_used_pct}% — threshold IS SAME AS ${WARN_PERCENT}% and unmounted"

plain_msg="(Warning)[$Set_timestamp] Filesystem at ${fs_used_pct}% — threshold is Beyond ${WARN_PERCENT}%"
     
  if (( "$fs_used_pct" == "$WARN_PERCENT" )) ; then 
 
   if umount "$WATCH_PATH"; then

      echo "$breaks" >>  "$LOG_FILE" 
      logger -i "$breaks"  
             exit 31
else
      echo "(ERROR)[$Set_timestamp] umount failed for $WATCH_PATH" >> "$LOG_FILE" 
          sleep "$Dang"
             continue

fi 
# mail -s "Disk Warning"  email@gmail.com 
        
elif 
        (( "$fs_used_pct" >  "$WARN_PERCENT" )); then 
 
          if umount "$WATCH_PATH"; then 
          echo "$plain_msg" >>  "$LOG_FILE" 
		logger -i "$plain_msg"
 exit 32 
else
                    echo "(ERROR)[$Set_timestamp] umount failed for $WATCH_PATH" >> "$LOG_FILE"
                 sleep "$Dang"
                    continue

                fi

# enable message to be sent to email  
# mail -s "Disk Warning" email@gmail.com 

        fi
fi  
   sleep "$Dang" 
#check log file in every iteration 
rotate_log_if_needed
done



}

# LifeCycle ============

kill_pid= 

PID_FILE="/tmp/dsk-daemon.pid"
   
# when you run for the firs time ./dsk-daemon it takes 1 as an arugment cmd=start
#  without no option/argument it cmd=run

cmd="${1:-run}"


case $cmd in
 
     Start|start|START)

        # the PID doesn't exit here so nothing to kill 
       if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "[INFO] Daemon already running (PID $(cat "$PID_FILE"))"
            exit 22
        fi
         # let the loop run in background 
        core_machine_loop  &
      # making the pid file come alive and pass the pid of the core_machine_loop to /tmp/dsk-daemon.pid
        echo $! > "$PID_FILE"
           # confirmation  sent to terminal  when start
        echo "(INFO) Daemon started in background (PID $!)"
        ;;
     stop|Stop|STOP)
            # the pid file is alive here 
        if [[ -f "$PID_FILE" ]]; then
       # store the pid into kill_pid

           kill_pid=$(cat "$PID_FILE")

         
            kill "$kill_pid" 2>/dev/null && echo -e "\033[31m[INFO] Daemon stopped\033[0m (PID $kill_pid)"
          

          rm -f "$PID_FILE"
        else
            echo -e " \033[31m(INFO) No PID file found — daemon may not be running \033[0m"
        fi
        ;;

      #  Status 
        status|Status|STATUS)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo   "(INFO) Daemon is running (PID $(cat "$PID_FILE"))"
        else
            echo -e  "\033[31m(INFO) Daemon is not running\033[0m "
        fi
        ;;

    run|Run|RUN)
       # pid already exit and it running just like restart
        core_machine_loop
        ;;
    
     *) # for unknown input 
       show_usage 
        exit 23
         ;; 




  esac 






#set +x
