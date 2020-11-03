# runtests.sh
LOGFILE=log.txt

matlab -nodesktop -nosplash -minimize -wait -logfile "$LOGFILE" -r 'executeTests';
CODE=$?

cat "$LOGFILE"

exit $CODE