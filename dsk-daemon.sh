#!/bin/bash 

#  =================================  Disk Daemon Management ================================================
#
# AUTHOR: Usman O. Olanrewaju (Blu3-Sky) 
# CREATED: 2026/06/08 
#
# STEPS USED: shoutout to  tlp for me using there steps for this daemon setups 
#
#
# STATUS: NOT YET COMPLETE BUT RUNNING
# PURPOSE: 
# this daemon helps to manage mounted Dir
# lvm
# autofs
# nfs 
# dev 
#  
# ===========================================================================================================




# There are condition here yet to be applied 
# Adding one more func later for unmount for thr file system to break  


# if [ ! -f "Config" ]; then 
 #  exit 25
#else 
 . dsk-daemon.conf  
# fi 


# Verify if the path is Directory or not with red color for error info
# for color modification you can use check William shotts textbook  
if [[ ! -d "$WATCH_PATH" ]]; then
    echo -e  "\033[31m[ERROR] WATCH_PATH does not exist or is not a directory: $WATCH_PATH \033[0m" >&2
    exit 1
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
#
show_usage() {
    echo "Usage: $0 {start|stop|status|run|restart}" 1>&2
}
# Returns total human-readable size of WATCH_PATH 

get_dir_size() {
    du -sh "$WATCH_PATH" 2>/dev/null | awk '{print $1}'
}

# Rotate log if it has grown beyond MAX_LOG_LINES
rotate_log_if_needed() {
    if [[ -f "$LOG_FILE" ]]; then
        local lines
        lines=$(wc -l < "$LOG_FILE")
        if (( lines > MAX_LOG_LINES )); then
            local rotated="${LOG_FILE}.$(date +%Y%m%d-%H%M%S)"
            mv "$LOG_FILE" "$rotated"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log rotated → $rotated" >> "$LOG_FILE"
        fi
    fi
}


# Rotate log if it has grown beyond MAX_LOG_LINES 

rotate_log_if_needed() {
    if [[ -f "$LOG_FILE" ]]; then
 # local variable 
        local lines
        lines=$(wc -l < "$LOG_FILE")

# lines is beyond default size 250  the it rotate 
#
        if (( lines > MAX_LOG_LINES )); then

# handle the log_file. date with hr and sec 
            local rotated="${LOG_FILE}.$(date +%Y%m%d-%H%M%S)"

# then we mv full log file to log.date we going to have (dsk.log.date) 
            mv "$LOG_FILE" "$rotated"

            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log rotated → $rotated" >> "$LOG_FILE"
        fi
    fi
}

# The real engine of  the daemon 
core_machine_loop(){ 

 

# Colored output to terminal only
 
echo -e  "\033[36m Daemon Started \033[0m [$(date '+%Y-%m-%d %H:%M:%S')].\033[36mWatching:\033[0m "$WATCH_PATH" \033[36m Info: \033[0m $(get_fs_info)" 

# Clean output to log file only
echo "Daemon Started [ $(date '+%Y-%m-%d %H:%M:%S')]. Watching: $WATCH_PATH Info: $(get_fs_info)" >> "$LOG_FILE"


#daemon running every sec

 while true; do
      local Set_timestamp dir_size fs_used_pct  path_all_size msg plain_msg 
       Set_timestamp=$(date '+%Y-%m-%d %H:%M:%S') 
      dir_size=$(get_dir_size)
      fs_used_pct=$(get_fs_usage_percent)
   	 path_all_size=$(get_fs_info | awk '{print $3}')

{    
		echo "=====================================================" 
		echo "  Timestamp : $Set_timestamp"
		echo "  Path      : $WATCH_PATH" 
		echo "  Dir size  : $dir_size"
            	echo "  FS used   : ${fs_used_pct}%"
		echo "  Path Disk size: $path_all_size"

        } >> "$LOG_FILE"

# threshold trigger setting i.e if the percentage grows beyond the warn percent it triggers 
if (( fs_used_pct >= WARN_PERCENT )); then

# message to show on terminal with color 
             msg="\033[31m[WARN]\033[0m[$Set_timestamp] Filesystem at ${fs_used_pct}% — threshold is ${WARN_PERCENT}%"
		
# message to show without color 
	plain_msg="[WARN][$Set_timestamp] Filesystem at ${fs_used_pct}% — threshold is ${WARN_PERCENT}%"

# broadcast message to  every logged-in terminal. check "man wall "
            echo "$msg" | wall  

 # message to send to log file 
    echo "$plain_msg" >>  "$LOG_FILE" 


# logging to system message journalctl 
		logger -i "$plain_msg"
# want the message sent via email 
 
#		mail -s "Disk Warning" email@gmail.com 

        fi
   sleep "$Dang" 

done




# ========================= LifeCycle =================================================


PID_FILE="/tmp/dsk-daemon.pid"
   
# when you run for the firs time ./dsk-daemon it takes 1 as an argument cmd=start
#  without no option/argument it cmd=run

cmd="${1:-run}"


case $cmd in 
     Start|start|START)
        # the PID doesn't exit here so nothing to kill 
       if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "[INFO] Daemon already running (PID $(cat "$PID_FILE"))"
            exit 0
        fi
         # let the loop run in background 
        core_machine_loop  &
      # making the pid file come alive and pass the pid of the core_machine_loop to /tmp/dsk-daemon.pid
        echo $! > "$PID_FILE"
           # confirmation  sent to terminal  when start
        echo "[INFO] Daemon started in background (PID $!)"
        ;;
     stop|Stop|STOP)
            # the pid file is alive here 
        if [[ -f "$PID_FILE" ]]; then
        # local variable
            local pid
       # store the pid into the local pid

            pid=$(cat "$PID_FILE")

          # stopp with local pid 
            kill "$pid" 2>/dev/null && echo "[INFO] Daemon stopped (PID $pid)"
            rm -f "$PID_FILE"
        else
            echo "[INFO] No PID file found — daemon may not be running"
        fi
        ;;
      #  Status 
        status|Status|STATUS)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "[INFO] Daemon is running (PID $(cat "$PID_FILE"))"
        else
            echo "[INFO] Daemon is not running"
        fi
        ;;
    run|Run|RUN)
       # pid already exit and it running just like restart
        core_machine_loop
        ;;
    
     restart|RESTART|Restart) 
 # SAME AS RUN 
         core_machine_loop
            ;; 
     *) # for unknown input 
        show_Usage
        exit 1 
         ;; 




  esac 






    
