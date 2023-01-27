xSUCCESS=unknown
trap check_finish EXIT
check_finish() {
  if [ $xSUCCESS = true ]; then
    echo '>>>' SUCCESS
  else
    echo "FAILED"
  fi
}
