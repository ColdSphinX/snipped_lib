if [[ $- =~ i ]]; then

# add filters as you like
function u@h {
  for h in $*
  do
    case $h in
    srv-*)
      echo -n "root@${h} "
    ;;
    *)
      echo -n "$USER@${h} "
    ;;
    esac
  done
}

#export CLUSTERX=(srv-x1 srv-x2 srv-x3)
#alias .clusterx="hostmux -n -s clusterx $(u@h ${CLUSTERX[@]})"

#export CLUSTERY=(srv-y1 srv-y2 srv-y3)
#alias .clustery="hostmux -n -s clusterx $(u@h ${CLUSTERY[@]})"

#alias .cluster-all="hostmux -n -s clusterx $(u@h ${CLUSTERX[@]} ${CLUSTERY[@]})"

# you get the idea :)
# you could split stage-db/stage-front/stage-backend/stage-all and so on

fi
# vi: syntax=sh ts=2
